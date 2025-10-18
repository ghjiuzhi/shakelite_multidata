`timescale 1 ns / 1 ps

module sha3_1003_tIP1_v1_0_S0_AXI #
(
    // Parameters of Axi Slave Bus Interface S0_AXI
    parameter integer C_S_AXI_DATA_WIDTH    = 32,
    parameter integer C_S_AXI_ADDR_WIDTH    = 8
)
(
    // Ports of Axi Slave Bus Interface S0_AXI
    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire  S_AXI_AWVALID,
    output wire  S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire  S_AXI_WREADY,
    output wire [1 : 0] S_AXI_BRESP,
    output wire  S_AXI_BVALID,
    input wire  S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire  S_AXI_ARVALID,
    output wire  S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire  S_AXI_RVALID,
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

    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 5;
    
    //---------------------------------------------------
    //-- Signals for user logic register space
    //---------------------------------------------------
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg4;
    reg [C_S_AXI_DATA_WIDTH-1:0] result_regs [0:41];
    
    // (我们暂时不使用这些新地址，但保留声明以备后用)
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg_cycle_count_low;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg_cycle_count_high;
    
    wire slv_reg_rden;
    wire slv_reg_wren;
    reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    integer byte_index;
    integer i;
    reg aw_en;

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // AXI Write Logic (unchanged from your original file)
    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
        axi_awready <= 1'b0;
        aw_en <= 1'b1;
      end else begin  
        if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
          axi_awready <= 1'b1;
          aw_en <= 1'b0;
        end else if (S_AXI_BREADY && axi_bvalid) begin
            aw_en <= 1'b1;
            axi_awready <= 1'b0;
        end else begin
          axi_awready <= 1'b0;
        end
      end 
    end 
    
    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
        axi_awaddr <= 0;
      end else begin    
        if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
          axi_awaddr <= S_AXI_AWADDR;
        end
      end 
    end     
    
    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
        axi_wready <= 1'b0;
      end else begin    
        if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en ) begin
          axi_wready <= 1'b1;
        end else begin
          axi_wready <= 1'b0;
        end
      end 
    end     

    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
        slv_reg0 <= 0;
        slv_reg1 <= 0;
        slv_reg2 <= 0;
        slv_reg3 <= 0;
      end else begin
        if (slv_reg_wren) begin
            case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
              6'h00:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 )
                    slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];  
              6'h01:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 )
                    slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];  
              6'h02:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 )
                    slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];  
              6'h03:
                for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
                  if ( S_AXI_WSTRB[byte_index] == 1 )
                    slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];  
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

    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
        axi_bvalid  <= 0;
        axi_bresp   <= 2'b0;
      end else begin    
        if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
          axi_bvalid <= 1'b1;
          axi_bresp  <= 2'b0; 
        end else begin
          if (S_AXI_BREADY && axi_bvalid) 
            axi_bvalid <= 1'b0; 
        end
      end
    end   

    // AXI Read Logic
    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
        axi_arready <= 1'b0;
        axi_araddr  <= 0;
      end else begin    
        if (~axi_arready && S_AXI_ARVALID) begin
          axi_arready <= 1'b1;
          axi_araddr  <= S_AXI_ARADDR;
        end else begin
          axi_arready <= 1'b0;
        end
      end 
    end     

    always @( posedge S_AXI_ACLK ) begin
      if ( S_AXI_ARESETN == 1'b0 ) begin
        axi_rvalid <= 0;
        axi_rresp  <= 0;
      end else begin    
        if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
          axi_rvalid <= 1'b1;
          axi_rresp  <= 2'b0;
        end else if (axi_rvalid && S_AXI_RREADY) begin
          axi_rvalid <= 1'b0;
        end               
      end
    end   

    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
    
    always @(*)
    begin
        case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
            6'h00   : reg_data_out <= slv_reg0;
            6'h01   : reg_data_out <= slv_reg1;
            6'h02   : reg_data_out <= slv_reg2;
            6'h03   : reg_data_out <= slv_reg3;
            6'h04   : reg_data_out <= slv_reg4; // 状态寄存器地址
            6'h2F   : reg_data_out <= slv_reg_cycle_count_low;
            6'h30   : reg_data_out <= slv_reg_cycle_count_high;
            default : begin
                if (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] >= 6'h05 && 
                    axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] <= 6'h2E) begin
                    reg_data_out <= result_regs[axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] - 6'h05];
                end else begin
                    reg_data_out <= 0;
                end
            end
        endcase
    end

    always @( posedge S_AXI_ACLK ) begin  
      if ( S_AXI_ARESETN == 1'b0 ) begin  
        axi_rdata  <= 0;
      end else begin    
        if (slv_reg_rden) begin
          axi_rdata <= reg_data_out;
        end   
      end
    end    

    // Add user logic here
    
    //----------------------------------------------
    // SHAKE/SHA3 Module Integration
    //----------------------------------------------
    
    wire [2:0]  mode_i;
    wire        start_i;
    wire [63:0] din_i;
    wire        din_valid_i;
    wire        last_din_i;
    wire [3:0]  last_din_byte_i;
    wire        dout_ready_i;
    wire        sha3_hold;
    wire [1343:0] dout_full_o;
    wire        dout_full_valid_o;
    
    // =================== START: 新增/修改的信号线 ===================
    wire [63:0] cycle_count_from_core;
    wire        start_pulse_from_core; // 从 shake_top 来的脉冲信号
    wire [63:0] live_cycle_count_from_core;
    // =================== END: 新增/修改的信号线 =====================

    reg [2:0] current_state;
    reg busy_flag;
    reg result_ready_flag;
    reg first_output_captured;
    
    assign mode_i          = slv_reg0[2:0];
    assign start_i         = slv_reg0[3];
    assign sha3_hold       = slv_reg0[4];
    assign din_i           = {slv_reg2, slv_reg1};
    assign last_din_i      = slv_reg3[0];
    assign last_din_byte_i = slv_reg3[4:1];
    assign din_valid_i     = slv_reg3[5];
    assign dout_ready_i    = slv_reg3[6];
    
    // =================== START: 修改状态寄存器更新逻辑 ===================
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg4 <= 32'h0;
            busy_flag <= 1'b0;
            result_ready_flag <= 1'b0;
            first_output_captured <= 1'b0;
        end else begin
            if (start_i) begin
                busy_flag <= 1'b1;
                result_ready_flag <= 1'b0;
                first_output_captured <= 1'b0;
            end else if (dout_full_valid_o && !first_output_captured) begin
                busy_flag <= 1'b0;
                result_ready_flag <= 1'b1;
                first_output_captured <= 1'b1;
            end
            
            // 将 start_pulse 连接到状态寄存器的最高位 (bit 31) 用于调试
            slv_reg4[31] <= start_pulse_from_core;

            // 原有的状态位
            slv_reg4[2:0] <= current_state;
            slv_reg4[3] <= dout_full_valid_o;
            slv_reg4[4] <= busy_flag;
            slv_reg4[5] <= result_ready_flag;
            // bit 30:6 保持为0，不被覆盖
        end
    end
    // =================== END: 修改状态寄存器更新逻辑 =====================
    
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            for (i = 0; i < 42; i = i + 1) begin
                result_regs[i] <= 32'h0;
            end
        end else if (dout_full_valid_o && !first_output_captured) begin
            for (i = 0; i < 42; i = i + 1) begin
                result_regs[i] <= dout_full_o[(i*32) +: 32];
            end
        end
    end
    
    // 捕获计数值的逻辑 (保持不变，以备后用)
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg_cycle_count_low  <= 32'h0;
            slv_reg_cycle_count_high <= 32'h0;
        end else begin
            slv_reg_cycle_count_low  <= cycle_count_from_core[31:0];
            slv_reg_cycle_count_high <= cycle_count_from_core[63:32];
        end
    end

    // =================== START: 修改 shake_top 实例化 ===================
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
        .dout_full_valid_o(dout_full_valid_o),
        // 新增的端口连接
        .cycle_count_o(cycle_count_from_core),
        .start_pulse_o(start_pulse_from_core),
        .live_cycle_count_o(live_cycle_count_from_core)
    );
    // =================== END: 修改 shake_top 实例化 =====================
    
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            current_state <= 3'b000;
        end else begin
            if (start_i) begin
                current_state <= 3'b001;
            end else if (dout_full_valid_o) begin
                current_state <= 3'b101;
            end
        end
    end

endmodule