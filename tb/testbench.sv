// Code your testbench here
// or browse Examples

class transaction;
  
  rand bit optr;
  rand bit [7:0] din;
  bit [7:0] dout;
  bit we, re;
  bit full, empty;
  bit [4:0] cnt;
  
  constraint value{
    optr dist {1 :/ 70 , 0 :/ 30};
  }
  
  function void display(string s);
  $display("[%0s]: We: %0b Re: %0b din: %0b dout: %0b empty: %0b full: %0b cnt: %0d at %0t",
           s, we, re, din, dout, empty, full, cnt, $time );
  endfunction
  
endclass


class generator;
  
  transaction trans_g;
  //mailbox #(transaction) mbx_gs;
  mailbox #(transaction) mbx_gd;
  event sb; //for signal from scoreboard
  event done;//for the entire operation
  
  int count = 0;
  int i=0;
  
  function new(/*mailbox #(transaction) mbx_gs,*/ mailbox #(transaction) mbx_gd);
    //this.mbx_gs = mbx_gs;
    this.mbx_gd = mbx_gd;
  endfunction
  
  task run();
    
    repeat(count) begin
      trans_g = new();
      assert(trans_g.randomize()) else $error("Randomization Failed");
      mbx_gd.put(trans_g);
      //mbx_gs.put(trans_g);
      i++ ;
      $display("[GEN]: OPTR %0d, iteration %0d at %0t", trans_g.optr, i, $time);
      @(sb);
    end
    ->done;
  endtask
  
endclass

class driver;
  transaction trans_d;
  mailbox #(transaction) mbx_gd;
  
  virtual fifo_if fif;
  
  function new(mailbox #(transaction) mbx_gd);
    this.mbx_gd = mbx_gd;
  endfunction
  
  task reset();
    fif.rst<=1;
    fif.din<=0;
    fif.we<=0;
    fif.re<=0;
    repeat(1) @(posedge fif.clk);
    fif.rst<=0;
    $display("Reset Done at %0t", $time);
    $display("-----------------");
      
  endtask
  
  task write(); //3 clk edges
    @(posedge fif.clk);
    fif.rst =0;
    fif.din =trans_d.din;
    fif.we =1;
    //trans_d.we = fif.we;
    fif.re =0;
    //trans_d.display("DRV");
    @(posedge fif.clk);
    $display("[DRV]: Written Din %0b at %0t", fif.din, $time);
    fif.we<=0;
    @(posedge fif.clk);
  endtask
  
  task read();
    @(posedge fif.clk);
    fif.rst=0;
    fif.we=0;
    fif.re=1; 
    @(posedge fif.clk);
    $display("[DRV]: Data Read at time %0t", $time);
    fif.re<=0;
    @(posedge fif.clk);
  endtask
  
  task run();
    
    forever begin
      mbx_gd.get(trans_d);
      if(trans_d.optr==1)
        write();
      else if(trans_d.optr==0)
        read();
    end
  endtask
endclass

class monitor;
  transaction tr_mon;
  mailbox #(transaction) mbx_ms;
  
  virtual fifo_if fif;
  
  function new(mailbox #(transaction) mbx_ms);
    this.mbx_ms = mbx_ms;
  endfunction
  
  task run();
    forever begin
    tr_mon = new();
    repeat(2) @(posedge fif.clk);
    tr_mon.we = fif.we;
    tr_mon.re = fif.re;
    tr_mon.din = fif.din;
    
    @(posedge fif.clk);
    tr_mon.dout = fif.dout;
    tr_mon.empty = fif.empty;
    tr_mon.full = fif.full;
      tr_mon.cnt   = fif.cnt;
      
    tr_mon.display("MON");
    mbx_ms.put(tr_mon);
    end
  endtask
  
endclass

class scoreboard;
  transaction tr_sco;
  //mailbox #(transaction) mbx_gs;
  mailbox #(transaction) mbx_ms;
  
  event sb;
  
  bit [7:0] din[$];
  bit [7:0] temp;
  int err = 0;
  
  function new(mailbox #(transaction) mbx_ms);
    this.mbx_ms = mbx_ms;
  endfunction
  
  task run();
  forever begin
    //tr_sco = new();
    //mbx_gs.get(tr_sco_g);
    mbx_ms.get(tr_sco);
    tr_sco.display("SCO");
    $display("------------------------");
    
    if(tr_sco.we)
      begin
      	if(!tr_sco.full)
          begin
        	din.push_front(tr_sco.din);
            $display("[SCO]: The data stored in Queue %0b at %0t", tr_sco.din, $time);
          end
        
        else
          $display("[SCO]: FIFO is full");
        $display("------------------------");
      end
    
    else if(tr_sco.re)
      begin
        if(!tr_sco.empty)
          begin
         	temp = din.pop_back();
            $display("[SCO]: The data popped from Queue %0b at %0t", temp, $time);
            $display("------------------------");
            
            if(temp == tr_sco.dout)
              $display("[SCO]: The Output matched at %0t", $time);
            
            else begin
              $error("[SCO]: The Output mismatched at %0t", $time);
              err++ ;
            end
          end
        
        
        else
          $display("FIFO Empty at %0t" , $time);
        
        $display("------------------------");
      end
    ->sb;
    
  end
  endtask
  
endclass

class environment;
  
  transaction tr;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  
  mailbox #(transaction) mbx_gd;
  mailbox #(transaction) mbx_ms;
  
  event next;
  
  virtual fifo_if fif;
  
  function new(virtual fifo_if fif);
    
    mbx_gd = new();
    mbx_ms = new();
    
    gen = new(mbx_gd);
    drv = new(mbx_gd);
    mon = new(mbx_ms);
    sco = new(mbx_ms);
    
    gen.sb = next;
    sco.sb = next;
    
    this.fif = fif;
    mon.fif = this.fif;
    drv.fif = this.fif;
    
  endfunction
  
  task pre_test();
    drv.reset();
  endtask
  
  task test();
    fork
      	gen.run(); //no clk pulse , keeps happening from 1st posedge after reset
      	drv.run(); // 2nd posedge (assigns the value to dut) , 3rd posedge (prints the value)
      mon.run(); //2nd poedge (assigns the inputs), 3rd posedge (ptints the output like dout and empty)
      sco.run();// receives from ms mbx at 3rd posedge and store it in queue at same time
    join_none

  endtask
  
  task post_test();
    wait(gen.done.triggered);
    $display("----------------");
    $display("[DUT]: count: %0d", fif.cnt);
    $display("Error Count %0d", sco.err);
    $display("----------------");
    $finish();
  endtask
  
  task run();
    pre_test(); //#10 1st posedge
    fork
      test();
      post_test();
      
    join
    
  endtask
  
endclass
               
module tb;
  environment env;
  fifo_if fif();
  

  
  fifo dut(fif.clk, fif.rst, fif.din, fif.we, fif.re, fif.empty, fif.full, fif.cnt, fif.dout);
  
  initial begin
    fif.clk <= 0;
  end
  
  always #10 fif.clk <= ~fif.clk;
  
  initial begin
    env = new(fif);
    env.gen.count = 20;
    env.run();
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end
  
endmodule