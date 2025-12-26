# FIFO Design and Verification (SystemVerilog)

## Overview

This project demonstrates the design and verification of a **First-In First-Out (FIFO)** memory buffer using SystemVerilog.  
The RTL is implemented and simulated in **Vivado (XSim)**, and the verification environment is constructed using **SystemVerilog OOP concepts** — including Generator, Driver, Monitor, and Scoreboard.

---

## Design Details

- **Design File:** `FIFO.sv`
- **Interface:** `fifo_if` (connects DUT and testbench)
- **Functionality:**  
  The FIFO stores incoming data and outputs it in a first-in-first-out (FIFO) manner, ensuring data ordering integrity. (first-in, first-out).  
  The design supports:
  - Write enable (`wr_en`)
  - Read enable (`rd_en`)
  - Full and Empty status flags
  - Synchronous operation with a single clock

**Source:** `src/FIFO.sv`

```systemverilog
module FIFO #(parameter DEPTH = 8, WIDTH = 8)(
  input  logic clk,
  input  logic rst,
  input  logic wr_en,
  input  logic rd_en,
  input  logic [WIDTH-1:0] din,
  output logic [WIDTH-1:0] dout,
  output logic full,
  output logic empty
);

  logic [WIDTH-1:0] mem [0:DEPTH-1];
  int wr_ptr, rd_ptr, count;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      count  <= 0;
    end else begin
      if (wr_en && !full) begin
        mem[wr_ptr] <= din;
        wr_ptr <= (wr_ptr + 1) % DEPTH;
        count  <= count + 1;
      end
      if (rd_en && !empty) begin
        dout   <= mem[rd_ptr];
        rd_ptr <= (rd_ptr + 1) % DEPTH;
        count  <= count - 1;
      end
    end
  end

  assign full  = (count == DEPTH);
  assign empty = (count == 0);

endmodule
