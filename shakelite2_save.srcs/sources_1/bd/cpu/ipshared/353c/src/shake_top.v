// 模块定义：SHAKE算法顶层模块
module shake_top
(
  // 输入时钟信号
  input               clk_i,              // system clock
  // 输入复位信号，低有效
  input               rst_ni,             // system reset, active low
  // 输入模式选择信号
  input       [2:0]   mode_i,             // mode selection
  // 输入启动信号
  input               start_i,            // start of SHAKE process
  // 输入数据
  input       [63:0]  din_i,              // data input
  // 输入数据有效信号
  input               din_valid_i,        // data input valid signal
  // 输入最后一个数据信号
  input               last_din_i,         // last data input
  // 输入最后一个数据的字节长度 0到8
  input       [3:0]   last_din_byte_i,    // byte length of last data input, 0 to 8
  // 输入输出数据请求信号
  input               dout_ready_i,       // signal to request output data
  // 输入暂停内部状态机的信号
  input               sha3_hold,          // hold signal to pause internal state machine

  // 输出完整R位数据
  output      [1343:0] dout_full_o,       // full R-bit output
  // 输出完整输出有效信号
  output              dout_full_valid_o,  // full output valid signal
  
  // =================== START: 新增/修改的端口 ===================
  output [63:0]   cycle_count_o,        // 调试端口: 输出锁存的最终计数值
  output          start_pulse_o,        // 调试端口: 输出内部生成的 start_pulse
  output [63:0]   live_cycle_count_o    // 调试端口: 输出实时运行的计数器值
  // =================== END: 新增/修改的端口 =====================
);

// 模式定义
localparam  MODE_SHAKE128 = 3'b000;
localparam  MODE_SHAKE256 = 3'b001;
localparam  MODE_SHA3_256 = 3'b010;
localparam  MODE_SHA3_512 = 3'b011;
localparam  MODE_SHA3_224 = 3'b100;
localparam  MODE_SHA3_384 = 3'b101;


// 分隔符定义
localparam  DELIMITER_SHAKE = 8'h1F;  // For SHAKE128/256
localparam  DELIMITER_SHA3  = 8'h06;  // For SHA3-256/512

// 速率参数（字节单位）
localparam  RATE_SHAKE128 = 168;  // 1344 bits
localparam  RATE_SHAKE256 = 136;  // 1088 bits
localparam  RATE_SHA3_256 = 136;  // 1088 bits
localparam  RATE_SHA3_512 = 72;   // 576 bits
localparam  RATE_SHA3_224 = 144;  // 1152 bits
localparam  RATE_SHA3_384 = 104;  // 832 bits

// 状态参数
localparam  S_IDLE      = 3'd0;
localparam  S_ABSORB    = 3'd1;
localparam  S_FULL      = 3'd2;
localparam  S_APPEND    = 3'd3;
localparam  S_LAST_FULL = 3'd4;
localparam  S_SQUEEZE   = 3'd5;

// 状态寄存器和下一个状态寄存器
reg     [2:0]   state, nstate;
// 最后一个数据标志
reg             last_data;
// 第一次追加标志
reg             first_append;
// 最后一个数据的字节数
reg     [3:0]   last_din_byte;
// 模式寄存器
reg     [2:0]   mode_reg;

// 内部信号
wire            din_ready_o;
wire    [63:0]  dout_o;
wire            dout_valid_o;

// din_valid 上升沿检测
reg din_valid_d;
wire din_valid_pulse = din_valid_i && !din_valid_d && !sha3_hold;

// 缓冲区信号
wire            buf_overflow;
wire    [63:0]  sampled_din;
reg     [63:0]  last_sampled_din;
wire            buf_en;
reg     [7:0]   byte_cnt;
wire    [7:0]   byte_cnt_next;
reg     [7:0]   rate_bytes;
wire    [7:0]   delimiter;

// 输出信号
reg             dout_buf_available;
wire            last_dout_buf;
reg     [8:0]   output_cnt;

// 数据缓冲区
reg     [1343:0] data_buf;

// Keccak相关信号
wire            keccak_start;
wire            keccak_squeeze;
wire            keccak_ready;
reg     [1599:0] keccak_state_in;
wire    [1599:0] keccak_state_out;


// =================== START: 所有计数器和调试逻辑 ===================
// 用于测量周期的计数器
reg [63:0] cycle_counter;
// 用于锁存上一次测量结果的寄存器
reg [63:0] latched_cycle_count;

// 用于 start_i 的上升沿检测
reg start_i_d1;   // start_i 延迟一个周期
wire start_pulse; // start_i 的单周期脉冲信号

// start_i 上升沿检测逻辑
always @(posedge clk_i) begin
    if (!rst_ni) begin
        start_i_d1 <= 1'b0;
    end else begin
        start_i_d1 <= start_i;
    end
end

// 当且仅当 当前的 start_i 是高电平(1)，而上一拍的 start_i_d1 是低电平(0)时，
// start_pulse 才会产生一个高电平脉冲。
assign start_pulse = start_i & ~start_i_d1;

// 计数器逻辑 (现在由 start_pulse 触发)
always @(posedge clk_i) begin
    if (!rst_ni) begin
        cycle_counter       <= 64'd0;
        latched_cycle_count <= 64'd0;
    end else if (start_pulse) begin // <--- 使用边沿检测后的脉冲信号
        latched_cycle_count <= cycle_counter;
        cycle_counter       <= 64'd0;
    end else begin
        cycle_counter <= cycle_counter + 1;
    end
end
// =================== END: 所有计数器和调试逻辑 =====================


// 模式相关参数选择逻辑
always @(*) begin
  case(mode_reg)
    MODE_SHAKE128: rate_bytes = RATE_SHAKE128;
    MODE_SHAKE256: rate_bytes = RATE_SHAKE256;
    MODE_SHA3_256: rate_bytes = RATE_SHA3_256;
    MODE_SHA3_512: rate_bytes = RATE_SHA3_512;
    MODE_SHA3_224: rate_bytes = RATE_SHA3_224;
    MODE_SHA3_384: rate_bytes = RATE_SHA3_384;
    default:       rate_bytes = RATE_SHAKE256;
  endcase
end
assign delimiter = (mode_reg == MODE_SHAKE128 || mode_reg == MODE_SHAKE256) ? 
                   DELIMITER_SHAKE : DELIMITER_SHA3;


// 模式寄存器更新逻辑
always @(posedge clk_i)
if(!rst_ni) begin
  mode_reg <= MODE_SHAKE256;
end
else if(start_i) begin
  mode_reg <= mode_i;
end


always @(posedge clk_i) begin
    if (!rst_ni) begin
        din_valid_d <= 1'b0;
    end else begin
        din_valid_d <= din_valid_i;
    end
end


// 数据缓冲区更新逻辑
always @(posedge clk_i)
if(!rst_ni)
  data_buf <= 'h0;
else if(!sha3_hold) begin
  if(keccak_squeeze) begin
    case(mode_reg)
      MODE_SHAKE128: data_buf <= keccak_state_out[1599:256];
      MODE_SHAKE256: begin
        data_buf[1343:256] <= keccak_state_out[1599:512];
        data_buf[255:0] <= 'h0;
      end
      MODE_SHA3_256: begin
        data_buf[1343:256] <= keccak_state_out[1599:512];
        data_buf[255:0] <= 'h0;
      end
      MODE_SHA3_512: begin
        data_buf[1343:768] <= keccak_state_out[1599:1024];
        data_buf[767:0] <= 'h0;
      end
      MODE_SHA3_224: begin
        data_buf[1343:192] <= keccak_state_out[1599:448];
        data_buf[192:0] <= 'h0;
      end
      MODE_SHA3_384: begin
        data_buf[1343:512] <= keccak_state_out[1599:768];
        data_buf[512:0] <= 'h0;
      end
    endcase
  end
  else if(buf_en)
    data_buf <= {data_buf[1343-64:0], sampled_din};
end

// 缓冲区使能信号逻辑
assign buf_en = din_ready_o & din_valid_pulse & (last_din_i? last_din_byte_i!=0 : 1'b1) |
                state==S_APPEND |
                (dout_valid_o & dout_ready_i & state==S_SQUEEZE);

// 采样数据选择逻辑
assign sampled_din = (din_ready_o & din_valid_i & last_din_i)? last_sampled_din :
                       state==S_APPEND? ((first_append & last_din_byte[2:0]==3'b000)? 
                                        {delimiter, 56'd0} : 64'd0) :
                       state==S_SQUEEZE? 64'd0 : din_i;

// 最后一个采样数据的生成逻辑
always @(*)
begin
  case(last_din_byte_i)
    1: last_sampled_din = {din_i[63-:1*8], delimiter, {6*8{1'b0}}};
    2: last_sampled_din = {din_i[63-:2*8], delimiter, {5*8{1'b0}}};
    3: last_sampled_din = {din_i[63-:3*8], delimiter, {4*8{1'b0}}};
    4: last_sampled_din = {din_i[63-:4*8], delimiter, {3*8{1'b0}}};
    5: last_sampled_din = {din_i[63-:5*8], delimiter, {2*8{1'b0}}};
    6: last_sampled_din = {din_i[63-:6*8], delimiter, {1*8{1'b0}}};
    7: last_sampled_din = {din_i[63-:7*8], delimiter};
    default: last_sampled_din = din_i;
  endcase
end


// 字节计数器更新逻辑
always @(posedge clk_i)
if(!rst_ni)
  byte_cnt <= 0;
else if(start_i | buf_overflow)
  byte_cnt <= 0;
else if(buf_en & !sha3_hold)
  byte_cnt <= byte_cnt_next;

// 下一个字节计数器的值逻辑
assign byte_cnt_next = (state!=S_SQUEEZE & din_valid_i & last_din_i & 
                       last_din_byte_i==0)? byte_cnt : byte_cnt + 8;
assign buf_overflow  = buf_en & byte_cnt_next==rate_bytes;


// 输出缓冲区可用标志更新逻辑
always @(posedge clk_i)
if(!rst_ni)
  dout_buf_available <= 0;
else if(start_i)
  dout_buf_available <= 0;
else if(!sha3_hold) begin
  if(keccak_squeeze)
    dout_buf_available <= 1;
  else if(last_dout_buf & dout_ready_i)
    dout_buf_available <= 0;
end

// 用于检测dout_valid_o上升沿的寄存器
reg dout_valid_o_reg;
always @(posedge clk_i)
if(!rst_ni)
  dout_valid_o_reg <= 0;
else
  dout_valid_o_reg <= dout_valid_o;

// 最后一个输出缓冲区信号
assign last_dout_buf = buf_overflow;


// 状态机更新逻辑
always @(posedge clk_i)
if(!rst_ni)
  state <= S_IDLE;
else if(start_i)
  state <= S_ABSORB;
else if(!sha3_hold)
  state <= nstate;

// 状态机转换逻辑
always @(*)
begin
  nstate = state;
  if(!sha3_hold) begin
    case(state)
      S_IDLE      : if(start_i)
                      nstate = S_ABSORB;
      S_ABSORB    : if(din_valid_i & last_din_i & last_din_byte_i!=8 & 
                       byte_cnt==(rate_bytes-8))
                      nstate = S_LAST_FULL;
                    else if(buf_overflow)
                      nstate = S_FULL;
                    else if(din_valid_i & last_din_i)
                      nstate = S_APPEND;
      S_FULL      : if(keccak_ready)
                      nstate = (last_data | last_din_i & din_valid_i)? S_APPEND : S_ABSORB;
      S_APPEND    : if(buf_overflow)
                      nstate = S_LAST_FULL;
      S_LAST_FULL : if(keccak_ready)
                      nstate = S_SQUEEZE;
      S_SQUEEZE   : if(start_i)
                      nstate = S_ABSORB;
      default     : nstate = S_IDLE;
    endcase
  end
end

// 最后一个数据信号
always @(posedge clk_i)
if(!rst_ni) begin
  last_data     <= 0;
  first_append  <= 0;
  last_din_byte <= 0;
end
else if(start_i) begin
  last_data     <= 0;
  first_append  <= 0;
  last_din_byte <= 0;
end
else if(!sha3_hold) begin
  if(last_din_i & din_ready_o) begin
    last_data     <= 1;
    first_append  <= 1;
    last_din_byte <= last_din_byte_i;
  end
  else if (first_append & state==S_APPEND)
    first_append <= 0;
end

// 数据输入就绪信号
assign din_ready_o = state==S_ABSORB | state==S_FULL & keccak_ready & ~last_data;


// Keccak控制信号
assign keccak_start = (state==S_FULL | state==S_LAST_FULL) & keccak_ready & !sha3_hold;
assign keccak_squeeze = state==S_SQUEEZE & keccak_ready & 
                        (~dout_buf_available | last_dout_buf & dout_ready_i) & !sha3_hold;

// 根据模式创建Keccak状态输入
wire [1599:0] keccak_state_in_shake128;
wire [1599:0] keccak_state_in_shake256;
wire [1599:0] keccak_state_in_sha3_256;
wire [1599:0] keccak_state_in_sha3_512;
wire [1599:0] keccak_state_in_sha3_224;
wire [1599:0] keccak_state_in_sha3_384;

assign keccak_state_in_shake128 = {keccak_state_out[1599:256] ^ 
                                   {data_buf[1343:8],
                                    data_buf[7]^(state==S_LAST_FULL),
                                    data_buf[6:0]},
                                   keccak_state_out[255:0]};

assign keccak_state_in_shake256 = {keccak_state_out[1599-:1088] ^ 
                                   {data_buf[1087:8],
                                    data_buf[7]^(state==S_LAST_FULL),
                                    data_buf[6:0]},
                                   keccak_state_out[511:0]};

assign keccak_state_in_sha3_256 = keccak_state_in_shake256;

assign keccak_state_in_sha3_512 = {keccak_state_out[1599-:576] ^ 
                                   {data_buf[575:8],
                                    data_buf[7]^(state==S_LAST_FULL),
                                    data_buf[6:0]},
                                   keccak_state_out[1023:0]};

assign keccak_state_in_sha3_224 = {keccak_state_out[1599-:1152] ^ 
                                   {data_buf[1151:8],
                                    data_buf[7]^(state==S_LAST_FULL),
                                    data_buf[6:0]},
                                   keccak_state_out[447:0]};

assign keccak_state_in_sha3_384 = {keccak_state_out[1599-:832] ^ 
                                   {data_buf[831:8],
                                    data_buf[7]^(state==S_LAST_FULL),
                                    data_buf[6:0]},
                                   keccak_state_out[767:0]};
// 选择合适的状态输入
always @(*) begin
  case(mode_reg)
    MODE_SHAKE128: keccak_state_in = keccak_state_in_shake128;
    MODE_SHAKE256: keccak_state_in = keccak_state_in_shake256;
    MODE_SHA3_256: keccak_state_in = keccak_state_in_sha3_256;
    MODE_SHA3_512: keccak_state_in = keccak_state_in_sha3_512;
    MODE_SHA3_224: keccak_state_in = keccak_state_in_sha3_224;
    MODE_SHA3_384: keccak_state_in = keccak_state_in_sha3_384;
    default:       keccak_state_in = keccak_state_in_shake256;
  endcase
end

// 原有输出
assign dout_o = data_buf[1343:1280];
assign dout_valid_o = dout_buf_available;

// 新增完整R位输出
wire dout_valid_rising_edge;
assign dout_valid_rising_edge = dout_valid_o & ~dout_valid_o_reg;

assign dout_full_o = (dout_valid_rising_edge & !sha3_hold) ? data_buf : 1344'h0;
assign dout_full_valid_o = dout_valid_rising_edge & !sha3_hold;

// Keccak模块实例化
keccak_top keccak_top (
    .Clock    (clk_i            ),
    .Reset    (~rst_ni | start_i),
    .Start    (keccak_start     ),
    .Din      (keccak_state_in  ),
    .Req_more (keccak_squeeze   ),
    .Hold     (sha3_hold        ),
    .Ready    (keccak_ready     ),
    .Dout     (keccak_state_out )
);

// =================== START: 连接所有输出端口 ===================
// 将锁存的、稳定的计数值连接到输出端口
assign cycle_count_o = latched_cycle_count;

// 将内部调试信号连接到新的输出端口
assign start_pulse_o = start_pulse;
assign live_cycle_count_o = cycle_counter;
// =================== END: 连接所有输出端口 =====================

endmodule