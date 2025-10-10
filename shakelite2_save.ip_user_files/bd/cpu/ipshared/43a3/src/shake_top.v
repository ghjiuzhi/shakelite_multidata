// 模块定义：SHAKE算法顶层模块
module shake_top
(
  // 输入时钟信号
  input                     clk_i,              //system clock
  // 输入复位信号，低有效
  input                     rst_ni,             //system reset, active low
  // 输入模式选择信号
  input   [2:0]             mode_i,             //mode selection
  // 输入启动信号＿1个时钟脉冿
  input                     start_i,            //start of SHAKE process, 1 clock pulse
  // 输入数据
  input   [63:0]            din_i,              //data input
  // 输入数据有效信号
  input                     din_valid_i,        //data input valid signal
  // 输入朿后一个数据信叿
  input                     last_din_i,         //last data input
  // 输入朿后一个数据的字节长度＿0刿8
  input   [3:0]             last_din_byte_i,    //byte length of last data input, 0 to 8
  // 输入输出数据请求信号
  input                     dout_ready_i,       //signal to request output data
  // 输入暂停内部状濁机的信叿
  input                     sha3_hold,          //hold signal to pause internal state machine
  
  // 输出完整R位数据（对于SHAKE128昿1344位，其他模式使用高R位）
  output  [1343:0]          dout_full_o,        //full R-bit output (1344 bits for SHAKE128, use high R bits for other modes)
  // 输出完整输出有效信号
  output                    dout_full_valid_o   //full output valid signal
);

// 模式定义
// SHAKE128模式
localparam  MODE_SHAKE128 = 3'b000;
// SHAKE256模式
localparam  MODE_SHAKE256 = 3'b001;
// SHA3-256模式
localparam  MODE_SHA3_256 = 3'b010;
// SHA3-512模式
localparam  MODE_SHA3_512 = 3'b011;
// SHA3-224模式
localparam  MODE_SHA3_224 = 3'b100;
// SHA3-384模式
localparam  MODE_SHA3_384 = 3'b101;


// 分隔符定乿
// SHAKE128/256的分隔符
localparam  DELIMITER_SHAKE = 8'h1F;  // For SHAKE128/256
// SHA3-256/512的分隔符
localparam  DELIMITER_SHA3  = 8'h06;  // For SHA3-256/512
// 速率参数（字节单位）
// SHAKE128的?率＿1344使
localparam  RATE_SHAKE128 = 168;  // 1344 bits
// SHAKE256的?率＿1088使
localparam  RATE_SHAKE256 = 136;  // 1088 bits  
// SHA3-256的?率＿1088使
localparam  RATE_SHA3_256 = 136;  // 1088 bits 
// SHA3-512的?率＿576使
localparam  RATE_SHA3_512 = 72;   // 576 bits
// SHA3-224的?率＿
localparam  RATE_SHA3_224 = 144;  // 1152 bits (same as SHAKE256)
// SHA3-384的?率＿
localparam  RATE_SHA3_384 = 104;   // 832 bits

// 状濁参敿
// 空闲状濿
localparam  S_IDLE      = 3'd0;
// 吸收状濿
localparam  S_ABSORB    = 3'd1;
// 满状怿
localparam  S_FULL      = 3'd2;
// 追加状濿
localparam  S_APPEND    = 3'd3;
// 朿后满状濿
localparam  S_LAST_FULL = 3'd4;
// 挤压状濿
localparam  S_SQUEEZE   = 3'd5;

// 状濁寄存器和下丿状濁寄存器
reg     [2:0]   state, nstate;
// 朿后一个数据标忿
reg             last_data;
// 第一次追加标忿
reg             first_append;
// 朿后一个数据的字节敿
reg     [3:0]   last_din_byte;
// 模式寄存器，用于存储当前模式
reg     [2:0]   mode_reg;  // Registered mode signal

// 内部信号替代移除的端叿
// 数据输入就绪信号
wire            din_ready_o;    // 内部din_ready信号
// 64位输出数据信叿
wire    [63:0]  dout_o;         // 内部64位输出信叿
// 输出有效信号
wire            dout_valid_o;   // 内部输出有效信号


// 新增：上升沿检测寄存器
reg din_valid_d;  // 延迟版本的din_valid_i

// 新增：din_valid脉冲信号（只在上升沿产生单周期高电平）
wire din_valid_pulse = din_valid_i && !din_valid_d && !sha3_hold;  // 加入!sha3_hold以确保hold时不触发





// 缓冲区溢出信叿
wire            buf_overflow;
// 采样后的输入数据
wire    [63:0]  sampled_din;
// 上一次采样的输入数据
reg     [63:0]  last_sampled_din;
// 缓冲区使能信叿
wire            buf_en;
// 字节计数噿
reg     [7:0]   byte_cnt;
// 下一个字节计数器的忿
wire    [7:0]   byte_cnt_next;
// 当前速率（字节单位）
reg     [7:0]   rate_bytes;  // Current rate in bytes
// 当前分隔笿
wire    [7:0]   delimiter;   // Current delimiter

// 输出缓冲区可用标忿
reg             dout_buf_available;
// 朿后一个输出缓冲区信号
wire            last_dout_buf;
// 输出计数器，用于SHA3输出字计敿
reg     [8:0]   output_cnt;  // Counter for SHA3 output words

// 数据缓冲区，朿大尺寸为SHAKE128＿168*8 - 1＿
reg     [1343:0]  data_buf;   // Max size for SHAKE128 (168*8 - 1)

// Keccak相关信号
// Keccak启动信号
wire                keccak_start;
// Keccak挤压信号
wire                keccak_squeeze;
// Keccak就绪信号
wire                keccak_ready;
// Keccak输入状濁寄存器
reg     [1599:0]    keccak_state_in;  // 改为reg类型
// Keccak输出状濿
wire    [1599:0]    keccak_state_out;

// 模式相关参数选择逻辑
// 根据当前模式选择速率参数
always @(*) begin
  case(mode_reg)
    MODE_SHAKE128: rate_bytes = RATE_SHAKE128;  // SHAKE128速率
    MODE_SHAKE256: rate_bytes = RATE_SHAKE256;  // SHAKE256速率
    MODE_SHA3_256: rate_bytes = RATE_SHA3_256;  // SHA3-256速率
    MODE_SHA3_512: rate_bytes = RATE_SHA3_512;  // SHA3-512速率
    MODE_SHA3_224: rate_bytes = RATE_SHA3_224;  // SHA3-224速率
    MODE_SHA3_384: rate_bytes = RATE_SHA3_384;  // SHA3-384速率
    default:       rate_bytes = RATE_SHAKE256;  // 默认使用SHAKE256速率
  endcase
end
// 分隔符?择逻辑
// 根据模式选择分隔笿
assign delimiter = (mode_reg == MODE_SHAKE128 || mode_reg == MODE_SHAKE256) ? 
                   DELIMITER_SHAKE : DELIMITER_SHA3;


// 模式寄存器更新?辑
always @(posedge clk_i)
if(!rst_ni) begin
  mode_reg <= MODE_SHAKE256;  // 复位时默认设置为SHAKE256模式
end
else if(start_i) begin
  mode_reg <= mode_i;         // 使用输入的mode_i更新模式
end


always @(posedge clk_i) begin
    if (!rst_ni) begin
        din_valid_d <= 1'b0;
    end else begin
        din_valid_d <= din_valid_i;  // 延迟一个周期
    end
end


// 数据缓冲区更新?辑
always @(posedge clk_i)
if(!rst_ni)
  data_buf <= 'h0;  // 复位时清空数据缓冲区
else if(!sha3_hold) begin  // 只有在hold信号为低时才允许更新
  if(keccak_squeeze) begin
    // 根据模式从状态中提取速率部分用于输出
    case(mode_reg)
      MODE_SHAKE128: data_buf <= keccak_state_out[1599:256];  // 1344使
      MODE_SHAKE256: begin
        data_buf[1343:256] <= keccak_state_out[1599:512];  // 1088使
        data_buf[255:0] <= 'h0;
      end
      MODE_SHA3_256: begin  
        data_buf[1343:256] <= keccak_state_out[1599:512];  // 1088使
        data_buf[255:0] <= 'h0;
      end
      MODE_SHA3_512: begin
        data_buf[1343:768] <= keccak_state_out[1599:1024];  // 576使
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
    data_buf <= {data_buf[1343-64:0], sampled_din};  // 更新数据缓冲匿
end
  
// 缓冲区使能信号?辑
// 使能信号用于数据输入、追加和挤压状濿
assign buf_en = din_ready_o & din_valid_pulse & (last_din_i? last_din_byte_i!=0 : 1'b1) | 
                state==S_APPEND | 
                (dout_valid_o & dout_ready_i & state==S_SQUEEZE);

// 采样数据选择逻辑
// 根据状濁和输入条件选择采样数据
assign sampled_din = (din_ready_o & din_valid_i & last_din_i)? last_sampled_din :
                     state==S_APPEND? ((first_append & last_din_byte[2:0]==3'b000)? 
                                      {delimiter, 56'd0} : 64'd0) :
                     state==S_SQUEEZE? 64'd0 : din_i;

// 朿后一个采样数据的生成逻辑
always @(*)
begin
  case(last_din_byte_i)
    1: last_sampled_din = {din_i[63-:1*8], delimiter, {6*8{1'b0}}};  // 1字节数据+分隔笿
    2: last_sampled_din = {din_i[63-:2*8], delimiter, {5*8{1'b0}}};  // 2字节数据+分隔笿
    3: last_sampled_din = {din_i[63-:3*8], delimiter, {4*8{1'b0}}};  // 3字节数据+分隔笿
    4: last_sampled_din = {din_i[63-:4*8], delimiter, {3*8{1'b0}}};  // 4字节数据+分隔笿
    5: last_sampled_din = {din_i[63-:5*8], delimiter, {2*8{1'b0}}};  // 5字节数据+分隔笿
    6: last_sampled_din = {din_i[63-:6*8], delimiter, {1*8{1'b0}}};  // 6字节数据+分隔笿
    7: last_sampled_din = {din_i[63-:7*8], delimiter};              // 7字节数据+分隔笿
    default: last_sampled_din = din_i;                              // 默认直接使用输入数据
  endcase
end


// 字节计数器更新?辑
always @(posedge clk_i)
if(!rst_ni)
  byte_cnt <= 0;  // 复位时清零字节计数器
else if(start_i | buf_overflow)
  byte_cnt <= 0;  // 启动或缓冲区溢出时清雿
else if(buf_en & !sha3_hold)  // 只有在hold信号为低时才允许更新
  byte_cnt <= byte_cnt_next;  // 更新字节计数噿

// 下一个字节计数器的忼?辑
// 在非挤压状濁下，如果是朿后一个数据且字节数为0，则保持当前计数
assign byte_cnt_next = (state!=S_SQUEEZE & din_valid_i & last_din_i & 
                       last_din_byte_i==0)? byte_cnt : byte_cnt + 8;
// 缓冲区溢出信叿
assign buf_overflow  = buf_en & byte_cnt_next==rate_bytes;


// 输出缓冲区可用标志更新?辑
always @(posedge clk_i)
if(!rst_ni)
  dout_buf_available <= 0;  // 复位时输出缓冲区不可甿
else if(start_i)
  dout_buf_available <= 0;  // 启动时输出缓冲区不可甿
else if(!sha3_hold) begin  // 只有在hold信号为低时才允许更新
  if(keccak_squeeze)
    dout_buf_available <= 1;  // 挤压时输出缓冲区可用
  else if(last_dout_buf & dout_ready_i)
    dout_buf_available <= 0;  // 朿后一个输出缓冲区且请求输出时不可甿
end

// 用于棿测dout_valid_o上升沿的寄存噿 - 修复sha3_hold控制逻辑
reg dout_valid_o_reg;
always @(posedge clk_i)
if(!rst_ni)
  dout_valid_o_reg <= 0;  // 复位时清雿
else
  dout_valid_o_reg <= dout_valid_o;  // 始终跟踪dout_valid_o，不受sha3_hold影响

// 朿后一个输出缓冲区信号
assign last_dout_buf = buf_overflow;


// 状濁机更新逻辑
always @(posedge clk_i)
if(!rst_ni)
  state <= S_IDLE;  // 复位时进入空闲状怿
else if(start_i)
  state <= S_ABSORB;  // 启动时进入吸收状怿
else if(!sha3_hold)  // 只有在hold信号为低时才允许状濁转捿
  state <= nstate;  // 更新状濿

// 状濁机转换逻辑
always @(*)
begin
  nstate = state;  // 默认保持当前状濿
  if(!sha3_hold) begin  // 只有在hold信号为低时才进行状濁转换?辑
    case(state)
      S_IDLE      : if(start_i)  // 空闲状濁：如果启动信号有效，进入吸收状怿
                      nstate = S_ABSORB;
      S_ABSORB    : if(din_valid_i & last_din_i & last_din_byte_i!=8 & 
                       byte_cnt==(rate_bytes-8))  // 吸收状濁：如果朿后一个数据且字节计数接近速率，进入最后满状濿
                      nstate = S_LAST_FULL;
                    else if(buf_overflow)  // 如果缓冲区溢出，进入满状怿
                      nstate = S_FULL;
                    else if(din_valid_i & last_din_i)  // 如果是最后一个数据，进入追加状濿
                      nstate = S_APPEND;
      S_FULL      : if(keccak_ready)  // 满状态：如果Keccak就绪，进入追加或吸收状濿
                      nstate = (last_data | last_din_i & din_valid_i)? S_APPEND : S_ABSORB;
      S_APPEND    : if(buf_overflow)  // 追加状濁：如果缓冲区溢出，进入朿后满状濿
                      nstate = S_LAST_FULL;
      S_LAST_FULL : if(keccak_ready)  // 朿后满状濁：如果Keccak就绪，进入挤压状怿
                      nstate = S_SQUEEZE;
      S_SQUEEZE   : if(start_i)  // 挤压状濁：如果启动信号有效，进入吸收状怿
                      nstate = S_ABSORB;
      default     : nstate = S_IDLE;  // 默认状濁：进入空闲状濿
    endcase
  end
end

// 朿后一个数据信叿 - 添加sha3_hold控制
always @(posedge clk_i)
if(!rst_ni) begin
  last_data     <= 0;  // 复位时清零最后一个数据标忿
  first_append  <= 0;  // 复位时清零第丿次追加标忿
  last_din_byte <= 0;  // 复位时清零最后一个数据字节数
end
else if(start_i) begin
  last_data     <= 0;  // 启动时清零最后一个数据标忿
  first_append  <= 0;  // 启动时清零第丿次追加标忿
  last_din_byte <= 0;  // 启动时清零最后一个数据字节数
end
else if(!sha3_hold) begin  
  if(last_din_i & din_ready_o) begin  // 如果朿后一个数据且输入就绪，更新相关标忿
    last_data     <= 1;
    first_append  <= 1;
    last_din_byte <= last_din_byte_i;
  end
  else if (first_append & state==S_APPEND)  // 如果第一次追加且在追加状态，清除第一次追加标忿
    first_append <= 0;
end

// 数据输入就绪信号
// 在吸收状态或满状态且Keccak就绪且非朿后一个数据时有效
assign din_ready_o = state==S_ABSORB | state==S_FULL & keccak_ready & ~last_data;


// Keccak控制信号
// Keccak启动信号：在满状态或朿后满状濁且Keccak就绪且无hold信号时有敿
assign keccak_start = (state==S_FULL | state==S_LAST_FULL) & keccak_ready & !sha3_hold;
// Keccak挤压信号：在挤压状濁且Keccak就绪且输出缓冲区不可用或朿后一个输出缓冲区且请求输出且无hold信号时有敿
assign keccak_squeeze = state==S_SQUEEZE & keccak_ready & 
                       (~dout_buf_available | last_dout_buf & dout_ready_i) & !sha3_hold;

// 根据模式创建Keccak状濁输兿
// SHAKE128状濁输入信叿
wire [1599:0] keccak_state_in_shake128;
// SHAKE256状濁输入信叿
wire [1599:0] keccak_state_in_shake256;
// SHA3-256状濁输入信叿
wire [1599:0] keccak_state_in_sha3_256;
// SHA3-512状濁输入信叿
wire [1599:0] keccak_state_in_sha3_512;
// SHA3-224状濁输入信叿
wire [1599:0] keccak_state_in_sha3_224;
// SHA3-384状濁输入信叿
wire [1599:0] keccak_state_in_sha3_384;

// SHAKE128：?率=1344，容釿=256
// 状濁输入为输出状濁与数据缓冲区的异或结果
assign keccak_state_in_shake128 = {keccak_state_out[1599:256] ^ 
                                   {data_buf[1343:8],
                                    data_buf[7]^(state==S_LAST_FULL),
                                    data_buf[6:0]},
                                   keccak_state_out[255:0]};

// SHAKE256和SHA3-256：?率=1088，容釿=512
// 状濁输入为输出状濁与数据缓冲区的异或结果
assign keccak_state_in_shake256 = {keccak_state_out[1599-:1088] ^ 
                                   {data_buf[1087:8],
                                    data_buf[7]^(state==S_LAST_FULL),
                                    data_buf[6:0]},
                                   keccak_state_out[511:0]};

// SHA3-256与SHAKE256使用相同的?率和容釿
assign keccak_state_in_sha3_256 = keccak_state_in_shake256;  // Same rate/capacity

// SHA3-512：?率=576，容釿=1024
// 状濁输入为输出状濁与数据缓冲区的异或结果
assign keccak_state_in_sha3_512 = {keccak_state_out[1599-:576] ^ 
                                   {data_buf[575:8],
                                    data_buf[7]^(state==S_LAST_FULL),
                                    data_buf[6:0]},
                                   keccak_state_out[1023:0]};

// SHA3-224：?率=1152，容釿=448
// 状濁输入为输出状濁与数据缓冲区的异或结果
assign keccak_state_in_sha3_224 = {keccak_state_out[1599-:1152] ^ 
                                   {data_buf[1151:8],
                                    data_buf[7]^(state==S_LAST_FULL),
                                    data_buf[6:0]},
                                   keccak_state_out[447:0]};

// SHA3-384：?率=832，容釿=768
// 状濁输入为输出状濁与数据缓冲区的异或结果
assign keccak_state_in_sha3_384 = {keccak_state_out[1599-:832] ^ 
                                   {data_buf[831:8],
                                    data_buf[7]^(state==S_LAST_FULL),
                                    data_buf[6:0]},
                                   keccak_state_out[767:0]};
// 选择合?的状濁输兿
always @(*) begin
  case(mode_reg)
    MODE_SHAKE128: keccak_state_in = keccak_state_in_shake128;  // SHAKE128状濁输兿
    MODE_SHAKE256: keccak_state_in = keccak_state_in_shake256;  // SHAKE256状濁输兿
    MODE_SHA3_256: keccak_state_in = keccak_state_in_sha3_256;  // SHA3-256状濁输兿
    MODE_SHA3_512: keccak_state_in = keccak_state_in_sha3_512;  // SHA3-512状濁输兿
    MODE_SHA3_224: keccak_state_in = keccak_state_in_sha3_224;  // SHA3-224状濁输兿
    MODE_SHA3_384: keccak_state_in = keccak_state_in_sha3_384;  // SHA3-384状濁输兿
    default:       keccak_state_in = keccak_state_in_shake256;  // 默认使用SHAKE256状濁输兿
  endcase
end

////////////////////////////////////////////////////////////////////////////////
// 原有输出（保持不变）
// 输出数据为数据缓冲区的高64使
assign dout_o = data_buf[1343:1280];
// 输出有效信号为输出缓冲区可用标志
assign dout_valid_o = dout_buf_available;

////////////////////////////////////////////////////////////////////////////////
// 新增完整R位输凿 - 修复hold期间的输出?辑
// 棿测dout_valid_o的上升沿，产生一个时钟周期的脉冲
wire dout_valid_rising_edge;
assign dout_valid_rising_edge = dout_valid_o & ~dout_valid_o_reg;

// 完整R位输凿 - 只有圿!sha3_hold时才允许输出脉冲
// 只有在上升沿且无hold信号时输出数据缓冲区内容
assign dout_full_o = (dout_valid_rising_edge & !sha3_hold) ? data_buf : 1344'h0;
// 完整输出有效信号
assign dout_full_valid_o = dout_valid_rising_edge & !sha3_hold;

// Keccak模块实例匿
keccak_top keccak_top (
    .Clock    (clk_i            ),  // 时钟信号输入
    .Reset    (~rst_ni | start_i),  // 复位信号，高有效（复位或启动时有效）
    .Start    (keccak_start     ),  // 启动信号
    .Din      (keccak_state_in  ),  // 输入状濁数捿
    .Req_more (keccak_squeeze   ),  // 请求更多数据信号
    .Hold     (sha3_hold        ),  // 暂停信号
    .Ready    (keccak_ready     ),  // 就绪信号输出
    .Dout     (keccak_state_out )   // 输出状濁数捿
);

//ila_0  u_ila (
//	.clk(clk_i), // input wire clk
//	.probe0(
//	{ din_i,
//	  last_din_i,
//	  dout_ready_i,
//	  dout_full_valid_o,
//	  din_valid_i,
//	  din_ready_o,
//	  sampled_din,
//      state,
//      byte_cnt,
//      dout_buf_available,
//      din_valid_pulse,
//      dout_o,
//      buf_en,
//      dout_full_o
//	}) // input wire [1799:0] probe0
//);


endmodule