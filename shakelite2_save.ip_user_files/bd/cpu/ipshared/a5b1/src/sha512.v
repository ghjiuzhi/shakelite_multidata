//Module  : sha512
// Type    : synthesizable, IP's top
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: SHA-512 Hash Calculator with AXI-Stream Interface
//           Converted from SystemVerilog to Verilog
//--------------------------------------------------------------------------------------------------------

module sha512(
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
    output wire [511:0] osha
);

// State machine encoding
parameter [2:0] IDLE   = 3'd0;
parameter [2:0] RUN    = 3'd1;
parameter [2:0] ADD8   = 3'd2;
parameter [2:0] ADD0   = 3'd3;
parameter [2:0] ADDLEN = 3'd4;
parameter [2:0] DONE   = 3'd5;

// Function declarations for SHA-512
function [63:0] SSIG0;
    input [63:0] x;
    begin
        SSIG0 = {x[0:0],x[63:1]} ^ {x[7:0],x[63:8]} ^ {7'h0,x[63:7]};
    end
endfunction

function [63:0] SSIG1;
    input [63:0] x;
    begin
        SSIG1 = {x[18:0],x[63:19]} ^ {x[60:0],x[63:61]} ^ {6'h0,x[63:6]};
    end
endfunction

function [63:0] BSIG0;
    input [63:0] x;
    begin
        BSIG0 = {x[27:0],x[63:28]} ^ {x[33:0],x[63:34]} ^ {x[38:0],x[63:39]};
    end
endfunction

function [63:0] BSIG1;
    input [63:0] x;
    begin
        BSIG1 = {x[13:0],x[63:14]} ^ {x[17:0],x[63:18]} ^ {x[40:0],x[63:41]};
    end
endfunction

// K constants (80 x 64-bit)
wire [63:0] k [0:79];
assign k[ 0] = 64'h428a2f98d728ae22;
assign k[ 1] = 64'h7137449123ef65cd;
assign k[ 2] = 64'hb5c0fbcfec4d3b2f;
assign k[ 3] = 64'he9b5dba58189dbbc;
assign k[ 4] = 64'h3956c25bf348b538;
assign k[ 5] = 64'h59f111f1b605d019;
assign k[ 6] = 64'h923f82a4af194f9b;
assign k[ 7] = 64'hab1c5ed5da6d8118;
assign k[ 8] = 64'hd807aa98a3030242;
assign k[ 9] = 64'h12835b0145706fbe;
assign k[10] = 64'h243185be4ee4b28c;
assign k[11] = 64'h550c7dc3d5ffb4e2;
assign k[12] = 64'h72be5d74f27b896f;
assign k[13] = 64'h80deb1fe3b1696b1;
assign k[14] = 64'h9bdc06a725c71235;
assign k[15] = 64'hc19bf174cf692694;
assign k[16] = 64'he49b69c19ef14ad2;
assign k[17] = 64'hefbe4786384f25e3;
assign k[18] = 64'h0fc19dc68b8cd5b5;
assign k[19] = 64'h240ca1cc77ac9c65;
assign k[20] = 64'h2de92c6f592b0275;
assign k[21] = 64'h4a7484aa6ea6e483;
assign k[22] = 64'h5cb0a9dcbd41fbd4;
assign k[23] = 64'h76f988da831153b5;
assign k[24] = 64'h983e5152ee66dfab;
assign k[25] = 64'ha831c66d2db43210;
assign k[26] = 64'hb00327c898fb213f;
assign k[27] = 64'hbf597fc7beef0ee4;
assign k[28] = 64'hc6e00bf33da88fc2;
assign k[29] = 64'hd5a79147930aa725;
assign k[30] = 64'h06ca6351e003826f;
assign k[31] = 64'h142929670a0e6e70;
assign k[32] = 64'h27b70a8546d22ffc;
assign k[33] = 64'h2e1b21385c26c926;
assign k[34] = 64'h4d2c6dfc5ac42aed;
assign k[35] = 64'h53380d139d95b3df;
assign k[36] = 64'h650a73548baf63de;
assign k[37] = 64'h766a0abb3c77b2a8;
assign k[38] = 64'h81c2c92e47edaee6;
assign k[39] = 64'h92722c851482353b;
assign k[40] = 64'ha2bfe8a14cf10364;
assign k[41] = 64'ha81a664bbc423001;
assign k[42] = 64'hc24b8b70d0f89791;
assign k[43] = 64'hc76c51a30654be30;
assign k[44] = 64'hd192e819d6ef5218;
assign k[45] = 64'hd69906245565a910;
assign k[46] = 64'hf40e35855771202a;
assign k[47] = 64'h106aa07032bbd1b8;
assign k[48] = 64'h19a4c116b8d2d0c8;
assign k[49] = 64'h1e376c085141ab53;
assign k[50] = 64'h2748774cdf8eeb99;
assign k[51] = 64'h34b0bcb5e19b48a8;
assign k[52] = 64'h391c0cb3c5c95a63;
assign k[53] = 64'h4ed8aa4ae3418acb;
assign k[54] = 64'h5b9cca4f7763e373;
assign k[55] = 64'h682e6ff3d6b2b8a3;
assign k[56] = 64'h748f82ee5defb2fc;
assign k[57] = 64'h78a5636f43172f60;
assign k[58] = 64'h84c87814a1f0ab72;
assign k[59] = 64'h8cc702081a6439ec;
assign k[60] = 64'h90befffa23631e28;
assign k[61] = 64'ha4506cebde82bde9;
assign k[62] = 64'hbef9a3f7b2c67915;
assign k[63] = 64'hc67178f2e372532b;
assign k[64] = 64'hca273eceea26619c;
assign k[65] = 64'hd186b8c721c0c207;
assign k[66] = 64'heada7dd6cde0eb1e;
assign k[67] = 64'hf57d4f7fee6ed178;
assign k[68] = 64'h06f067aa72176fba;
assign k[69] = 64'h0a637dc5a2c898a6;
assign k[70] = 64'h113f9804bef90dae;
assign k[71] = 64'h1b710b35131c471b;
assign k[72] = 64'h28db77f523047d84;
assign k[73] = 64'h32caab7b40c72493;
assign k[74] = 64'h3c9ebe0a15c9bebc;
assign k[75] = 64'h431d67c49c100d4c;
assign k[76] = 64'h4cc5d4becb3e42b6;
assign k[77] = 64'h597f299cfc657e2a;
assign k[78] = 64'h5fcb6fab3ad6faec;
assign k[79] = 64'h6c44198c4a475817;

// Initial hash values (8 x 64-bit)
wire [63:0] hinit [0:7];
reg  [63:0] h [0:7];
reg  [63:0] hsave [0:7];
reg  [63:0] hadder [0:7];
assign hinit[ 0] = 64'h6a09e667f3bcc908;
assign hinit[ 1] = 64'hbb67ae8584caa73b;
assign hinit[ 2] = 64'h3c6ef372fe94f82b;
assign hinit[ 3] = 64'ha54ff53a5f1d36f1;
assign hinit[ 4] = 64'h510e527fade682d1;
assign hinit[ 5] = 64'h9b05688c2b3e6c1f;
assign hinit[ 6] = 64'h1f83d9abfb41bd6b;
assign hinit[ 7] = 64'h5be0cd19137e2179;

// W message schedule array and buffer (SHA-512 uses 128-byte blocks)
reg [63:0] w [0:15];
reg [ 7:0] buff [0:127];

// State machine and counters
reg  [2:0] status;
reg  [60:0] cnt;
reg  [ 6:0] tcnt;
wire [127:0] bitlen;
assign bitlen = {64'h0,cnt,3'h0};

// Pipeline registers
wire       iinit;
reg        ifirst;
reg        ivalid;
reg        ilast;
reg [60:0] ilen;
reg [31:0] iid;
reg [ 7:0] idata;
reg [ 6:0] icnt;

// Edge detection for tvalid
reg        tvalid_d;
wire       tvalid_posedge;

reg        minit;
reg        men;
reg        mlast;
reg [31:0] mid;
reg [60:0] mlen;
reg [ 6:0] mcnt;
reg        winit;
reg        wen;
reg        wlast;
reg [31:0] wid;
reg [60:0] wlen;
reg        wstart;
reg        wfinal;
reg [63:0] wadder;
reg        wkinit;
reg        wken;
reg        wklast;
reg [31:0] wkid;
reg [60:0] wklen;
reg        wkstart;
reg [63:0] wk;

// Temporary variables for hash computation
reg [63:0] t1, t2;

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
    tcnt = 7'd0;
    tvalid_d = 1'b0;
    ifirst = 1'b0;
    ivalid = 1'b0;
    ilast = 1'b0;
    ilen = 61'd0;
    iid = 32'd0;
    idata = 8'd0;
    icnt = 7'd0;
    minit = 1'b0;
    men = 1'b0;
    mlast = 1'b0;
    mid = 32'd0;
    mlen = 61'd0;
    mcnt = 7'd0;
    winit = 1'b0;
    wen = 1'b0;
    wlast = 1'b0;
    wid = 32'd0;
    wlen = 61'd0;
    wstart = 1'b0;
    wfinal = 1'b0;
    wadder = 64'd0;
    wkinit = 1'b0;
    wken = 1'b0;
    wklast = 1'b0;
    wkid = 32'd0;
    wklen = 61'd0;
    wkstart = 1'b0;
    wk = 64'd0;
    ovalid = 1'b0;
    oid = 32'd0;
    olen = 61'd0;
    for(i=0; i<8; i=i+1) begin
        h[i] = 64'd0;
        hsave[i] = 64'd0;
        hadder[i] = 64'd0;
    end
    for(i=0; i<16; i=i+1) w[i] = 64'd0;
    for(i=0; i<128; i=i+1) buff[i] = 8'd0;
end

// Main state machine
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        status <= IDLE;
        cnt <= 61'd0;
        tcnt <= 7'd0;
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
                tcnt <= cnt[6:0] + 7'd1;
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
                tcnt <= cnt[6:0] + 7'd1;
                ivalid <= tvalid_posedge;
                if(&tcnt) ifirst <= 1'b0;
                ilast  <= 1'b0;
                idata  <= tdata;
            end
            ADD8    : begin
                status <= (cnt[6:0]==7'h6f) ? ADDLEN : ADD0;
                tcnt <= cnt[6:0] + 7'd1;
                ivalid <= 1'b1;
                if(&tcnt) ifirst <= 1'b0;
                ilast  <= 1'b0;
                idata  <= 8'h80;
            end
            ADD0    : begin
                status <= (tcnt==7'h6f) ? ADDLEN : ADD0;
                tcnt <= tcnt + 7'd1;
                ivalid <= 1'b1;
                if(&tcnt) ifirst <= 1'b0;
                ilast  <= 1'b0;
                idata  <= 8'h00;
            end
            ADDLEN  : begin
                status <= (&tcnt) ? DONE : ADDLEN;
                tcnt <= tcnt + 7'd1;
                ivalid <= 1'b1;
                if(&tcnt) ifirst <= 1'b0;
                ilast  <= (&tcnt);
                case(tcnt[3:0])
                    4'd0:  idata <= bitlen[127:120];
                    4'd1:  idata <= bitlen[119:112];
                    4'd2:  idata <= bitlen[111:104];
                    4'd3:  idata <= bitlen[103: 96];
                    4'd4:  idata <= bitlen[ 95: 88];
                    4'd5:  idata <= bitlen[ 87: 80];
                    4'd6:  idata <= bitlen[ 79: 72];
                    4'd7:  idata <= bitlen[ 71: 64];
                    4'd8:  idata <= bitlen[ 63: 56];
                    4'd9:  idata <= bitlen[ 55: 48];
                    4'd10: idata <= bitlen[ 47: 40];
                    4'd11: idata <= bitlen[ 39: 32];
                    4'd12: idata <= bitlen[ 31: 24];
                    4'd13: idata <= bitlen[ 23: 16];
                    4'd14: idata <= bitlen[ 15:  8];
                    4'd15: idata <= bitlen[  7:  0];
                endcase
            end
            default : begin
                status <= IDLE;
                cnt <= 61'd0;
                tcnt <= 7'd0;
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
        icnt <= 7'd0;
        for(i=0; i<128; i=i+1) buff[i] <= 8'd0;
    end else begin
        if(iinit) begin
            icnt <= 7'd0;
        end else if(ivalid) begin
            buff[icnt] <= idata;
            icnt <= icnt + 7'd1;
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
        mcnt  <= 7'd0;
    end else begin
        minit <= ifirst & (icnt==7'h7e);
        if(ifirst & (icnt==7'h7e)) begin
            men   <= 1'b0;
            mlast <= 1'b0;
            mcnt  <= 7'd0;
        end else if(ivalid & (&icnt)) begin
            men   <= 1'b1;
            mlast <= ilast;
            mid   <= iid;
            mlen  <= ilen;
            mcnt  <= 7'd0;
        end else begin
            if(mcnt==7'h4f) begin
                men   <= 1'b0;
                mlast <= 1'b0;
            end
            if(men)
                mcnt <= mcnt + 7'd1;
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
        wadder <= 64'd0;
        for(i=0; i<16; i=i+1) w[i] <= 64'd0;
    end else begin
        winit  <= minit;
        wen    <= men;
        wlast  <= mlast & (mcnt==7'h4f);
        wid    <= mid;
        wlen   <= mlen;
        wstart <= men & (mcnt==7'h00);
        wfinal <= men & (mcnt==7'h4f);
        wadder <= k[mcnt];
        if(mcnt<7'd16) begin
            // Load W from buffer (8 bytes per word for SHA-512)
            w[0] <= {buff[{mcnt[3:0],3'd0}],
                     buff[{mcnt[3:0],3'd1}],
                     buff[{mcnt[3:0],3'd2}],
                     buff[{mcnt[3:0],3'd3}],
                     buff[{mcnt[3:0],3'd4}],
                     buff[{mcnt[3:0],3'd5}],
                     buff[{mcnt[3:0],3'd6}],
                     buff[{mcnt[3:0],3'd7}]};
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
        wk <= 64'd0;
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
        for(i=0; i<8; i=i+1) hsave[i] <= 64'd0;
    end else begin
        if(wkstart)
            for(i=0; i<8; i=i+1) hsave[i] <= h[i];
    end

// Prepare adder values
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        for(i=0; i<8; i=i+1) hadder[i] <= 64'd0;
    end else begin
        if(wfinal) begin
            for(i=0; i<8; i=i+1) hadder[i] <= hsave[i];
        end else begin
            for(i=0; i<8; i=i+1) hadder[i] <= 64'd0;
        end
    end

// Main hash computation
always @ (posedge clk or negedge rstn)
    if(~rstn) begin
        for(i=0; i<8; i=i+1) h[i] <= 64'd0;
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