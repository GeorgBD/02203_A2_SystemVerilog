
// Task 2:
// Simple package for constants, enums and others

package task2_pkg;

localparam NEW_IMG_START_ADDR = 25344;

localparam NUM_ROWS = 288;
localparam NUM_COLS = 352;

localparam PW = 8;                  // Pixel width (in bits)
localparam PPT = 4;                 // Pixels Per Transfer
localparam FIFO_DEPTH = 352;        // 352 bytes pr line
localparam WORDS_PR_LINE = 88;      // 352/4 == 88 (4 bytes/pixels per word)

//25344 = 352*288/4 = pix_width*pix_height/pix_pr_word
localparam WR_ADDR_START = 25344 + WORDS_PR_LINE;   // TODO: remove WORDS_PR_LINE when added support for calculating row 0 and row 287
localparam WR_ADDR_END = 50687;

localparam ADDR_WIDTH_FIFO = $clog2(FIFO_DEPTH);
localparam DATA_WIDTH = PPT * PW;

typedef logic [PW-1:0] pixel;

endpackage