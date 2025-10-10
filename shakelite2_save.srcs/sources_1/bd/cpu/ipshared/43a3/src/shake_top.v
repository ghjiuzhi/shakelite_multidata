// ģ�鶨�壺SHAKE�㷨����ģ��
module shake_top
(
  // ����ʱ���ź�
  input                     clk_i,              //system clock
  // ���븴λ�źţ�����Ч
  input                     rst_ni,             //system reset, active low
  // ����ģʽѡ���ź�
  input   [2:0]             mode_i,             //mode selection
  // ���������źţ�1��ʱ������
  input                     start_i,            //start of SHAKE process, 1 clock pulse
  // ��������
  input   [63:0]            din_i,              //data input
  // ����������Ч�ź�
  input                     din_valid_i,        //data input valid signal
  // ����c��һ�������Ņ�
  input                     last_din_i,         //last data input
  // ����c��һ�����ݵ��ֽڳ��ȣ�0��8
  input   [3:0]             last_din_byte_i,    //byte length of last data input, 0 to 8
  // ����������������ź�
  input                     dout_ready_i,       //signal to request output data
  // ������ͣ�ڲ�״������Ņ�
  input                     sha3_hold,          //hold signal to pause internal state machine
  
  // �������Rλ���ݣ�����SHAKE128�p1344λ������ģʽʹ�ø�Rλ��
  output  [1343:0]          dout_full_o,        //full R-bit output (1344 bits for SHAKE128, use high R bits for other modes)
  // ������������Ч�ź�
  output                    dout_full_valid_o   //full output valid signal
);

// ģʽ����
// SHAKE128ģʽ
localparam  MODE_SHAKE128 = 3'b000;
// SHAKE256ģʽ
localparam  MODE_SHAKE256 = 3'b001;
// SHA3-256ģʽ
localparam  MODE_SHA3_256 = 3'b010;
// SHA3-512ģʽ
localparam  MODE_SHA3_512 = 3'b011;
// SHA3-224ģʽ
localparam  MODE_SHA3_224 = 3'b100;
// SHA3-384ģʽ
localparam  MODE_SHA3_384 = 3'b101;


// �ָ������v
// SHAKE128/256�ķָ���
localparam  DELIMITER_SHAKE = 8'h1F;  // For SHAKE128/256
// SHA3-256/512�ķָ���
localparam  DELIMITER_SHA3  = 8'h06;  // For SHA3-256/512
// ���ʲ������ֽڵ�λ��
// SHAKE128��?�ʣ�1344ʹ
localparam  RATE_SHAKE128 = 168;  // 1344 bits
// SHAKE256��?�ʣ�1088ʹ
localparam  RATE_SHAKE256 = 136;  // 1088 bits  
// SHA3-256��?�ʣ�1088ʹ
localparam  RATE_SHA3_256 = 136;  // 1088 bits 
// SHA3-512��?�ʣ�576ʹ
localparam  RATE_SHA3_512 = 72;   // 576 bits
// SHA3-224��?�ʣ�
localparam  RATE_SHA3_224 = 144;  // 1152 bits (same as SHAKE256)
// SHA3-384��?�ʣ�
localparam  RATE_SHA3_384 = 104;   // 832 bits

// ״��Δ�
// ����״�W
localparam  S_IDLE      = 3'd0;
// ����״�W
localparam  S_ABSORB    = 3'd1;
// ��״��
localparam  S_FULL      = 3'd2;
// ׷��״�W
localparam  S_APPEND    = 3'd3;
// �c����״�W
localparam  S_LAST_FULL = 3'd4;
// ��ѹ״�W
localparam  S_SQUEEZE   = 3'd5;

// ״��Ĵ�������د״��Ĵ���
reg     [2:0]   state, nstate;
// �c��һ�����ݱ��
reg             last_data;
// ��һ��׷�ӱ��
reg             first_append;
// �c��һ�����ݵ��ֽڔ�
reg     [3:0]   last_din_byte;
// ģʽ�Ĵ��������ڴ洢��ǰģʽ
reg     [2:0]   mode_reg;  // Registered mode signal

// �ڲ��ź�����Ƴ��Ķ˅�
// ������������ź�
wire            din_ready_o;    // �ڲ�din_ready�ź�
// 64λ��������Ņ�
wire    [63:0]  dout_o;         // �ڲ�64λ����Ņ�
// �����Ч�ź�
wire            dout_valid_o;   // �ڲ������Ч�ź�


// �����������ؼ��Ĵ���
reg din_valid_d;  // �ӳٰ汾��din_valid_i

// ������din_valid�����źţ�ֻ�������ز��������ڸߵ�ƽ��
wire din_valid_pulse = din_valid_i && !din_valid_d && !sha3_hold;  // ����!sha3_hold��ȷ��holdʱ������





// ����������Ņ�
wire            buf_overflow;
// ���������������
wire    [63:0]  sampled_din;
// ��һ�β�������������
reg     [63:0]  last_sampled_din;
// ������ʹ���Ņ�
wire            buf_en;
// �ֽڼ�����
reg     [7:0]   byte_cnt;
// ��һ���ֽڼ������ķ�
wire    [7:0]   byte_cnt_next;
// ��ǰ���ʣ��ֽڵ�λ��
reg     [7:0]   rate_bytes;  // Current rate in bytes
// ��ǰ�ָ��J
wire    [7:0]   delimiter;   // Current delimiter

// ������������ñ��
reg             dout_buf_available;
// �c��һ������������ź�
wire            last_dout_buf;
// ���������������SHA3����ּƔ�
reg     [8:0]   output_cnt;  // Counter for SHA3 output words

// ���ݻ��������c��ߴ�ΪSHAKE128��168*8 - 1��
reg     [1343:0]  data_buf;   // Max size for SHAKE128 (168*8 - 1)

// Keccak����ź�
// Keccak�����ź�
wire                keccak_start;
// Keccak��ѹ�ź�
wire                keccak_squeeze;
// Keccak�����ź�
wire                keccak_ready;
// Keccak����״��Ĵ���
reg     [1599:0]    keccak_state_in;  // ��Ϊreg����
// Keccak���״�W
wire    [1599:0]    keccak_state_out;

// ģʽ��ز���ѡ���߼�
// ���ݵ�ǰģʽѡ�����ʲ���
always @(*) begin
  case(mode_reg)
    MODE_SHAKE128: rate_bytes = RATE_SHAKE128;  // SHAKE128����
    MODE_SHAKE256: rate_bytes = RATE_SHAKE256;  // SHAKE256����
    MODE_SHA3_256: rate_bytes = RATE_SHA3_256;  // SHA3-256����
    MODE_SHA3_512: rate_bytes = RATE_SHA3_512;  // SHA3-512����
    MODE_SHA3_224: rate_bytes = RATE_SHA3_224;  // SHA3-224����
    MODE_SHA3_384: rate_bytes = RATE_SHA3_384;  // SHA3-384����
    default:       rate_bytes = RATE_SHAKE256;  // Ĭ��ʹ��SHAKE256����
  endcase
end
// �ָ���?���߼�
// ����ģʽѡ��ָ��J
assign delimiter = (mode_reg == MODE_SHAKE128 || mode_reg == MODE_SHAKE256) ? 
                   DELIMITER_SHAKE : DELIMITER_SHA3;


// ģʽ�Ĵ�������?��
always @(posedge clk_i)
if(!rst_ni) begin
  mode_reg <= MODE_SHAKE256;  // ��λʱĬ������ΪSHAKE256ģʽ
end
else if(start_i) begin
  mode_reg <= mode_i;         // ʹ�������mode_i����ģʽ
end


always @(posedge clk_i) begin
    if (!rst_ni) begin
        din_valid_d <= 1'b0;
    end else begin
        din_valid_d <= din_valid_i;  // �ӳ�һ������
    end
end


// ���ݻ���������?��
always @(posedge clk_i)
if(!rst_ni)
  data_buf <= 'h0;  // ��λʱ������ݻ�����
else if(!sha3_hold) begin  // ֻ����hold�ź�Ϊ��ʱ���������
  if(keccak_squeeze) begin
    // ����ģʽ��״̬����ȡ���ʲ����������
    case(mode_reg)
      MODE_SHAKE128: data_buf <= keccak_state_out[1599:256];  // 1344ʹ
      MODE_SHAKE256: begin
        data_buf[1343:256] <= keccak_state_out[1599:512];  // 1088ʹ
        data_buf[255:0] <= 'h0;
      end
      MODE_SHA3_256: begin  
        data_buf[1343:256] <= keccak_state_out[1599:512];  // 1088ʹ
        data_buf[255:0] <= 'h0;
      end
      MODE_SHA3_512: begin
        data_buf[1343:768] <= keccak_state_out[1599:1024];  // 576ʹ
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
    data_buf <= {data_buf[1343-64:0], sampled_din};  // �������ݻ�����
end
  
// ������ʹ���ź�?��
// ʹ���ź������������롢׷�Ӻͼ�ѹ״�W
assign buf_en = din_ready_o & din_valid_pulse & (last_din_i? last_din_byte_i!=0 : 1'b1) | 
                state==S_APPEND | 
                (dout_valid_o & dout_ready_i & state==S_SQUEEZE);

// ��������ѡ���߼�
// ����״�����������ѡ���������
assign sampled_din = (din_ready_o & din_valid_i & last_din_i)? last_sampled_din :
                     state==S_APPEND? ((first_append & last_din_byte[2:0]==3'b000)? 
                                      {delimiter, 56'd0} : 64'd0) :
                     state==S_SQUEEZE? 64'd0 : din_i;

// �c��һ���������ݵ������߼�
always @(*)
begin
  case(last_din_byte_i)
    1: last_sampled_din = {din_i[63-:1*8], delimiter, {6*8{1'b0}}};  // 1�ֽ�����+�ָ��J
    2: last_sampled_din = {din_i[63-:2*8], delimiter, {5*8{1'b0}}};  // 2�ֽ�����+�ָ��J
    3: last_sampled_din = {din_i[63-:3*8], delimiter, {4*8{1'b0}}};  // 3�ֽ�����+�ָ��J
    4: last_sampled_din = {din_i[63-:4*8], delimiter, {3*8{1'b0}}};  // 4�ֽ�����+�ָ��J
    5: last_sampled_din = {din_i[63-:5*8], delimiter, {2*8{1'b0}}};  // 5�ֽ�����+�ָ��J
    6: last_sampled_din = {din_i[63-:6*8], delimiter, {1*8{1'b0}}};  // 6�ֽ�����+�ָ��J
    7: last_sampled_din = {din_i[63-:7*8], delimiter};              // 7�ֽ�����+�ָ��J
    default: last_sampled_din = din_i;                              // Ĭ��ֱ��ʹ����������
  endcase
end


// �ֽڼ���������?��
always @(posedge clk_i)
if(!rst_ni)
  byte_cnt <= 0;  // ��λʱ�����ֽڼ�����
else if(start_i | buf_overflow)
  byte_cnt <= 0;  // �����򻺳������ʱ���
else if(buf_en & !sha3_hold)  // ֻ����hold�ź�Ϊ��ʱ���������
  byte_cnt <= byte_cnt_next;  // �����ֽڼ�����

// ��һ���ֽڼ������ď�?��
// �ڷǼ�ѹ״���£�����ǖc��һ���������ֽ���Ϊ0���򱣳ֵ�ǰ����
assign byte_cnt_next = (state!=S_SQUEEZE & din_valid_i & last_din_i & 
                       last_din_byte_i==0)? byte_cnt : byte_cnt + 8;
// ����������Ņ�
assign buf_overflow  = buf_en & byte_cnt_next==rate_bytes;


// ������������ñ�־����?��
always @(posedge clk_i)
if(!rst_ni)
  dout_buf_available <= 0;  // ��λʱ������������ɮm
else if(start_i)
  dout_buf_available <= 0;  // ����ʱ������������ɮm
else if(!sha3_hold) begin  // ֻ����hold�ź�Ϊ��ʱ���������
  if(keccak_squeeze)
    dout_buf_available <= 1;  // ��ѹʱ�������������
  else if(last_dout_buf & dout_ready_i)
    dout_buf_available <= 0;  // �c��һ��������������������ʱ���ɮm
end

// ���ڗ���dout_valid_o�����صļĴ懒 - �޸�sha3_hold�����߼�
reg dout_valid_o_reg;
always @(posedge clk_i)
if(!rst_ni)
  dout_valid_o_reg <= 0;  // ��λʱ���
else
  dout_valid_o_reg <= dout_valid_o;  // ʼ�ո���dout_valid_o������sha3_holdӰ��

// �c��һ������������ź�
assign last_dout_buf = buf_overflow;


// ״��������߼�
always @(posedge clk_i)
if(!rst_ni)
  state <= S_IDLE;  // ��λʱ�������״��
else if(start_i)
  state <= S_ABSORB;  // ����ʱ��������״��
else if(!sha3_hold)  // ֻ����hold�ź�Ϊ��ʱ������״��ת��
  state <= nstate;  // ����״�W

// ״���ת���߼�
always @(*)
begin
  nstate = state;  // Ĭ�ϱ��ֵ�ǰ״�W
  if(!sha3_hold) begin  // ֻ����hold�ź�Ϊ��ʱ�Ž���״��ת��?��
    case(state)
      S_IDLE      : if(start_i)  // ����״�᣺��������ź���Ч����������״��
                      nstate = S_ABSORB;
      S_ABSORB    : if(din_valid_i & last_din_i & last_din_byte_i!=8 & 
                       byte_cnt==(rate_bytes-8))  // ����״�᣺����c��һ���������ֽڼ����ӽ����ʣ����������״�W
                      nstate = S_LAST_FULL;
                    else if(buf_overflow)  // ��������������������״��
                      nstate = S_FULL;
                    else if(din_valid_i & last_din_i)  // ��������һ�����ݣ�����׷��״�W
                      nstate = S_APPEND;
      S_FULL      : if(keccak_ready)  // ��״̬�����Keccak����������׷�ӻ�����״�W
                      nstate = (last_data | last_din_i & din_valid_i)? S_APPEND : S_ABSORB;
      S_APPEND    : if(buf_overflow)  // ׷��״�᣺������������������c����״�W
                      nstate = S_LAST_FULL;
      S_LAST_FULL : if(keccak_ready)  // �c����״�᣺���Keccak���������뼷ѹ״��
                      nstate = S_SQUEEZE;
      S_SQUEEZE   : if(start_i)  // ��ѹ״�᣺��������ź���Ч����������״��
                      nstate = S_ABSORB;
      default     : nstate = S_IDLE;  // Ĭ��״�᣺�������״�W
    endcase
  end
end

// �c��һ�������Ņ� - ���sha3_hold����
always @(posedge clk_i)
if(!rst_ni) begin
  last_data     <= 0;  // ��λʱ�������һ�����ݱ��
  first_append  <= 0;  // ��λʱ�����د��׷�ӱ��
  last_din_byte <= 0;  // ��λʱ�������һ�������ֽ���
end
else if(start_i) begin
  last_data     <= 0;  // ����ʱ�������һ�����ݱ��
  first_append  <= 0;  // ����ʱ�����د��׷�ӱ��
  last_din_byte <= 0;  // ����ʱ�������һ�������ֽ���
end
else if(!sha3_hold) begin  
  if(last_din_i & din_ready_o) begin  // ����c��һ�����������������������ر��
    last_data     <= 1;
    first_append  <= 1;
    last_din_byte <= last_din_byte_i;
  end
  else if (first_append & state==S_APPEND)  // �����һ��׷������׷��״̬�������һ��׷�ӱ��
    first_append <= 0;
end

// ������������ź�
// ������״̬����״̬��Keccak�����ҷǖc��һ������ʱ��Ч
assign din_ready_o = state==S_ABSORB | state==S_FULL & keccak_ready & ~last_data;


// Keccak�����ź�
// Keccak�����źţ�����״̬��c����״����Keccak��������hold�ź�ʱ�Д�
assign keccak_start = (state==S_FULL | state==S_LAST_FULL) & keccak_ready & !sha3_hold;
// Keccak��ѹ�źţ��ڼ�ѹ״����Keccak��������������������û�c��һ������������������������hold�ź�ʱ�Д�
assign keccak_squeeze = state==S_SQUEEZE & keccak_ready & 
                       (~dout_buf_available | last_dout_buf & dout_ready_i) & !sha3_hold;

// ����ģʽ����Keccak״�����
// SHAKE128״�������Ņ�
wire [1599:0] keccak_state_in_shake128;
// SHAKE256״�������Ņ�
wire [1599:0] keccak_state_in_shake256;
// SHA3-256״�������Ņ�
wire [1599:0] keccak_state_in_sha3_256;
// SHA3-512״�������Ņ�
wire [1599:0] keccak_state_in_sha3_512;
// SHA3-224״�������Ņ�
wire [1599:0] keccak_state_in_sha3_224;
// SHA3-384״�������Ņ�
wire [1599:0] keccak_state_in_sha3_384;

// SHAKE128��?��=1344�����Y=256
// ״������Ϊ���״�������ݻ������������
assign keccak_state_in_shake128 = {keccak_state_out[1599:256] ^ 
                                   {data_buf[1343:8],
                                    data_buf[7]^(state==S_LAST_FULL),
                                    data_buf[6:0]},
                                   keccak_state_out[255:0]};

// SHAKE256��SHA3-256��?��=1088�����Y=512
// ״������Ϊ���״�������ݻ������������
assign keccak_state_in_shake256 = {keccak_state_out[1599-:1088] ^ 
                                   {data_buf[1087:8],
                                    data_buf[7]^(state==S_LAST_FULL),
                                    data_buf[6:0]},
                                   keccak_state_out[511:0]};

// SHA3-256��SHAKE256ʹ����ͬ��?�ʺ����Y
assign keccak_state_in_sha3_256 = keccak_state_in_shake256;  // Same rate/capacity

// SHA3-512��?��=576�����Y=1024
// ״������Ϊ���״�������ݻ������������
assign keccak_state_in_sha3_512 = {keccak_state_out[1599-:576] ^ 
                                   {data_buf[575:8],
                                    data_buf[7]^(state==S_LAST_FULL),
                                    data_buf[6:0]},
                                   keccak_state_out[1023:0]};

// SHA3-224��?��=1152�����Y=448
// ״������Ϊ���״�������ݻ������������
assign keccak_state_in_sha3_224 = {keccak_state_out[1599-:1152] ^ 
                                   {data_buf[1151:8],
                                    data_buf[7]^(state==S_LAST_FULL),
                                    data_buf[6:0]},
                                   keccak_state_out[447:0]};

// SHA3-384��?��=832�����Y=768
// ״������Ϊ���״�������ݻ������������
assign keccak_state_in_sha3_384 = {keccak_state_out[1599-:832] ^ 
                                   {data_buf[831:8],
                                    data_buf[7]^(state==S_LAST_FULL),
                                    data_buf[6:0]},
                                   keccak_state_out[767:0]};
// ѡ���?��״�����
always @(*) begin
  case(mode_reg)
    MODE_SHAKE128: keccak_state_in = keccak_state_in_shake128;  // SHAKE128״�����
    MODE_SHAKE256: keccak_state_in = keccak_state_in_shake256;  // SHAKE256״�����
    MODE_SHA3_256: keccak_state_in = keccak_state_in_sha3_256;  // SHA3-256״�����
    MODE_SHA3_512: keccak_state_in = keccak_state_in_sha3_512;  // SHA3-512״�����
    MODE_SHA3_224: keccak_state_in = keccak_state_in_sha3_224;  // SHA3-224״�����
    MODE_SHA3_384: keccak_state_in = keccak_state_in_sha3_384;  // SHA3-384״�����
    default:       keccak_state_in = keccak_state_in_shake256;  // Ĭ��ʹ��SHAKE256״�����
  endcase
end

////////////////////////////////////////////////////////////////////////////////
// ԭ����������ֲ��䣩
// �������Ϊ���ݻ������ĸ�64ʹ
assign dout_o = data_buf[1343:1280];
// �����Ч�ź�Ϊ������������ñ�־
assign dout_valid_o = dout_buf_available;

////////////////////////////////////////////////////////////////////////////////
// ��������Rλ���� - �޸�hold�ڼ�����?��
// ����dout_valid_o�������أ�����һ��ʱ�����ڵ�����
wire dout_valid_rising_edge;
assign dout_valid_rising_edge = dout_valid_o & ~dout_valid_o_reg;

// ����Rλ���� - ֻ�Ј]!sha3_holdʱ�������������
// ֻ��������������hold�ź�ʱ������ݻ���������
assign dout_full_o = (dout_valid_rising_edge & !sha3_hold) ? data_buf : 1344'h0;
// ���������Ч�ź�
assign dout_full_valid_o = dout_valid_rising_edge & !sha3_hold;

// Keccakģ��ʵ����
keccak_top keccak_top (
    .Clock    (clk_i            ),  // ʱ���ź�����
    .Reset    (~rst_ni | start_i),  // ��λ�źţ�����Ч����λ������ʱ��Ч��
    .Start    (keccak_start     ),  // �����ź�
    .Din      (keccak_state_in  ),  // ����״������
    .Req_more (keccak_squeeze   ),  // ������������ź�
    .Hold     (sha3_hold        ),  // ��ͣ�ź�
    .Ready    (keccak_ready     ),  // �����ź����
    .Dout     (keccak_state_out )   // ���״������
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