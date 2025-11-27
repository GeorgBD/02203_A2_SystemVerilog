module shift_register #(
    parameter TOTAL_BYTES = 16,
    parameter SHIFT_BYTES = 4,
    parameter READ_BYTES = 6
) (
    input  logic clk,
    input  logic reset,          // Active-HIGH reset
    input  logic shift_en,       // Shift and write enable
    input  logic [SHIFT_BYTES*8-1:0] data_in,  // SHIFT_BYTES in
    output logic [READ_BYTES*8-1:0] data_out   // READ_BYTES out 
);
    
    // Internal shift register - 7 bytes = 56 bits
    logic [TOTAL_BYTES*8-1:0] shift_reg;
    
    // Output is the top 4 bytes - asynchronous read
    assign data_out = shift_reg[TOTAL_BYTES*8-1 : (TOTAL_BYTES-READ_BYTES)*8];
    
    // Input is bottom 4 bytes - synchronous write / shift. 
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_reg <= '0;  // Clear register
        end else if (shift_en) begin
            // New data comes in at bottom, old data shifts towards top
            shift_reg <= {shift_reg[(TOTAL_BYTES-SHIFT_BYTES)*8-1 : 0], data_in};
        end
    end
    
endmodule