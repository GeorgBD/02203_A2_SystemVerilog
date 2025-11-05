
## How will we compute edge detection?

Top level explanation:

1. Read in Entire first row.
2. Read in Entire second row.

3. Read in One word (4 pixels) of Third row.
4. Compute 2 pixels in second row. (only two available)

5. Read in next word (4 pixels) of Third row.
6. Compute 4 pixels in second row. (now four available).
7. Write back 

8. Repeat step 5 and 6 until second row completely calculated.
9. Periodically write values back whenever 4 pixels have been calculated.

10. Now do the same for the next three rows.

Possible problem:

1.

Optimization:

1. 
