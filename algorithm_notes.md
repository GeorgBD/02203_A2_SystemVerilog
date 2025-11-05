

### Algorithm

Present data structures and then algorithm. 

##### data structures: 

1. FIFO A - This needs to be able to hold one full row of pixels
2. FIFO B - This needs to be able to hold one full row of pixels
3. BUFFER_IN  - 6 pixels - Holds reads from MEM (THIRD ROW). 
4. SHREG A    - 6 pixels - Holds values Popped from FIFO A. 
5. SHREG B    - 6 pixels - Holds values Popped from FIFO B.
6. BUFFER_RES - 4 pixels - Holds results calculated. When 4 results write and wipe. 

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
4. Calculate Pixel B2 and B3:
    A) From FIFO A POP A1 A2 A3 A4. Shift into SHREG A.
    B) From FIFO B POP B1 B2 B3 B4. Shift into SHREG B.
    C) From BUFFER_IN get C1 C2 C3 C4. 

4. Save result in BUFFER_RES. 
    A) When number of stored results = 4 do WRITE and clear. Maybe use counter to keep track?

5. Set up for next pixel: 
    A) Push C1 C2 C3 C4 into FIFO A.         (transform into row "C" slowly)
    B) Push B1 B2 B3 B4 back into FIFO B.    (keep as row "B" currently)

// THIS IS THE NORMAL PIXEL CASE

6. Calculate Pixel B4, B5, B6, B7: 
    A) From FIFO A POP A5, A6, A7, A8. Shift into SHREG A. 
    B) From FIFO B POP B5, B6, B7, B8. Shift into SHREG B. 
    







### Hardware



