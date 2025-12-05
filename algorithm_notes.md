

### Algorithm

Present data structures and then algorithm. 

##### data structures: 

1. FIFO A - This needs to be able to hold one full row of pixels
2. FIFO B - This needs to be able to hold one full row of pixels
3. BUFFER_IN  - 6 pixels - Holds reads from MEM (THIRD ROW). 
4. SHREG A    - 6 pixels - Holds values Popped from FIFO A. 
5. SHREG B    - 6 pixels - Holds values Popped from FIFO B.
6. BUFFER_RES - 7 pixels - Holds results calculated. When 7 results write bottom 4 and shift 4 down. 

##### Algorithm step by step:

(assumption -> All reads are done from left to right in order)

Pixels are named for one matrix as following. 

A1 A2 A3 A4  
B1 B2 B3 B4  
C1 C2 C3 C4  

Be aware that the algorithm is a little different for the very first pixel (in each row) compared to the rest. 

// START OF ALGO: 

1. Read the full first line. Put into FIFO A.          
2. Read the full second line. Put into FIFO B.         
3. Read one word from third line. Put into BUFFER_IN.

Now that we have initial data we can begin to calculate.

// THIS IS A SPECIAL PIXEL CASE
4. Calculate Pixel B1, B2 and B3:
    A) From FIFO A POP A1 A2 A3 A4. Shift into SHREG A.
    B) From FIFO B POP B1 B2 B3 B4. Shift into SHREG B.
    C) From BUFFER_IN get C1 C2 C3 C4. 

4. Save result in BUFFER_RES. 
    A) When number of stored results = 7 do WRITE of the bottom 4 and then shift 4 down.

5. Set up for next pixel: 
    A) Push C1 C2 C3 C4 into FIFO A.         (transform into row "C" slowly)
    B) Push B1 B2 B3 B4 back into FIFO B.    (keep as row "B" currently)

// THIS IS THE NORMAL PIXEL CASE

6. Calculate Pixel B4, B5, B6, B7: 
    A) From FIFO A POP A5, A6, A7, A8. Shift into SHREG A. 
    B) From FIFO B POP B5, B6, B7, B8. Shift into SHREG B. 
    



    
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
                idle (with start high):
                    Stage mem read
                stores_2_lines (1-87)
                    rd_addr er 1.

                    Stage FIFO write for next cycle.
                    Stage mem read for next cycle.
                    next_rd_addr++;
                store_2_lines (88)
                    Stage FIFO read
                    Stage FIFO write to receive last mem read stage
                    Stage mem read for bIn next cycle.
                Setup cycle: 
                    1.  LAST STORE_2_LINES CYCLE: 
                        Stage fifo read for shreg               (For #0.1)
                        Stage read from MEM into bIn            (For #0.1)

                    2.  SETUP CYCLE
                        Stage shreg read from fifo              (For #0.1)
                        Put data from input into bIn            (for #0.1)

                0: 
                    1.  COMPUTE CYCLE (LEFT SPECIAL CASE)
                        Stage fifo read for shreg               (for #1.1)
                        Stage fifoA write from shregB           (for #6.1?) fordi vi bruger den der (stager den i 5.1, får den ind i shreg i 5.2)
                        Stage fifoB write from bIN              (for #6.1?)  - || - 

                        Data shregs -> edge detector
                        Stage ED output to bRes[7:4](shift)     (for #0.2)
                        Stage read from MEM into bIn            (For #1.1)

                    2.  WRITE CYCLE
                        Stage shreg read from fifo              (For #1.1)
                        put data from input into bIn            (for #1.1)

                        DO NOT WRITE DATA OR SHIFT bRES (LEFT SPECIAL)
                        next_column_idx++                       (for #1.1)

                1:
                    1.  COMPUTE CYCLE 
                        Stage fifo read for shreg               (for #2.1)
                        Stage fifoA write from shregB           (for #7.1?) fordi vi bruger den der (stager den i 5.1, får den ind i shreg i 5.2)
                        Stage fifoB write from bIN              (for #7.1?)  - || - 

                        Data shregs -> edge detector (ED)
                        Stage ED output to bRes[7:4](shift)     (for #1.2)
                        Stage read from MEM into bIn            (For #2.1)

                    2.  WRITE CYCLE
                        Stage shreg read from fifo              (For #2.1)
                        put data from input into bIn            (for #2.1)

                        Stage write from bRes data[3:0]
                        next_column_idx++                       (for #2.1)

                ... REPEAT FAST FOWARD UNTIL RIGHT SPECIAL (5)

                5:
                    1. COMPUTE CYCLE (RIGHT SPECIAL CASE)
                        (SAME but special case because ED sees column_idx=WORDS_PR_LINE
                            and DONT stage fifo read here)

                        Special case in ED -> only p20 calculated (using right mirroring)
                                           -> still output 4 pixels (S1,S2,S3 at this point garbage)
                                           -> garbage shifted out at (#7.1)

                    2. WRITE CYCLE (RIGHT SPECIAL CASE)
                                            
                        Stage write from bRes data[3:0]  
                        DONT put data from input into bIn       (for #6.1)

                        DONT Stage shreg read from fifo         (For #6.1)
                        
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
        



### Hardware



