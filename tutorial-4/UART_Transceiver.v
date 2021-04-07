`include "UART_RX.v"
`include "UART_TX.v"
`include "fifo_memory.v"
`include "lower_to_upper.v"

module UART_Transceiver (
    input i_Clock,
    input i_Reset,
    input i_RX_Serial,
    output o_TX_Serial,
    output o_TX_Done
    );
    
    // Board uses a 24 MHz clock
    // Want to interface to 115200 baud UART
    // 24000000 / 115200 = 208 Clocks Per Bit.
    parameter CLOCK_PERIOD_NS = 41;
    parameter CLKS_PER_BIT    = 208;
    parameter BIT_PERIOD      = 8600;
    parameter FIFO_DEPTH      = 7;
    parameter FIFO_WIDTH      = 7;

    // UART RX signals
    wire UART_RX_Data_Valid;
    wire [7:0] UART_RX_Byte;

    // UART_RX instance
    UART_RX #(.CLKS_PER_BIT(CLKS_PER_BIT)) UART_RX_INST
       (.i_Clock(i_Clock),
        .i_Reset(i_Reset),
        .i_RX_Serial(i_RX_Serial),
        .o_RX_Data_Valid(UART_RX_Data_Valid),
        .o_RX_Byte(UART_RX_Byte)
        );

    // FIFO signals
    wire fifo_Write_En;
    wire fifo_Read_En;
    wire [7:0] fifo_Data_In;
    wire [7:0] fifo_Data_Out;
    wire fifo_full;
    wire fifo_empty;
    wire fifo_overflow;
    wire fifo_underflow;

    assign fifo_Data_In  = UART_RX_Byte;
    assign fifo_Write_En = UART_RX_Data_Valid ? 1'b1 : 1'b0;
    assign fifo_Read_En = l2u_write_enable;


    // FIFO instance
    fifo_memory #(
        .c_DEPTH(FIFO_DEPTH),
        .c_WIDTH(FIFO_WIDTH)
    ) fifo_memory_instance (
        .i_Clock(i_Clock),
        .i_Reset(i_Reset),
        .i_Write_En(fifo_Write_En),
        .i_Read_En(fifo_Read_En),
        .i_Data_In(fifo_Data_In),
        .o_Data_Out(fifo_Data_Out),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty),
        .fifo_overflow(fifo_overflow),
        .fifo_underflow(fifo_underflow)
        );

    // Lower to Upper signals
    wire [7:0] l2u_data_in;
    wire [7:0] l2u_data_out;
    wire l2u_write_enable;
    wire l2u_read_enable;

    assign l2u_data_in      = fifo_Data_Out;

    // Lower to Upper instance
    lower_to_upper lower_to_upper_instance(
        .i_Clock(i_Clock),
        .i_Reset(i_Reset),
        .i_Data_Empty(fifo_empty),
        .i_data(l2u_data_in),
        .o_data(l2u_data_out),
        .o_write_enable(l2u_write_enable),
        .o_read_enable(l2u_read_enable)
        );

    // UART TX signals
    wire UART_TX_DV;
    wire [7:0] UART_TX_Byte;
    // wire UART_TX_Active;

    // Check if data is ready to be read from l2u
    assign UART_TX_Byte = l2u_data_out;
    assign UART_TX_DV = l2u_read_enable;

    // UART TX instance
    UART_TX #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) UART_TX_Inst (
        .i_Clock(i_Clock),
        .i_Reset(i_Reset),
        .i_TX_DV(UART_TX_DV),
        .i_TX_Byte(UART_TX_Byte),
        .o_TX_Active(),
        .o_TX_Serial(o_TX_Serial),
        .o_TX_Done(o_TX_Done)
        );

endmodule