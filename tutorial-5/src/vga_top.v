module vga_top
#(
	parameter c_TOTAL_COLS 			= 800,
	parameter c_TOTAL_ROWS    		= 525,
	parameter c_ACTIVE_COLS			= 640,
	parameter c_ACTIVE_ROWS 		= 480,
	parameter c_VIDEO_WIDTH 		= 3 // 3 bits per pixel
)

( 
	// 24MHz clock on board
	input wire clk,
	input wire rst,
	
	
	// VGA Connections
	output wire [c_VIDEO_WIDTH-1:0] R,
	output wire [c_VIDEO_WIDTH-1:0] G,
	output wire [c_VIDEO_WIDTH-1:0] B,
	output wire o_VGA_HSync,
	output wire o_VGA_VSync
);

	// Internal wires and registers
	// wire clk25mhz;
	// wire clk234mhz;

	// Internal R,G,B wires: VGA Signals
	wire [c_VIDEO_WIDTH-1:0] w_Red_Video_TP, w_Red_Video_Porch;
	wire [c_VIDEO_WIDTH-1:0] w_Grn_Video_TP, w_Grn_Video_Porch;
	wire [c_VIDEO_WIDTH-1:0] w_Blu_Video_TP, w_Blu_Video_Porch;

	// Create 234MHz and 25MHz clock using PLL IP
	// pll pllinst(
	//  	.refclk   (clk),
	//  	.reset    (~rst),
	//  	.stdby    (),
	//  	.extlock  (),
	//  	.clk0_out (clk25mhz),
	//  	.clk1_out (clk234mhz));
	
	// VGA_Sync_Pulses to generate HSYNC and VSYNC
	VGA_Sync_Pulses   #(  
		.TOTAL_COLS  (c_TOTAL_COLS), 
   		.TOTAL_ROWS  (c_TOTAL_ROWS),
   		.ACTIVE_COLS (c_ACTIVE_COLS), 
   		.ACTIVE_ROWS (c_ACTIVE_ROWS)
	) VGA_Sync_Pulses_Inst (
		.i_Clk (clk),
   		.o_HSync (w_HSync_Start),
   		.o_VSync (w_VSync_Start),
   		.o_Col_Count (), 
   		.o_Row_Count ()
  	);
  	
  	// Test pattern to generate R,G,B signals
	Test_Pattern_Gen  #(
		.VIDEO_WIDTH(c_VIDEO_WIDTH),
		.TOTAL_COLS(c_TOTAL_COLS),
		.TOTAL_ROWS(c_TOTAL_ROWS),
		.ACTIVE_COLS(c_ACTIVE_COLS),
		.ACTIVE_ROWS(c_ACTIVE_ROWS))
	Test_Pattern_Gen_Inst(
		.i_Clk(clk),
		.i_Pattern(4'h1), // color bars
		.i_HSync(w_HSync_Start),
		.i_VSync(w_VSync_Start),
		.o_HSync(w_HSync_TP),
		.o_VSync(w_VSync_TP),
		.o_Red_Video(w_Red_Video_TP),
		.o_Grn_Video(w_Grn_Video_TP),
		.o_Blu_Video(w_Blu_Video_TP));

	// Add inactive area to output HSYNC, VSYNC from test pattern
	VGA_Sync_Porch  #(
		.VIDEO_WIDTH(c_VIDEO_WIDTH),
		.TOTAL_COLS(c_TOTAL_COLS),
		.TOTAL_ROWS(c_TOTAL_ROWS),
		.ACTIVE_COLS(c_ACTIVE_COLS),
		.ACTIVE_ROWS(c_ACTIVE_ROWS))
	VGA_Sync_Porch_Inst(
		.i_Clk(clk),
		.i_HSync(w_HSync_TP),
		.i_VSync(w_VSync_TP),
		.i_Red_Video(w_Red_Video_TP),
		.i_Grn_Video(w_Grn_Video_TP),
		.i_Blu_Video(w_Blu_Video_TP),
		.o_HSync(w_HSync_Porch),
		.o_VSync(w_VSync_Porch),
		.o_Red_Video(w_Red_Video_Porch),
		.o_Grn_Video(w_Grn_Video_Porch),
		.o_Blu_Video(w_Blu_Video_Porch));

	// Send final signals to output pins
	assign o_VGA_HSync = w_HSync_Porch;
	assign o_VGA_VSync = w_VSync_Porch;
	
	assign R = w_Red_Video_Porch;
	assign G = w_Grn_Video_Porch;
	assign B = w_Blu_Video_Porch;

endmodule
