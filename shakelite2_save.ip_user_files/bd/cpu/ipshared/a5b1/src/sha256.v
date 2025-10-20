//--------------------------------------------------------------------------------------------------------
// Module  : sha256
// Type    : synthesizable, IP's top
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: SHA-256 Hash Calculator with AXI-Stream Interface
//           Converted from SystemVerilog to Verilog
//--------------------------------------------------------------------------------------------------------

module sha256(
    input  wire         rstn,
    input  wire         clk,
    input  wire         tvalid,
    output wire         tready,
    input  wire         tlast,
    input  wire [ 31:0] tid,
    input  wire [  7:0] tdata,
    output reg          ovalid,
    output reg  [ 31:0] oid,
    output reg  [ 60:0] olen,
    output wire [255:0] osha
);

// State machine encoding
parameter [2:0] IDLE   = 3'd0;
parameter [2:0] RUN    = 3'd1;
parameter [2:0] ADD8   = 3'd2;
parameter [2:0] ADD0   = 3'd3;
parameter [2:0] ADDLEN = 3'd4;
parameter [2:0] DONE   = 3'd5;

// Function declarations
function [31:0] SSIG0;
    input [31:0] x;
    begin
        SSIG0 = {x[6:0],x[31:7]} ^ {x[17:0],x[31:18]} ^ {3'h0,x[31:3]};
    end
endfunction

function [31:0] SSIG1;
    input [31:0] x;
    begin
        SSIG1 = {x[16:0],x[31:17]} ^ {x[18:0],x[31:19]} ^ {10'h0,x[31:10]};
    end
endfunction

function [31:0] BSIG0;
    input [31:0] x;
    begin
        BSIG0 = {x[1:0],x[31:2]} ^ {x[12:0],x[31:13]} ^ {x[21:0],x[31:22]};
    end
endfunction

function [31:0] BSIG1;
    input [31:0] x;
    begin
        BSIG1 = {x[5:0],x[31:6]} ^ {x[10:0],x[31:11]} ^ {x[24:0],x[31:25]};
    end
endfunction

// K constants (64 x 32-bit)
wire [31:0] k [0:63];
assign k[ 0] = 32'h428a2f98;
assign k[ 1] = 32'h71374491;
assign k[ 2] = 32'hb5c0fbcf;
assign k[ 3] = 32'he9b5dba5;
assign k[ 4] = 32'h3956c25b;
assign k[ 5] = 32'h59f111f1;
assign k[ 6] = 32'h923f82a4;
assign k[ 7] = 32'hab1c5ed5;
assign k[ 8] = 32'hd807aa98;
assign k[ 9] = 32'h12835b01;
assign k[10] = 32'h243185be;
assign k[11] = 32'h550c7dc3;
assign k[12] = 32'h72be5d74;
assign k[13] = 32'h80deb1fe;
assign k[14] = 32'h9bdc06a7;
assign k[15] = 32'hc19bf174;
assign k[16] = 32'he49b69c1;
assign k[17] = 32'hefbe4786;
assign k[18] = 32'h0fc19dc6;
assign k[19] = 32'h240ca1cc;
assign k[20] = 32'h2de92c6f;
assign k[21] = 32'h4a7484aa;
assign k[22] = 32'h5cb0a9dc;
assign k[23] = 32'h76f988da;
assign k[24] = 32'h983e5152;
assign k[25] = 32'ha831c66d;
assign k[26] = 32'hb00327c8;
assign k[27] = 32'hbf597fc7;
assign k[28] = 32'hc6e00bf3;
assign k[29] = 32'hd5a79147;
assign k[30] = 32'h06ca6351;
assign k[31] = 32'h14292967;
assign k[32] = 32'h27b70a85;
assign k[33] = 32'h2e1b2138;
assign k[34] = 32'h4d2c6dfc;
assign k[35] = 32'h53380d13;
assign k[36] = 32'h650a7354;
assign k[37] = 32'h766a0abb;
assign k[38] = 32'h81c2c92e;
assign k[39] = 32'h92722c85;
assign k[40] = 32'ha2bfe8a1;
assign k[41] = 32'ha81a664b;
assign k[42] = 32'hc24b8b70;
assign k[43] = 32'hc76c51a3;
assign k[44] = 32'hd192e819;
assign k[45] = 32'hd6990624;
assign k[46] = 32'hf40e3585;
assign k[47] = 32'h106aa070;
assign k[48] = 32'h19a4c116;
assign k[49] = 32'h1e376c08;
assign k[50] = 32'h2748774c;
assign k[51] = 32'h34b0bcb5;
assign k[52] = 32'h391c0cb3;
assign k[53] = 32'h4ed8aa4a;
assign k[54] = 32'h5b9cca4f;
assign k[55] = 32'h682e6ff3;
assign k[56] = 32'h748f82ee;
assign k[57] = 32'h78a5636f;
assign k[58] = 32'h84c87814;
assign k[59] = 32'h8cc70208;
assign k[60] = 32'h90befffa;
assign k[61] = 32'ha4506ceb;
assign k[62] = 32'hbef9a3f7;
assign k[63] = 32'hc67178f2;

// Initial hash values (8 x 32-bit)
wire [31:0] hinit [0:7];
reg  [31:0] h [0:7];
reg  [31:0] hsave [0:7];
reg  [31:0] hadder [0:7];
assign hinit[0] = 32'h6a09e667;
assign hinit[1] = 32'hbb67ae85;
assign hinit[2] = 32'h3c6ef372;
assign hinit[3] = 32'ha54ff53a;
assign hinit[4] = 32'h510e527f;
assign hinit[5] = 32'h9b05688c;
assign hinit[6] = 32'h1f83d9ab;
assign hinit[7] = 32'h5be0cd19;

// W message schedule array and buffer
reg [31:0] w [0:15];
reg [ 7:0] buff [0:63];

// State machine and counters
reg  [2:0] status;
reg  [60:0] cnt;
reg  [ 5:0] tcnt;
wire [63:0] bitlen;
assign bitlen = {cnt,3'h0};

// Pipeline registers
wire       iinit;
reg        ifirst;
reg        ivalid;
reg        ilast;
reg [60:0] ilen;
reg [31:0] iid;
reg [ 7:0] idata;
reg [ 5:0] icnt;

// Edge detection for tvalid
reg        tvalid_d;
wire       tvalid_posedge;

reg        minit;
reg        men;
reg        mlast;
reg [31:0] mid;
reg [60:0] mlen;
reg [ 5:0] mcnt;
reg        winit;
reg        wen;
reg        wlast;
reg [31:0] wid;
reg [60:0] wlen;
reg        wstart;
reg        wfinal;
reg [31:0] wadder;
reg        wkinit;
reg        wken;
reg        wklast;
reg [31:0] wkid;
reg [60:0] wklen;
reg        wkstart;
reg [31:0] wk;

// Temporary variables for hash computation
reg [31:0] t1, t2;

// Control signals
assign tready = (status==IDLE) || (status==RUN);
assign iinit  = (status==IDLE) & tvalid_posedge;

// Edge detection for tvalid
assign tvalid_posedge = tvalid & ~tvalid_d;

// Initialize registers
integer i;
initial begin
    status = IDLE;
    cnt = 61'd0;
    tcnt = 6'd0;
    tvalid_d = 1'b0;
    ifirst = 1'b0;
    ivalid = 1'b0;
    ilast = 1'b0;
    ilen = 61'd0;
    iid = 32'd0;
    idata = 8'd0;
    icnt = 6'd0;
    minit = 1'b0;
    men = 1'b0;
    mlast = 1'b0;
    mid = 32'd0;
    mlen = 61'd0;
    mcnt = 6'd0;
    winit = 1'b0;
    wen = 1'b0;
    wlast = 1'b0;
    wid = 32'd0;
    wlen = 61'd0;
    wstart = 1'b0;
    wfinal = 1'b0;
    wadder = 32'd0;
    wkinit = 1'b0;
    wken = 1'b0;
    wklast = 1'b0;
    wkid = 32'd0;
    wklen = 61'd0;
    wkstart = 1'b0;
    wk = 32'd0;
    ovalid = 1'b0;
    oid = 32'd0;
    olen = 61'd0;
    for(i=0; i<8; i=i+1) begin
        h[i] = 32'd0;
        hsave[i] = 32'd0;
        hadder[i] = 32'd0;
    end
    for(i=0; i<16; i=i+1) w[i] = 32'd0;
    for(i=0; i<64; i=i+1) buff[i] = 8'd0;
end

// Main state machine
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        status <= IDLE;
        cnt <= 61'd0;
        tcnt <= 6'd0;
        tvalid_d <= 1'b0;
        ivalid <= 1'b0;
        ifirst <= 1'b0;
        ilast <= 1'b0;
        ilen <= 61'd0;
        iid <= 32'd0;
        idata <= 8'd0;
    end else begin
        // Update edge detection register
        tvalid_d <= tvalid;
        
        ilen <= cnt;
        case(status)
            IDLE   : begin
                if(tvalid_posedge) begin
                    status <= tlast ? ADD8 : RUN;
                    cnt <= 61'd1;
                end
                tcnt <= cnt[5:0] + 6'd1;
                ivalid <= tvalid_posedge;
                ifirst <= tvalid_posedge;
                ilast  <= 1'b0;
                iid    <= tid;
                idata  <= tdata;
            end
            RUN     : begin
                if(tvalid_posedge) begin
                    status <= tlast ? ADD8 : RUN;
                    cnt <= cnt + 61'd1;
                end
                tcnt <= cnt[5:0] + 6'd1;
                ivalid <= tvalid_posedge;
                if(tcnt==6'h3f) ifirst <= 1'b0;
                ilast  <= 1'b0;
                idata  <= tdata;
            end
            ADD8    : begin
                status <= (cnt[5:0]==6'h37) ? ADDLEN : ADD0;
                tcnt <= cnt[5:0] + 6'd1;
                ivalid <= 1'b1;
                if(tcnt==6'h3f) ifirst <= 1'b0;
                ilast  <= 1'b0;
                idata  <= 8'h80;
            end
            ADD0    : begin
                status <= (tcnt==6'h37) ? ADDLEN : ADD0;
                tcnt <= tcnt + 6'd1;
                ivalid <= 1'b1;
                if(tcnt==6'h3f) ifirst <= 1'b0;
                ilast  <= 1'b0;
                idata  <= 8'h00;
            end
            ADDLEN  : begin
                status <= (tcnt==6'h3f) ? DONE : ADDLEN;
                tcnt <= tcnt + 6'd1;
                ivalid <= 1'b1;
                if(tcnt==6'h3f) ifirst <= 1'b0;
                ilast  <= (tcnt==6'h3f);
                case(tcnt[2:0])
                    3'd0: idata <= bitlen[63:56];
                    3'd1: idata <= bitlen[55:48];
                    3'd2: idata <= bitlen[47:40];
                    3'd3: idata <= bitlen[39:32];
                    3'd4: idata <= bitlen[31:24];
                    3'd5: idata <= bitlen[23:16];
                    3'd6: idata <= bitlen[15: 8];
                    3'd7: idata <= bitlen[ 7: 0];
                endcase
            end
            default : begin
                status <= IDLE;
                cnt <= 61'd0;
                tcnt <= 6'd0;
                ivalid <= 1'b0;
                ifirst <= 1'b0;
                ilast <= 1'b0;
                ilen <= 61'd0;
                idata <= 8'd0;
            end
        endcase
    end

// Buffer input data
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        icnt <= 6'd0;
        for(i=0; i<64; i=i+1) buff[i] <= 8'd0;
    end else begin
        if(iinit) begin
            icnt <= 6'd0;
        end else if(ivalid) begin
            buff[icnt] <= idata;
            icnt <= icnt + 6'd1;
        end
    end

// Pipeline stage: minit, men, mlast
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        minit <= 1'b0;
        men   <= 1'b0;
        mlast <= 1'b0;
        mid   <= 32'd0;
        mlen  <= 61'd0;
        mcnt  <= 6'd0;
    end else begin
        minit <= ifirst & (icnt==6'h3e);
        if(ifirst & (icnt==6'h3e)) begin
            men   <= 1'b0;
            mlast <= 1'b0;
            mcnt  <= 6'd0;
        end else if(ivalid & (icnt==6'h3f)) begin
            men   <= 1'b1;
            mlast <= ilast;
            mid   <= iid;
            mlen  <= ilen;
            mcnt  <= 6'd0;
        end else begin
            if(mcnt==6'h3f) begin
                men   <= 1'b0;
                mlast <= 1'b0;
            end
            if(men)
                mcnt <= mcnt + 6'd1;
        end
    end

// Pipeline stage: W message schedule
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        winit  <= 1'b0;
        wen    <= 1'b0;
        wlast  <= 1'b0;
        wid    <= 32'd0;
        wlen   <= 61'd0;
        wstart <= 1'b0;
        wfinal <= 1'b0;
        wadder <= 32'd0;
        for(i=0; i<16; i=i+1) w[i] <= 32'd0;
    end else begin
        winit  <= minit;
        wen    <= men;
        wlast  <= mlast & (mcnt==6'h3f);
        wid    <= mid;
        wlen   <= mlen;
        wstart <= men & (mcnt==6'h00);
        wfinal <= men & (mcnt==6'h3f);
        wadder <= k[mcnt];
        if(mcnt<6'd16) begin
            // Load W from buffer
            w[0] <= {buff[{mcnt[3:0],2'd0}],
                     buff[{mcnt[3:0],2'd1}],
                     buff[{mcnt[3:0],2'd2}],
                     buff[{mcnt[3:0],2'd3}]};
        end else begin
            // Calculate W from previous values
            w[0] <= SSIG1(w[1]) + w[6] + SSIG0(w[14]) + w[15];
        end
        for(i=1; i<16; i=i+1) w[i] <= w[i-1];
    end

// Pipeline stage: Add K constant
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        wkinit <= 1'b0;
        wken <= 1'b0;
        wklast <= 1'b0;
        wkid   <= 32'd0;
        wklen  <= 61'd0;
        wkstart <= 1'b0;
        wk <= 32'd0;
    end else begin
        wkinit <= winit;
        wken <= wen;
        wklast <= wlast;
        wkid   <= wid;
        wklen  <= wlen;
        wkstart <= wstart;
        wk <= w[0] + wadder;
    end

// Save hash values at block start
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        for(i=0; i<8; i=i+1) hsave[i] <= 32'd0;
    end else begin
        if(wkstart)
            for(i=0; i<8; i=i+1) hsave[i] <= h[i];
    end

// Prepare adder values
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        for(i=0; i<8; i=i+1) hadder[i] <= 32'd0;
    end else begin
        if(wfinal) begin
            for(i=0; i<8; i=i+1) hadder[i] <= hsave[i];
        end else begin
            for(i=0; i<8; i=i+1) hadder[i] <= 32'd0;
        end
    end

// Main hash computation
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        for(i=0; i<8; i=i+1) h[i] <= 32'd0;
    end else begin
        if(wkinit) begin
            for(i=0; i<8; i=i+1) h[i] <= hinit[i];
        end else if(wken) begin
            t1 = h[7] + BSIG1(h[4]) + ((h[4] &  h[5]) ^ (~h[4] & h[6])) + wk;
            t2 = BSIG0(h[0]) + ((h[0] & h[1]) ^ (h[0] & h[2]) ^ (h[1] & h[2]));
            h[7] <= hadder[7] + h[6];
            h[6] <= hadder[6] + h[5];
            h[5] <= hadder[5] + h[4];
            h[4] <= hadder[4] + h[3] + t1;
            h[3] <= hadder[3] + h[2];
            h[2] <= hadder[2] + h[1];
            h[1] <= hadder[1] + h[0];
            h[0] <= hadder[0] + t1 + t2;
        end
    end

// Output hash value
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        ovalid <= 1'b0;
        oid  <= 32'd0;
        olen <= 61'd0;
    end else begin
        ovalid <= wklast;
        oid  <= wkid;
        olen <= wklen;
    end

assign osha = {h[0],h[1],h[2],h[3],h[4],h[5],h[6],h[7]};

endmodule