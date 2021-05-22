module Seven_Segment (
	input wire CLK_IN,
	input wire [3:0]NUMBER_IN,
	output reg [6:0] OUTPUT
    );

	//  AAAA            AAAA    AAAA            AAAA    AAAA    AAAA    AAAA    AAAA    AAAA                            AAAA    AAAA
	// F    B       B       B       B  F    B  F       F            B  F    B  F    B  F    B  F                    B  F       F
	// F    B       B       B       B  F    B  F       F            B  F    B  F    B  F    B  F                    B  F       F
	//                  GGGG    GGGG    GGGG    GGGG    GGGG            GGGG    GGGG    GGGG    GGGG    GGGG    GGGG    GGGG    GGGG
	// E    C       C  E            C       C       C  E    C       C  E    C       C  E    C  E    C  E       E    C  E       E
	// E    C       C  E            C       C       C  E    C       C  E    C       C  E    C  E    C  E       E    C  E       E
	//  DDDD            DDDD    DDDD            DDDD    DDDD            DDDD    DDDD            DDDD    DDDD    DDDD    DDDD

	parameter zero   = 7'b1111110;  //Value for zero
	parameter one    = 7'b0110000;  //Value for one
	parameter two    = 7'b1101101;  //Value for two
	parameter three  = 7'b1111001;  //Value for three
	parameter four   = 7'b0110011;  //Value for four
	parameter five   = 7'b1011011;  //Value for five
	parameter six    = 7'b1011111;  //Value for six
	parameter seven  = 7'b1110000;  //Value for seven
	parameter eight  = 7'b1111111;  //Value for eight
	parameter nine   = 7'b1110011;  //Value for nine
	parameter A      = 7'b1110111;  //Value for A
	parameter B      = 7'b0011111;  //Value for B 
	parameter C      = 7'b1001110;  //Value for C
	parameter D      = 7'b0111101;  //Value for D
	parameter E      = 7'b1001111;  //Value for E
	parameter F      = 7'b1000111;  //Value for F

	always @(posedge CLK_IN) begin
		case(NUMBER_IN)
			4'b0000: OUTPUT <= ~zero;
			4'b0001: OUTPUT <= ~one;
			4'b0010: OUTPUT <= ~two;
			4'b0011: OUTPUT <= ~three;
			4'b0100: OUTPUT <= ~four;
			4'b0101: OUTPUT <= ~five;
			4'b0110: OUTPUT <= ~six;
			4'b0111: OUTPUT <= ~seven;
			4'b1000: OUTPUT <= ~eight;
			4'b1001: OUTPUT <= ~nine;
			4'b1010: OUTPUT <= ~A;
			4'b1011: OUTPUT <= ~B;
			4'b1100: OUTPUT <= ~C;
			4'b1101: OUTPUT <= ~D;
			4'b1110: OUTPUT <= ~E;
			4'b1111: OUTPUT <= ~F;
			default: OUTPUT <= ~zero;
		endcase
 	end
endmodule