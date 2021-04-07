`timescale 1ns/1ns
`include "SwitchesToLEDs.v"

module SwitchesToLEDs_tb;
	reg i_Switch_1;
    reg i_Switch_2;
    wire o_LED_1;
    wire o_LED_2;
    wire o_LED_3;
    wire o_LED_4;
    
    // Instantiating module to test
    SwitchesToLEDs uut(
    	.i_Switch_1(i_Switch_1),
        .i_Switch_2(i_Switch_2),
        .o_LED_1(o_LED_1),
        .o_LED_2(o_LED_2),
        .o_LED_3(o_LED_3),
        .o_LED_4(o_LED_4)
    );
    
    initial begin
    	// Define testbench behaviour
        $dumpfile("SwitchesToLEDs_tb.vcd");
        $dumpvars(0, SwitchesToLEDs_tb);
        
        // Test conditions
        for (integer i=0; i<4; i = i+1) begin
        	{i_Switch_1, i_Switch_2} = i;
            #10;
        end
        
        $display("Test completed!");
    end
    
endmodule