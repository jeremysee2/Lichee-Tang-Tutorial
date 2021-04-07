module fifo_memory (
    input i_Clock,
    input i_Reset,
    input i_Write_En,
    input i_Read_En,
    input  [c_WIDTH:0] i_Data_In,
    output [c_WIDTH:0] o_Data_Out,
    output reg fifo_full,
    output reg fifo_empty,
    output reg fifo_overflow,
    output reg fifo_underflow
    );

    // Internal memory, 7 16-bit wide registers
    parameter c_DEPTH = 7;
    parameter c_WIDTH = 7;
    reg [c_WIDTH:0] memory [0:c_DEPTH];
    reg [c_DEPTH:0]  wraddr = 0;
    reg [c_DEPTH:0]  rdaddr = 0;
    reg [c_WIDTH:0] r_Data_Out;

    // Writing to FIFO
    always @(posedge i_Clock) begin
        if (i_Write_En) begin
            memory[wraddr] <= i_Data_In;

            // Incrementing wraddr pointer
            if ((!fifo_full) || (i_Read_En)) begin
                wraddr <= wraddr + 1'b1;
                fifo_overflow <= 1'b0;
            end
            else
                fifo_overflow <= 1'b1;
        end
    end

    // Reading from FIFO
    always @(posedge i_Clock) begin
        if (i_Read_En) begin
            r_Data_Out <= memory[rdaddr];

            // Incrementing raddr pointer
            if (!fifo_empty) begin
                rdaddr <= rdaddr + 1'b1;
                fifo_underflow <= 1'b0;
            end
            else
                fifo_underflow <= 1'b1;
        end
    end

    assign o_Data_Out = r_Data_Out;

    // Calculating full/empty flags, referenced from zipcpu.com
    wire	[c_DEPTH:0]	dblnext, nxtread;
    assign	dblnext = wraddr + 2;
    assign	nxtread = rdaddr + 1'b1;

    always @(posedge i_Clock, negedge i_Reset)
        // Reset case
        if (!i_Reset)
        begin
            // Reset output flags
            fifo_full <= 1'b0;
            fifo_empty <= 1'b1;
            
            // Reset internal signals
            wraddr <= 0;
            rdaddr <= 0;
            r_Data_Out <= 0;
        end else casez({ i_Write_En, i_Read_En, !fifo_full, !fifo_empty })
        4'b01?1: begin	// A successful read
            fifo_full  <= 1'b0;
            fifo_empty <= (nxtread == wraddr);
        end
        4'b101?: begin	// A successful write
            fifo_full <= (dblnext == rdaddr);
            fifo_empty <= 1'b0;
        end
        4'b11?0: begin	// Successful write, failed read
            fifo_full  <= 1'b0;
            fifo_empty <= 1'b0;
        end
        4'b11?1: begin	// Successful read and write
            fifo_full  <= fifo_full;
            fifo_empty <= 1'b0;
        end
        default: begin end
        endcase
    
endmodule