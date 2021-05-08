// Verilog testbench created by TD v4.6.18154
// 2002-10-22 12:35:22

`timescale 1ns / 1ps

module vga_top_tb();

reg clk;
reg rst;
wire [2:0] B;
wire [2:0] G;
wire [2:0] R;
wire o_VGA_HSync;
wire o_VGA_VSync;

//Clock process
parameter PERIOD = 10;
always #(PERIOD/2) clk = ~clk;

//glbl Instantiate
glbl glbl();

//Unit Instantiate
vga_top uut(
	.clk(clk),
	.rst(rst),
	.B(B),
	.G(G),
	.R(R),
	.o_VGA_HSync(o_VGA_HSync),
	.o_VGA_VSync(o_VGA_VSync));

//Stimulus process
initial begin
//To be inserted
end

endmodule