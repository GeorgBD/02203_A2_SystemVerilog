`timescale 1ns / 1ps

// Standard FIFO which utilizes a write pointer and a read pointer. 
// Both pointers are cyclical.
// Hence we should be able to "just" use it as a large shift register
// Without the overhead of actually shifting the data each cycle. 

module fifo #(
	parameter PW = 8,                  // Pixel width (in bits)
	parameter PPT = 4,                 // Pixels per transfer
	parameter FIFO_DEPTH = 88         // 88 words pr line
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

	always_ff @(posedge clk or posedge reset) begin
		if (reset) begin
			wr_ptr <= '0;
			rd_ptr <= '0;
			fifo_count <= '0;
			rd_data <= '0;
		end else begin
			// write
			if (wr_en && !full) begin
				mem[wr_ptr] <= wr_data;
				wr_ptr <= (wr_ptr == FIFO_DEPTH - 1) ? '0 : wr_ptr + 1;
			end
			// read
			if (rd_en && !empty) begin
				rd_data <= mem[rd_ptr];
				rd_ptr <= (rd_ptr == FIFO_DEPTH - 1) ? '0 : rd_ptr + 1;
				rd_valid <= 1;
			end else begin
				rd_valid <= 0;
			end
			// count
			if (wr_en && rd_en) fifo_count <= fifo_count;
			else begin
				case ({wr_en && !full, rd_en && !empty})
					2'b10: fifo_count <= fifo_count + 1; // write only
					2'b01: fifo_count <= fifo_count - 1; // read only
					default: fifo_count <= fifo_count;   // both or neither
				endcase
			end
		end
	end
endmodule
