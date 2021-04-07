`timescale 1ns/1ns
`include "fifo_memory.v"

module fifo_memory_tb ();
    
    // Test signals
    reg r_Clock = 0;
    reg r_Reset = 1;
    reg r_Write_En = 0;
    reg r_Read_En = 0;
    reg  [15:0] r_Data_In = 0;
    wire [15:0] w_Data_Out;
    wire w_fifo_full;
    wire w_fifo_empty;
    wire w_fifo_overflow;
    wire w_fifo_underflow;

    parameter c_CLOCK_PERIOD_NS = 10;


    // Instantiate module
    fifo_memory #(
        .c_DEPTH(7),
        .c_WIDTH(15)
    ) UUT (
        .i_Clock(r_Clock),
        .i_Reset(r_Reset),
        .i_Write_En(r_Write_En),
        .i_Read_En(r_Read_En),
        .i_Data_In(r_Data_In),
        .o_Data_Out(w_Data_Out),
        .fifo_full(w_fifo_full),
        .fifo_empty(w_fifo_empty),
        .fifo_overflow(w_fifo_overflow),
        .fifo_underflow(w_fifo_underflow)
        );

    // Testbench logic
    always
        #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;

    // Main Testing:
    initial
    begin
        // Initialise module through reset
        r_Reset = ~r_Reset;
        #10
        r_Reset = ~r_Reset;
        #10

        // Write two bytes
        r_Data_In  <= 16'hBEEF;
        r_Write_En <= 1'b1;
        #10;
        r_Write_En <= 1'b0;
        r_Read_En  <= 1'b1;
        #10
        // Check that the correct data was received
        if (w_Data_Out == 16'hBEEF)
        $display("Test Passed - Correct two bytes received");
        else
        $display("Test Failed - Incorrect two bytes received");
        

        // Try overflowing it
        r_Write_En <= 1'b0;
        r_Read_En  <= 1'b0;

        for (integer i = 16'h0; i < 16'h1FF; i = i + 1'b1) begin
            r_Data_In  <= i;
            r_Write_En <= 1'b1;
            #10;
        end
        r_Write_En <= 1'b0;
        r_Read_En  <= 1'b0;
        if (w_fifo_overflow)
        $display("Test Passed - Overflow flag works");
        else
        $display("Test Failed - Overflow flag failed");


        // Try underflowing it
        r_Write_En <= 1'b0;
        r_Read_En  <= 1'b0;

        for (integer i = 16'h0; i < 16'h2FF; i = i + 1'b1) begin
            r_Read_En <= 1'b1;
            #10;
        end
        r_Write_En <= 1'b0;
        r_Read_En  <= 1'b0;
        if (w_fifo_underflow)
        $display("Test Passed - Underflow flag works");
        else
        $display("Test Failed - Underflow flag failed");
        $finish();
    end

    initial 
    begin
    // Required to dump signals
    $dumpfile("dump.vcd");
    $dumpvars(0);
    end

endmodule