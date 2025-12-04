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
    assign data_out = shift_reg[READ_BYTES*8-1 : 0];
    
    // Input is bottom 4 bytes - synchronous write / shift. 
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_reg <= '0;  // Clear register
        end else if (shift_en) begin
            // New data comes in at bottom, old data shifts towards top
            shift_reg <= {data_in, shift_reg[TOTAL_BYTES*8-1 : SHIFT_BYTES*8]};

            /*
                Ekspempel.
                    Antag vi kører igennem 1 række. 1 række = 5 words. WORDS_PR_LINE=5

                Pixels i billede:
                p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,p17,p18,p19,p20
                S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15,S16,S17,S18,S19,S20

                Hvis vi giver rightmost på MSB:  
            0    MSB[p4,p3,p2,p1,x,x]LSB                             (Colm = 0)
                    Edge detector output res p3,p2,p1,p4 (Bør trigger left-special case her)
                    bRES content:
                        MSB[p3,p2,p1 < p4,x,x,x > ]LSB  
                ->
            1    MSB[p8,p7,p6,p5,p4,p3]LSB                           (Colm = 1)
                    Edge detector output res p7,p6,p5,p4
                    bRES content:
                        MSB[p7,p6,p5, | p4,p3,p2,p1 | ]LSB 
                ->
            2    MSB[p12,p11,p10,p9,p8,p7]LSB                        (Colm = 2)
                    Edge detector output res p11,p10,p9,p8
                    bRES content:
                        MSB[p11,p10,p9, | p8,p7,p6,p5 | ]LSB
                ->
            3    MSB[p16,p15,p14,p13,p12,p11]LSB                     (Colm = 3)
                    Edge detector output res p15,p14,p13,p12
                    bRES content:
                        MSB[p15,p14,p13, | p12,p11,p10,p9 | ]LSB
                -> 
            4    MSB[p20,p19,p18,p17,p16,p15]LSB                     (Colm = 4)
                    Edge detector output res p19,p18,p17,p16
                    bRES content:
                        MSB[p19,p18,p17, | p16,p15,p14,p13 | ]LSB    
                ->
            5    MSB[S4,S3,S2,S1,p20,p19]LSB                         (Colm = 5)
                    Edge detector output res p20  (Bør trigger right-special case her!)
                    bRES content:
                        MSB[S3,S2,S1, | p20,p19,p18,p17 | ]LSB
                    ->
                
            6    MSB[S4,S3,S2,S1,p20,p19]LSB                         (Colm = 0)
                    Edge detector output res S3,S2,S1  (Bør trigger left-special case her!)
                    bRES content:
                        MSB[S3,S2,S1, < S4, S3, S2, S1 > ]LSB


            Hvad skal stages i hver column cycle?:

                -1: 
                    1.  LAST STORE_2_LINES CYCLE: 
                        Stage fifo read for shreg               (For #0.1)
                    
                    2.  SETUP CYCLE
                        Stage read from MEM into bIn            (For #0.1)
                        Stage shreg read from fifo              (For #0.1)

                0: 
                    1.  COMPUTE CYCLE (LEFT SPECIAL CASE)
                        Stage fifo read for shreg               (for #1.1)
                        Stage fifoA write from shregB           (for #6.1?) fordi vi bruger den der (stager den i 5.1, får den ind i shreg i 5.2)
                        Stage fifoB write from bIN              (for #6.1?)  - || - 

                        Data shregs -> edge detector
                        Stage ED output to bRes[7:4](shift)     (for #1.2)

                    2.  WRITE CYCLE
                        Stage shreg read from fifo              (For #1.1)
                        Stage read from MEM into bIn            (For #1.1)

                        DO NOT WRITE DATA OR SHIFT bRES (LEFT SPECIAL)
                        next_column_idx++                       (for #1.1)

                1:
                    1.  COMPUTE CYCLE 
                        Stage fifo read for shreg               (for #2.1)
                        Stage fifoA write from shregB           (for #7.1?) fordi vi bruger den der (stager den i 5.1, får den ind i shreg i 5.2)
                        Stage fifoB write from bIN              (for #7.1?)  - || - 

                        Data shregs -> edge detector (ED)
                        Stage ED output to bRes[7:4](shift)     (for #2.2)

                    2.  WRITE CYCLE
                        Stage shreg read from fifo              (For #2.1)
                        Stage read from MEM into bIn            (For #2.1)

                        Stage write from bRes data[3:0]
                        next_column_idx++                       (for #2.1)

                ... REPEAT FAST FOWARD UNTIL RIGHT SPECIAL (5)

                5:
                    1. COMPUTE CYCLE (RIGHT SPECIAL CASE)
                        (SAME but special case because ED sees column_idx=WORDS_PR_LINE)

                        Special case in ED -> only p20 calculated (using right mirroring)
                                           -> still output 4 pixels (S1,S2,S3 at this point garbage)
                                           -> garbage shifted out at (#7.1)

                    2. WRITE CYCLE (RIGHT SPECIAL CASE)
                        
                        Stage read from MEM into bIn            (For #6.1)
                        
                        Stage write from bRes data[3:0]  

                        Stage shreg read from fifo              (For #6.1)
                        
                        next_row_idx++;                         (For #6.1)
                        next_column_idx = 0;                    (For #6.1)

                6:
                    1.  COMPUTE CYCLE (LEFT SPECIAL CASE)
                        (EXACT SAME CASE AS FOR #0.1) 
                            (different write/read addr)
                            (new row being computed)

                    2.  WRITE CYCLE
                        (EXACT SAME CASE AS FOR #0.2) 
                            (different write/read addr)
            */
        end
    end
    
endmodule