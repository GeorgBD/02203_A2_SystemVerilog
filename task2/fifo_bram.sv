// BRAM inference version
module fifo #(
    parameter PW = 8,
    parameter PPT = 4,
    parameter FIFO_DEPTH = 88
)(
    input  logic                clk,
    input  logic                reset,
    input  logic                wr_en,
    input  logic                rd_en,
    input  logic [PPT*PW-1:0]   wr_data,
    output logic [PPT*PW-1:0]   rd_data,
    output logic                full,
    output logic                empty,
    output logic [$clog2(FIFO_DEPTH+1)-1:0] count,
    output logic                rd_valid
);
    import task2_pkg::*;

    logic [DATA_WIDTH-1:0] mem [0:FIFO_DEPTH-1];
    logic [ADDR_WIDTH_FIFO-1:0] wr_ptr, rd_ptr;
    logic [$clog2(FIFO_DEPTH+1)-1:0] fifo_count;
    
    assign empty = (fifo_count == 0);
    assign full  = (fifo_count == FIFO_DEPTH);
    assign count = fifo_count;
    
    // Write logic
    always_ff @(posedge clk) begin
        if (wr_en && !full) begin
            mem[wr_ptr] <= wr_data;
        end
    end
    
    // Read logic
    always_ff @(posedge clk) begin
        if (rd_en && !empty) begin
            rd_data <= mem[rd_ptr];
        end
    end
    
    // Pointer and control logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            fifo_count <= '0;
            rd_valid <= '0;
        end else begin
            // Write pointer
            if (wr_en && !full) begin
                wr_ptr <= (wr_ptr == FIFO_DEPTH - 1) ? '0 : wr_ptr + 1;
            end
            
            // Read pointer
            if (rd_en && !empty) begin
                rd_ptr <= (rd_ptr == FIFO_DEPTH - 1) ? '0 : rd_ptr + 1;
                rd_valid <= 1;
            end else begin
                rd_valid <= 0;
            end
            
            // Count logic
            case ({wr_en && !full, rd_en && !empty})
                2'b10: fifo_count <= fifo_count + 1;
                2'b01: fifo_count <= fifo_count - 1;
                default: fifo_count <= fifo_count;
            endcase
        end
    end
endmodule