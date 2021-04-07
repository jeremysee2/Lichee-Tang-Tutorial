`timescale 1ps/1ps
`include "lower_to_upper.v"

module lower_to_upper_tb ();

    reg r_Clock = 0;
    reg r_Reset = 1;
    reg r_Data_Empty = 1;
    reg [7:0] r_data = 8'b0;
    wire [7:0] w_data_out;
    wire w_write_enable;
    wire w_read_enable;

    parameter c_CLOCK_PERIOD_NS = 10;
    
    lower_to_upper UUT (
        .i_Clock(r_Clock),
        .i_Reset(r_Reset),
        .i_Data_Empty(r_Data_Empty),
        .i_data(r_data),
        .o_data(w_data_out),
        .o_write_enable(w_write_enable),
        .o_read_enable(w_read_enable)
    );

    always #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;

    initial begin
        r_Data_Empty <= 0;
        r_data <= 8'h61;
        #(c_CLOCK_PERIOD_NS)

        if (w_data_out == 8'h41)
            $display("Test passed");
        else
            $display("Test failed, 0x%0h",w_data_out);
        
        
        $finish();

    end

    initial 
    begin
        // Required to dump signals
        $dumpfile("dump.vcd");
        $dumpvars(0);
    end

endmodule