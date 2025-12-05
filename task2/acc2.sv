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
  logic [$clog2(NUM_ROWS)                 - 1 : 0] compute_row_idx, next_compute_row_idx;
  logic [$clog2(WORDS_PR_LINE)            - 1 : 0] compute_clmn_idx, next_compute_clmn_idx;

  // Module Instantiations (FIFO A, FIFO B) - and signals
    
  logic [DATA_WIDTH - 1 : 0 ] read_FA, read_FB, write_FA, write_FB;
  logic                       rd_en_FA, rd_en_FB, wr_en_FA, wr_en_FB, rd_vld_FA, rd_vld_FB;

  fifo #(
    .PW(PW),
    .PPT(PPT),
    .FIFO_DEPTH(WORDS_PR_LINE)
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
    .FIFO_DEPTH(WORDS_PR_LINE)
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


  logic R_special, L_special, NOT_special, T_special;
  
  assign R_special    = compute_clmn_idx == WORDS_PR_LINE;
  assign L_special    = compute_clmn_idx == '0;
  assign NOT_special  = !R_special && !L_special;
  assign T_special    = compute_row_idx == 'd0;


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
    .M_X_IT(WORDS_PR_LINE),
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
      idle = 0, clear_state = 1, store_2_lines = 2, setup_cycle = 3, compute_cycle = 4, write_cycle = 5, done = 6
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

    // Shreg expects data as : {P6 , P5 , P4 , P3 , P2 , P1} (rightmost pixel = MSB)
    // FIFOS gives data as : 
    shregA_in = read_FA;
    shregB_in = read_FB;
    bIN_in = dataR;

    bRES_in   = '0;

    // edge detector defaults
    ed_R1_IN = '0;
    ed_R2_IN = '0;
    ed_R3_IN = '0;
    
    // Default for next values
    next_rd_addr = rd_addr;
    next_wr_addr = wr_addr;
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
            next_rd_addr = 'd1;
          end
        end
      
      store_2_lines: 
        begin
          // ----------------------------------------------------------------------------------------------------------------
          // This state we read an entire line from mem and also 1 word of 2nd line.
          // ----------------------------------------------------------------------------------------------------------------

          //Read from memory into FIFOs
          if (rd_addr < WORDS_PR_LINE) begin  //If reading data belongs to first line
            wr_en_FB    = 1'b1;               //Store data in FIFO A
            wr_en_FA    = 1'b1;
            write_FA    = 'd0;                //FIFO A gets zeros
            req = 1'b1;
            
            next_rd_addr = rd_addr + 1;
            next_state  = store_2_lines;  
          end else begin                                     
            
            next_state  = setup_cycle; 
            
            wr_en_FB    = 1'b1; //Receive final mem stage of addr 87  
            wr_en_FA    = 1'b1;

            rd_en_FA  = 1'b1; //Stage FIFO read for shreg
            rd_en_FB  = 1'b1; // -||-
            
            req = 1'b1; //Stage read from MEM into bIn
            next_rd_addr = rd_addr + 1;
          end

        end
      
      setup_cycle:
        begin
          //Receive FIFO data into shregs
          shregA_en = 1'b1;   // Get data from FIFOA
          shregB_en = 1'b1;   // Get data from FIFOB 
          bIN_en    = 1'b1;   // Put input data into bIn
          
          next_state = compute_cycle;

        end

      compute_cycle: 
        begin
          if(NOT_special) begin
            
            rd_en_FA  = 1'b1; // Stage fifo reads for shregs
            rd_en_FB  = 1'b1; // Stage fifo reads for shregs
            
            wr_en_FA = 1'b1; //Stage fifoA write from shregB  (ROTATE)
            write_FA = shregB_out[6*PW-1 : 2*PW]; //Take 4x MSB because LSB unvalid
            wr_en_FB = 1'b1; //Stage fifoB write from bIN  (ROTATE)
            write_FB = bIN_out[6*PW-1 : 2*PW]; //Take 4x MSB because LSB unvalid

            ed_R1_IN = shregA_out; //Data shregs -> edge detector
            ed_R2_IN = shregB_out; // -||-
            ed_R3_IN = bIN_out;    // -||-
            
            bRES_en = 'd1; // enable bRes to get pixels from edge detector module
            bRES_in[4*PW-1 : 3*PW] = ed_P_OUT[3];
            bRES_in[3*PW-1 : 2*PW] = ed_P_OUT[2];
            bRES_in[2*PW-1 : 1*PW] = ed_P_OUT[1];
            bRES_in[1*PW-1 : 0*PW] = ed_P_OUT[0];

            req = 1'b1;         // Stage read from MEM into bIN
            next_rd_addr++;     // -||-

            next_state = write_cycle;
          end else if(L_special) begin
            rd_en_FA  = 1'b1; // Stage fifo reads for shregs
            rd_en_FB  = 1'b1; // Stage fifo reads for shregs

            if(T_special) begin
              wr_en_FA = 1'b1; //Stage fifoA write from shregB  (ROTATE)
              write_FA = shregB_out[6*PW-1 : 2*PW]; //Take 4x MSB because LSB unvalid
              wr_en_FB = 1'b1; //Stage fifoB write from bIN  (ROTATE)
              write_FB = bIN_out[6*PW-1 : 2*PW]; //Take 4x MSB because LSB unvalid
            end
            
            ed_R1_IN = shregA_out; //Data shregs -> edge detector
            ed_R2_IN = shregB_out; // -||-
            ed_R3_IN = bIN_out;    // -||-

            bRES_en = 'd1; // enable bRes to get pixels from edge detector module
            bRES_in[4*PW-1 : 3*PW] = ed_P_OUT[3];
            bRES_in[3*PW-1 : 2*PW] = ed_P_OUT[2];
            bRES_in[2*PW-1 : 1*PW] = ed_P_OUT[1];
            bRES_in[1*PW-1 : 0*PW] = ed_P_OUT[0];

            req = 1'b1;         // Stage read from MEM into bIN
            next_rd_addr++;     // -||-

            next_state = write_cycle;
          end else if(R_special) begin
            
            //rd_en_FA  = 1'b1; DONT Stage fifo reads for shregs
            //rd_en_FB  = 1'b1; DONT Stage fifo reads for shregs

            wr_en_FA = 1'b1; //Stage fifoA write from shregB  (ROTATE)
            write_FA = shregB_out[6*PW-1 : 2*PW]; //Take 4x MSB because LSB unvalid
            wr_en_FB = 1'b1; //Stage fifoB write from bIN  (ROTATE)
            write_FB = bIN_out[6*PW-1 : 2*PW]; //Take 4x MSB because LSB unvalid

            ed_R1_IN = shregA_out; //Data shregs -> edge detector
            ed_R2_IN = shregB_out; // -||-
            ed_R3_IN = bIN_out;    // -||-

            bRES_en = 'd1; // enable bRes to get pixels from edge detector module
            bRES_in[4*PW-1 : 3*PW] = ed_P_OUT[3];
            bRES_in[3*PW-1 : 2*PW] = ed_P_OUT[2];
            bRES_in[2*PW-1 : 1*PW] = ed_P_OUT[1];
            bRES_in[1*PW-1 : 0*PW] = ed_P_OUT[0];

            next_state = write_cycle;
          end else begin
            //ILLEGAL STATE
            $error("ERROR");
          end

        end 
      
      write_cycle:  
        begin
          if(NOT_special === 'd1) begin
            
            bIN_en = 1'b1;    // Get data from input read into bIn
            shregA_en = 1'b1; // Get data from FIFO A into shreg
            shregB_en = 1'b1; // Get data from FIFO B into shreg

            addr = wr_addr;               //Stage write from bRes to mem
            dataW = bRES_out;             //
            req     = 1'b1;               //
            wr_req  = 1'b1;               //
            next_wr_addr = wr_addr + 'd1; //

            next_compute_clmn_idx++;  //increment column index

            next_state = compute_cycle;

          end else if(L_special === 'd1) begin
            
            bIN_en = 1'b1;    // Get data from input read into bIn
            shregA_en = 1'b1; // Get data from FIFO A into shreg
            shregB_en = 1'b1; // Get data from FIFO B into shreg

            //addr = wr_addr;               //DONT Stage write from bRes to mem
            //dataW = bRES_out;             //
            //req     = 1'b1;               //
            //wr_req  = 1'b1;               //
            //next_wr_addr = wr_addr + 'd1; //

            next_compute_clmn_idx++;  //increment column index

            next_state = compute_cycle;

          end else if(R_special === 'd1) begin
            addr = wr_addr;               //Stage write from bRes to mem
            dataW = bRES_out;             //
            req     = 1'b1;               //
            wr_req  = 1'b1;               //
            next_wr_addr = wr_addr + 'd1; //
            
            
            next_state = compute_cycle;
            
            if(compute_row_idx == (NUM_ROWS-1)) begin
              next_state = done;
            end else begin
              next_compute_row_idx++;
            end

            next_compute_clmn_idx = 0;

          end else begin
            //ILLEGAL STATE
            $error("ERROR");
          end

        end
      
      done:
      begin
        finish = 1'b1;
        next_compute_row_idx = 'd0;   
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
      
      compute_row_idx <= 'd0;
      compute_clmn_idx <= '0;

    end else begin
      state     <= next_state;
      wr_addr   <= next_wr_addr;
      rd_addr   <= next_rd_addr;

      compute_row_idx   <= next_compute_row_idx;
      compute_clmn_idx  <= next_compute_clmn_idx;
    end
  end

endmodule
