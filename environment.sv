`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"

class environment;

  //--------------------------------------------------
  // Components
  //--------------------------------------------------
  generator  gen;
  driver     drv;
  monitor    mon;
  scoreboard scb;

  //--------------------------------------------------
  // Mailboxes
  //--------------------------------------------------
  mailbox #(transaction) gen2drv;
  mailbox #(transaction) mon2scb;

  //--------------------------------------------------
  // Virtual Interface
  //--------------------------------------------------
  virtual riscv_if vif;

  //--------------------------------------------------
  // Constructor
  //--------------------------------------------------
  function new(virtual riscv_if vif);

    this.vif = vif;

    // Create mailboxes
    gen2drv = new();
    mon2scb = new();

    // Create components
    gen = new(gen2drv);
    drv = new(gen2drv, vif);
    mon = new(mon2scb, vif);
    scb = new(mon2scb);

  endfunction

  //--------------------------------------------------
  // Run
  //--------------------------------------------------
  task run();

    $display("---------------------------------------");
    $display("ENVIRONMENT STARTED");
    $display("---------------------------------------");

    fork
      gen.run();
      drv.run();
      mon.run();
      scb.run();
    join

  endtask

endclass
