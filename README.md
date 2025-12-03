\# FIFO Design and Verification (SystemVerilog)



\## Overview



This project demonstrates the design and verification of a \*\*First-In First-Out (FIFO)\*\* memory buffer using SystemVerilog.  

The RTL is implemented and simulated in \*\*Vivado (XSim)\*\*, and the verification environment is constructed using \*\*SystemVerilog OOP concepts\*\* — including Generator, Driver, Monitor, and Scoreboard.



---



\## Design Details



\- \*\*Design File:\*\* `FIFO.sv`

\- \*\*Interface:\*\* `fifo\_if` (connects DUT and testbench)

\- \*\*Functionality:\*\*  

&nbsp; The FIFO temporarily stores incoming data and releases it in the same order it was received (first-in, first-out).  

&nbsp; The design supports:

&nbsp; - Write enable (`wr\_en`)

&nbsp; - Read enable (`rd\_en`)

&nbsp; - Full and Empty status flags

&nbsp; - Synchronous operation with a single clock



\*\*Source:\*\* `src/FIFO.sv`



```systemverilog

module FIFO #(parameter DEPTH = 8, WIDTH = 8)(

&nbsp; input  logic clk,

&nbsp; input  logic rst,

&nbsp; input  logic wr\_en,

&nbsp; input  logic rd\_en,

&nbsp; input  logic \[WIDTH-1:0] din,

&nbsp; output logic \[WIDTH-1:0] dout,

&nbsp; output logic full,

&nbsp; output logic empty

);



&nbsp; logic \[WIDTH-1:0] mem \[0:DEPTH-1];

&nbsp; int wr\_ptr, rd\_ptr, count;



&nbsp; always\_ff @(posedge clk or posedge rst) begin

&nbsp;   if (rst) begin

&nbsp;     wr\_ptr <= 0;

&nbsp;     rd\_ptr <= 0;

&nbsp;     count  <= 0;

&nbsp;   end else begin

&nbsp;     if (wr\_en \&\& !full) begin

&nbsp;       mem\[wr\_ptr] <= din;

&nbsp;       wr\_ptr <= (wr\_ptr + 1) % DEPTH;

&nbsp;       count  <= count + 1;

&nbsp;     end

&nbsp;     if (rd\_en \&\& !empty) begin

&nbsp;       dout   <= mem\[rd\_ptr];

&nbsp;       rd\_ptr <= (rd\_ptr + 1) % DEPTH;

&nbsp;       count  <= count - 1;

&nbsp;     end

&nbsp;   end

&nbsp; end



&nbsp; assign full  = (count == DEPTH);

&nbsp; assign empty = (count == 0);



endmodule



