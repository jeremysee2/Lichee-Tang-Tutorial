/**
	Adapted from piotr-go's Lichee-Tang repository on Github @ https://github.com/piotr-go/Lichee-Tang
*/

`timescale 1 ps / 1 ps

module vga 
#(
	parameter c_COLOUR_BITS = 3,
	parameter c_HPIXELS = 11'd640,
	parameter c_HSYNCS  = 11'd656,
	parameter c_HSYNCE  = 11'd752,
	parameter c_HMAX    = 11'd800,
	parameter c_VPIXELS = 11'd480,
	parameter c_VSYNCS  = 11'd490,
	parameter c_VSYNCE  = 11'd492,
	parameter c_VMAX    = 11'd525,
	parameter c_COUNTER_WIDTH = 10
)

(
	input  wire SYS_CLK, // 24MHz
	input  wire SYS_RST,
	output wire [c_COLOUR_BITS-1:0] VGA_R,
	output wire [c_COLOUR_BITS-1:0] VGA_G,
	output wire [c_COLOUR_BITS-1:0] VGA_B,
	output wire VGA_H,
	output wire VGA_V,
	output wire VGA_CLK
);
	// PLL signal and VGA clock
	wire bufpll_lock, pclk;
	
	// generate clock of 25.175MHz
	ip_pll pll
	(
		.refclk		(SYS_CLK),
		.reset		(~SYS_RST),
		.extlock	(bufpll_lock),
		.clk0_out	(pclk)
		);

	// Wires to count pixel position
	wire [c_COUNTER_WIDTH-1:0] bgnd_hcount;
	wire [c_COUNTER_WIDTH-1:0] bgnd_vcount;
	wire H, V, de;

	video_gen #(  //640x480@60Hz HSYNC VSYNC Generator
		.HPIXELS (c_HPIXELS),
		.HSYNCS  (c_HSYNCS),
		.HSYNCE  (c_HSYNCE),
		.HMAX    (c_HMAX),
		.VPIXELS (c_VPIXELS),
		.VSYNCS  (c_VSYNCS),
		.VSYNCE  (c_VSYNCE),
		.VMAX    (c_VMAX),
		.COUNTER_WIDTH (c_COUNTER_WIDTH)

		) video_gen_inst
		(
		.rst(SYS_RST),
		.clk(pclk),
		.hcount(bgnd_hcount),
		.vcount(bgnd_vcount),
		.picture(de),
		.hsync(H),
		.vsync(V)
		);
	
	// RGB Data bus
	reg [7:0] red_data, green_data, blue_data;

	always @(posedge pclk) begin
		//if(bgnd_hcount < 64 || bgnd_hcount >= 576 || bgnd_vcount < 8 || bgnd_vcount >= 472) begin
		if (1'b0) begin
			red_data <= 128;
			green_data <= 128;
			blue_data <= 128;
		end
		else begin
			red_data <= 255 - ((bgnd_vcount+32)>>1);
			green_data <= ((bgnd_hcount-64)>>1);
			blue_data <= ((bgnd_vcount+32)>>1);
		end
	end

	assign VGA_R = de ? red_data[7:5] : 3'b0;
	assign VGA_G = de ? green_data[7:5] : 3'b0;
	assign VGA_B = de ? blue_data[7:5] : 3'b0;
	assign VGA_H = H;
	assign VGA_V = V;
	assign VGA_CLK = pclk;
	
endmodule



/**
	Generate HSYNC and VSYNC for VGA
*/
module video_gen
	#( //640x480@60Hz
	parameter HPIXELS = 11'd640,
	parameter HSYNCS  = 11'd656,
	parameter HSYNCE  = 11'd720,
	parameter HMAX    = 11'd834 - 11'd1,
	parameter VPIXELS = 11'd480,
	parameter VSYNCS  = 11'd481,
	parameter VSYNCE  = 11'd484,
	parameter VMAX    = 11'd500 - 11'd1,
	parameter COUNTER_WIDTH = 10
	)

	(
	input  wire 	   rst,
	input  wire        clk,

	output wire [COUNTER_WIDTH-1:0] hcount, 	// counter to note which pixel currently at
	output wire [COUNTER_WIDTH-1:0] vcount,
	output wire        picture, // HIGH when in active zone, LOW when in inactive zone

	output wire        hsync,
	output wire        vsync
	);

	reg [COUNTER_WIDTH-1:0] hcnt;
	reg [COUNTER_WIDTH-1:0] vcnt;

	assign picture = (hcnt < HPIXELS) && (vcnt < VPIXELS);
	assign hsync = ~((hcnt > HSYNCS) && (hcnt <= HSYNCE)); // HSYNC low for sync pulse
	assign vsync = ~((vcnt > VSYNCS) && (vcnt <= VSYNCE)); // VSYNC low for sync pulse
	assign hcount = hcnt;
	assign vcount = vcnt;

	always @ (posedge clk) begin
		if (hcnt<HMAX)
			hcnt <= hcnt + 11'd1;
		else if (~rst) begin
			hcnt <= 0;
			vcnt <= 0;
		end
		else begin
			hcnt <= 11'd0;
			if (vcnt<VMAX)
				vcnt <= vcnt + 11'd1;
			else
				vcnt <= 11'd0;
		end
	end
endmodule



/**
	PLL IP module to generate VGA clock
*/
module ip_pll(refclk,
		reset,
		extlock,
		clk0_out);

	input refclk;
	input reset;
	output extlock;
	output clk0_out;

	wire clk0_buf;

	EG_LOGIC_BUFG bufg_feedback( .i(clk0_buf), .o(clk0_out) );

	EG_PHY_PLL #(.DPHASE_SOURCE("DISABLE"),
		.DYNCFG("DISABLE"),
		.FIN("24.000"),
		.FEEDBK_MODE("NORMAL"),
		.FEEDBK_PATH("CLKC0_EXT"),
		.STDBY_ENABLE("DISABLE"),
		.PLLRST_ENA("ENABLE"),
		.SYNC_ENABLE("ENABLE"),
		.DERIVE_PLL_CLOCKS("DISABLE"),
		.GEN_BASIC_CLOCK("DISABLE"),
		.GMC_GAIN(6),
		.ICP_CURRENT(3),
		.KVCO(6),
		.LPF_CAPACITOR(3),
		.LPF_RESISTOR(2),
		.REFCLK_DIV(24),
		.FBCLK_DIV(25),
		.CLKC0_ENABLE("ENABLE"),
		.CLKC0_DIV(30),
		.CLKC0_CPHASE(30),
		.CLKC0_FPHASE(0)	)
	pll_inst (.refclk(refclk),
		.reset(reset),
		.stdby(1'b0),
		.extlock(extlock),
		.psclk(1'b0),
		.psdown(1'b0),
		.psstep(1'b0),
		.psclksel(3'b000),
		.psdone(open),
		.dclk(1'b0),
		.dcs(1'b0),
		.dwe(1'b0),
		.di(8'b00000000),
		.daddr(6'b000000),
		.do({open, open, open, open, open, open, open, open}),
		.fbclk(clk0_out),
		.clkc({open, open, open, open, clk0_buf}));

endmodule
