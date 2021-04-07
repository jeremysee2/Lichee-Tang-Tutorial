`include "Seven_Segment_Display.v"
`include "Fibonacci_Series.v"

module Seven_Segment_Display_Top (
    input wire clk,
    input wire RST_N,
    output wire [3:0] Cathode,
    output wire [6:0] Segment_out
    );

    // Signal to send number to Seven_Segment_Display module
    wire [15:0] Displayed_number;

    // For modification during simulation later
    parameter startRefreshCounter = 14;
    parameter endRefreshCounter = 15;

    // Frequency of master clock
    parameter time1 = 25'd24_000_000;  // 24 MHz counter

    // Slow clock divider
    reg [24:0] count = 24'b0;
    reg clk_slow = 1'b0;

    // Slow clock to increment number displayed
    always @(posedge clk) begin
        // Code for reset
        if(RST_N==0) begin			
            count <= 25'd0;
            clk_slow <= 1'b0;
        end
        if(count == time1) begin
            count <= 25'd0;
            clk_slow <= ~clk_slow;      
            end
        else begin 
            count <= count + 1'b1;
            end
        end

    // Creating Fibonacci_Series instance
    Fibonacci_Series i1
    (
        .CLK_IN(clk_slow),
        .RST_N(RST_N),
        .SEQUENCE(Displayed_number)
    );

    // Creating 4-digit seven segment display instance
    Seven_Segment_Display #(
        .startRefreshCounter(startRefreshCounter),
        .endRefreshCounter(endRefreshCounter)
    ) Seven_Segment_Display_inst
    (
        .clk(clk),
        .RST_N(RST_N),
        .Displayed_number(Displayed_number),
        .Cathode(Cathode),
        .Segment_out(Segment_out)
    );

endmodule