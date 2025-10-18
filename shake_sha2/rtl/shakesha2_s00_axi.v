`timescale 1 ns / 1 ps

module shake_sha2_ip_v1_0_S00_AXI #
(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH = 8
)
(
    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line

    // Global Clock Signal
    input wire  S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input wire  S_AXI_ARESETN,
    // Write address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    // Write channel Protection type. This signal indicates the
        // privilege and security level of the transaction, and whether
        // the transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_AWPROT,
    // Write address valid. This signal indicates that the master signaling
        // valid write address and control information.
    input wire  S_AXI_AWVALID,
    // Write address ready. This signal indicates that the slave is ready
        // to accept an address and associated control signals.
    output wire  S_AXI_AWREADY,
    // Write data (issued by master, acceped by Slave) 
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte lanes hold
        // valid data. There is one write strobe bit for each eight
        // bits of the write data bus.    
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    // Write valid. This signal indicates that valid write
        // data and strobes are available.
    input wire  S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
        // can accept the write data.
    output wire  S_AXI_WREADY,
    // Write response. This signal indicates the status
        // of the write transaction.
    output wire [1 : 0] S_AXI_BRESP,
    // Write response valid. This signal indicates that the channel
        // is signaling a valid write response.
    output wire  S_AXI_BVALID,
    // Response ready. This signal indicates that the master
        // can accept a write response.
    input wire  S_AXI_BREADY,
    // Read address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    // Protection type. This signal indicates the privilege
        // and security level of the transaction, and whether the
        // transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_ARPROT,
    // Read address valid. This signal indicates that the channel
        // is signaling valid read address and control information.
    input wire  S_AXI_ARVALID,
    // Read address ready. This signal indicates that the slave is
        // ready to accept an address and associated control signals.
    output wire  S_AXI_ARREADY,
    // Read data (issued by slave)
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    // Read response. This signal indicates the status of the
        // read transfer.
    output wire [1 : 0] S_AXI_RRESP,
    // Read valid. This signal indicates that the channel is
        // signaling the required read data.
    output wire  S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
        // accept the read data and response information.
    input wire  S_AXI_RREADY
);

// AXI4LITE signals
reg [C_S_AXI_ADDR_WIDTH-1 : 0]  axi_awaddr;
reg  axi_awready;
reg  axi_wready;
reg [1 : 0]  axi_bresp;
reg  axi_bvalid;
reg [C_S_AXI_ADDR_WIDTH-1 : 0]  axi_araddr;
reg  axi_arready;
reg [C_S_AXI_DATA_WIDTH-1 : 0]  axi_rdata;
reg [1 : 0]  axi_rresp;
reg  axi_rvalid;

// Example-specific design signals
// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
// ADDR_LSB is used for addressing 32/64 bit registers/memories
// ADDR_LSB = 2 for 32 bits (n downto 2)
// ADDR_LSB = 3 for 64 bits (n downto 3)
localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
localparam integer OPT_MEM_ADDR_BITS = 5;
//----------------------------------------------
//-- Signals for user logic register space example
//------------------------------------------------
//-- Number of Slave Registers 52
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;  // Control: algo_mode, start, hold
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;  // SHAKE din_i low 32-bit
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;  // SHAKE din_i high 32-bit
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;  // SHAKE last_din, byte, valid, ready
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg4;  // SHA2 tdata (3 bytes), reserved
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg5;  // SHA2 tid
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg6;  // SHA2 tvalid, tlast, reserved
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg7;  // Status: state, valid, busy, ready, ovalid (read-only)
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg8;  // SHA2 oid (read-only)
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg9;  // SHA2 olen low (read-only)
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg10; // SHA2 olen high (read-only)

 // Result registers (42 registers for 1344 bits)
    reg [C_S_AXI_DATA_WIDTH-1:0] result_regs [0:41];
    
wire  slv_reg_rden;
wire  slv_reg_wren;
reg [C_S_AXI_DATA_WIDTH-1:0]  reg_data_out;
integer  byte_index;
reg  aw_en;

// I/O Connections assignments

assign S_AXI_AWREADY = axi_awready;
assign S_AXI_WREADY = axi_wready;
assign S_AXI_BRESP = axi_bresp;
assign S_AXI_BVALID = axi_bvalid;
assign S_AXI_ARREADY = axi_arready;
assign S_AXI_RDATA = axi_rdata;
assign S_AXI_RRESP = axi_rresp;
assign S_AXI_RVALID = axi_rvalid;
// Implement axi_awready generation
// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
// de-asserted when reset is low.

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_awready <= 1'b0;
      aw_en <= 1'b1;
    end 
  else
    begin    
      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
        begin
          // slave is ready to accept write address when 
          // there is a valid write address and write data
          // on the write address and data bus. This design 
          // expects no outstanding transactions. 
          axi_awready <= 1'b1;
          aw_en <= 1'b0;
        end
        else if (S_AXI_BREADY && axi_bvalid)
            begin
              aw_en <= 1'b1;
              axi_awready <= 1'b0;
            end
      else           
        begin
          axi_awready <= 1'b0;
        end
    end 
end       

// Implement axi_awaddr latching
// This process is used to latch the address when both 
// S_AXI_AWVALID and S_AXI_WVALID are valid. 

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_awaddr <= 0;
    end 
  else
    begin    
      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
        begin
          // Write Address latching 
          axi_awaddr <= S_AXI_AWADDR;
        end
    end 
end       

// Implement axi_wready generation
// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
// de-asserted when reset is low. 

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_wready <= 1'b0;
    end 
  else
    begin    
      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en )
        begin
          // slave is ready to accept write data when 
          // there is a valid write address and write data
          // on the write address and data bus. This design 
          // expects no outstanding transactions. 
          axi_wready <= 1'b1;
        end
      else
        begin
          axi_wready <= 1'b0;
        end
    end 
end       

// Implement memory mapped register select and write logic generation
// The write data is accepted and written to memory mapped registers when
// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
// select byte enables of slave registers while writing.
// These registers are cleared when reset (active low) is applied.
// Slave register write enable is asserted when valid address and data are available
// and the slave is ready to accept the write address and write data.
assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      slv_reg0 <= 0;
      slv_reg1 <= 0;
      slv_reg2 <= 0;
      slv_reg3 <= 0;
      slv_reg4 <= 0;
      slv_reg5 <= 0;
      slv_reg6 <= 0;
    end 
  else begin
    if (slv_reg_wren)
      begin
        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
          6'h00:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Control: algo_mode [3:0], start, hold
                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h01:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // SHAKE din_i low 32-bit
                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h02:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // SHAKE din_i high 32-bit
                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h03:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // SHAKE last_din, byte, valid, ready
                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h04:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // SHA2 tdata (3 bytes)
                slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h05:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // SHA2 tid
                slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h06:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // SHA2 tvalid, tlast
                slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          default : begin
                      slv_reg0 <= slv_reg0;
                      slv_reg1 <= slv_reg1;
                      slv_reg2 <= slv_reg2;
                      slv_reg3 <= slv_reg3;
                      slv_reg4 <= slv_reg4;
                      slv_reg5 <= slv_reg5;
                      slv_reg6 <= slv_reg6;
                    end
        endcase
      end
    // Only update read-only registers in status/output logic below
  end    
end    

// Implement write response logic generation
// The write response and response valid signals are asserted by the slave 
// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
// This marks the acceptance of address and indicates the status of 
// write transaction.

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_bvalid  <= 0;
      axi_bresp   <= 2'b0;
    end 
  else
    begin    
      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
        begin
          // indicates a valid write response is available
          axi_bvalid <= 1'b1;
          axi_bresp  <= 2'b0; // 'OKAY' response 
        end                   // work error responses in future
      else
        begin
          if (S_AXI_BREADY && axi_bvalid) 
            //check if bready is asserted while bvalid is high 
            begin
              axi_bvalid <= 1'b0; 
            end  
        end
    end
end   

// Implement axi_arready generation
// axi_arready is asserted for one S_AXI_ACLK clock cycle when
// S_AXI_ARVALID is asserted. axi_awready is 
// de-asserted when reset (active low) is asserted. 
// The read address is also latched once S_AXI_ARVALID is 
// asserted. axi_araddr is reset to zero on reset assertion.

always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_arready <= 1'b0;
      axi_araddr  <= 32'b0;
    end 
  else
    begin    
      if (~axi_arready && S_AXI_ARVALID)
        begin
          // indicates that the slave has acceped the valid read address
          axi_arready <= 1'b1;
          // Read address latching
          axi_araddr  <= S_AXI_ARADDR;
        end
      else
        begin
          axi_arready <= 1'b0;
        end
    end 
end       

// Implement axi_arvalid generation
// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
// data are available on the axi_rdata bus at this instance. The 
// assertion of axi_rvalid marks the validity of read data on the 
// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
// is deasserted on reset (active low). axi_rresp and axi_rdata are 
// cleared to zero on reset (active low).  
always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_rvalid <= 0;
      axi_rresp  <= 0;
    end 
  else
    begin    
      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
        begin
          // Valid read data is available at the read data bus
          axi_rvalid <= 1'b1;
          axi_rresp  <= 2'b0; // 'OKAY' response
        end   
      else if (axi_rvalid && S_AXI_RREADY)
        begin
          // Read data is accepted by the master
          axi_rvalid <= 1'b0;
        end                
    end
end    

// Implement memory mapped register select and read logic generation
// Slave register read enable is asserted when valid address is available
// and the slave is ready to accept the read address.
assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
always @(*)
begin
      // Address decoding for reading registers
      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
        6'h00   : reg_data_out <= slv_reg0;
        6'h01   : reg_data_out <= slv_reg1;
        6'h02   : reg_data_out <= slv_reg2;
        6'h03   : reg_data_out <= slv_reg3;
        6'h04   : reg_data_out <= slv_reg4;
        6'h05   : reg_data_out <= slv_reg5;
        6'h06   : reg_data_out <= slv_reg6;
        6'h07   : reg_data_out <= slv_reg7;
        6'h08   : reg_data_out <= slv_reg8;
        6'h09   : reg_data_out <= slv_reg9;
        6'h0A   : reg_data_out <= slv_reg10;
          default : begin
                if (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] >= 6'h0B && 
                    axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] <= 6'h34) begin 
                    reg_data_out <= result_regs[axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] - 6'h0B];
                end else begin
                    reg_data_out <= 0;
                end
            end
        endcase
    end
// Output register or memory read data
always @( posedge S_AXI_ACLK )
begin
  if ( S_AXI_ARESETN == 1'b0 )
    begin
      axi_rdata  <= 0;
    end 
  else
    begin    
      // When there is a valid read address (S_AXI_ARVALID) with 
      // acceptance of read address by the slave (axi_arready), 
      // output the read dada 
      if (slv_reg_rden)
        begin
          axi_rdata <= reg_data_out;     // register read data
        end   
    end
end    

// Add user logic here

// User-defined signals for shake_sha2_top
wire [3:0] algo_mode;
wire shake_start_i;
wire [63:0] shake_din_i;
wire shake_din_valid_i;
wire shake_last_din_i;
wire [3:0] shake_last_din_byte_i;
wire shake_dout_ready_i;
wire shake_hold;
wire sha2_tvalid;
wire sha2_tlast;
wire [31:0] sha2_tid;
wire [7:0] sha2_tdata;
wire sha2_tready;  // From module
wire [1343:0] dout;
wire dout_valid;
wire sha2_ovalid;
wire [31:0] sha2_oid;
wire [60:0] sha2_olen;

// Internal signals
reg [2:0] current_state;  // Simplified state tracking
reg busy_flag;            // Busy flag
reg result_ready_flag;    // Result ready flag
reg first_output_captured;  // Flag to capture first output only
//reg [31:0] result_regs [0:41];  // 42 regs for 1344-bit dout
reg [31:0] sha2_oid_reg;        // For sha2_oid
reg [31:0] sha2_olen_low;       // Low 32-bit of sha2_olen
reg [28:0] sha2_olen_high;      // High 29-bit (61-bit total)
integer i;

// Extract control signals from AXI registers
assign algo_mode = slv_reg0[3:0];  // algo_mode [3:0]
assign shake_start_i = slv_reg0[4];  // Start pulse
assign shake_hold = slv_reg0[5];     // Hold
assign shake_din_i = {slv_reg2, slv_reg1};  // 64-bit input data
assign shake_last_din_i = slv_reg3[0];
assign shake_last_din_byte_i = slv_reg3[4:1];
assign shake_din_valid_i = slv_reg3[5];  // Valid signal
assign shake_dout_ready_i = slv_reg3[6]; // Ready request

// SHA2 signals from regs (assuming 3 bytes input)
assign sha2_tdata = slv_reg4[7:0];   // First byte
// Second and third bytes in slv_reg4[23:8], but since small input, simulate single write
assign sha2_tid = slv_reg5;          // tid [31:0]
assign sha2_tvalid = slv_reg6[0];    // tvalid
assign sha2_tlast = slv_reg6[1];     // tlast

// Status register update (slv_reg7 for status, slv_reg8-10 for sha2_olen, slv_reg11-52 for dout)
always @(posedge S_AXI_ACLK) begin
    if (S_AXI_ARESETN == 1'b0) begin
        busy_flag <= 1'b0;
        result_ready_flag <= 1'b0;
        first_output_captured <= 1'b0;
        slv_reg7 <= 32'h0;  // Status reg
        sha2_oid_reg <= 32'h0;
        sha2_olen_low <= 32'h0;
        sha2_olen_high <= 29'h0;
    end else begin
        // Set busy when start or tvalid triggered
        if (shake_start_i || sha2_tvalid) begin
            busy_flag <= 1'b1;
            result_ready_flag <= 1'b0;
            first_output_captured <= 1'b0;
        end else if (dout_valid && !first_output_captured) begin
            busy_flag <= 1'b0;
            result_ready_flag <= 1'b1;
            first_output_captured <= 1'b1;
            // Capture SHA2 metadata if applicable
            if (sha2_ovalid) begin
                sha2_oid_reg <= sha2_oid;
                sha2_olen_low <= sha2_olen[31:0];
                sha2_olen_high <= sha2_olen[60:32];
            end
        end
        
        // Update status register (slv_reg7) - read-only
        slv_reg7[2:0] <= current_state;       // Current state
        slv_reg7[3] <= dout_valid;            // Output valid
        slv_reg7[4] <= busy_flag;             // Busy
        slv_reg7[5] <= result_ready_flag;     // Result ready
        slv_reg7[6] <= sha2_tready;           // SHA2 tready
        slv_reg7[7] <= sha2_ovalid;           // SHA2 ovalid
        slv_reg7[31:8] <= 24'h0;              // Reserved
        
        // SHA2 oid and olen to regs - read-only
        slv_reg8 <= sha2_oid_reg;             // sha2_oid
        slv_reg9 <= sha2_olen_low;            // sha2_olen low
        slv_reg10 <= {3'b0, sha2_olen_high};  // sha2_olen high (padded)
    end
end

// Update result registers when output is valid - only first output (read-only)
always @(posedge S_AXI_ACLK) begin
    if (S_AXI_ARESETN == 1'b0) begin
        for (i = 0; i < 42; i = i + 1) begin
            result_regs[i] <= 32'h0;
        end
    end else if (dout_valid && !first_output_captured) begin
        for (i = 0; i < 42; i = i + 1) begin
            result_regs[i] <= dout[(i*32) +: 32];
        end
       
    end
end

// SHAKE/SHA2 top module instantiation
shake_sha2_top u_shake_sha2_top (
    .clk(S_AXI_ACLK),
    .rstn(S_AXI_ARESETN),
    .algo_mode(algo_mode),
    .sha2_tvalid(sha2_tvalid),
    .sha2_tready(sha2_tready),
    .sha2_tlast(sha2_tlast),
    .sha2_tid(sha2_tid),
    .sha2_tdata(sha2_tdata),
    .shake_start_i(shake_start_i),
    .shake_din_i(shake_din_i),
    .shake_din_valid_i(shake_din_valid_i),
    .shake_last_din_i(shake_last_din_i),
    .shake_last_din_byte_i(shake_last_din_byte_i),
    .shake_dout_ready_i(shake_dout_ready_i),
    .shake_hold(shake_hold),
    .dout(dout),
    .dout_valid(dout_valid),
    .sha2_ovalid(sha2_ovalid),
    .sha2_oid(sha2_oid),
    .sha2_olen(sha2_olen)
);

// Simplified state tracking (expand as needed)
always @(posedge S_AXI_ACLK) begin
    if (S_AXI_ARESETN == 1'b0) begin
        current_state <= 3'b000; // IDLE
    end else begin
        if (shake_start_i || sha2_tvalid) begin
            current_state <= 3'b001; // ABSORB/RUN
        end else if (dout_valid) begin
            current_state <= 3'b101; // SQUEEZE/DONE
        end
        // Add more logic if needed
    end
end

// User logic ends

endmodule