module Fibonacci_Series ( 
    input wire CLK_IN,
    input wire RST_N,
    output wire [15:0] SEQUENCE
    );

    reg [15:0] SEQUENCE_I1,SEQUENCE_I2;

    assign SEQUENCE = RST_N ? (SEQUENCE_I1 + SEQUENCE_I2) : 16'b1;

    always @(posedge CLK_IN) begin 
        if(SEQUENCE < 16'hDAAA) begin 
            SEQUENCE_I2 = SEQUENCE_I1;
            SEQUENCE_I1 = SEQUENCE;
        end 
        else begin 
            SEQUENCE_I2 = 16'b1;
            SEQUENCE_I1 = 16'b0;
        end 
    end 
endmodule