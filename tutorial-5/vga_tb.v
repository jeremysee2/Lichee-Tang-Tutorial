`timescale 1ns/1ns
`include "vga.v"

module vga_tb;
    
    // Generate clock 25MHz
    always #20 clk <= ~clk;
    wire vgaclk;
    wire rst = 1'b1;

    // VGA signals
    wire [2:0] VGA_R, VGA_G, VGA_B;
    wire o_VGA_HSync, o_VGA_VSync;

    vga #(
        .c_COLOUR_BITS(3),
        .c_HPIXELS(11'd640),
        .c_HSYNCS (11'd656),
        .c_HSYNCE (11'd752),
        .c_HMAX   (11'd800),
        .c_VPIXELS(11'd480),
        .c_VSYNCS (11'd490),
        .c_VSYNCE (11'd492),
        .c_VMAX   (11'd525),
        .c_COUNTER_WIDTH(10)
    ) UUT (
        .SYS_CLK (clk), // 24MHz
        .SYS_RST (rst),
        .VGA_R (VGA_R),
        .VGA_G (VGA_G),
        .VGA_B (VGA_B),
        .VGA_H (o_VGA_HSync),
        .VGA_V (o_VGA_VSync),
        .VGA_CLK (vgaclk)
    );

    initial begin
        $dumpfile("vga_tb.vcd");
        $dumpvars(0, vga_tb);

        #5000;
        $finish();
        $display("end of test");
    end

endmodule