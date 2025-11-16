
// Purely combinational edge detector unit. 
// Utilizes Sobel convolution masks for computing UP TO 4 pixels at one time.
// Handles special cases (when at edges of picture)

module edge_detector #(

  parameter MAX_Y = 287,   // 288-1
  parameter MAX_X = 351,   // 352-1

)(

  import task2_pkg::*;

  // PIXEL INPUTS
  input pixel  [5:0] R1_pixels,      // Will at most need 6 pixels for calc for each row
  input pixel  [5:0] R2_pixels,      // Will at most need 6 pixels for calc for each row
  input pixel  [5:0] R3_pixels,      // Will at most need 6 pixels for calc for each row

  // PIXEL OUTPUT
  output pixel [3:0] pixels_out,    // Can at most calculate 4 pixels in parallel

  // CONTROL INPUTS - these are for calculating when special case is needed (e.g. when at edge)
  input logic  [$clog2(MAX_X+1)-1:0] pixel_x;
  input logic  [$clog2(MAX_Y+1)-1:0] pixel_y;

)

// plan:
// 1. Use given pixel_x and pixel_y with parameters to find out if we are in a special case
//    or normal operation.


function logic [PW-1 : 0] sobel_convolution(

  input pixel [3:1] R1,
  input pixel [3:1] R2,
  input pixel [3:1] R3

);

  logic signed [11:0] Dx; // 12 bits needed for calc
  logic signed [11:0] Dy; // 12 bits needed for calc
  logic [11:0] abs_Dx;  // Absolute value unsigned
  logic [11:0] abs_Dy;  // Absolute value unsigned
  logic [12:0] Dn;      // Sum of two 12-bit values needs 13 bits


  Dx = R1[3] - R1[1] + ( (R2[3] - R2[1]) << 1 ) + R3[3] - R3[1];
  Dy = R1[1] - R3[1] + ( (R1[2] - R3[2]) << 1 ) + R1[3] - R3[3];

  // Calculate absolute values
  abs_Dx = (Dx < 0) ? -Dx : Dx;
  abs_Dy = (Dy < 0) ? -Dy : Dy;

  Dn = abs_Dx + abs_Dy;

  // Saturate or truncate
  if (Dn > (2**PW - 1)) 
    return {PW{1'b1}};  // Saturate to max value
  else
    return Dn[PW-1:0];  // Return lower bits

endfunction


// Calculate the first pixel (leftmost)
// SPECIAL CASES: when at top / bottom row AND when calculating leftmost pixel
always_comb pixel_1 begin



end pixel_1


// Calculate the second pixel (second most left)
// SPECIAL CASES: when at top / bottom row
always_comb pixel_2 begin



end pixel_2


// Calculate the third pixel (second most right)
// SPECIAL CASES: when at top / bottom row
always_comb pixel_3 begin



end pixel_3


// Calculate the last pixel (rightmost)
// SPECIAL CASES: when at top / bottom row AND when calculating rightmost pixel
always_comb pixel_4 begin



end pixel_4




endmodule