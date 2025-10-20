//--------------------------------------------------------------------------------------------------------
// Module  : sha2_shake_top
// Type    : synthesizable, IP's top
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: Integrated SHA2 (SHA-256/512) and SHAKE/SHA3 hash calculator
//           Mode selection via 'algo_mode' signal (4-bit)
//           algo_mode[3]: Algorithm selector (0=SHA2, 1=SHAKE/SHA3)
//           algo_mode[2:0]: Mode selector
//             SHA2 modes: [0]=SHA-256, [1]=SHA-512  
//             SHAKE modes: 000=SHAKE128, 001=SHAKE256, 010=SHA3-256,
//                         011=SHA3-512, 100=SHA3-224, 101=SHA3-384
//--------------------------------------------------------------------------------------------------------

module shake_sha2_top #(
    parameter ALGO_WIDTH = 4    // 0-2: Mode selection (SHA2: 0-1, SHAKE: 0-5)
                                 // 3: Algorithm selector (0=SHA2, 1=SHAKE)
)(
    // Clock and reset
    input  wire              clk,
    input  wire              rstn,
    
    // Algorithm mode selection
    input  wire  [3:0]       algo_mode,    // {algo_type, mode_bits}
                                           // algo_type: 0=SHA2, 1=SHAKE
                                           // mode_bits[2:0]: Specific mode
                                           // SHA2: mode_bits[0] (0=SHA256, 1=SHA512)
                                           // SHAKE: mode_bits[2:0] (000=SHAKE128, 001=SHAKE256, etc.)
    
    // SHA2 Input Interface (AXI-Stream compatible)
    input  wire              sha2_tvalid,
    output wire              sha2_tready,
    input  wire              sha2_tlast,
    input  wire  [31:0]      sha2_tid,
    input  wire  [7:0]       sha2_tdata,
    
    // SHA2 Output Interface (includes transaction metadata)
    output wire              sha2_ovalid,
    output wire  [31:0]      sha2_oid,      // Transaction ID
    output wire  [60:0]      sha2_olen,     // Data length
    
    // SHAKE Input Interface
    input  wire              shake_start_i,
    input  wire  [63:0]      shake_din_i,
    input  wire              shake_din_valid_i,
    input  wire              shake_last_din_i,
    input  wire  [3:0]       shake_last_din_byte_i,
    input  wire              shake_dout_ready_i,
    input  wire              shake_hold,
    
    // Shared Hash Output Interface (no metadata - pure hash data only)
    output wire  [1343:0]    dout,         // Hash output: SHA2 padded to 1344-bit, SHAKE full width
    output wire              dout_valid    // Hash output valid signal
);

//--------------------------------------------------------------------------------------------------------
// Algorithm Mode Decoding
//--------------------------------------------------------------------------------------------------------
wire algo_is_shake  = algo_mode[3];
wire algo_is_sha512 = algo_mode[0];

// For SHAKE mode, extract the specific variant (only lower 3 bits)
wire [2:0] shake_variant = algo_mode[2:0];

//--------------------------------------------------------------------------------------------------------
// SHA2 Module Instance
//--------------------------------------------------------------------------------------------------------
wire        sha2_ovalid_int;
wire [31:0] sha2_oid_int;
wire [60:0] sha2_olen_int;
wire [511:0] sha2_osha;

sha2_top u_sha2_top (
    .rstn        ( rstn           ),
    .clk         ( clk            ),
    .mode        ( algo_is_sha512 ),  // 0: SHA-256, 1: SHA-512
    .tvalid      ( sha2_tvalid    ),
    .tready      ( sha2_tready    ),
    .tlast       ( sha2_tlast     ),
    .tid         ( sha2_tid       ),
    .tdata       ( sha2_tdata     ),
    .ovalid      ( sha2_ovalid_int),
    .oid         ( sha2_oid_int   ),
    .olen        ( sha2_olen_int  ),
    .osha        ( sha2_osha      )
);

//--------------------------------------------------------------------------------------------------------
// SHAKE Module Instance
//--------------------------------------------------------------------------------------------------------
wire        shake_ovalid_int;
wire [1343:0] shake_odata;

shake_top u_shake_top (
    .clk_i              ( clk                ),
    .rst_ni             ( rstn               ),
    .mode_i             ( shake_variant      ),
    .start_i            ( shake_start_i      ),
    .din_i              ( shake_din_i        ),
    .din_valid_i        ( shake_din_valid_i  ),
    .last_din_i         ( shake_last_din_i   ),
    .last_din_byte_i    ( shake_last_din_byte_i ),
    .dout_ready_i       ( shake_dout_ready_i ),
    .sha3_hold          ( shake_hold         ),
    .dout_full_o        ( shake_odata        ),
    .dout_full_valid_o  ( shake_ovalid_int   )
);

//--------------------------------------------------------------------------------------------------------
// Hash Output Multiplexing - Select between SHA2 and SHAKE hash outputs
//--------------------------------------------------------------------------------------------------------

// Output data selection and padding
wire [1343:0] sha2_osha_padded = {sha2_osha,832'h0};  // Pad SHA-512 (512-bit) to 1344-bit

assign dout = algo_is_shake ? shake_odata : sha2_osha_padded;

// Output valid signal selection
assign dout_valid = algo_is_shake ? shake_ovalid_int : sha2_ovalid_int;

// SHA2 dedicated outputs (transaction metadata - only valid for SHA2 mode)
assign sha2_ovalid = ~algo_is_shake & sha2_ovalid_int;
assign sha2_oid    = sha2_oid_int;     // Transaction ID
assign sha2_olen     = sha2_olen_int;    // Data length

// Note: SHAKE mode does not provide transaction metadata

//ila_0  u_ila (
//	.clk(clk), // input wire clk
//	.probe0(
//	{
//	 algo_mode,
//	 sha2_tvalid,
//	 sha2_tready,
//	 sha2_tlast,   
//	 sha2_tdata, 
//	 sha2_ovalid,  
//	 shake_start_i,        
//	 shake_din_i,          
//	 shake_din_valid_i,    
//	 shake_last_din_i,     
//	 shake_last_din_byte_i,
//	 shake_dout_ready_i,   
//	 shake_hold, 
//	 dout,     
//	 dout_valid,
// shake_ovalid_int,
// sha2_ovalid        
	 
//	}) // input wire [1799:0] probe0
//);



endmodule