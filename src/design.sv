// Code your design here

module fifo(
  input clk, input rst,
  input [7:0] din, input we, input re, 
  output empty, full,
  output reg [4:0] cnt,
  output reg [7:0] dout
);
  //reg [4:0] cnt = 0;
  reg [3:0] wptr = 0;
  reg [3:0] rptr = 0;
  reg [7:0] mem [15:0];
  
  always @(posedge clk) begin
    
    if(rst == 1'b1) begin
      
      wptr <= 0;
      rptr <= 0;
      cnt <= 0;
    end
    
    else if(we && !full) begin
      mem[wptr] <= din;
      wptr <= wptr + 1;
      cnt <= cnt+1;
    end
    
    else if (re && !empty) begin
      dout <= mem[rptr];
      rptr <= rptr +1;
      cnt <= cnt-1;
    end
    
  end
  
  
  assign empty = (cnt == 0)? 1'b1:1'b0;
  assign full = (cnt == 16)? 1'b1:1'b0;
  
  
endmodule

interface fifo_if;
  
  logic clk, rst, we, re, empty, full;
  logic [7:0] din; 
  logic [7:0] dout;
  logic [4:0] cnt;
  
endinterface