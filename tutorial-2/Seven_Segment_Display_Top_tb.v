`timescale 1ns/1ns
`include "Seven_Segment_Display_Top.v"

module Seven_Segment_Display_Top_tb ();

    // Test signals
    reg clk = 1'b0;
    reg RST_N = 1'b1;
    wire [3:0] Cathode;
    wire [6:0] Segment_out;

    // Instantiate the top module
    Seven_Segment_Display_Top #(
        // Change parameters for simulation purposes, to speed up changes
        .time1(2),
        .startRefreshCounter(0),
        .endRefreshCounter(1)
    ) uut
    (
        .clk(clk),
        .RST_N(RST_N),
        .Cathode(Cathode),
        .Segment_out(Segment_out)
    );

    initial begin
        // Define testbench behaviour
        $dumpfile("Seven_Segment_Display_Top_tb.vcd");
        $dumpvars(0, Seven_Segment_Display_Top_tb);

        // Test conditions
        for (integer i=0; i<100; i=i+1) begin
            // Pulse clock, 20 units per cycle
            clk = ~clk; #10;
        end
        $display("Test completed!");
    end

endmodule