`timescale 1 ns / 1 ps

module sha3_1003_tIP1_v1_0_S0_AXI #
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
    reg     axi_awready;
    reg     axi_wready;
    reg [1 : 0]     axi_bresp;
    reg     axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0]  axi_araddr;
    reg     axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0]  axi_rdata;
    reg [1 : 0]     axi_rresp;
    reg     axi_rvalid;

    // Example-specific design signals
    // local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
    // ADDR_LSB is used for addressing 32/64 bit registers/memories
    // ADDR_LSB = 2 for 32 bits (n downto 2)
    // ADDR_LSB = 3 for 64 bits (n downto 3)
    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 5;  // Support 32 registers with axi_awaddr[6:2]
    
    //----------------------------------------------
    //-- Signals for user logic register space
    //------------------------------------------------
    // AXI Register Map:
    // 0x00: Control register - mode[2:0], start, hold, reserved
    // 0x04: Data input low 32 bits
    // 0x08: Data input high 32 bits  
    // 0x0C: Control register 2 - last_din, last_din_byte[3:0], din_valid, dout_ready
    // 0x10: Status register - state[2:0], dout_full_valid, busy, ready
    // 0x14-0x50: Result output (1344 bits = 42 x 32-bit registers)
    
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;   // Control: mode[2:0], start, hold
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;   // Data input low 32 bits
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;   // Data input high 32 bits
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;   // Control 2: last_din, last_din_byte[3:0], din_valid, dout_ready
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg4;   // Status register
    
    // Result registers (42 registers for 1344 bits)
    reg [C_S_AXI_DATA_WIDTH-1:0] result_regs [0:41];
    
    wire slv_reg_rden;
    wire slv_reg_wren;
    reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    integer byte_index;
    integer i;
    reg aw_en;

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
              axi_awaddr <= S_AXI_AWADDR;
            end
        end 
    end       

    // Implement axi_wready generation
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
              axi_wready <= 1'b1;
            end
          else
            begin
              axi_wready <= 1'b0;
            end
        end 
    end       

    // Implement memory mapped register select and write logic generation
    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          slv_reg0 <= 0;
          slv_reg1 <= 0;
          slv_reg2 <= 0;
          slv_reg3 <= 0;
          // slv_reg4 is status register, handled separately
          // result_regs are output registers, handled separately
        end 
      else begin
        // 移除自动停止逻辑，因为现在只记录第一个输出，不需要自动清除dout_ready_i
        if (slv_reg_wren) begin
            case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
              6'h00:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end  
              6'h01:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end  
              6'h02:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end  
              6'h03:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                    slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                  end  
              default : begin
                slv_reg0 <= slv_reg0;
                slv_reg1 <= slv_reg1;
                slv_reg2 <= slv_reg2;
                slv_reg3 <= slv_reg3;
              end
            endcase
        end
      end
    end    

    // Implement write response logic generation
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
              axi_bvalid <= 1'b1;
              axi_bresp  <= 2'b0; // 'OKAY' response 
            end                   
          else
            begin
              if (S_AXI_BREADY && axi_bvalid) 
                begin
                  axi_bvalid <= 1'b0; 
                end  
            end
        end
    end   

    // Implement axi_arready generation
    always @( posedge S_AXI_ACLK )
    begin
      if ( S_AXI_ARESETN == 1'b0 )
        begin
          axi_arready <= 1'b0;
          axi_araddr  <= 0;
        end 
      else
        begin    
          if (~axi_arready && S_AXI_ARVALID)
            begin
              axi_arready <= 1'b1;
              axi_araddr  <= S_AXI_ARADDR;
            end
          else
            begin
              axi_arready <= 1'b0;
            end
        end 
    end       

    // Implement axi_arvalid generation
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
              axi_rvalid <= 1'b1;
              axi_rresp  <= 2'b0; // 'OKAY' response
            end   
          else if (axi_rvalid && S_AXI_RREADY)
            begin
              axi_rvalid <= 1'b0;
            end                
        end
    end    

    // Implement memory mapped register select and read logic generation
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
            default : begin
                if (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] >= 6'h05 && 
                    axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] <= 6'h2E) begin  // 6'h05 �? 6'h2E (42个寄存器)
                    reg_data_out <= result_regs[axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] - 6'h05];
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
          if (slv_reg_rden)
            begin
              axi_rdata <= reg_data_out;
            end   
        end
    end    

    // Add user logic here
    
    //----------------------------------------------
    // SHAKE/SHA3 Module Integration
    //----------------------------------------------
    
    // SHAKE/SHA3 interface signals
    wire [2:0] mode_i;
    wire start_i;
    wire [63:0] din_i;
    wire din_valid_i;
    wire last_din_i;
    wire [3:0] last_din_byte_i;
    wire dout_ready_i;
    wire sha3_hold;
    wire [1343:0] dout_full_o;
    wire dout_full_valid_o;
    
    // Internal state tracking
    reg [2:0] current_state;
    reg busy_flag;
    reg result_ready_flag;
    reg start_i_reg;
    reg first_output_captured;  // 新增：标志位，跟踪是否已经捕获了第一个输�?
    
    // Extract control signals from AXI registers
    assign mode_i = slv_reg0[2:0];
    assign start_i = slv_reg0[3];
    assign sha3_hold = slv_reg0[4];
    assign din_i = {slv_reg2, slv_reg1};
    assign last_din_i = slv_reg3[0];
    assign last_din_byte_i = slv_reg3[4:1];
    assign din_valid_i = slv_reg3[5];  // 直接从寄存器位读取，持续有效
    assign dout_ready_i = slv_reg3[6];
    
    // Status register update
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg4 <= 32'h0;
            busy_flag <= 1'b0;
            result_ready_flag <= 1'b0;
            first_output_captured <= 1'b0;  // 复位时清除标志位
        end else begin
            // Set busy flag when start is triggered
            if (start_i) begin
                busy_flag <= 1'b1;
                result_ready_flag <= 1'b0;
                first_output_captured <= 1'b0;  // 新计算开始时清除标志�?
            end else if (dout_full_valid_o && !first_output_captured) begin
                // 只有在第�?次输出时才设置标志位和状�?
                busy_flag <= 1'b0;
                result_ready_flag <= 1'b1;
                first_output_captured <= 1'b1;  // 标记已经捕获了第�?个输�?
            end
            
            // Update status register
            slv_reg4[2:0] <= current_state;      // Current state
            slv_reg4[3] <= dout_full_valid_o;    // Output valid
            slv_reg4[4] <= busy_flag;            // Busy flag
            slv_reg4[5] <= result_ready_flag;    // Result ready flag
            slv_reg4[31:6] <= 26'h0;             // Reserved
        end
    end
    
    // Update result registers when output is valid - 只记录第�?个输�?
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            for (i = 0; i < 42; i = i + 1) begin
                result_regs[i] <= 32'h0;
            end
        end else if (dout_full_valid_o && !first_output_captured) begin
            // 只在第一次dout_full_valid_o时存�?1344位结果到42�?32位寄存器
            for (i = 0; i < 42; i = i + 1) begin
                result_regs[i] <= dout_full_o[(i*32) +: 32];
            end
        end
        // 注意：后续的dout_full_valid_o脉冲将被忽略，直到下�?次start_i
    end
    
    // SHAKE/SHA3 top module instantiation
    shake_top u_shake_top (
        .clk_i(S_AXI_ACLK),
        .rst_ni(S_AXI_ARESETN),
        .mode_i(mode_i),
        .start_i(start_i),
        .din_i(din_i),
        .din_valid_i(din_valid_i),
        .last_din_i(last_din_i),
        .last_din_byte_i(last_din_byte_i),
        .dout_ready_i(dout_ready_i),
        .sha3_hold(sha3_hold),
        .dout_full_o(dout_full_o),
        .dout_full_valid_o(dout_full_valid_o)
    );
    
    // Extract current state from shake_top for status reporting
    // Note: This requires adding a state output to shake_top module
    // For now, we'll use a simplified state tracking
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            current_state <= 3'b000; // IDLE
        end else begin
            if (start_i) begin
                current_state <= 3'b001; // ABSORB
            end else if (dout_full_valid_o) begin
                current_state <= 3'b101; // SQUEEZE
            end
            // Add more state tracking logic as needed
        end
    end

    // User logic ends

endmodule