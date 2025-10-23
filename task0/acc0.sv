// -----------------------------------------------------------------------------
//
//  Title      :  Initial image inversion task - task 0.
//             :
//  Developers :  Georg Brink Dyvad - s224038@student.dtu.dk
//             :  Sadaf Ayub - s224027@student.dtu.dk
//             :  Sofus Hammelsø - s224039@student.dtu.dk
//             :  Alexander Wang Aakersø - s223998@student.dtu.dk
//             :
//  Purpose    :  This design contains an entity for the accelerator that must be build
//             :  in task two of the Edge Detection design project. It contains an
//             :  architecture skeleton for the entity as well.
//             :
//  Revision   :  1.0   09-10-25     Final version
//             :
//
// ----------------------------------------------------------------------------//

//------------------------------------------------------------------------------
// The module for task zero. Notice the additional signals for the memory.
// reset is active high.
//------------------------------------------------------------------------------

parameter MAX_WORD_COUNT = 25344;

module acc (
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

    typedef enum logic [2:0] {
        idle = 0, read = 1, comp_write = 2, done = 3
    } state_t;

    state_t state, next_state;

    //Standard signals:
    //We need 355*288/4 = 25344 word reads to get the source image
    shortint unsigned word_cnt, next_word_cnt;


    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= idle;
            word_cnt <= 1'b0;
        end else begin
            state <= next_state;
            word_cnt <= next_word_cnt;
        end
    end

    //Combinatorial Logic
    always_comb begin
        //Default sigs:
        next_state = state;
        en = 1'b0;
        we = 1'b0;
        finish = 1'b0;
        next_word_cnt = next_word_cnt;

        //State machine:
        case(state)
            idle:
            begin
                if(start) next_state = read;
                next_word_cnt = 1'b0;
            end

            read:
            begin
                en = 1'b1;
                addr = word_cnt;
                next_state = comp_write;
            end

            comp_write:
            begin
                en = 1'b1;
                we = 1'b1;
                dataW = {
                    8'd255 - dataR[31:24],
                    8'd255 - dataR[23:16],
                    8'd255 - dataR[15:8],
                    8'd255 - dataR[7:0]
                };
                addr = word_cnt + MAX_WORD_COUNT;
                next_word_cnt = word_cnt + 1;

                //Add 1 because
                if(word_cnt == (MAX_WORD_COUNT - 16'd1)) begin
                    next_state = done;
                end else begin
                    next_state = read;
                end
            end

            done:
            begin
                finish = 1'b1;
                next_state = idle;
                next_word_cnt = 1'b0;
            end

            default: next_state = idle;
        endcase
    end

endmodule