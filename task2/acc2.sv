// -----------------------------------------------------------------------------
//
//  Title      :  Edge-Detection design project - task 2.
//             :
//  Developers :  YOUR NAME HERE - s??????@student.dtu.dk
//             :  YOUR NAME HERE - s??????@student.dtu.dk
//             :
//  Purpose    :  This design contains an entity for the accelerator that must be build
//             :  in task two of the Edge Detection design project. It contains an
//             :  architecture skeleton for the entity as well.
//             :
//  Revision   :  1.0   ??-??-??     Final version
//             :
//
// ----------------------------------------------------------------------------//

//------------------------------------------------------------------------------
// The module for task two. Notice the additional signals for the memory.
// reset is active high.
//------------------------------------------------------------------------------

module acc2 (
  input  logic        clk,        // The clock.
  input  logic        reset,      // The reset signal. Active high.
  output logic [15:0] addr,       // Address bus for data (halfword_t).
  input  logic [31:0] dataR,      // The data bus (word_t).
  output logic [31:0] dataW,      // The data bus (word_t).
  output logic        en,         // Request signal for data.
  output logic        we,         // Read/Write signal for data.
  input  logic        start,
  output logic        finish
);

  import task2_pkg::*;

  // IO signals
  logic req, wr_req;
  assign en = req;
  assign we = wr_req;

  //------------------------------------------------------------------------------
  // DATAPATH
  //------------------------------------------------------------------------------

  // Signals for counters
  logic [$clog2(NUM_ROWS)                 - 1 : 0] read_row_idx, next_read_row_idx, compute_row_idx, next_compute_row_idx;
  logic [$clog2(WORDS_PR_LINE)            - 1 : 0] read_clmn_idx, next_read_clmn_idx, compute_clmn_idx, next_compute_clmn_idx;

  // Module Instantiations (FIFO A, FIFO B) - and signals
    
  logic [DATA_WIDTH - 1 : 0 ] read_FA, read_FB, write_FA, write_FB;
  logic                       rd_en_FA, rd_en_FB, wr_en_FA, wr_en_FB, rd_vld_FA, rd_vld_FB;

  fifo #(
    .PW(PW),
    .PPT(PPT),
    .FIFO_DEPTH(FIFO_DEPTH)
  ) FIFO_A (
    .clk(clk),              // IN : 1 bit
    .reset(reset),          // IN : 1 bit, active HIGH
    .wr_en(wr_en_FA),       // IN : 1 bit
    .rd_en(rd_en_FA),       // IN : 1 bit
    .wr_data(write_FA),     // IN : 32 bit
    .rd_data(read_FA),      // OUT: 32 bit
    .full(),                // OUT: 1 bit - unused
    .empty(),               // OUT: 1 bit - unused
    .count(),               // OUT: 1 bit - unused
    .rd_valid(rd_vld_FA)    // OUT: 1 bit - used to qualify read data
  );

  fifo #(
    .PW(PW),
    .PPT(PPT),
    .FIFO_DEPTH(FIFO_DEPTH)
  ) FIFO_B (
    .clk(clk),
    .reset(reset),
    .wr_en(wr_en_FB),
    .rd_en(rd_en_FB),
    .wr_data(write_FB),
    .rd_data(read_FB),
    .full(),
    .empty(),
    .count(),
    .rd_valid(rd_vld_FB)
  );

  // Module Instantiations (Shift registers) - synchronous write, asynchronous read

  logic [DATA_WIDTH - 1 : 0 ] shregA_in, shregB_in, bRES_in, bIN_in;
  logic [DATA_WIDTH - 1 : 0 ] bRES_out;
  logic [6*PW - 1       : 0 ] shregA_out, shregB_out, bIN_out;
  logic                       shregA_en, shregB_en, bRES_en, bIN_en;

  shift_register #(
    .TOTAL_BYTES(6),      // shreg_A
    .SHIFT_BYTES(4),
    .READ_BYTES(6)
  ) shreg_A (
    .clk(clk),            // IN : 1 bit.
    .reset(reset),        // IN : 1 bit, ACTIVE HIGH.
    .shift_en(shregA_en), // IN : 1 bit, enables shifting.
    .data_in(shregA_in),  // IN : 32 bits, data for shifting.
    .data_out(shregA_out) // OUT: 48 bits, data from shifting.
  );

  shift_register #(
    .TOTAL_BYTES(6),      // shreg_B
    .SHIFT_BYTES(4),
    .READ_BYTES(6)
  ) shreg_B (
    .clk(clk),            // IN : 1 bit.
    .reset(reset),        // IN : 1 bit, ACTIVE HIGH.
    .shift_en(shregB_en), // IN : 1 bit, enables shifting.
    .data_in(shregB_in),  // IN : 32 bits, data for shifting IN.
    .data_out(shregB_out) // OUT: 48 bits, data from shifting OUT.
  );

  shift_register #(
    .TOTAL_BYTES(7),    // buffer_res
    .SHIFT_BYTES(4),
    .READ_BYTES(4)
  ) buffer_RES (
    .clk(clk),          // IN : 1 bit.
    .reset(reset),      // IN : 1 bit, ACTIVE HIGH.
    .shift_en(bRES_en), // IN : 1 bit, enables shifting.
    .data_in(bRES_in),  // IN : 32 bits, data for shifting IN.
    .data_out(bRES_out) // OUT: 32 bits, data from shifting OUT.
  );

  shift_register #(
    .TOTAL_BYTES(6),   // buffer_in
    .SHIFT_BYTES(4),
    .READ_BYTES(6)
  ) buffer_IN (
    .clk(clk),         // IN : 1 bit.
    .reset(reset),     // IN : 1 bit, ACTIVE HIGH.
    .shift_en(bIN_en), // IN : 1 bit, enables shifting.
    .data_in(bIN_in),  // IN : 32 bits, data for shifting IN.
    .data_out(bIN_out) // OUT: 48 bits, data from shifting OUT.
  );

  // Pixel detector logic module instantiation

  pixel [5:0] ed_R1_IN;
  pixel [5:0] ed_R2_IN;
  pixel [5:0] ed_R3_IN;
  pixel [3:0] ed_P_OUT;

  edge_detector #(
    .M_X_IT(WORDS_PR_LINE-1),
    .M_Y_IT(NUM_ROWS-1)
  ) ed (
    // pixel inputs
    .R1_pixels(ed_R1_IN), 
    .R2_pixels(ed_R2_IN),
    .R3_pixels(ed_R3_IN),

    // pixel output
    .pixels_out(ed_P_OUT),

    // control inputs
    .X_IT(compute_clmn_idx),        // From statemachine : Current column index
    .Y_IT(compute_row_idx)          // From statemaching : Current row index
  );

  //------------------------------------------------------------------------------
  // FSM
  //------------------------------------------------------------------------------
  
  typedef enum logic [2:0] {
        idle = 0, store_2_lines = 1, setup_compute = 2, compute_pixels = 3, write_one_word = 4, write_last_word_in_row = 5, done = 6
    } state_t;

  state_t state, next_state;

  //Standard signals:
  //We need 355*288/4 = 25344 word reads to get the source image
  shortint unsigned wr_addr, next_wr_addr;
  shortint unsigned rd_addr, next_rd_addr;
  
  always_comb begin
    
    //Defaults:
    next_state  = state;
    req         = 1'b0;
    wr_req      = 1'b0;
    finish      = 1'b0;
    addr        = rd_addr; //word addressing. addr = 0 gives first word, =1 gives second. etc.
    dataW       = '0;

    //FIFO Defaults:
    rd_en_FA = 1'b0;
    rd_en_FB = 1'b0;
    wr_en_FA = 1'b0;
    wr_en_FB = 1'b0;
    write_FA = dataR;         //FIFO A gets data from mem read
    write_FB = dataR;         //FIFO B gets data from mem read

    //SHREG Defaults:
    shregA_en = 1'b0;
    shregB_en = 1'b0;
    bRES_en   = 1'b0;
    bIN_en    = 1'b0;
    shregA_in = read_FA;      //shregA gets output of FIFO A
    shregB_in = read_FB;      //shregB gets output of FIFO B
    bRES_in   = '0;
    bIN_in    = dataR;        //input buffer gets data from mem read

    // edge detector defaults
    ed_R1_IN = '0;
    ed_R2_IN = '0;
    ed_R3_IN = '0;
    
    // Default for next values
    next_rd_addr = rd_addr;
    next_wr_addr = wr_addr;
    next_read_row_idx  = read_row_idx;
    next_read_clmn_idx = read_clmn_idx;
    next_compute_row_idx = compute_row_idx;
    next_compute_clmn_idx = compute_clmn_idx;
    
    case(state)
      
      idle:
        begin
          next_rd_addr = 0;
          next_wr_addr = WR_ADDR_START;
          if (start) begin
            next_state = store_2_lines;
            req = 1'b1;
            next_rd_addr++;
            next_read_clmn_idx++;
          end
        end
      
      store_2_lines: 
        begin
          // ----------------------------------------------------------------------------------------------------------------
          // This state we read an entire 2 lines from mem and also 1 word of 3rd line.
          // ----------------------------------------------------------------------------------------------------------------
          req = 1'b1;
          next_rd_addr++;

          //Read from memory into FIFOs
          if (read_row_idx == 'd0) begin                      //If reading data belongs to first line
            wr_en_FA    = 1'b1;                                    //Store data in FIFO A
            next_state  = store_2_lines;                         //Keep reading
          end else if (read_row_idx == 'd1) begin             //If read data belongs to second line
            wr_en_FB    = 1'b1;                                    //Store data in FIFO B
            next_state  = store_2_lines;                         //Keep reading
          end else begin                                      //If read data belongs to third line (only one word)
            bIN_en      = 1'b1;                                      //Store data in input buffer
            next_state  = setup_compute;                        //Go to compute pixels

            //Stage FIFO read. FIFO -> SHREG. Then the data is ready next cycle in compute state.
            rd_en_FA  = 1'b1;
            rd_en_FB  = 1'b1;

            // Request bIN data for first compute (from mem)
            req = 1'b1;
            next_rd_addr++;

          end

          if(read_clmn_idx == (WORDS_PR_LINE-1)) begin 
            next_read_clmn_idx = '0;
            next_read_row_idx  = read_row_idx + 'd1;
          end else begin
            next_read_clmn_idx = read_clmn_idx + 'd1;
          end

        end
      
      setup_compute:
        begin
          //Receive FIFO data into shregs
          shregA_en = 1'b1;
          shregB_en = 1'b1;
  
          // Receive input mem data into buffer input
          bIN_en = 1'b1;

          next_state = compute_pixels;

        end

      compute_pixels: 
        begin
         
          // ----------------------------------------------------------------------------------------------------------------
          // This state we: 
          // 1. Use data present on outputs of shregs and bIn to compute pixels
          // 2. Stages the computed pixels to go inside the result buffer
          // 3. Request to read one word of data (should go into bIn next clock cycle)
          // 4. Rotates data; biN -> FIFO_B, shregB -> FIFO_A, shreg_A -> void
          // 5. Stage FIFO reads for next states SHREG read.
          // 6. Go back and forth to write_one_word state where we write data from result buffer to mem
          // ----------------------------------------------------------------------------------------------------------------

          // ================================================================================================================
          // (1) - Give inputs to edge detector module
          for (int i = 0; i < 6; i++) begin
            ed_R1_IN[i] = shregA_out[i*8 +: 8];  //[a +: b] means you want b bits out starting at index a
            ed_R2_IN[i] = shregB_out[i*8 +: 8];
            ed_R3_IN[i] = bIN_out[i*8 +: 8];
          end       

          // ================================================================================================================
          // (2) - Stage computed pixel result to go inside bRes
          bRES_en = 'd1; // enable bRes to get pixels from edge detector module
          for (int i = 0; i < 4; i++) bRES_in[i*8 +: 8] = ed_P_OUT[i]; // Result buffer gets pixels from edge detector module
          //for (int i = 0; i < 4; i++) bRES_in[i*8 +: 8] = ed_P_OUT[3-i];  // Result buffer gets pixels from edge detector module

          // ================================================================================================================
          // (3) - Request to read one word of data
          req = 1'b1;      // request
          next_rd_addr++;     // increment read address
          addr = rd_addr;

          // ================================================================================================================
          // (4) - Rotate fifo data 
          wr_en_FA = 1'b1;
          write_FA = shregB_out[DATA_WIDTH - 1 : 0];
          wr_en_FB = 1'b1;
          write_FB = bIN_out[DATA_WIDTH - 1 : 0];

          // ================================================================================================================
          // (5) - Stage FIFO read
          rd_en_FA  = 1'b1;
          rd_en_FB  = 1'b1;

          // ================================================================================================================
          next_state = write_one_word;

        end 
      
      write_one_word:  
        begin
          
          // ----------------------------------------------------------------------------------------------------------------
          // This state we write a word from result buffer (if enough pixels calculated). 
          // ----------------------------------------------------------------------------------------------------------------

          // Ensure that read request from previous stage goes to correct input buffer
          bIN_en = 1'b1;
          
          //Receive FIFO read into shregs. Then the data is ready next cycle in compute state for edge detector.
          shregA_en = 1'b1;
          shregB_en = 1'b1;

          addr = wr_addr;

          // logic to qualify if we want to do the write
          if (compute_clmn_idx > 'd0) begin 
            dataW = bRES_out;
            req     = 1'b1; 
            wr_req  = 1'b1;
            next_wr_addr = wr_addr + 'd1;
          end 

          next_state = compute_pixels;

          // ================================================================================================================
          // Counter to keep track of X, Y indexes for handling special cases and controlling next_state
          if (compute_clmn_idx == (WORDS_PR_LINE-1)) begin 
            next_compute_clmn_idx = '0;
            next_state = write_last_word_in_row;
            bRES_en = 'd1;

          end else begin
            next_compute_clmn_idx = compute_clmn_idx + 'd1;
          end

        end

      write_last_word_in_row:
        begin
          req     = 1'b1; 
          wr_req  = 1'b1;
          addr = wr_addr;
          next_wr_addr = wr_addr + 'd1;
          dataW = bRES_out;
          next_state = compute_pixels;

          if(compute_row_idx == (NUM_ROWS-1)) begin
            next_state = done;
          end else begin
            next_compute_row_idx  = compute_row_idx + 'd1;
          end

        end  
      
      done:
        begin
          finish                = 1'b1;
          next_read_row_idx     = 'd0;
          next_read_clmn_idx    = 'd0;
          next_compute_row_idx  = 'd1;    // TODO: CHANGE TO 0 WITH EDGE CASE
          next_compute_clmn_idx = 'd0;

          next_state = done;
        end
      default: 
        begin
          next_state = idle;
        end
    endcase

  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state     <= idle;
      wr_addr   <= NEW_IMG_START_ADDR;
      rd_addr   <= '0;
      
      read_row_idx   <= '0;
      read_clmn_idx  <= '0;
      
      compute_row_idx <= 'd1;
      compute_clmn_idx <= '0;

    end else begin
      state     <= next_state;
      wr_addr   <= next_wr_addr;
      rd_addr   <= next_rd_addr;

      read_row_idx   <= next_read_row_idx;
      read_clmn_idx  <= next_read_clmn_idx;

      compute_row_idx   <= next_compute_row_idx;
      compute_clmn_idx  <= next_compute_clmn_idx;
    end
  end

endmodule
