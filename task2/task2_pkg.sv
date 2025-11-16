
// Task 2:
// Simple package for constants, enums and others


package task2_pkg;

localparam NEW_IMG_START_ADDR = 25344;

localparam PW = 8,                  // Pixel width (in bits)
localparam PPT = 4,                 // Pixels Per Transfer
localparam FIFO_DEPTH = 177         // (2*352 + 4)/4

localparam ADDR_WIDTH_FIFO = $clog2(FIFO_DEPTH);
localparam DATA_WIDTH = PPT * PW;

typedef logic [7:0] pixel;

endpackage