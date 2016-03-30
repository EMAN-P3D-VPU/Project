module coeff_ROM(clk,addr,c1,c2,c3,c4);

input clk;				
input [5:0] addr;		// select 1 of 32 entries
output reg [15:0] c1, c2, c3, c4;

  reg [15:0] rom[63:0];
  
  //In coeff.txt, every 4 lines is 100 times the value of cos, -sin, sin, and cos for an angle\
  //Angles are (in degrees) - 3, 15, 30, 45, 60, 75, 90, 180
                        // - -3,-15,-30,-45,-60,-75,-90,-180
  initial
    $readmemh("coeff.txt",rom);		// Read coefficients
  
  always @(posedge clk) begin
    c1 <= rom[addr];
    c2 <= rom[addr+1];
    c3 <= rom[addr+2];
    c4 <= rom[addr+3];
  end
	
endmodule
