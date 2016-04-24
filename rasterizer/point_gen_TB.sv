//TESTS COORDINATE GENERATION IN QUADRANT 1 AND 2
module point_gen_TB ();

reg clk, rst;
reg [68:0] CAP_REG;
reg pos_or_neg;

//regs to contain all line info
//Y = mX (+b)
real x0, y0, x1, y1, d0, d1, diff, Xf, new_x, new_y;
real rDX, rDY;
real slope, Yf;

assign rDX = x1 - x0;
assign rDY = y1 - y0;
assign slope = rDY/rDX;
assign Yf = Xf * slope;
assign d0 = (pos_or_neg) ? (y0 - Yf) :(y0 + 1) - Yf;
assign d1 = (pos_or_neg) ? ((Yf) - (y0 - 1)):Yf - y0;
assign diff = d0 - d1;

point_gen POINT_GEN(.x_i(CAP_REG[68:59]), .y_i(CAP_REG[58:49]), .dy(CAP_REG[28:18]), .dx(CAP_REG[17:7]), .p_or_n(CAP_REG[0]), .Xn(new_x), .Yn(new_y));




always
  #10 clk = ~clk;

always @(posedge clk)
begin

  CAP_REG[68:59] = new_x;
  CAP_REG[58:49] = new_y;


end

initial 
begin

  //init clk
  clk = 0;
  pos_or_neg = 1;
//begining parameters
//slope should be 1/2
  x0 = 0;
  y0 = 0;
  x1 = 100;
  y1 = -50;

  #20 

  #20

  //set the cap reg to be the same values
  CAP_REG[0] = pos_or_neg;; //positive version
  CAP_REG[68:59] = x0;
  CAP_REG[58:49] = y0; 
  CAP_REG[28:18] = rDY;
  CAP_REG[17:7]  = rDX;


  
    for(x0 = 0; x0 < x1; x0++)
    begin
      //x_i + 1
      Xf = x0 + 1;
      @(posedge clk)
      begin
        $display("REAL Y = mX :: Y = %f", Yf);
        $display("d0: %d, d1: %d", d0, d1);
        if(pos_or_neg)
        begin
          if((diff) >= 0)
            y0 = y0 - 1;
        end
        else
        begin
          if((diff) < 0)
            y0 = y0 + 1;
        end

        $display("[CAP REG] generated x: %d, generated y: %d", CAP_REG[68:59], $signed(CAP_REG[58:49]));
        $display("[GOLDEN] generated x: %d, generated y: %d", x0 + 1, y0);

        if((CAP_REG[68:59] != x0 + 1) || ($signed(CAP_REG[58:49]) != y0))
        begin
          $display("DUT FAILED, UNEQUIVALENT POINTS GENERATED.",);
          $stop;
        end
    end

    end

    $display("finished simulation");
    $stop;

end

endmodule
