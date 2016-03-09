module coeff_ROM(clk,addr,dout);

input clk;				
input [5:0] addr;		// select 1 of 32 entries
output reg [7:0] dout;	// coefficient out

  reg [7:0] rom[63:0];
  
  //In coeff.txt, every 4 lines is 100 times the value of cos, sin, -sin, and cos for an angle\
  //Angles are (in degrees) - 3, 15, 30, 45, 60, 75, 90, 180
                        // - -3,-15,-30,-45,-60,-75,-90,-180
  initial
    $readmemh("coeff.txt",rom);		// Read coefficients
  
  always @(posedge clk)
    dout <= rom[addr];
	
endmodule
