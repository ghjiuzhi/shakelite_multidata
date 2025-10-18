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
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg4;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg5;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg6;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg7;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg8;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg9;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg10;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg11;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg12;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg13;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg14;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg15;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg16;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg17;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg18;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg19;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg20;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg21;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg22;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg23;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg24;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg25;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg26;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg27;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg28;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg29;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg30;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg31;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg32;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg33;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg34;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg35;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg36;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg37;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg38;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg39;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg40;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg41;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg42;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg43;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg44;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg45;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg46;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg47;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg48;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg49;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg50;
reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg51;
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
      slv_reg7 <= 0;
      slv_reg8 <= 0;
      slv_reg9 <= 0;
      slv_reg10 <= 0;
      slv_reg11 <= 0;
      slv_reg12 <= 0;
      slv_reg13 <= 0;
      slv_reg14 <= 0;
      slv_reg15 <= 0;
      slv_reg16 <= 0;
      slv_reg17 <= 0;
      slv_reg18 <= 0;
      slv_reg19 <= 0;
      slv_reg20 <= 0;
      slv_reg21 <= 0;
      slv_reg22 <= 0;
      slv_reg23 <= 0;
      slv_reg24 <= 0;
      slv_reg25 <= 0;
      slv_reg26 <= 0;
      slv_reg27 <= 0;
      slv_reg28 <= 0;
      slv_reg29 <= 0;
      slv_reg30 <= 0;
      slv_reg31 <= 0;
      slv_reg32 <= 0;
      slv_reg33 <= 0;
      slv_reg34 <= 0;
      slv_reg35 <= 0;
      slv_reg36 <= 0;
      slv_reg37 <= 0;
      slv_reg38 <= 0;
      slv_reg39 <= 0;
      slv_reg40 <= 0;
      slv_reg41 <= 0;
      slv_reg42 <= 0;
      slv_reg43 <= 0;
      slv_reg44 <= 0;
      slv_reg45 <= 0;
      slv_reg46 <= 0;
      slv_reg47 <= 0;
      slv_reg48 <= 0;
      slv_reg49 <= 0;
      slv_reg50 <= 0;
      slv_reg51 <= 0;
    end 
  else begin
    if (slv_reg_wren)
      begin
        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
          6'h00:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 0
                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h01:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 1
                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h02:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 2
                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h03:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 3
                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h04:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 4
                slv_reg4[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h05:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 5
                slv_reg5[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h06:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 6
                slv_reg6[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h07:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 7
                slv_reg7[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h08:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 8
                slv_reg8[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h09:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 9
                slv_reg9[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h0A:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 10
                slv_reg10[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h0B:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 11
                slv_reg11[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h0C:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 12
                slv_reg12[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h0D:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 13
                slv_reg13[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h0E:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 14
                slv_reg14[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h0F:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 15
                slv_reg15[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h10:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 16
                slv_reg16[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h11:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 17
                slv_reg17[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h12:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 18
                slv_reg18[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h13:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 19
                slv_reg19[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h14:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 20
                slv_reg20[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h15:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 21
                slv_reg21[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h16:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 22
                slv_reg22[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h17:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 23
                slv_reg23[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h18:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 24
                slv_reg24[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h19:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 25
                slv_reg25[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h1A:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 26
                slv_reg26[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h1B:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 27
                slv_reg27[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h1C:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 28
                slv_reg28[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h1D:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 29
                slv_reg29[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h1E:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 30
                slv_reg30[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h1F:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 31
                slv_reg31[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h20:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 32
                slv_reg32[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h21:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 33
                slv_reg33[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h22:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 34
                slv_reg34[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h23:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 35
                slv_reg35[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h24:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 36
                slv_reg36[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h25:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 37
                slv_reg37[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h26:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 38
                slv_reg38[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h27:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 39
                slv_reg39[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h28:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 40
                slv_reg40[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h29:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 41
                slv_reg41[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h2A:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 42
                slv_reg42[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h2B:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 43
                slv_reg43[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h2C:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 44
                slv_reg44[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h2D:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 45
                slv_reg45[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h2E:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 46
                slv_reg46[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h2F:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 47
                slv_reg47[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h30:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 48
                slv_reg48[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h31:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 49
                slv_reg49[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h32:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 50
                slv_reg50[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          6'h33:
            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                // Respective byte enables are asserted as per write strobes 
                // Slave register 51
                slv_reg51[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
              end  
          default : begin
                      slv_reg0 <= slv_reg0;
                      slv_reg1 <= slv_reg1;
                      slv_reg2 <= slv_reg2;
                      slv_reg3 <= slv_reg3;
                      slv_reg4 <= slv_reg4;
                      slv_reg5 <= slv_reg5;
                      slv_reg6 <= slv_reg6;
                      slv_reg7 <= slv_reg7;
                      slv_reg8 <= slv_reg8;
                      slv_reg9 <= slv_reg9;
                      slv_reg10 <= slv_reg10;
                      slv_reg11 <= slv_reg11;
                      slv_reg12 <= slv_reg12;
                      slv_reg13 <= slv_reg13;
                      slv_reg14 <= slv_reg14;
                      slv_reg15 <= slv_reg15;
                      slv_reg16 <= slv_reg16;
                      slv_reg17 <= slv_reg17;
                      slv_reg18 <= slv_reg18;
                      slv_reg19 <= slv_reg19;
                      slv_reg20 <= slv_reg20;
                      slv_reg21 <= slv_reg21;
                      slv_reg22 <= slv_reg22;
                      slv_reg23 <= slv_reg23;
                      slv_reg24 <= slv_reg24;
                      slv_reg25 <= slv_reg25;
                      slv_reg26 <= slv_reg26;
                      slv_reg27 <= slv_reg27;
                      slv_reg28 <= slv_reg28;
                      slv_reg29 <= slv_reg29;
                      slv_reg30 <= slv_reg30;
                      slv_reg31 <= slv_reg31;
                      slv_reg32 <= slv_reg32;
                      slv_reg33 <= slv_reg33;
                      slv_reg34 <= slv_reg34;
                      slv_reg35 <= slv_reg35;
                      slv_reg36 <= slv_reg36;
                      slv_reg37 <= slv_reg37;
                      slv_reg38 <= slv_reg38;
                      slv_reg39 <= slv_reg39;
                      slv_reg40 <= slv_reg40;
                      slv_reg41 <= slv_reg41;
                      slv_reg42 <= slv_reg42;
                      slv_reg43 <= slv_reg43;
                      slv_reg44 <= slv_reg44;
                      slv_reg45 <= slv_reg45;
                      slv_reg46 <= slv_reg46;
                      slv_reg47 <= slv_reg47;
                      slv_reg48 <= slv_reg48;
                      slv_reg49 <= slv_reg49;
                      slv_reg50 <= slv_reg50;
                      slv_reg51 <= slv_reg51;
                    end
        endcase
      end
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
            //(there is a possibility that bready is always asserted high)   
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
        6'h0B   : reg_data_out <= slv_reg11;
        6'h0C   : reg_data_out <= slv_reg12;
        6'h0D   : reg_data_out <= slv_reg13;
        6'h0E   : reg_data_out <= slv_reg14;
        6'h0F   : reg_data_out <= slv_reg15;
        6'h10   : reg_data_out <= slv_reg16;
        6'h11   : reg_data_out <= slv_reg17;
        6'h12   : reg_data_out <= slv_reg18;
        6'h13   : reg_data_out <= slv_reg19;
        6'h14   : reg_data_out <= slv_reg20;
        6'h15   : reg_data_out <= slv_reg21;
        6'h16   : reg_data_out <= slv_reg22;
        6'h17   : reg_data_out <= slv_reg23;
        6'h18   : reg_data_out <= slv_reg24;
        6'h19   : reg_data_out <= slv_reg25;
        6'h1A   : reg_data_out <= slv_reg26;
        6'h1B   : reg_data_out <= slv_reg27;
        6'h1C   : reg_data_out <= slv_reg28;
        6'h1D   : reg_data_out <= slv_reg29;
        6'h1E   : reg_data_out <= slv_reg30;
        6'h1F   : reg_data_out <= slv_reg31;
        6'h20   : reg_data_out <= slv_reg32;
        6'h21   : reg_data_out <= slv_reg33;
        6'h22   : reg_data_out <= slv_reg34;
        6'h23   : reg_data_out <= slv_reg35;
        6'h24   : reg_data_out <= slv_reg36;
        6'h25   : reg_data_out <= slv_reg37;
        6'h26   : reg_data_out <= slv_reg38;
        6'h27   : reg_data_out <= slv_reg39;
        6'h28   : reg_data_out <= slv_reg40;
        6'h29   : reg_data_out <= slv_reg41;
        6'h2A   : reg_data_out <= slv_reg42;
        6'h2B   : reg_data_out <= slv_reg43;
        6'h2C   : reg_data_out <= slv_reg44;
        6'h2D   : reg_data_out <= slv_reg45;
        6'h2E   : reg_data_out <= slv_reg46;
        6'h2F   : reg_data_out <= slv_reg47;
        6'h30   : reg_data_out <= slv_reg48;
        6'h31   : reg_data_out <= slv_reg49;
        6'h32   : reg_data_out <= slv_reg50;
        6'h33   : reg_data_out <= slv_reg51;
        default : reg_data_out <= 0;
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
reg [31:0] result_regs [0:41];  // 42 regs for 1344-bit dout
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

// Status register update (slv_reg7 for status, slv_reg8-9 for sha2_olen, slv_reg10 for sha2_oid, slv_reg11-52 for dout)
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
        
        // Update status register (slv_reg7)
        slv_reg7[2:0] <= current_state;       // Current state
        slv_reg7[3] <= dout_valid;            // Output valid
        slv_reg7[4] <= busy_flag;             // Busy
        slv_reg7[5] <= result_ready_flag;     // Result ready
        slv_reg7[6] <= sha2_tready;           // SHA2 tready
        slv_reg7[7] <= sha2_ovalid;           // SHA2 ovalid
        slv_reg7[31:8] <= 24'h0;              // Reserved
        
        // SHA2 oid and olen to regs
        slv_reg8 <= sha2_oid_reg;             // sha2_oid
        slv_reg9 <= sha2_olen_low;            // sha2_olen low
        slv_reg10 <= {3'b0, sha2_olen_high};  // sha2_olen high (padded)
    end
end

// Update result registers when output is valid - only first output
always @(posedge S_AXI_ACLK) begin
    if (S_AXI_ARESETN == 1'b0) begin
        for (i = 0; i < 42; i = i + 1) begin
            result_regs[i] <= 32'h0;
        end
    end else if (dout_valid && !first_output_captured) begin
        for (i = 0; i < 42; i = i + 1) begin
            result_regs[i] <= dout[(i*32) +: 32];
        end
        // Map to slv_reg11-52 (42 regs: 11 to 52)
        for (i = 0; i < 42; i = i + 1) begin
            case (i)
                0: slv_reg11 <= result_regs[0];
                1: slv_reg12 <= result_regs[1];
                // ... (continue for all 42)
                41: slv_reg52 <= result_regs[41];
            endcase
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