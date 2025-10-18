module shake_top_tb;
parameter PERIOD = 10; 
parameter DELAY  = 0.1*PERIOD;


reg                      clk_i;
reg                      rst_ni;
reg    [2:0]            mode_i;
reg                      start_i;
reg    [63:0]           din_i;
reg                      din_valid_i;
reg                      last_din_i;
reg    [3:0]            last_din_byte_i;
reg                      dout_ready_i;
reg                      sha3_hold;
wire   [1343:0]         dout_full_o;
wire                     dout_full_valid_o;

// 初始�?
initial begin
    clk_i = 0;
    rst_ni = 0;
    mode_i = 3'b010;  // SHAKE256
    start_i = 0;
    din_valid_i = 0;
    last_din_i = 0;
    last_din_byte_i = 0;
    dout_ready_i = 0;
    sha3_hold = 0;

    // 复位
    #100 rst_ni = 1;

    //==========================================================================
    // Test 1: 基本功能测试
    //==========================================================================
    #10 
    $display("\n=== Test 1: Basic Function Test with SHAKE256 ===");
    
    @(posedge clk_i) #(DELAY);
    mode_i = 3'b010;  // SHAKE256
    start_i = 1;
    @(posedge clk_i) #(DELAY) start_i = 0;
    
    // 发�?�数�?
    din_valid_i = 1;
    din_i = 64'h0123456789abcdef;
    @(posedge clk_i) #(DELAY);
    @(posedge clk_i) #(DELAY);
    @(posedge clk_i) #(DELAY);
    @(posedge clk_i) #(DELAY);
 

    din_valid_i = 0;
    @(posedge clk_i) #(DELAY);
    @(posedge clk_i) #(DELAY);
    @(posedge clk_i) #(DELAY);
    @(posedge clk_i) #(DELAY);
    @(posedge clk_i) #(DELAY);
    din_valid_i = 1;
    din_i = 64'hfedcba9876543210;
//    @(posedge clk_i) #(DELAY);
////   din_i = 64'hB2A1F6E5D4C3B2A1;
////   @(posedge clk_i) #(DELAY);
////   din_i = 64'hD4C3B2A1F6E5D4C3;
////   @(posedge clk_i) #(DELAY);
////   din_i = 64'hF6E5D4C3B2A1F6E5;
////   @(posedge clk_i) #(DELAY);
////   din_i = 64'hB2A1F6E5D4C3B2A1;
  
    last_din_i = 1;
    last_din_byte_i = 8; 
    @(posedge clk_i) #(DELAY);
    @(posedge clk_i) #(DELAY);
    @(posedge clk_i) #(DELAY);
    @(posedge clk_i) #(DELAY);
  
    din_valid_i = 0;
    last_din_i = 0;
    
    // 等待输出
    dout_ready_i = 1;

    #1000 dout_ready_i = 0;

    //==========================================================================
    // Test 2: SHA3 Hold测试
    //==========================================================================
    #100
    $display("\n=== Test 2: SHA3 Hold Test ===");
    
    @(posedge clk_i) #(DELAY);
    mode_i = 3'b001;  // SHAKE256
    start_i = 1;
    @(posedge clk_i) #(DELAY) start_i = 0;
    
    // 发�?�数据并测试hold
    din_valid_i = 1;
    din_i = 64'hB2A1F6E5D4C3B2A1;
    @(posedge clk_i) #(DELAY);
    
    sha3_hold = 1;
    #500;

    sha3_hold = 0;
    
    din_i = 64'hD4C3B2A1F6E5D4C3;
    @(posedge clk_i) #(DELAY);
    
    din_i = 64'hF6E5D4C3B2A1F6E5;
    @(posedge clk_i) #(DELAY);
    
    din_i = 64'hB2A1F6E5D4C3B2A1;
    last_din_i = 1;
    last_din_byte_i = 8;
    @(posedge clk_i) #(DELAY);
    
    din_valid_i = 0;
    last_din_i = 0;
    
    // 等待输出
    #50 dout_ready_i = 1;

    #1000 dout_ready_i = 0;

    //==========================================================================
    // Test 3: 不同模式测试
    //==========================================================================
    #100
    $display("\n=== Test 3: Different Modes Test ===");
    

    @(posedge clk_i) #(DELAY);
    mode_i = 3'b001;  
    start_i = 1;
    @(posedge clk_i) #(DELAY) start_i = 0;
    
    din_valid_i = 1;
    

//   din_i = 64'hB2A1F6E5D4C3B2A1;
//   @(posedge clk_i) #(DELAY);
//   din_i = 64'hD4C3B2A1F6E5D4C3;
//   @(posedge clk_i) #(DELAY);
//   din_i = 64'hF6E5D4C3B2A1F6E5;
//   @(posedge clk_i) #(DELAY);
//   din_i = 64'hB2A1F6E5D4C3B2A1;
    last_din_i = 1;
    last_din_byte_i = 8; 
    @(posedge clk_i) #(DELAY);
    
    din_valid_i = 0;
    last_din_i = 0;
    
    // 等待输出
    #50 dout_ready_i = 1;

    #500;
    sha3_hold = 1;
    #500;
    sha3_hold = 0;
    #500;
    sha3_hold = 1;
    #500;
    sha3_hold = 0;
    
    #10 dout_ready_i = 0;

    // 测试SHA3-256
    #100;
    @(posedge clk_i) #(DELAY);
    mode_i = 3'b010;  // SHA3-256
    start_i = 1;
    @(posedge clk_i) #(DELAY) start_i = 0;
    
    din_valid_i = 1;
    din_i = 64'h1111222233334444;
    @(posedge clk_i) #(DELAY);
    
    din_i = 64'h5555666677778888;
    last_din_i = 1;
    last_din_byte_i = 8;
    @(posedge clk_i) #(DELAY);
    
    din_valid_i = 0;
    last_din_i = 0;
    
    #50 dout_ready_i = 1;
    wait(dout_full_valid_o);
    $display("SHA3-256 output: %h", dout_full_o);
    #10 dout_ready_i = 0;

    #100 $finish;
end

// 时钟生成
always #(PERIOD/2) clk_i = ~clk_i;

// 监控hold信号变化
always @(sha3_hold)
    $display("Time %0t: SHA3_HOLD changed to %b", $time, sha3_hold);

// 监控输出
always @(posedge clk_i) begin
    if(dout_full_valid_o)
        $display("Time %0t: Full output valid, data = %h", $time, dout_full_o);
end

// DUT实例�? - 使用�?化后的端口列�?
shake_top dut (
    .clk_i            (clk_i),
    .rst_ni           (rst_ni),
    .mode_i           (mode_i),
    .start_i          (start_i),
    .din_i            (din_i),
    .din_valid_i      (din_valid_i),
    .last_din_i       (last_din_i),
    .last_din_byte_i  (last_din_byte_i),
    .dout_ready_i     (dout_ready_i),
    .sha3_hold        (sha3_hold),
    .dout_full_o      (dout_full_o),
    .dout_full_valid_o(dout_full_valid_o)
);

endmodule