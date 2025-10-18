//--------------------------------------------------------------------------------------------------------
// Module  : tb_sha2_shake_top
// Type    : simulation, top
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: 综合测试SHA2和SHAKE/SHA3集成模块的testbench
//           测试算法模式切换、两种接口协议和输出结果
//--------------------------------------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_sha2_shake_top ();

//--------------------------------------------------------------------------------------------------------
// 时钟和复位信号
//--------------------------------------------------------------------------------------------------------
reg rstn;
reg clk;

initial begin
    rstn = 1'b0;
    clk = 1'b1;
end

always #5 clk = ~clk;   // 100MHz时钟

//--------------------------------------------------------------------------------------------------------
// DUT接口信号
//--------------------------------------------------------------------------------------------------------

// 算法模式选择
reg  [3:0]       algo_mode;    // {算法类型, 模式位}

// SHA2接口信号 (AXI-Stream兼容)
reg              sha2_tvalid;
wire             sha2_tready;
reg              sha2_tlast;
reg  [31:0]      sha2_tid;
reg  [7:0]       sha2_tdata;

// SHA2输出接口 (包含事务元数据)
wire             sha2_ovalid;
wire [31:0]      sha2_oid;
wire [60:0]      sha2_olen;

// SHAKE接口信号
reg              shake_start_i;
reg  [63:0]      shake_din_i;
reg              shake_din_valid_i;
reg              shake_last_din_i;
reg  [3:0]       shake_last_din_byte_i;
reg              shake_dout_ready_i;
reg              shake_hold;

// 共享哈希输出接口
wire [1343:0]    dout;         // 哈希输出：SHA2填充到1344位，SHAKE全宽度
wire             dout_valid;   // 哈希输出有效信号

//--------------------------------------------------------------------------------------------------------
// 信号初始化
//--------------------------------------------------------------------------------------------------------
initial begin
    // 算法模式初始化
    algo_mode = 4'b0000;       // 默认SHA-256模式
    
    // SHA2接口初始化
    sha2_tvalid = 1'b0;
    sha2_tlast  = 1'b0;
    sha2_tid    = 32'd0;
    sha2_tdata  = 8'd0;
    
    // SHAKE接口初始化
    shake_start_i = 1'b0;
    shake_din_i = 64'd0;
    shake_din_valid_i = 1'b0;
    shake_last_din_i = 1'b0;
    shake_last_din_byte_i = 4'd0;
    shake_dout_ready_i = 1'b0;
    shake_hold = 1'b0;
end

//--------------------------------------------------------------------------------------------------------
// DUT实例化
//--------------------------------------------------------------------------------------------------------
sha2_shake_top u_sha2_shake_top (
    // 时钟和复位
    .clk                    ( clk                    ),
    .rstn                   ( rstn                   ),
    
    // 算法模式选择
    .algo_mode              ( algo_mode              ),
    
    // SHA2接口
    .sha2_tvalid            ( sha2_tvalid            ),
    .sha2_tready            ( sha2_tready            ),
    .sha2_tlast             ( sha2_tlast             ),
    .sha2_tid               ( sha2_tid               ),
    .sha2_tdata             ( sha2_tdata             ),
    .sha2_ovalid            ( sha2_ovalid            ),
    .sha2_oid               ( sha2_oid               ),
    .sha2_olen              ( sha2_olen              ),
    
    // SHAKE接口
    .shake_start_i          ( shake_start_i          ),
    .shake_din_i            ( shake_din_i            ),
    .shake_din_valid_i      ( shake_din_valid_i      ),
    .shake_last_din_i       ( shake_last_din_i       ),
    .shake_last_din_byte_i  ( shake_last_din_byte_i  ),
    .shake_dout_ready_i     ( shake_dout_ready_i     ),
    .shake_hold             ( shake_hold             ),
    
    // 共享哈希输出
    .dout                   ( dout                   ),
    .dout_valid             ( dout_valid             )
);

//--------------------------------------------------------------------------------------------------------
// 结果显示任务
//--------------------------------------------------------------------------------------------------------

// 显示SHA2结果（包含事务信息）
always @(posedge clk) begin
    if(sha2_ovalid) begin
        $display("===========================================");
        if(algo_mode[0])
            $display("SHA-512结果:");
        else
            $display("SHA-256结果:");
        $display("  事务ID   = 0x%h", sha2_oid);
        $display("  数据长度 = %0d 字节", sha2_olen);
        $display("===========================================");
    end
end

// 显示共享哈希输出
always @(posedge clk) begin
    if(dout_valid) begin
        $display("===========================================");
        if(algo_mode[3]) begin
            // SHAKE模式
            case(algo_mode[2:0])
                3'b000: $display("SHAKE128输出:");
                3'b001: $display("SHAKE256输出:");
                3'b010: $display("SHA3-256输出:");
                3'b011: $display("SHA3-512输出:");
                3'b100: $display("SHA3-224输出:");
                3'b101: $display("SHA3-384输出:");
                default: $display("未知SHAKE模式输出:");
            endcase
            $display("  完整哈希 = %h", dout);
        end else begin
            // SHA2模式
            if(algo_mode[0]) begin
                $display("SHA-512共享输出:");
                $display("  哈希     = %h", dout[511:0]);
            end else begin
                $display("SHA-256共享输出:");
                $display("  哈希     = %h", dout[511:256]);  // SHA-256现在在高位
            end
        end
        $display("===========================================");
    end
end

//--------------------------------------------------------------------------------------------------------
// SHA2数据发送任务
//--------------------------------------------------------------------------------------------------------
task send_sha2_bytes;
    input [31:0] id;
    input [1023:0] data_array;  // 最大128字节
    input integer num_bytes;
    integer i;
    begin
        $display("发送SHA2数据 %0d 字节 (ID=0x%h)", num_bytes, id);
        
        @(posedge clk);
        while(~sha2_tready) @(posedge clk);
        
        for(i = num_bytes-1; i >= 0; i = i - 1) begin
            sha2_tvalid <= 1'b1;
            sha2_tid    <= (i == num_bytes-1) ? id : 32'd0;
            sha2_tdata  <= data_array[i*8 +: 8];
            sha2_tlast  <= (i == 0);
            
            @(posedge clk);
            while(~sha2_tready) @(posedge clk);
        end
        
        sha2_tvalid <= 1'b0;
        sha2_tlast  <= 1'b0;
        sha2_tid    <= 32'd0;
        sha2_tdata  <= 8'd0;
    end
endtask

//--------------------------------------------------------------------------------------------------------
// SHAKE数据发送任务
//--------------------------------------------------------------------------------------------------------
task send_shake_data;
    input [2:0] mode;
    input [1023:0] data_array;  // 最大数据
    input integer num_blocks;   // 64位块数
    integer i;
    begin
        $display("发送SHAKE数据，模式=%0d，块数=%0d", mode, num_blocks);
        
        @(posedge clk);
        shake_start_i <= 1'b1;
        @(posedge clk);
        shake_start_i <= 1'b0;
        
        for(i = num_blocks-1; i >= 0; i = i - 1) begin
            shake_din_valid_i <= 1'b1;
            shake_din_i <= data_array[i*64 +: 64];
            shake_last_din_i <= (i == 0);
            shake_last_din_byte_i <= (i == 0) ? 4'd8 : 4'd0;
            
            @(posedge clk);
        end
        
        shake_din_valid_i <= 1'b0;
        shake_last_din_i <= 1'b0;
        shake_last_din_byte_i <= 4'd0;
        
        // 等待输出
        shake_dout_ready_i <= 1'b1;
        wait(dout_valid);
        @(posedge clk);
        shake_dout_ready_i <= 1'b0;
    end
endtask

//--------------------------------------------------------------------------------------------------------
// 主测试序列
//--------------------------------------------------------------------------------------------------------
initial begin
    
    // 复位序列
    repeat(4) @(posedge clk);
    rstn <= 1'b1;
    repeat(2) @(posedge clk);
    
    //========================================
    // 第一部分：SHA2模式测试
    //========================================
    $display("\n");
    $display("*******************************************");
    $display("*       SHA2模式测试 (SHA-256/512)        *");
    $display("*******************************************");
    
    // SHA-256测试
    $display("\n--- SHA-256模式测试 ---");
    algo_mode <= 4'b0000;  // SHA-256模式
    repeat(2) @(posedge clk);
    
    send_sha2_bytes(32'h2561, 
        {8'h01, 8'h23, 8'h45, 8'h67, 8'h89, 8'hAB, 8'hCD, 8'hEF}, 
        8);
    wait(dout_valid);
    repeat(10) @(posedge clk);
    
    // SHA-512测试
    $display("\n--- SHA-512模式测试 ---");
    algo_mode <= 4'b0001;  // SHA-512模式
    repeat(2) @(posedge clk);
    
    send_sha2_bytes(32'h5121, 
        {8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5,
         8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A}, 
        16);
    wait(dout_valid);
    repeat(10) @(posedge clk);
    
    //========================================
    // 第二部分：SHAKE模式测试
    //========================================
    $display("\n");
    $display("*******************************************");
    $display("*       SHAKE模式测试                     *");
    $display("*******************************************");
    
    // SHAKE128测试
    $display("\n--- SHAKE128模式测试 ---");
    algo_mode <= 4'b1000;  // SHAKE128模式
    repeat(2) @(posedge clk);
    
    send_shake_data(3'b000, {64'h0123456789ABCDEF, 64'hFEDCBA9876543210}, 2);
    repeat(10) @(posedge clk);
    
    // SHAKE256测试
    $display("\n--- SHAKE256模式测试 ---");
    algo_mode <= 4'b1001;  // SHAKE256模式
    repeat(2) @(posedge clk);
    
    send_shake_data(3'b001, {64'hB2A1F6E5D4C3B2A1, 64'hD4C3B2A1F6E5D4C3}, 2);
    repeat(10) @(posedge clk);
    
    // SHA3-256测试
    $display("\n--- SHA3-256模式测试 ---");
    algo_mode <= 4'b1010;  // SHA3-256模式
    repeat(2) @(posedge clk);
    
    send_shake_data(3'b010, {64'h1111222233334444, 64'h5555666677778888}, 2);
    repeat(10) @(posedge clk);
    
    //========================================
    // 第三部分：算法切换测试
    //========================================
    $display("\n");
    $display("*******************************************");
    $display("*       算法切换测试                       *");
    $display("*******************************************");
    
    // SHA-256 -> SHAKE256快速切换
    $display("\n--- SHA-256 -> SHAKE256切换 ---");
    algo_mode <= 4'b0000;  // SHA-256
    repeat(2) @(posedge clk);
    send_sha2_bytes(32'h2599, {8'h12, 8'h34, 8'h56, 8'h78}, 4);
    wait(dout_valid);
    repeat(5) @(posedge clk);
    
    algo_mode <= 4'b1001;  // SHAKE256
    repeat(2) @(posedge clk);
    send_shake_data(3'b001, {64'hAABBCCDDEEFF0011}, 1);
    repeat(10) @(posedge clk);
    
    // SHAKE -> SHA-512快速切换
    $display("\n--- SHAKE256 -> SHA-512切换 ---");
    algo_mode <= 4'b1001;  // SHAKE256
    repeat(2) @(posedge clk);
    send_shake_data(3'b001, {64'h9988776655443322}, 1);
    repeat(5) @(posedge clk);
    
    algo_mode <= 4'b0001;  // SHA-512
    repeat(2) @(posedge clk);
    send_sha2_bytes(32'h5199, {8'hFF, 8'hEE, 8'hDD, 8'hCC, 8'hBB, 8'hAA, 8'h99, 8'h88}, 8);
    wait(dout_valid);
    repeat(10) @(posedge clk);
    
    //========================================
    // 第四部分：SHAKE Hold信号测试
    //========================================
    $display("\n");
    $display("*******************************************");
    $display("*       SHAKE Hold信号测试                *");
    $display("*******************************************");
    
    algo_mode <= 4'b1001;  // SHAKE256模式
    repeat(2) @(posedge clk);
    
    @(posedge clk);
    shake_start_i <= 1'b1;
    @(posedge clk);
    shake_start_i <= 1'b0;
    
    // 发送数据并测试hold
    shake_din_valid_i <= 1'b1;
    shake_din_i <= 64'hB2A1F6E5D4C3B2A1;
    @(posedge clk);
    
    $display("激活SHAKE Hold信号");
    shake_hold <= 1'b1;
    repeat(50) @(posedge clk);
    
    $display("释放SHAKE Hold信号");
    shake_hold <= 1'b0;
    
    shake_din_i <= 64'hD4C3B2A1F6E5D4C3;
    shake_last_din_i <= 1'b1;
    shake_last_din_byte_i <= 4'd8;
    @(posedge clk);
    
    shake_din_valid_i <= 1'b0;
    shake_last_din_i <= 1'b0;
    
    shake_dout_ready_i <= 1'b1;
    wait(dout_valid);
    @(posedge clk);
    shake_dout_ready_i <= 1'b0;
    repeat(10) @(posedge clk);
    
    //========================================
    // 测试完成
    //========================================
    repeat(100) @(posedge clk);
    
    $display("\n===========================================");
    $display("所有测试完成！");
    $display("- SHA2模式（SHA-256/512）");
    $display("- SHAKE模式（SHAKE128/256, SHA3-256）");  
    $display("- 算法切换测试");
    $display("- SHAKE Hold信号测试");
    $display("===========================================");
    $finish;
end

//--------------------------------------------------------------------------------------------------------
// 超时看门狗
//--------------------------------------------------------------------------------------------------------
initial begin
    #50_000_000;  // 50ms超时
    $display("\n错误：仿真超时！");
    $finish;
end

//--------------------------------------------------------------------------------------------------------
// 调试监控
//--------------------------------------------------------------------------------------------------------

// 监控算法模式切换
always @(algo_mode) begin
    $display("时间 %0t: 算法模式切换到 %b (%s-%s)", $time, algo_mode,
             algo_mode[3] ? "SHAKE" : "SHA2",
             algo_mode[3] ? (algo_mode[2:0] == 3'b000 ? "128" :
                            algo_mode[2:0] == 3'b001 ? "256" :
                            algo_mode[2:0] == 3'b010 ? "SHA3-256" :
                            algo_mode[2:0] == 3'b011 ? "SHA3-512" :
                            algo_mode[2:0] == 3'b100 ? "SHA3-224" :
                            algo_mode[2:0] == 3'b101 ? "SHA3-384" : "未知") :
                           (algo_mode[0] ? "512" : "256"));
end

// 监控SHAKE Hold信号
always @(shake_hold) begin
    if(algo_mode[3])
        $display("时间 %0t: SHAKE Hold信号变化为 %b", $time, shake_hold);
end

endmodule

