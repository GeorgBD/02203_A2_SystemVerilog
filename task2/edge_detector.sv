
// Purely combinational edge detector unit. 
// Utilizes Sobel convolution masks for computing UP TO 4 pixels at one time.
// Handles special cases (when at edges of picture)

import task2_pkg::*;

module edge_detector #(

  parameter M_X_IT = WORDS_PR_LINE,   // Maximum number of X iterations per row (words pr. line)
  parameter M_Y_IT = NUM_ROWS         // Maximum number of Y iterations (number of rows)

)(
  // PIXEL INPUTS
  input pixel  [5:0] R1_pixels,      // Will at most need 6 pixels for calc for each row
  input pixel  [5:0] R2_pixels,      // Will at most need 6 pixels for calc for each row
  input pixel  [5:0] R3_pixels,      // Will at most need 6 pixels for calc for each row

  // PIXEL OUTPUT
  output pixel [3:0] pixels_out,    // Can at most calculate 4 pixels in parallel

  // CONTROL INPUTS - these are for calculating when special case is needed (e.g. when at edge)
  input logic [$clog2(M_X_IT+1)-1:0] X_IT,
  input logic [$clog2(M_Y_IT+1)-1:0] Y_IT

);

  function logic [PW-1 : 0] sobel_convolution(

    input pixel [3:1] R1,
    input pixel [3:1] R2,
    input pixel [3:1] R3

  );

    logic signed [11:0] Dx; // 12 bits needed for calc
    logic signed [11:0] Dy; // 12 bits needed for calc
    logic [11:0] abs_Dx;    // Absolute value unsigned
    logic [11:0] abs_Dy;    // Absolute value unsigned
    logic [12:0] Dn;        // Sum of two 12-bit values needs 13 bits

    Dx = R1[1] - R1[3] + ( (R2[1] - R2[3]) << 1 ) + R3[1] - R3[3]; // 1->3, 3->1
    Dy = R1[3] - R3[3] + ( (R1[2] - R3[2]) << 1 ) + R1[1] - R3[1]; // 1->3, 3->1

    // Calculate absolute values
    abs_Dx = (Dx < 0) ? -Dx : Dx;
    abs_Dy = (Dy < 0) ? -Dy : Dy;

    Dn = abs_Dx + abs_Dy;

    // Saturate or truncate - NOTE: probably not correct to always just truncate
    if (Dn > (2**PW - 1)) 
      return {PW{1'b1}};  // Saturate to max value
    else
      return Dn[PW-1:0];  // Return lower bits

  endfunction

  // Special cases:
  // 1. Edges - TOP, BOTTOM, LEFT, RIGHT
  // 2. First iteration of every loop for every row - only calc 2 pixels (with 4 valid input pixels)

  // Signals for determining if in special case
  logic TOP_special, BOT_special, LEFT_special, RIGHT_special; // for handling the edges

  assign LEFT_special   = X_IT == 'd1      ?    1 : 0;
  assign RIGHT_special  = X_IT == M_X_IT   ?    1 : 0;
  assign BOT_special    = Y_IT == M_Y_IT   ?    1 : 0;
  assign TOP_special    = Y_IT == 'd0      ?    1 : 0;

  pixel [3:0] pixels_calc;    // Can at most calculate 4 pixels in parallel

  // Calculate the leftmost pixel
  // SPECIAL CASES: when at top / bottom row AND when calculating leftmost pixel
  always_comb begin

    pixel [2:0] R1, R2, R3;

    R1 = R1_pixels[5:3];
    R2 = R2_pixels[5:3];
    R3 = R2_pixels[5:3];

    if(LEFT_special == 'd1) begin // needs to be reworked with edge cases

      R1 = '0;
      R2 = '0;
      R3 = '0;

    end 

    pixels_calc[3] = sobel_convolution(R1, R2, R3);

  end


  // Calculate the second most left pixel 
  // SPECIAL CASES: when at top / bottom row
  always_comb begin

    pixel [2:0] R1, R2, R3;

    R1 = R1_pixels[4:2];
    R2 = R2_pixels[4:2];
    R3 = R2_pixels[4:2];

    if(LEFT_special) begin // needs to be reworked with edge cases

    end 
    
    pixels_calc[2] = sobel_convolution(R1, R2, R3);

  end


  // Calculate the second most right pixel
  // SPECIAL CASES: when at top / bottom row
  always_comb begin

    pixel [2:0] R1, R2, R3;

    R1 = R1_pixels[3:1];
    R2 = R2_pixels[3:1];
    R3 = R2_pixels[3:1];

    if(LEFT_special) begin // needs to be reworked with edge cases

    end 

    pixels_calc[1] = sobel_convolution(R1, R2, R3);

  end


  // Calculate the rightmost pixel
  // SPECIAL CASES: when at top / bottom row AND when calculating rightmost pixel
  always_comb begin

    pixel [2:0] R1, R2, R3;

    R1 = R1_pixels[2:0];
    R2 = R2_pixels[2:0];
    R3 = R2_pixels[2:0];

    if(LEFT_special) begin // needs to be reworked with edge cases

      R1 = '0;
      R2 = '0;
      R3 = '0;

    end 

    pixels_calc[0] = sobel_convolution(R1, R2, R3);

  end


  // Assign calculated pixels to output pixels based on special cases

  always_comb begin

    // default

    pixels_out = pixels_calc;

    if(LEFT_special) begin // needs to be reworked with edge cases

      pixels_out[3] = pixels_calc[0];
      pixels_out[2] = pixels_calc[3];
      pixels_out[1] = pixels_calc[2];
      pixels_out[0] = pixels_calc[1];

    end 

  end



endmodule