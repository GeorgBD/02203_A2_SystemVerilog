
// Purely combinational edge detector unit. 
// Utilizes Sobel convolution masks for computing UP TO 4 pixels at one time.
// Handles special cases (when at edges of picture)

import task2_pkg::*;

module edge_detector #(

  parameter M_X_IT = WORDS_PR_LINE-1,   // Maximum number of X iterations per row (words pr. line)
  parameter M_Y_IT = NUM_ROWS-1         // Maximum number of Y iterations (number of rows)

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

  function pixel sobel_convolution(

    input pixel [3:1] R1,
    input pixel [3:1] R2,
    input pixel [3:1] R3

  );
    logic signed [9:0] Dx;
    logic signed [9:0] Dy;
    logic [10:0] D_abs;

    // Compute Dx(n) - equation (4)

    assign Dx = $signed({2'b0, R1[3]}) - $signed({2'b0, R1[1]}) + 
                (($signed({2'b0, R2[3]}) - $signed({2'b0, R2[1]})) <<< 1 ) + 
                $signed({2'b0, R3[3]}) - $signed({2'b0, R3[1]});

    // Compute Dy(n) - equation (5)
    
    assign Dy = $signed({2'b0, R1[1]}) - $signed({2'b0, R3[1]}) + 
                (($signed({2'b0, R1[2]}) - $signed({2'b0, R3[2]})) <<< 1 )  + 
                $signed({2'b0, R1[3]}) - $signed({2'b0, R3[3]});

    // Compute |D(n)| - equation (6)
    assign D_abs = (Dx[9] ? -Dx : Dx) + (Dy[9] ? -Dy : Dy);

    //Saturate or truncate - NOTE: probably not correct to always just truncate
    if (D_abs > (2**PW - 1)) 
      return {PW{1'b1}};  // Saturate to max value
    else
      return D_abs[PW-1:0];  // Return lower bits

    // ANSWER: DO NEITHER - INSTEAD JUST SHIFT THE RESULT DOWN (ALWAYS) - ELSE TOO WHITE
    // return (D_abs[10:3] + D_abs[10:5]);

    // Comment everything else and uncomment this to do pass-through test
    //return R2[2];  // Center of 3x3 window
  endfunction

  // Special cases:
  // 1. Edges - TOP, BOTTOM, LEFT, RIGHT
  // 2. First iteration of every loop for every row - only calc 2 pixels (with 4 valid input pixels)

  // Signals for determining if in special case
  logic TOP_special, BOT_special, LEFT_special, RIGHT_special; // for handling the edges

  assign LEFT_special   = X_IT == 'd0      ?    1 : 0;       
  assign RIGHT_special  = X_IT == M_X_IT   ?    1 : 0;        
  assign BOT_special    = Y_IT == M_Y_IT   ?    1 : 0;
  assign TOP_special    = Y_IT == 'd0      ?    1 : 0;

  pixel [3:0] pixels_calc;    // Can at most calculate 4 pixels in parallel

  // Calculate the rightmost pixel
  // SPECIAL CASES: when at top / bottom row AND when calculating leftmost pixel
  always_comb begin

    pixel [2:0] R1, R2, R3;

    R1 = R1_pixels[5:3];
    R2 = R2_pixels[5:3];
    R3 = R3_pixels[5:3];

    pixels_calc[3] = sobel_convolution(R1, R2, R3);

  end

  // Calculate the second most right pixel 
  // SPECIAL CASES: when at top / bottom row
  always_comb begin

    pixel [2:0] R1, R2, R3;

    R1 = R1_pixels[4:2];
    R2 = R2_pixels[4:2];
    R3 = R3_pixels[4:2];

    if(LEFT_special) begin // needs to be reworked with edge cases

    end 
    
    pixels_calc[2] = sobel_convolution(R1, R2, R3);

  end


  // Calculate the second most left pixel
  // SPECIAL CASES: when at top / bottom row
  always_comb begin

    pixel [2:0] R1, R2, R3;

    R1 = R1_pixels[3:1];
    R2 = R2_pixels[3:1];
    R3 = R3_pixels[3:1];

    if(LEFT_special) begin // needs to be reworked with edge cases

    end 

    pixels_calc[1] = sobel_convolution(R1, R2, R3);

  end


  // Calculate the leftmost pixel
  // SPECIAL CASES: when at top / bottom row AND when calculating rightmost pixel
  always_comb begin

    pixel [2:0] R1, R2, R3;

    R1 = R1_pixels[2:0];
    R2 = R2_pixels[2:0];
    R3 = R3_pixels[2:0];

    pixels_calc[0] = sobel_convolution(R1, R2, R3);

  end


  // Assign calculated pixels to output pixels based on special cases

  always_comb begin

    // default

    pixels_out = pixels_calc;

    if(LEFT_special) begin // needs to be reworked with edge cases

      pixels_out[0] = pixels_calc[3];
      pixels_out[3] = pixels_calc[2];
      pixels_out[2] = pixels_calc[1];
      pixels_out[1] = pixels_calc[0];

    end 

  end



endmodule