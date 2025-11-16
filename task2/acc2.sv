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

  //------------------------------------------------------------------------------
  // DATAPATH
  //------------------------------------------------------------------------------

  // Module Instantiations (FIFO A, FIFO B) - and signals

    
  logic [DATA_WIDTH - 1 : 0 ] read_FA, read_FB, write_FA, write_FB;
  logic                       rd_en_FA, rd_en_FB, wr_en_FA, wr_en_FB, rd_vld_FA, rd_vld_FB;

  fifo #(
    .PW(8),
    .PPT(4),
    .FIFO_DEPTH(177)
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
  )

  fifo #(
    .PW(8),
    .PPT(4),
    .FIFO_DEPTH(177)
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

  // Shift registers Instantiation - synchronous write, asynchronous read

  logic [DATA_WIDTH - 1 : 0 ] shregA_in, shregB_in, bRES_in, bIN_in;
  logic [DATA_WIDTH - 1 : 0 ] shregA_out, shregB_out, bRES_out, bIN_out;
  logic                       shregA_en, shregB_en, bRES_en, bIN_en;

  shift_register #(
    .TOTAL_BYTES(6),      // shreg_A
    .SHIFT_BYTES(4)
  ) shreg_A (
    .clk(clk),            // IN : 1 bit.
    .reset(reset),        // IN : 1 bit, ACTIVE HIGH.
    .shift_en(shregA_en), // IN : 1 bit, enables shifting.
    .data_in(shregA_in),  // IN : 32 bits, data for shifting.
    .data_out(shregA_out) // OUT: 32 bits, data from shifting.
  );

  shift_register #(
    .TOTAL_BYTES(6),      // shreg_B
    .SHIFT_BYTES(4)
  ) shreg_B (
    .clk(clk),            // IN : 1 bit.
    .reset(reset),        // IN : 1 bit, ACTIVE HIGH.
    .shift_en(shregB_en), // IN : 1 bit, enables shifting.
    .data_in(shregB_in),  // IN : 32 bits, data for shifting IN.
    .data_out(shregB_out) // OUT: 32 bits, data from shifting OUT.
  );

  shift_register #(
    .TOTAL_BYTES(7),    // buffer_res
    .SHIFT_BYTES(4)
  ) buffer_RES (
    .clk(clk),          // IN : 1 bit.
    .reset(reset),      // IN : 1 bit, ACTIVE HIGH.
    .shift_en(bRES_en), // IN : 1 bit, enables shifting.
    .data_in(bRES_in),  // IN : 32 bits, data for shifting IN.
    .data_out(bRES_out) // OUT: 32 bits, data from shifting OUT.
  );

  shift_register #(
    .TOTAL_BYTES(6),   // buffer_in
    .SHIFT_BYTES(4)
  ) buffer_IN (
    .clk(clk),         // IN : 1 bit.
    .reset(reset),     // IN : 1 bit, ACTIVE HIGH.
    .shift_en(bIN_en), // IN : 1 bit, enables shifting.
    .data_in(bIN_in),  // IN : 32 bits, data for shifting IN.
    .data_out(bIN_out) // OUT: 32 bits, data from shifting OUT.
  );

  // Pixel detector logic module instantiation

  edge_detector #(
    .MAX_X(),
    .MAX_Y()

  )(
    





  )




  //------------------------------------------------------------------------------
  // FSM
  //------------------------------------------------------------------------------
  
  typedef enum logic [2:0] {
        idle = 0, read = 1, store_2_lines = 2, compute_pixels = 3, read_one_word = 4, done = 5
    } state_t;

  state_t state, next_state;

  //Standard signals:
  //We need 355*288/4 = 25344 word reads to get the source image
  shortint unsigned wr_addr, next_wr_addr;
  shortint unsigned rd_addr, next_rd_addr;
  
  
  always_comb begin
    next_state = state;
    en = 1'b0;
    we = 1'b0;
    finish = 1'b0;
    addr = rd_addr;
    dataW = 0;

    //FIFO Defaults:
    rd_en_FA = 1'b0;
    rd_en_FB = 1'b0;
    wr_en_FA = 1'b0;
    wr_en_FB = 1'b0;
    write_FA = dataR; //Should also be FB_out sometimes
    write_FB = dataR;

    //SHREG Defaults:
    shregA_in = read_FA;
    shregB_in = read_FB;
    bRES_in = edge_out; ////FIX WHEN edge initiated
    bIN_in = dataR; //Should be fine since en is 0.
    shregA_en = 1'b0;
    shregB_en = 1'b0;
    bRES_en = 1'b0;
    bIN_en = 1'b0;

    
    case(state)
      idle:
        begin
          next_rd_addr = 0;
          next_wr_addr = 25344;
          if(start) next_state = read;
        end
      read:
        begin
          en = 1'b1;
          next_state = store_2_lines;
        end  
      store_2_lines:
        begin
          en = 1'b1;
          next_rd_addr++;
          
          //Read from memory into FIFOs
          if(rd_addr <= 88){ //////////CHECK is 88 correct?
            wr_en_FA;
          } else {
            wr_en_FB;
          }

          if(rd_addr <= 8'b176){
            next_state = store_2_lines;
          } else {
            next_state = compute_pixels;
          }
        end
      compute_pixels:
        begin
          we = 1'b1;
          en = 1'b1;
          addr = wr_addr;
  
          //INSERT FIFO write from previous stage (bIn or FB)

          //INSERT FIFO read staged to the approriate shreg. 
          
          //if(SHREG FULL (6px)): enable compute of 4 pixels from the 6 pixels in shreg and shift shreg 4px down.
          //else if(SHREG 4px): compute 2 pixels and shift the 4px in each down the shregs
          //else: no compute (waiting one cycle for 4px to come in)

          if(write_adr <= 16'b50687){
            next_state = read_one_word;
          } else {
            next_state = done;
          }
        end
      read_one_word:
        begin
          en = 1'b1;
          next_rd_addr++;
          next_state = compute_pixels;
        end
      done:
        begin
          finish = 1'b1;
          next_state = idle;
        end
      default: 
        begin
          next_state = idle;
        end
    endcase
  end

  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= idle;
      wr_addr <= 16'b(NEW_IMG_START_ADDR); //How to do this here??
      rd_addr <= 1'b0;
    end else begin
      state <= next_state;
      wr_addr <= next_wr_addr;
      rd_addr <= next_rd_addr;
    end
  end





endmodule
