`timescale 1ns/1ns
`include "vga_top.v"
`include "VGA_Sync_Porch.v"
`include "VGA_Sync_Pulses.v"
`include "Test_Pattern_Gen.v"

module vga_top_tb;
    
	// input clock
	reg clk = 1'b0;
	reg rst = 1'b1;
	
    parameter c_VIDEO_WIDTH = 3;
    parameter c_TOTAL_COLS  = 10;
    parameter c_TOTAL_ROWS  = 6;
    parameter c_ACTIVE_COLS = 8;
    parameter c_ACTIVE_ROWS = 4;

    wire [c_VIDEO_WIDTH-1:0] w_Red_Video_TP;
    wire [c_VIDEO_WIDTH-1:0] w_Grn_Video_TP;
    wire [c_VIDEO_WIDTH-1:0] w_Blu_Video_TP;

    // Generate clock
    always #20 clk <= ~clk;
	
	// VGA Connections
	wire [c_VIDEO_WIDTH-1:0] R;
	wire [c_VIDEO_WIDTH-1:0] G;
	wire [c_VIDEO_WIDTH-1:0] B;
	wire o_VGA_HSync;
	wire o_VGA_VSync;

    vga_top #(c_TOTAL_COLS, c_TOTAL_ROWS, c_ACTIVE_COLS, c_ACTIVE_ROWS, c_VIDEO_WIDTH) 
    UUT (clk, rst, R, G, B, o_VGA_HSync, o_VGA_VSync);

    initial begin
        $dumpfile("vga_top_tb.vcd");
        $dumpvars(0, vga_top_tb);

        #5000;
        $finish();
        $display("end of test");
    end

endmodule