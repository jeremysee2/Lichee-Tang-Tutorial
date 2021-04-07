/////////////////////////////////////////////////////////////////////
// File Downloaded from http://www.nandland.com
/////////////////////////////////////////////////////////////////////
// This file contains the UART Receiver.  This receiver is able to
// receive 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  When receive is complete o_rx_dv will be
// driven high for one clock cycle.
// 
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
// Example: 24 MHz Clock, 115200 baud UART
// (24000000)/(115200) = 208
 
module UART_RX
  #(parameter CLKS_PER_BIT = 208)
  (
   input        i_Clock,
   input        i_Reset,
   input        i_RX_Serial,
   output       o_RX_Data_Valid,
   output [7:0] o_RX_Byte
   );
   
  parameter IDLE         = 3'b000;
  parameter RX_START_BIT = 3'b001;
  parameter RX_DATA_BITS = 3'b010;
  parameter RX_STOP_BIT  = 3'b011;
  parameter CLEANUP      = 3'b100;
  
  reg [7:0]     r_Clock_Count   = 0;
  reg [2:0]     r_Bit_Index     = 0; //8 bits total
  reg [7:0]     r_RX_Byte       = 0;
  reg           o_RX_Data_Valid = 0;
  reg [2:0]     r_SM_Main       = 0;
  
  
  // Purpose: Control RX state machine
  always @(posedge i_Clock, negedge i_Reset)
  begin
    if (!i_Reset) begin
        o_RX_Data_Valid   <= 1'b0;
        r_Clock_Count     <= 0;
        r_Bit_Index       <= 0;
        r_SM_Main         <= IDLE;
    end
    case (r_SM_Main)
      IDLE :
        begin
          o_RX_Data_Valid   <= 1'b0;
          r_Clock_Count     <= 0;
          r_Bit_Index       <= 0;
          
          if (i_RX_Serial == 1'b0)          // Start bit detected
            r_SM_Main <= RX_START_BIT;
          else
            r_SM_Main <= IDLE;
        end
      
      // Check middle of start bit to make sure it's still low
      RX_START_BIT :
        begin
          if (r_Clock_Count == (CLKS_PER_BIT-1)/2)
          begin
            if (i_RX_Serial == 1'b0)
            begin
              r_Clock_Count <= 0;  // reset counter, found the middle
              r_SM_Main     <= RX_DATA_BITS;
            end
            else
              r_SM_Main <= IDLE;
          end
          else
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= RX_START_BIT;
          end
        end // case: RX_START_BIT
      
      
      // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
      RX_DATA_BITS :
        begin
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= RX_DATA_BITS;
          end
          else
          begin
            r_Clock_Count          <= 0;
            r_RX_Byte[r_Bit_Index] <= i_RX_Serial;
            
            // Check if we have received all bits
            if (r_Bit_Index < 7)
            begin
              r_Bit_Index <= r_Bit_Index + 1;
              r_SM_Main   <= RX_DATA_BITS;
            end
            else
            begin
              r_Bit_Index <= 0;
              r_SM_Main   <= RX_STOP_BIT;
            end
          end
        end // case: RX_DATA_BITS
      
      
      // Receive Stop bit.  Stop bit = 1
      RX_STOP_BIT :
        begin
          // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
     	    r_SM_Main     <= RX_STOP_BIT;
          end
          else
          begin
       	    o_RX_Data_Valid <= 1'b1;
            r_Clock_Count   <= 0;
            r_SM_Main       <= CLEANUP;
          end
        end // case: RX_STOP_BIT
      
      
      // Stay here 1 clock
      CLEANUP :
        begin
          r_SM_Main         <= IDLE;
          o_RX_Data_Valid   <= 1'b0;
        end
      
      
      default :
        r_SM_Main <= IDLE;
      
    endcase
  end    
  
  assign o_RX_DV   = o_RX_Data_Valid;
  assign o_RX_Byte = r_RX_Byte;
  
endmodule // UART_RX