`include "UART_Transceiver.v"
`timescale 1ps/1ps

module UART_Transceiver_tb();
    // Test signals
    reg r_Clock;
    reg r_Reset;
    reg r_RX_Serial;
    wire w_TX_Serial;
    wire w_TX_Done;

    // Testbench signals
    wire w_RX_Byte;
    reg  r_RX_Byte;
    reg [7:0] r_Task_UART_Read_DATA = 8'b0;
    reg r_Task_UART_Read_START = 1;
    reg r_Task_UART_Read_STOP = 0;

    parameter c_CLOCK_PERIOD_NS = 40; //40
    parameter c_CLKS_PER_BIT    = 208; //208
    parameter c_BIT_PERIOD      = 8600; //8600
    parameter c_FIFO_DEPTH      = 7;
    parameter c_FIFO_WIDTH      = 7;

    // Instantiate top module
    UART_Transceiver UUT (
        .i_Clock(r_Clock),
        .i_Reset(r_Reset),
        .i_RX_Serial(r_RX_Serial),
        .o_TX_Serial(w_TX_Serial),
        .o_TX_Done(w_TX_Done)
        );

    // Takes in input byte and serializes it 
    task UART_WRITE_BYTE;
    input [7:0] i_Data;
    integer     ii;
    begin
        // Send Start Bit
        r_RX_Serial <= 1'b0;
        #(c_BIT_PERIOD);
        #(c_BIT_PERIOD/8);
        
        // Send Data Byte
        for (ii=0; ii<8; ii=ii+1)
        begin
            r_RX_Serial <= i_Data[ii];
            #(c_BIT_PERIOD);
        end
        
        // Send Stop Bit
        r_RX_Serial <= 1'b1;
        #(c_BIT_PERIOD);
        end
    endtask // UART_WRITE_BYTE

    // Takes in input UART and deserializes it 
    task UART_READ_BYTE;
    integer     iii;
    begin
        // Read Start Bit
        r_Task_UART_Read_START <= w_TX_Serial;
        // #(c_BIT_PERIOD);
        #1000;
        
        // Read Data Byte
        for (iii=0; iii<8; iii=iii+1)
        begin
            r_Task_UART_Read_DATA[iii] <= w_TX_Serial;
            #(c_BIT_PERIOD);
        end
        
        // Read Stop Bit
        r_Task_UART_Read_STOP <= w_TX_Serial;
        #(c_BIT_PERIOD);
        end


    endtask // UART_READ_BYTE

    always #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;

    initial begin
        r_Task_UART_Read_START = 0;
        r_Task_UART_Read_STOP  = 0;
        r_Task_UART_Read_DATA  = 8'b0;
        r_RX_Serial = 1;
        r_Reset = 1;
        r_Clock = 0;

        // Initialise module through reset
        r_Reset = ~r_Reset;
        @(posedge r_Clock);
        r_Reset = ~r_Reset;
        @(posedge r_Clock);
        
        // Send a command to the UART (exercise Rx)
        @(posedge r_Clock);
        UART_WRITE_BYTE(8'h61); // 'a' in ASCII
        @(posedge r_Clock);
            
        // Check that the correct command was received
        @(posedge r_Clock);
        UART_READ_BYTE();
        @(posedge r_Clock);
        if (r_Task_UART_Read_DATA == 8'h41) // 'A' in ASCII
        $display("Test Passed - Correct Byte Received");
        else
        $display("Test Failed - Incorrect Byte Received, 0x%0h",r_Task_UART_Read_DATA);

        $finish();
    end

  
    initial 
    begin
        // Required to dump signals
        $dumpfile("dump.vcd");
        $dumpvars(0);
    end


endmodule