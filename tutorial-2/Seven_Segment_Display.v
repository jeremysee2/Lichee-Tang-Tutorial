`include "Seven_Segment.v"

module Seven_Segment_Display (
    input wire clk,
    input wire RST_N,
    input wire [15:0] Displayed_number,
    output reg [3:0] Cathode,
    output wire [6:0] Segment_out
    );

    // For modification during simulation later
    parameter startRefreshCounter = 14;
    parameter endRefreshCounter = 15;

    wire [1:0] LED_activating_counter;
    reg [3:0] Digit_number;
    reg [15:0] refresh_counter = 16'b0;

    // Creating Seven_Segment instance
    Seven_Segment i2
    (
        .CLK_IN(clk),
        .NUMBER_IN(Digit_number),
        .OUTPUT(Segment_out[6:0])
    );

    // Switch between 4 digits of display
    always @(posedge clk or negedge RST_N)
        begin
            if (RST_N==0)
                refresh_counter <= 0;
            else
                refresh_counter <= refresh_counter + 1;
        end

    // every 24M / (2^14) hz switch to next digit in 7-seg display
    assign LED_activating_counter = refresh_counter[endRefreshCounter:startRefreshCounter];

    // select digit to light up
    always @(posedge clk) begin
            case(LED_activating_counter)
            2'b00: begin
                // pull to ground for first digit
                Cathode = 4'b1000;
                Digit_number <= Displayed_number[15:11];
            end
            2'b01: begin
                // pull to ground for second digit
                Cathode = 4'b0100;
                Digit_number <= Displayed_number[10:8];
            end	
            2'b10: begin
                // pull to ground for third digit
                Cathode = 4'b0010;
                Digit_number <= Displayed_number[7:4];
            end
            2'b11: begin
                // pull to ground for fourth digit
                Cathode = 4'b0001;
                Digit_number <= Displayed_number[3:0];
            end
            default: begin
                // pull to ground for default first digit
                Cathode <= 4'b1111;
                Digit_number <= 4'b1111;
            end
            endcase
        end
    
endmodule