/////////////////////////////////////////////////////////////////////
// File Downloaded from http://www.nandland.com
/////////////////////////////////////////////////////////////////////
// This file contains the UART Receiver.  This receiver is able to
// receive 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  When receive is complete o_rx_dv will be
// driven high for one clock cycle.
// 
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of CLK)/(Frequency of UART)
// Example: 25 MHz Clock, 115200 baud UART
// (25000000)/(115200) = 217
 
module UART_TX
  #(parameter CLKS_PER_BIT = 217)
  (
   input        CLK,
   input 	i_TX_DV,
   input [7:0] 	i_TX_Byte,
   output reg   TX,
   output	o_TX_Active,
   output	o_TX_Done);
   
  parameter IDLE         = 3'b000;
  parameter TX_START_BIT = 3'b001;
  parameter TX_DATA_BITS = 3'b010;
  parameter TX_STOP_BIT  = 3'b011; 
  parameter CLEANUP      = 3'b100;
  
  reg [2:0]     r_SM_Main     = 0;
  reg [7:0]     r_Clock_Count = 0;
  reg [2:0]     r_Bit_Index   = 0; //8 bits total
  reg [7:0]	r_TX_Data     = 0;
  reg		r_TX_Active   = 0;
  reg 		r_TX_Done     = 0;
  
  
  // Purpose: Control TX state machine
  always @(posedge CLK) //or nonedge i_Rst_L)
  begin
      
    case (r_SM_Main)
      IDLE :
        begin
          TX	        <= 1'b1;
          r_TX_Done	<= 1'b0;
          r_Clock_Count <= 0;
          r_Bit_Index   <= 0;
          
          if (i_TX_DV == 1'b1)          // Start bit detected
            begin
            r_TX_Active <= 1'b1;
            r_TX_Data <= i_TX_Byte;
            r_SM_Main <= TX_START_BIT;
            end
          else
            begin
            r_SM_Main <= IDLE;
            end
        end
      
      // Check middle of start bit to make sure it's still low
      TX_START_BIT :
        begin
          TX <= 1'b0;
          if (r_Clock_Count == CLKS_PER_BIT-1)
          begin
              r_Clock_Count <= 0;
              r_SM_Main     <= TX_DATA_BITS;
          end
          else
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_START_BIT;
          end
        end // case: TX_START_BIT
      
      
      // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
      TX_DATA_BITS :
        begin
          TX <= r_TX_Data[r_Bit_Index];
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
            r_SM_Main     <= TX_DATA_BITS;
          end
          else
          begin
            r_Clock_Count          <= 0;
            // Check if we have received all bits
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
      
      
      // Receive Stop bit.  Stop bit = 1
      TX_STOP_BIT :
        begin
          TX <= 1'b1;
          // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
          if (r_Clock_Count < CLKS_PER_BIT-1)
          begin
            r_Clock_Count <= r_Clock_Count + 1;
     	    r_SM_Main     <= TX_STOP_BIT;
          end
          else
          begin
       	    r_TX_Done       <= 1'b1;
            r_Clock_Count <= 0;
            r_SM_Main     <= CLEANUP;
            r_TX_Active	  <= 1'b0;
          end
        end // case: TX_STOP_BIT
      
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
  
endmodule // UART_TX
