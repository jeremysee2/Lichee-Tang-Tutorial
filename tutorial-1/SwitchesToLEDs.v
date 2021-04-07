// Logic gate examples
module SwitchesToLEDs
  (input i_Switch_1,  
   input i_Switch_2,
   output o_LED_1,
   output o_LED_2,
   output o_LED_3,
   output o_LED_4);
       
assign o_LED_1 = i_Switch_1 & i_Switch_2;     // AND  gate
assign o_LED_2 = i_Switch_1 | i_Switch_2;     // OR   gate
assign o_LED_3 = ~(i_Switch_1 & i_Switch_2);  // NAND gate
assign o_LED_4 = i_Switch_1 ^  i_Switch_2;    // XOR  gate
 
endmodule