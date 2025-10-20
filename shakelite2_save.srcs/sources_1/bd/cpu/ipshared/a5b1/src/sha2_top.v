//--------------------------------------------------------------------------------------------------------
// Module  : sha2_top
// Type    : synthesizable, IP's top
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: Top-level wrapper for SHA-2 family (SHA-256 and SHA-512)
//           Supports mode selection via 'mode' signal
//           mode = 1'b0: SHA-256 (256-bit output)
//           mode = 1'b1: SHA-512 (512-bit output)
//--------------------------------------------------------------------------------------------------------

module sha2_top #(
    parameter MODE_WIDTH = 1  // 0=SHA-256, 1=SHA-512
)(
    input  wire        rstn,
    input  wire        clk,
    // Mode selection
    input  wire        mode,      // 0: SHA-256, 1: SHA-512
    // AXI-Stream Input Interface
    input  wire        tvalid,
    output wire        tready,
    input  wire        tlast,
    input  wire [31:0] tid,
    input  wire [ 7:0] tdata,
    // Output Interface
    output wire        ovalid,
    output wire [31:0] oid,
    output wire [60:0] olen,
    output wire [511:0] osha      // Full 512-bit output (for SHA-512)
);

//--------------------------------------------------------------------------------------------------------
// SHA-256 Instance Signals
//--------------------------------------------------------------------------------------------------------
wire        sha256_tready;
wire        sha256_ovalid;
wire [31:0] sha256_oid;
wire [60:0] sha256_olen;
wire [255:0] sha256_osha;

//--------------------------------------------------------------------------------------------------------
// SHA-512 Instance Signals
//--------------------------------------------------------------------------------------------------------
wire        sha512_tready;
wire        sha512_ovalid;
wire [31:0] sha512_oid;
wire [60:0] sha512_olen;
wire [511:0] sha512_osha;

//--------------------------------------------------------------------------------------------------------
// Mode Register (optional: can make it synchronous)
//--------------------------------------------------------------------------------------------------------
reg mode_reg;
always @(posedge clk or negedge rstn) begin
    if (!rstn)
        mode_reg <= 1'b0;  // Default to SHA-256
    else
        mode_reg <= mode;
end

//--------------------------------------------------------------------------------------------------------
// Input Demultiplexing
// Route input to selected SHA module
//--------------------------------------------------------------------------------------------------------
wire sha256_tvalid = tvalid && !mode_reg;
wire sha512_tvalid = tvalid && mode_reg;

//--------------------------------------------------------------------------------------------------------
// SHA-256 Instance
//--------------------------------------------------------------------------------------------------------
sha256 u_sha256 (
    .rstn   ( rstn           ),
    .clk    ( clk            ),
    .tvalid ( sha256_tvalid  ),
    .tready ( sha256_tready  ),
    .tlast  ( tlast          ),
    .tid    ( tid            ),
    .tdata  ( tdata          ),
    .ovalid ( sha256_ovalid  ),
    .oid    ( sha256_oid     ),
    .olen   ( sha256_olen    ),
    .osha   ( sha256_osha    )
);

//--------------------------------------------------------------------------------------------------------
// SHA-512 Instance
//--------------------------------------------------------------------------------------------------------
sha512 u_sha512 (
    .rstn   ( rstn           ),
    .clk    ( clk            ),
    .tvalid ( sha512_tvalid  ),
    .tready ( sha512_tready  ),
    .tlast  ( tlast          ),
    .tid    ( tid            ),
    .tdata  ( tdata          ),
    .ovalid ( sha512_ovalid  ),
    .oid    ( sha512_oid     ),
    .olen   ( sha512_olen    ),
    .osha   ( sha512_osha    )
);

//--------------------------------------------------------------------------------------------------------
// Output Multiplexing
// Select output based on mode
//--------------------------------------------------------------------------------------------------------
assign tready = mode_reg ? sha512_tready : sha256_tready;
assign ovalid = mode_reg ? sha512_ovalid : sha256_ovalid;
assign oid    = mode_reg ? sha512_oid    : sha256_oid;
assign olen   = mode_reg ? sha512_olen   : sha256_olen;

// SHA output: extend SHA-256 to 512 bits (SHA-256 in high bits, pad low bits with zeros)
assign osha   = mode_reg ? sha512_osha : {sha256_osha, 256'h0};

endmodule

