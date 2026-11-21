interface mux_if (input logic clk);
  logic d0, d1, d2, d3;
  logic [1:0] sel;
  logic y;
  logic valid;
endinterface


class transaction;
  rand bit d0, d1, d2, d3;
  rand bit [1:0] sel;
  bit y;

  function void display(string tag);
    $display("[%0t] %-4s d0=%b d1=%b d2=%b d3=%b sel=%0d | y=%b", $time, tag, d0, d1, d2, d3, sel, y);
  endfunction
endclass


class generator;
  mailbox #(transaction) gen2drv;
  int unsigned num_random = 20;
  int unsigned total;
  bit finished;

  function new(mailbox #(transaction) gen2drv);
    this.gen2drv = gen2drv;
  endfunction

  task run();
    transaction t;

    repeat (num_random) begin
      t = new();
      if (!t.randomize()) $fatal(1, "Randomization failed");
      gen2drv.put(t);
      total++;
    end
    finished = 1;
  endtask
endclass


class driver;
  virtual mux_if vif;
  mailbox #(transaction) gen2drv;

  function new(virtual mux_if vif, mailbox #(transaction) gen2drv);
    this.vif = vif;
    this.gen2drv = gen2drv;
  endfunction

  task run();
    transaction t;
    vif.valid = 0;
    forever begin
      gen2drv.get(t);
      @(posedge vif.clk);
      vif.d0    <= t.d0;
      vif.d1    <= t.d1;
      vif.d2    <= t.d2;
      vif.d3    <= t.d3;
      vif.sel   <= t.sel;
      vif.valid <= 1;
      t.display("DRV");
      @(posedge vif.clk);
      vif.valid <= 0;
    end
  endtask
endclass


class monitor;
  virtual mux_if vif;
  mailbox #(transaction) mon2scb;

  function new(virtual mux_if vif, mailbox #(transaction) mon2scb);
    this.vif = vif;
    this.mon2scb = mon2scb;
  endfunction

  task run();
    transaction t;
    forever begin
      @(negedge vif.clk);
      if (vif.valid) begin
        t = new();
        t.d0 = vif.d0;  t.d1 = vif.d1;  t.d2 = vif.d2;  t.d3 = vif.d3;
        t.sel = vif.sel;
        t.y = vif.y;
        t.display("MON");
        mon2scb.put(t);
      end
    end
  endtask
endclass


class scoreboard;
  mailbox #(transaction) mon2scb;
  int unsigned checked, errors;

  function new(mailbox #(transaction) mon2scb);
    this.mon2scb = mon2scb;
  endfunction

  task run();
    transaction t;
    bit exp_y;
    bit [3:0] d;
    forever begin
      mon2scb.get(t);
      d = {t.d3, t.d2, t.d1, t.d0};
      exp_y = d[t.sel];
      checked++;
      if (t.y !== exp_y) begin
        errors++;
        $error("[SCB] MISMATCH d=%b sel=%0d | got y=%b, exp y=%b", d, t.sel, t.y, exp_y);
      end else
        $display("[%0t] SCB  PASS d=%b sel=%0d", $time, d, t.sel);
    end
  endtask
endclass


class environment;
  generator  gen;
  driver     drv;
  monitor    mon;
  scoreboard scb;
  mailbox #(transaction) gen2drv, mon2scb;
  virtual mux_if vif;

  function new(virtual mux_if vif);
    this.vif = vif;
    gen2drv = new();
    mon2scb = new();
    gen = new(gen2drv);
    drv = new(vif, gen2drv);
    mon = new(vif, mon2scb);
    scb = new(mon2scb);
  endfunction

  task run();
    fork
      gen.run();
      drv.run();
      mon.run();
      scb.run();
    join_none
    wait (gen.finished);
    wait (scb.checked == gen.total);
    #10;
    report();
  endtask

  function void report();
    $display("=========================================");
    $display(" Checked: %0d   Errors: %0d", scb.checked, scb.errors);
    $display(" %s", (scb.errors == 0) ? "TEST PASSED" : "TEST FAILED");
    $display("=========================================");
  endfunction
endclass


program test (mux_if vif);
  environment env;
  initial begin
    env = new(vif);
    env.gen.num_random = 20;
    env.run();
    $finish;
  end
endprogram


module tb_top;
  logic clk = 0;
  always #5 clk = ~clk;

  mux_if intf (clk);

  mux4to1 dut (
    .d0(intf.d0), .d1(intf.d1), .d2(intf.d2), .d3(intf.d3),
    .sel(intf.sel), .y(intf.y)
  );

  test t (intf);

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top);
  end
endmodule
