// ģ�鶨�壺SHAKE�㷨����ģ��
module shake_top
(
  // ����ʱ���ź�
  input               clk_i,              // system clock
  // ���븴λ�źţ�����Ч
  input               rst_ni,             // system reset, active low
  // ����ģʽѡ���ź�
  input       [2:0]   mode_i,             // mode selection
  // ���������ź�
  input               start_i,            // start of SHAKE process
  // ��������
  input       [63:0]  din_i,              // data input
  // ����������Ч�ź�
  input               din_valid_i,        // data input valid signal
  // �������һ�������ź�
  input               last_din_i,         // last data input
  // �������һ�����ݵ��ֽڳ��� 0��8
  input       [3:0]   last_din_byte_i,    // byte length of last data input, 0 to 8
  // ����������������ź�
  input               dout_ready_i,       // signal to request output data
  // ������ͣ�ڲ�״̬�����ź�
  input               sha3_hold,          // hold signal to pause internal state machine

  // �������Rλ����
  output      [1343:0] dout_full_o,       // full R-bit output
  // ������������Ч�ź�
  output              dout_full_valid_o,  // full output valid signal
  
  // =================== START: ����/�޸ĵĶ˿� ===================
  output [63:0]   cycle_count_o,        // ���Զ˿�: �����������ռ���ֵ
  output          start_pulse_o,        // ���Զ˿�: ����ڲ����ɵ� start_pulse
  output [63:0]   live_cycle_count_o    // ���Զ˿�: ���ʵʱ���еļ�����ֵ
  // =================== END: ����/�޸ĵĶ˿� =====================
);

// ģʽ����
localparam  MODE_SHAKE128 = 3'b000;
localparam  MODE_SHAKE256 = 3'b001;
localparam  MODE_SHA3_256 = 3'b010;
localparam  MODE_SHA3_512 = 3'b011;
localparam  MODE_SHA3_224 = 3'b100;
localparam  MODE_SHA3_384 = 3'b101;


// �ָ�������
localparam  DELIMITER_SHAKE = 8'h1F;  // For SHAKE128/256
localparam  DELIMITER_SHA3  = 8'h06;  // For SHA3-256/512

// ���ʲ������ֽڵ�λ��
localparam  RATE_SHAKE128 = 168;  // 1344 bits
localparam  RATE_SHAKE256 = 136;  // 1088 bits
localparam  RATE_SHA3_256 = 136;  // 1088 bits
localparam  RATE_SHA3_512 = 72;   // 576 bits
localparam  RATE_SHA3_224 = 144;  // 1152 bits
localparam  RATE_SHA3_384 = 104;  // 832 bits

// ״̬����
localparam  S_IDLE      = 3'd0;
localparam  S_ABSORB    = 3'd1;
localparam  S_FULL      = 3'd2;
localparam  S_APPEND    = 3'd3;
localparam  S_LAST_FULL = 3'd4;
localparam  S_SQUEEZE   = 3'd5;

// ״̬�Ĵ�������һ��״̬�Ĵ���
reg     [2:0]   state, nstate;
// ���һ�����ݱ�־
reg             last_data;
// ��һ��׷�ӱ�־
reg             first_append;
// ���һ�����ݵ��ֽ���
reg     [3:0]   last_din_byte;
// ģʽ�Ĵ���
reg     [2:0]   mode_reg;

// �ڲ��ź�
wire            din_ready_o;
wire    [63:0]  dout_o;
wire            dout_valid_o;

// din_valid �����ؼ��
reg din_valid_d;
wire din_valid_pulse = din_valid_i && !din_valid_d && !sha3_hold;

// �������ź�
wire            buf_overflow;
wire    [63:0]  sampled_din;
reg     [63:0]  last_sampled_din;
wire            buf_en;
reg     [7:0]   byte_cnt;
wire    [7:0]   byte_cnt_next;
reg     [7:0]   rate_bytes;
wire    [7:0]   delimiter;

// ����ź�
reg             dout_buf_available;
wire            last_dout_buf;
reg     [8:0]   output_cnt;

// ���ݻ�����
reg     [1343:0] data_buf;

// Keccak����ź�
wire            keccak_start;
wire            keccak_squeeze;
wire            keccak_ready;
reg     [1599:0] keccak_state_in;
wire    [1599:0] keccak_state_out;


// =================== START: ���м������͵����߼� ===================
// ���ڲ������ڵļ�����
reg [63:0] cycle_counter;
// ����������һ�β�������ļĴ���
reg [63:0] latched_cycle_count;

// ���� start_i �������ؼ��
reg start_i_d1;   // start_i �ӳ�һ������
wire start_pulse; // start_i �ĵ����������ź�

// start_i �����ؼ���߼�
always @(posedge clk_i) begin
    if (!rst_ni) begin
        start_i_d1 <= 1'b0;
    end else begin
        start_i_d1 <= start_i;
    end
end

// ���ҽ��� ��ǰ�� start_i �Ǹߵ�ƽ(1)������һ�ĵ� start_i_d1 �ǵ͵�ƽ(0)ʱ��
// start_pulse �Ż����һ���ߵ�ƽ���塣
assign start_pulse = start_i & ~start_i_d1;

// �������߼� (������ start_pulse ����)
always @(posedge clk_i) begin
    if (!rst_ni) begin
        cycle_counter       <= 64'd0;
        latched_cycle_count <= 64'd0;
    end else if (start_pulse) begin // <--- ʹ�ñ��ؼ���������ź�
        latched_cycle_count <= cycle_counter;
        cycle_counter       <= 64'd0;
    end else begin
        cycle_counter <= cycle_counter + 1;
    end
end
// =================== END: ���м������͵����߼� =====================


// ģʽ��ز���ѡ���߼�
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


// ģʽ�Ĵ��������߼�
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


// ���ݻ����������߼�
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

// ������ʹ���ź��߼�
assign buf_en = din_ready_o & din_valid_pulse & (last_din_i? last_din_byte_i!=0 : 1'b1) |
                state==S_APPEND |
                (dout_valid_o & dout_ready_i & state==S_SQUEEZE);

// ��������ѡ���߼�
assign sampled_din = (din_ready_o & din_valid_i & last_din_i)? last_sampled_din :
                       state==S_APPEND? ((first_append & last_din_byte[2:0]==3'b000)? 
                                        {delimiter, 56'd0} : 64'd0) :
                       state==S_SQUEEZE? 64'd0 : din_i;

// ���һ���������ݵ������߼�
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


// �ֽڼ����������߼�
always @(posedge clk_i)
if(!rst_ni)
  byte_cnt <= 0;
else if(start_i | buf_overflow)
  byte_cnt <= 0;
else if(buf_en & !sha3_hold)
  byte_cnt <= byte_cnt_next;

// ��һ���ֽڼ�������ֵ�߼�
assign byte_cnt_next = (state!=S_SQUEEZE & din_valid_i & last_din_i & 
                       last_din_byte_i==0)? byte_cnt : byte_cnt + 8;
assign buf_overflow  = buf_en & byte_cnt_next==rate_bytes;


// ������������ñ�־�����߼�
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

// ���ڼ��dout_valid_o�����صļĴ���
reg dout_valid_o_reg;
always @(posedge clk_i)
if(!rst_ni)
  dout_valid_o_reg <= 0;
else
  dout_valid_o_reg <= dout_valid_o;

// ���һ������������ź�
assign last_dout_buf = buf_overflow;


// ״̬�������߼�
always @(posedge clk_i)
if(!rst_ni)
  state <= S_IDLE;
else if(start_i)
  state <= S_ABSORB;
else if(!sha3_hold)
  state <= nstate;

// ״̬��ת���߼�
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

// ���һ�������ź�
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

// ������������ź�
assign din_ready_o = state==S_ABSORB | state==S_FULL & keccak_ready & ~last_data;


// Keccak�����ź�
assign keccak_start = (state==S_FULL | state==S_LAST_FULL) & keccak_ready & !sha3_hold;
assign keccak_squeeze = state==S_SQUEEZE & keccak_ready & 
                        (~dout_buf_available | last_dout_buf & dout_ready_i) & !sha3_hold;

// ����ģʽ����Keccak״̬����
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
// ѡ����ʵ�״̬����
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

// ԭ�����
assign dout_o = data_buf[1343:1280];
assign dout_valid_o = dout_buf_available;

// ��������Rλ���
wire dout_valid_rising_edge;
assign dout_valid_rising_edge = dout_valid_o & ~dout_valid_o_reg;

assign dout_full_o = (dout_valid_rising_edge & !sha3_hold) ? data_buf : 1344'h0;
assign dout_full_valid_o = dout_valid_rising_edge & !sha3_hold;

// Keccakģ��ʵ����
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

// =================== START: ������������˿� ===================
// ������ġ��ȶ��ļ���ֵ���ӵ�����˿�
assign cycle_count_o = latched_cycle_count;

// ���ڲ������ź����ӵ��µ�����˿�
assign start_pulse_o = start_pulse;
assign live_cycle_count_o = cycle_counter;
// =================== END: ������������˿� =====================

endmodule