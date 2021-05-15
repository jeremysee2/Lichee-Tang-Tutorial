### Tutorial 3: UART Interface

In this tutorial, we will create a UART interface to send and receive data with your computer. This introduces the concept of a state machine to handle incoming data.

[Click here for the introduction to FPGAs on the Lichee Tang board](https://jeremysee2.github.io/2021/03/28/the-15-fpga-with-20-000-luts/).

[Click here for Tutorial 2, controlling a seven segment display](https://jeremysee2.github.io/2021/03/31/tutorial-2-seven-segment-display/).

Let's define some parameters for the UART interface we're using.

* 115200 baud rate
* 8 data bits
* No parity bit
* 1 stop bit
* No flow control

For a detailed explanation of UART, watch [this video by nandland](https://www.youtube.com/watch?v=Vh0KdoXaVgU&t=1172s). We'll focus on the implementation in Verilog, and how to use it with the Lichee Tang board.

#### UART Receiver

We use a state machine to perform a sequence of actions to wait for data, look for the start bit, look for data bits, look for the stop bit and clean up the state machine by going back to the `IDLE` state. For our `UART_RX` module, we'll define a `clk` input and a `RXserial` input, a `datavalid` output and a `RXbyte` bus output.

We'll also add in the states for our state machine, so we can reference them intuitively instead of relying on values like `3`b001\`. We define internal signals as well.

`rClockCount` divides the clock so we only read the data in once, to avoid re-sampling the same data. `rBitIndex` keeps track of which data bit we are currently at, while `rRXByte` keeps track of the actual data. `oRXDataValid`is an output that we use to signal whether the data received is in the correct format, and will be useful for downstream modules that take in data from this UART module. `rSMMain` is the main variable that stores our states for this state machine.

Note that the `case` statement is used for the state machines, rather than daisy-chained `if` `else` blocks.

```verilog
module UART_RX (
   input        i_Clock,
   input        i_RX_Serial,
   output       o_RX_Data_Valid,
   output [7:0] o_RX_Byte
   );
  
  // States for finite state machine (FSM)
  parameter IDLE         = 3'b000;
  parameter RX_START_BIT = 3'b001;
  parameter RX_DATA_BITS = 3'b010;
  parameter RX_STOP_BIT  = 3'b011;
  parameter CLEANUP      = 3'b100;
  
  // Internal signals to count clock, keep track of bit position
  reg [7:0]     r_Clock_Count   = 0;
  reg [2:0]     r_Bit_Index     = 0; //8 bits total
  reg [7:0]     r_RX_Byte       = 0;
  reg           o_RX_Data_Valid = 0;
  reg [2:0]     r_SM_Main       = 0;

endmodule
```

Now, let's add in the logic for the state machine itself. The entire state machine is nested within an `always` block, sensitive to `posedge i_Clk`.

The `IDLE` state resets internal signals, and looks for the start bit of `1`b0\`. If it's detected, it goes to the next state.

`RX-START-BIT` uses the internal clock counter to divide the 24MHz clock to 115200, matching the baud rate of the UART line. It uses that to double-check that the start bit has been set, then sets the `RX-DATA-BITS` state. Else, it goes back to the `IDLE` state.

`RX-DATA-BITS` waits `CLKS-PER-BIT -1` clock cycles to sample the incoming data, using the `r-Clock-Count` variable. Once done waiting, in the `else` block, it samples the data bit into the correct position of the `r-RX-Byte[r-Bit-Index]` for storage, until all 8 bits are received. Once the entire byte has been received, it goes to the next state to look for the stop bit.

`RX-STOP-BIT` waits `CLKS-PER-BIT -1` clock cycles, assuming that the stop bit will appear and pass. Then, it sends the state machine to the `CLEANUP` state, and raises high the `o-RX-Data-Valid` signal, to indicate to downstream modules that a data byte is valid, and ready to be read.

`CLEANUP` is the final state, which adds a one clock delay for downstream modules to read the data byte. It then sets the `o-RX-Data-Valid` signal low to indicate that the output data is invalid. Downstream modules can use this signal to ensure they do not read the same output data twice.

Finally, there are some assign statements to tie internal signals to output ports.

```verilog
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
   input  		i_Reset,
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
    if (~i_Reset) begin
      o_RX_Data_Valid   <= 1'b0;
      r_Clock_Count     <= 0;
      r_Bit_Index       <= 0;
      r_SM_Main <= IDLE;
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
```

Now, let's write the testbench to ensure that our state machine is able to read and output data correctly.

We start with the `timescale 1ns/10ps`, that defines the timestep to be 1ns, and the minimum resolution to be 10ps. Then, we include our module to be tested `include "UART_RX.v"`.

```verilog
`timescale 1ns/10ps
`include "UART_RX.v"

module UART_RX_tb();
endmodule
```

Then, we define some clocking parameters to simulate the actual clock. These calculations are very rough, but will be good enough to provide behavioural simulation analysis.

```verilog
`timescale 1ns/10ps
`include "UART_RX.v"

module UART_RX_tb();

  // Testbench uses a 24 MHz clock (same as Lichee Tang board)
  // Want to interface to 115200 baud UART
  // 24000000 / 115200 = 208 Clocks Per Bit.
  parameter c_CLOCK_PERIOD_NS = 41;
  parameter c_CLKS_PER_BIT    = 208;
  parameter c_BIT_PERIOD      = 8600;
  
endmodule
```

Next, we define test signals to send to our top level module.

```verilog
`timescale 1ns/10ps
`include "UART_RX.v"

module UART_RX_tb();

  // Testbench uses a 24 MHz clock (same as Lichee Tang board)
  // Want to interface to 115200 baud UART
  // 24000000 / 115200 = 208 Clocks Per Bit.
  parameter c_CLOCK_PERIOD_NS = 41;
  parameter c_CLKS_PER_BIT    = 208;
  parameter c_BIT_PERIOD      = 8600;
  
  reg r_Clock = 0;
  reg r_Reset = 1;
  reg r_RX_Serial = 1;
  wire [7:0] w_RX_Byte;
  
endomdule
```

Next, we set up a code block that generates the test signal we want to send to our module. This introduces the `task` and `endtask` keyword. Think of it as a more general function, that takes in multiple inputs and sends out multiple outputs, with specific timing. In this case, it takes in our parallel test data `0x37` and serializes it for the UART receiver test. It sends the start bit, 8 data bits and stop bit with appropriate timings.

```verilog
  // Takes in input byte and serializes it 
  task UART_WRITE_BYTE;
    input [7:0] i_Data;
    integer     ii;
    begin
      
      // Send Start Bit
      r_RX_Serial <= 1'b0;
      #(c_BIT_PERIOD);
      #1000;
      
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
```

Next, let's initialise our unit under test (UUT), and create our simulation clock.

```verilog
  UART_RX #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_RX_INST
    (.i_Clock(r_Clock),
     .i_Reset(r_Reset),
     .i_RX_Serial(r_RX_Serial),
     .o_RX_Data_Valid(),
     .o_RX_Byte(w_RX_Byte)
     );
  
  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
```

Lastly, we'll add in the initial block to pipe signals from our `task` to our UUT, and save all signals to an output waveform for viewing.

```verilog
  // Main Testing:
  initial
    begin
      // Send a command to the UART (exercise Rx)
      @(posedge r_Clock);
      UART_WRITE_BYTE(8'h37);
      @(posedge r_Clock);
            
      // Check that the correct command was received
      if (w_RX_Byte == 8'h37)
        $display("Test Passed - Correct Byte Received");
      else
        $display("Test Failed - Incorrect Byte Received");
    $finish();
    end
  
  initial 
  begin
    // Required to dump signals to EPWave
    $dumpfile("dump.vcd");
    $dumpvars(0);
  end
```

Bringing it all together, here's the final `testbench` Verilog file.

```verilog
//////////////////////////////////////////////////////////////////////
// File Downloaded from http://www.nandland.com
//////////////////////////////////////////////////////////////////////

// This testbench will exercise the UART RX.
// It sends out byte 0x37, and ensures the RX receives it correctly.
`timescale 1ns/10ps
`include "UART_RX.v"

module UART_RX_tb();

  // Testbench uses a 24 MHz clock (same as Lichee Tang board)
  // Want to interface to 115200 baud UART
  // 24000000 / 115200 = 208 Clocks Per Bit.
  parameter c_CLOCK_PERIOD_NS = 41;
  parameter c_CLKS_PER_BIT    = 208;
  parameter c_BIT_PERIOD      = 8600;
  
  reg r_Clock = 0;
  reg r_Reset = 1;
  reg r_RX_Serial = 1;
  wire [7:0] w_RX_Byte;
  

  // Takes in input byte and serializes it 
  task UART_WRITE_BYTE;
    input [7:0] i_Data;
    integer     ii;
    begin
      
      // Send Start Bit
      r_RX_Serial <= 1'b0;
      #(c_BIT_PERIOD);
      #1000;
      
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
  
  
  UART_RX #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_RX_INST
    (.i_Clock(r_Clock),
     .i_Reset(r_Reset),
     .i_RX_Serial(r_RX_Serial),
     .o_RX_Data_Valid(),
     .o_RX_Byte(w_RX_Byte)
     );
  
  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;

  
  // Main Testing:
  initial
    begin
      // Send a command to the UART (exercise Rx)
      @(posedge r_Clock);
      UART_WRITE_BYTE(8'h37);
      @(posedge r_Clock);
            
      // Check that the correct command was received
      if (w_RX_Byte == 8'h37)
        $display("Test Passed - Correct Byte Received");
      else
        $display("Test Failed - Incorrect Byte Received");
    $finish();
    end
  
  initial 
  begin
    // Required to dump signals
    $dumpfile("dump.vcd");
    $dumpvars(0);
  end
  
endmodule
```

Congratulations! We've successfully followed [nandland's tutorial](https://www.youtube.com/watch?v=Vh0KdoXaVgU&t=1172s) on building a UART receiver. Now, let's move on to building the UART transmitter.

#### UART Transmitter

For the UART transmitter, it's quite similar to the `task` from the UART receiver testbench. The variable names are also similar to the UART receiver module. We define an additional signal, `r-TX-Active` to indicate when the transmitter is active. This allows you to handle half-duplex applications where you transmit and receive on the same line.

```verilog
module UART_TX 
  #(parameter CLKS_PER_BIT = 208)
  (
   input       i_Clock,
   input       i_Reset,
   input       i_TX_DV,
   input [7:0] i_TX_Byte, 
   output      o_TX_Active,
   output reg  o_TX_Serial,
   output      o_TX_Done
   );
 
  parameter IDLE         = 3'b000;
  parameter TX_START_BIT = 3'b001;
  parameter TX_DATA_BITS = 3'b010;
  parameter TX_STOP_BIT  = 3'b011;
  parameter CLEANUP      = 3'b100;
  
  reg [2:0] r_SM_Main     = 0;
  reg [7:0] r_Clock_Count = 0;
  reg [2:0] r_Bit_Index   = 0;
  reg [7:0] r_TX_Data     = 0;
  reg       r_TX_Done     = 0;
  reg       r_TX_Active   = 0;

endmodule
```

Next, we define the behaviour of the module. Within the main `always` block of the code, we have the state machine for the UART transmitter.

`IDLE` initialises the values of the output and internal signals, waiting for a ready signal on `i-TX-DV`. Once available, it saves the data to be sent `i-TX-Data` and goes to the next state.

`TX-START-BIT` sends out the start bit, then waits for it to finish to adhere to timing. Once done, it moves to the next state to start sending data bits.

`TX-DATA-BITS` handles the sending of the data, one bit at a time, according to the `r-Bit-Index` variable. It adheres to timing by waiting the appropriate amount of time after setting each output bit, effectively converting from parallel to serial data.

`TX-STOP-BIT` state sets the stop bit, waits for some time, then sets the `r-TX-Done` flag to signal that transmission of the byte has finished. It then resets some internal signals, before moving on to the next state.

`CLEANUP` state waits for one clock cycle, before going back to the `IDLE` state to wait for more data to be sent. Lastly, some `assign` statements connect internal signals to output ports.

```verilog
  always @(posedge i_Clock, negedge i_Reset)
  begin
    if (!i_Reset) begin
        r_SM_Main <= IDLE;
    end
    case (r_SM_Main)
      IDLE :
        begin
          o_TX_Serial   <= 1'b1;         // Drive Line High for Idle
          r_TX_Done     <= 1'b0;
          r_Clock_Count <= 0;
          r_Bit_Index   <= 0;
          
          if (i_TX_DV == 1'b1)
          begin
            r_TX_Active <= 1'b1;
            r_TX_Data   <= i_TX_Byte;
            r_SM_Main   <= TX_START_BIT;
          end
          else
            r_SM_Main <= IDLE;
        end // case: IDLE
      
      
      // Send out Start Bit. Start bit = 0
      TX_START_BIT :
        begin
          o_TX_Serial <= 1'b0;
          
          // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_START_BIT;
          end
          else
          begin
            r_Clock_Count <= 0;
            r_SM_Main     <= TX_DATA_BITS;
          end
        end // case: TX_START_BIT
      
      
      // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish         
      TX_DATA_BITS :
        begin
          o_TX_Serial <= r_TX_Data[r_Bit_Index];
          
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_DATA_BITS;
          end
          else
          begin
            r_Clock_Count <= 0;
            
            // Check if we have sent out all bits
            if (r_Bit_Index < 7)
            begin
              r_Bit_Index <= r_Bit_Index + 1;
              r_SM_Main   <= TX_DATA_BITS;
            end
            else
            begin
              r_Bit_Index <= 0;
              r_SM_Main   <= TX_STOP_BIT;
            end
          end 
        end // case: TX_DATA_BITS
      
      
      // Send out Stop bit.  Stop bit = 1
      TX_STOP_BIT :
        begin
          o_TX_Serial <= 1'b1;
          
          // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_STOP_BIT;
          end
          else
          begin
            r_TX_Done     <= 1'b1;
            r_Clock_Count <= 0;
            r_SM_Main     <= CLEANUP;
            r_TX_Active   <= 1'b0;
          end 
        end // case: TX_STOP_BIT
      
      
      // Stay here 1 clock
      CLEANUP :
        begin
          r_TX_Done <= 1'b1;
          r_SM_Main <= IDLE;
        end
      
      
      default :
        r_SM_Main <= IDLE;
      
    endcase
  end
  
  assign o_TX_Active = r_TX_Active;
  assign o_TX_Done   = r_TX_Done;
```

s

```verilog
//////////////////////////////////////////////////////////////////////
// File Downloaded from http://www.nandland.com
//////////////////////////////////////////////////////////////////////
// This file contains the UART Transmitter.  This transmitter is able
// to transmit 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  When transmit is complete o_Tx_done will be
// driven high for one clock cycle.
//
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
// Example: 24 MHz Clock, 115200 baud UART
// (24000000)/(115200) = 208
 
module UART_TX 
  #(parameter CLKS_PER_BIT = 208)
  (
   input       i_Clock,
   input       i_Reset,
   input       i_TX_DV,
   input [7:0] i_TX_Byte, 
   output      o_TX_Active,
   output reg  o_TX_Serial,
   output      o_TX_Done
   );
 
  parameter IDLE         = 3'b000;
  parameter TX_START_BIT = 3'b001;
  parameter TX_DATA_BITS = 3'b010;
  parameter TX_STOP_BIT  = 3'b011;
  parameter CLEANUP      = 3'b100;
  
  reg [2:0] r_SM_Main     = 0;
  reg [7:0] r_Clock_Count = 0;
  reg [2:0] r_Bit_Index   = 0;
  reg [7:0] r_TX_Data     = 0;
  reg       r_TX_Done     = 0;
  reg       r_TX_Active   = 0;
    
  always @(posedge i_Clock, negedge i_Reset)
  begin
    if (!i_Reset) begin
        r_SM_Main <= IDLE;
    end
    case (r_SM_Main)
      IDLE :
        begin
          o_TX_Serial   <= 1'b1;         // Drive Line High for Idle
          r_TX_Done     <= 1'b0;
          r_Clock_Count <= 0;
          r_Bit_Index   <= 0;
          
          if (i_TX_DV == 1'b1)
          begin
            r_TX_Active <= 1'b1;
            r_TX_Data   <= i_TX_Byte;
            r_SM_Main   <= TX_START_BIT;
          end
          else
            r_SM_Main <= IDLE;
        end // case: IDLE
      
      
      // Send out Start Bit. Start bit = 0
      TX_START_BIT :
        begin
          o_TX_Serial <= 1'b0;
          
          // Wait CLKS_PER_BIT-1 clock cycles for start bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_START_BIT;
          end
          else
          begin
            r_Clock_Count <= 0;
            r_SM_Main     <= TX_DATA_BITS;
          end
        end // case: TX_START_BIT
      
      
      // Wait CLKS_PER_BIT-1 clock cycles for data bits to finish         
      TX_DATA_BITS :
        begin
          o_TX_Serial <= r_TX_Data[r_Bit_Index];
          
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_DATA_BITS;
          end
          else
          begin
            r_Clock_Count <= 0;
            
            // Check if we have sent out all bits
            if (r_Bit_Index < 7)
            begin
              r_Bit_Index <= r_Bit_Index + 1;
              r_SM_Main   <= TX_DATA_BITS;
            end
            else
            begin
              r_Bit_Index <= 0;
              r_SM_Main   <= TX_STOP_BIT;
            end
          end 
        end // case: TX_DATA_BITS
      
      
      // Send out Stop bit.  Stop bit = 1
      TX_STOP_BIT :
        begin
          o_TX_Serial <= 1'b1;
          
          // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_STOP_BIT;
          end
          else
          begin
            r_TX_Done     <= 1'b1;
            r_Clock_Count <= 0;
            r_SM_Main     <= CLEANUP;
            r_TX_Active   <= 1'b0;
          end 
        end // case: TX_STOP_BIT
      
      
      // Stay here 1 clock
      CLEANUP :
        begin
          r_TX_Done <= 1'b1;
          r_SM_Main <= IDLE;
        end
      
      
      default :
        r_SM_Main <= IDLE;
      
    endcase
  end
  
  assign o_TX_Active = r_TX_Active;
  assign o_TX_Done   = r_TX_Done;
  
endmodule
```

Next, let's set up a testbench to simulate the UART transmitter and receiver in loopback mode, where the transmitter connects to the receiver.

```verilog
//////////////////////////////////////////////////////////////////////
// File Downloaded from http://www.nandland.com
//////////////////////////////////////////////////////////////////////

// This testbench will exercise the UART RX.
// It sends out byte 0x37, and ensures the RX receives it correctly.
`timescale 1ns/10ps

`include "UART_TX.v"

module UART_TX_TB ();

  // Testbench uses a 24 MHz clock (same as Lichee Tang board)
  // Want to interface to 115200 baud UART
  // 24000000 / 115200 = 208 Clocks Per Bit.
  parameter c_CLOCK_PERIOD_NS = 41;
  parameter c_CLKS_PER_BIT    = 208;
  parameter c_BIT_PERIOD      = 8600;
  
  reg r_Clock = 0;
  reg r_Reset = 1;
  reg r_TX_DV = 0;
  wire w_TX_Active, w_UART_Line;
  wire w_TX_Serial;
  reg [7:0] r_TX_Byte = 0;
  wire [7:0] w_RX_Byte;

  UART_RX #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_RX_Inst
    (.i_Clock(r_Clock),
     .i_Reset(r_Reset),
     .i_RX_Serial(w_UART_Line),
     .o_RX_DV(w_RX_DV),
     .o_RX_Byte(w_RX_Byte)
     );
  
  UART_TX #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_TX_Inst
    (.i_Clock(r_Clock),
     .i_Reset(r_Reset),
     .i_TX_DV(r_TX_DV),
     .i_TX_Byte(r_TX_Byte),
     .o_TX_Active(w_TX_Active),
     .o_TX_Serial(w_TX_Serial),
     .o_TX_Done()
     );

  // Keeps the UART Receive input high (default) when
  // UART transmitter is not active
  assign w_UART_Line = w_TX_Active ? w_TX_Serial : 1'b1;
    
  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
  
  // Main Testing:
  initial
    begin
      // Tell UART to send a command (exercise TX)
      @(posedge r_Clock);
      @(posedge r_Clock);
      r_TX_DV   <= 1'b1;
      r_TX_Byte <= 8'h3F;
      @(posedge r_Clock);
      r_TX_DV <= 1'b0;

      // Check that the correct command was received
      @(posedge w_RX_DV);
      if (w_RX_Byte == 8'h3F)
        $display("Test Passed - Correct Byte Received");
      else
        $display("Test Failed - Incorrect Byte Received");
      $finish();
    end
  
  initial 
  begin
    // Required to dump signals to EPWave
    $dumpfile("dump.vcd");
    $dumpvars(0);
  end
endmodule
```

Finally, we've implemented a basic UART peripheral! You'll note that this only allows you to receive one byte at a time, and has no buffer to store the last few bytes. This means that whatever you send will push old data out of the system, which usually isn't desirable when you don't know when the next data byte will come - fast or slow.