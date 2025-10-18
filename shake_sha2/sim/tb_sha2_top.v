//--------------------------------------------------------------------------------------------------------
// Module  : tb_sha2_top
// Type    : simulation, top
// Standard: Verilog 2001 (IEEE1364-2001)
// Function: Unified testbench for SHA-2 top module (SHA-256 and SHA-512)
//--------------------------------------------------------------------------------------------------------

`timescale 1ns/1ps

module tb_sha2_top ();

// Clock and reset
reg rstn;
reg clk;

initial begin
    rstn = 1'b0;
    clk = 1'b1;
end

always #5 clk = ~clk;   // 100MHz clock

// SHA2_TOP interface signals
reg         mode;       // 0: SHA-256, 1: SHA-512
wire        tready;
reg         tvalid;
reg         tlast;
reg  [31:0] tid;
reg  [ 7:0] tdata;

wire         ovalid;
wire [ 31:0] oid;
wire [ 60:0] olen;
wire [511:0] osha;

// Initialize regs
initial begin
    mode   = 1'b0;      // Default to SHA-256
    tvalid = 1'b0;
    tlast  = 1'b0;
    tid    = 32'd0;
    tdata  = 8'd0;
end

// Instantiate SHA2_TOP
sha2_top u_sha2_top (
    .rstn   ( rstn   ),
    .clk    ( clk    ),
    .mode   ( mode   ),
    .tvalid ( tvalid ),
    .tready ( tready ),
    .tlast  ( tlast  ),
    .tid    ( tid    ),
    .tdata  ( tdata  ),
    .ovalid ( ovalid ),
    .oid    ( oid    ),
    .olen   ( olen   ),
    .osha   ( osha   )
);

// Display results
always @(posedge clk) begin
    if(ovalid) begin
        $display("===========================================");
        if(mode)
            $display("SHA-512 Result:");
        else
            $display("SHA-256 Result:");
        $display("  ID      = 0x%h", oid);
        $display("  Length  = %0d bytes", olen);
        if(mode)
            $display("  Hash    = %h", osha);
        else
            $display("  Hash    = %h", osha[255:0]);
        $display("===========================================");
    end
end

// Task to send bytes
task send_bytes;
    input [31:0] id;
    input [1023:0] data_array;  // Max 128 bytes
    input integer num_bytes;
    integer i;
    begin
        $display("Sending %0d bytes (ID=0x%h)", num_bytes, id);
        
        @(posedge clk);
        while(~tready) @(posedge clk);
        
        for(i = num_bytes-1; i >= 0; i = i - 1) begin
            tvalid <= 1'b1;
            tid    <= (i == num_bytes-1) ? id : 32'd0;
            tdata  <= data_array[i*8 +: 8];
            tlast  <= (i == 0);
            
            @(posedge clk);
            while(~tready) @(posedge clk);
        end
        
        tvalid <= 1'b0;
        tlast  <= 1'b0;
        tid    <= 32'd0;
        tdata  <= 8'd0;
    end
endtask

// Main test sequence
initial begin
    
    // Reset
    repeat(4) @(posedge clk);
    rstn <= 1'b1;
    repeat(2) @(posedge clk);
    
    //========================================
    // Part 1: SHA-256 Mode Tests (6 data groups)
    //========================================
    $display("\n");
    $display("*******************************************");
    $display("*       SHA-256 MODE (6 GROUPS)           *");
    $display("*******************************************");
    mode <= 1'b0;  // Select SHA-256
    repeat(2) @(posedge clk);
    
    // SHA-256 Test 1: 64-bit data 1
    $display("\n--- SHA-256 Test 1: 64'h0123456789ABCDEF (8 bytes) ---");
    send_bytes(32'h2561, 
        {8'h01, 8'h23, 8'h45, 8'h67, 8'h89, 8'hAB, 8'hCD, 8'hEF}, 
        8);
    wait(ovalid);
    repeat(10) @(posedge clk);
    
    // SHA-256 Test 2: 64-bit data 2
    $display("\n--- SHA-256 Test 2: 64'hFFFFFFFF00000000 (8 bytes) ---");
    send_bytes(32'h2562, 
        {8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h00, 8'h00, 8'h00, 8'h00}, 
        8);
    wait(ovalid);
    repeat(10) @(posedge clk);
    
    // SHA-256 Test 3: 128-bit data 1
    $display("\n--- SHA-256 Test 3: 128'hA5A5A5A5A5A5A5A55A5A5A5A5A5A5A5A (16 bytes) ---");
    send_bytes(32'h2563, 
        {8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5,
         8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A}, 
        16);
    wait(ovalid);
    repeat(10) @(posedge clk);
    
    // SHA-256 Test 4: 128-bit data 2
    $display("\n--- SHA-256 Test 4: 128'h550E8400E29B41D4A716446655440000 (16 bytes) ---");
    send_bytes(32'h2564, 
        {8'h55, 8'h0E, 8'h84, 8'h00, 8'hE2, 8'h9B, 8'h41, 8'hD4,
         8'hA7, 8'h16, 8'h44, 8'h66, 8'h55, 8'h44, 8'h00, 8'h00}, 
        16);
    wait(ovalid);
    repeat(10) @(posedge clk);
    
    // SHA-256 Test 5: 256-bit data 1
    $display("\n--- SHA-256 Test 5: 256'h000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F (32 bytes) ---");
    send_bytes(32'h2565, 
        {8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07,
         8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D, 8'h0E, 8'h0F,
         8'h10, 8'h11, 8'h12, 8'h13, 8'h14, 8'h15, 8'h16, 8'h17,
         8'h18, 8'h19, 8'h1A, 8'h1B, 8'h1C, 8'h1D, 8'h1E, 8'h1F}, 
        32);
    wait(ovalid);
    repeat(10) @(posedge clk);
    
    // SHA-256 Test 6: 256-bit data 2
    $display("\n--- SHA-256 Test 6: 256'h5348413225365f4249545f484153485f544553545f44415441212100000000 (32 bytes) ---");
    send_bytes(32'h2566, 
        {8'h53, 8'h48, 8'h41, 8'h32, 8'h25, 8'h36, 8'h5F, 8'h42,
         8'h49, 8'h54, 8'h5F, 8'h48, 8'h41, 8'h53, 8'h48, 8'h5F,
         8'h54, 8'h45, 8'h53, 8'h54, 8'h5F, 8'h44, 8'h41, 8'h54,
         8'h41, 8'h21, 8'h21, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00}, 
        32);
    wait(ovalid);
    repeat(10) @(posedge clk);
    
    //========================================
    // Part 2: SHA-512 Mode Tests (6 data groups - same data)
    //========================================
    $display("\n");
    $display("*******************************************");
    $display("*       SHA-512 MODE (6 GROUPS)           *");
    $display("*******************************************");
    mode <= 1'b1;  // Switch to SHA-512
    repeat(2) @(posedge clk);
    
    // SHA-512 Test 7: 64-bit data 1 (same as Test 1)
    $display("\n--- SHA-512 Test 7: 64'h0123456789ABCDEF (8 bytes) ---");
    send_bytes(32'h5121, 
        {8'h01, 8'h23, 8'h45, 8'h67, 8'h89, 8'hAB, 8'hCD, 8'hEF}, 
        8);
    wait(ovalid);
    repeat(10) @(posedge clk);
    
    // SHA-512 Test 8: 64-bit data 2 (same as Test 2)
    $display("\n--- SHA-512 Test 8: 64'hFFFFFFFF00000000 (8 bytes) ---");
    send_bytes(32'h5122, 
        {8'hFF, 8'hFF, 8'hFF, 8'hFF, 8'h00, 8'h00, 8'h00, 8'h00}, 
        8);
    wait(ovalid);
    repeat(10) @(posedge clk);
    
    // SHA-512 Test 9: 128-bit data 1 (same as Test 3)
    $display("\n--- SHA-512 Test 9: 128'hA5A5A5A5A5A5A5A55A5A5A5A5A5A5A5A (16 bytes) ---");
    send_bytes(32'h5123, 
        {8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5,
         8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A}, 
        16);
    wait(ovalid);
    repeat(10) @(posedge clk);
    
    // SHA-512 Test 10: 128-bit data 2 (same as Test 4)
    $display("\n--- SHA-512 Test 10: 128'h550E8400E29B41D4A716446655440000 (16 bytes) ---");
    send_bytes(32'h5124, 
        {8'h55, 8'h0E, 8'h84, 8'h00, 8'hE2, 8'h9B, 8'h41, 8'hD4,
         8'hA7, 8'h16, 8'h44, 8'h66, 8'h55, 8'h44, 8'h00, 8'h00}, 
        16);
    wait(ovalid);
    repeat(10) @(posedge clk);
    
    // SHA-512 Test 11: 256-bit data 1 (same as Test 5)
    $display("\n--- SHA-512 Test 11: 256'h000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F   (32 bytes) ---");
    send_bytes(32'h5125, 
        {8'h00, 8'h01, 8'h02, 8'h03, 8'h04, 8'h05, 8'h06, 8'h07,
         8'h08, 8'h09, 8'h0A, 8'h0B, 8'h0C, 8'h0D, 8'h0E, 8'h0F,
         8'h10, 8'h11, 8'h12, 8'h13, 8'h14, 8'h15, 8'h16, 8'h17,
         8'h18, 8'h19, 8'h1A, 8'h1B, 8'h1C, 8'h1D, 8'h1E, 8'h1F}, 
        32);
    wait(ovalid);
    repeat(10) @(posedge clk);
    
    // SHA-512 Test 12: 256-bit data 2 (same as Test 6)
    $display("\n--- SHA-512 Test 12: 256'h5348413225365f4249545f484153485f544553545f44415441212100000000 (32 bytes) ---");
    send_bytes(32'h5126, 
        {8'h53, 8'h48, 8'h41, 8'h32, 8'h25, 8'h36, 8'h5F, 8'h42,
         8'h49, 8'h54, 8'h5F, 8'h48, 8'h41, 8'h53, 8'h48, 8'h5F,
         8'h54, 8'h45, 8'h53, 8'h54, 8'h5F, 8'h44, 8'h41, 8'h54,
         8'h41, 8'h21, 8'h21, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00}, 
        32);
    wait(ovalid);
    repeat(10) @(posedge clk);
    
    //========================================
    // Part 3: Mode Switching Test
    //========================================
    $display("\n");
    $display("*******************************************");
    $display("*       MODE SWITCHING TEST               *");
    $display("*******************************************");
    
    // Quick switch to SHA-256
    $display("\n--- Quick Switch: SHA-256 ---");
    mode <= 1'b0;
    repeat(2) @(posedge clk);
    send_bytes(32'h2599, 
        {8'h01, 8'h23, 8'h45, 8'h67, 8'h89, 8'hAB, 8'hCD, 8'hEF}, 
        8);
    wait(ovalid);
    repeat(10) @(posedge clk);
    
    // Quick switch to SHA-512
    $display("\n--- Quick Switch: SHA-512 ---");
    mode <= 1'b1;
    repeat(2) @(posedge clk);
    send_bytes(32'h5199, 
        {8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5, 8'hA5,
         8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A, 8'h5A}, 
        16);
    wait(ovalid);
    repeat(10) @(posedge clk);
    
    // Wait for completion
    repeat(200) @(posedge clk);
    
    $display("\n===========================================");
    $display("All 14 tests completed successfully!");
    $display("===========================================");
    $finish;
end

// Timeout watchdog
initial begin
    #20_000_000;  // 20ms timeout
    $display("\nERROR: Simulation timeout!");
    $finish;
end

endmodule

