module coeff_ROM(clk,addr,c1,c2,c3,c4);

input clk;				
input [3:0] addr;		// select 1 of 16 entries
output reg [15:0] c1, c2, c3, c4;

  reg [63:0] rom[15:0];
  
  //In coeff.txt, every line is 2^15 times the value of cos, -sin, sin, and cos for an angle\
  //Angles are (in degrees) : 3, 15, 30, 45, 60, 75, 90, 180
                        //  :-3,-15,-30,-45,-60,-75,-90,-180
  initial
    $readmemh("coeff_new.txt",rom);		// Read coefficients
    //$readmemh("/userspace/p/procek/554_eMan_Final/Project/VPU_RTL/coeff_new.txt",rom);		// Read coefficients
  
  always @(posedge clk) begin
    c1 <= rom[addr][63:48];
    c2 <= rom[addr][47:32];
    c3 <= rom[addr][31:16];
    c4 <= rom[addr][15:0];
  end
	
endmodule
