class monitor;

  //----------------------------------------------------
  // Mailbox
  //----------------------------------------------------
  mailbox #(transaction) mon2scb;

  //----------------------------------------------------
  // Virtual Interface
  //----------------------------------------------------
  virtual riscv_if vif;

  //----------------------------------------------------
  // Constructor
  //----------------------------------------------------
  function new(mailbox #(transaction) mb,
               virtual riscv_if vif);

    this.mon2scb = mb;
    this.vif     = vif;

  endfunction

  //----------------------------------------------------
  // Run
  //----------------------------------------------------
  task run();

    transaction tr;

    forever begin

      @(posedge vif.clk);

      if(vif.rst)
        continue;

      tr = new();

      //-----------------------------
      // Capture current instruction
      //-----------------------------
      tr.instr = vif.instruction;

      //-----------------------------
      // Decode instruction name
      //-----------------------------
      case(vif.instruction[6:0])

        7'b0110011 : tr.instr_name = "ADD/SUB";
        7'b0010011 : tr.instr_name = "ADDI";
        7'b0000011 : tr.instr_name = "LW";
        7'b0100011 : tr.instr_name = "SW";
        7'b1100011 : tr.instr_name = "BEQ";

        default    : tr.instr_name = "UNKNOWN";

      endcase

      //-----------------------------
      // Sample Functional Coverage
      //-----------------------------
      tr.sample();

      //-----------------------------
      // Send to Scoreboard
      //-----------------------------
      mon2scb.put(tr.copy());

      //-----------------------------
      // Display
      //-----------------------------
      $display("--------------------------------------");
      $display("MONITOR");
      $display("--------------------------------------");
      $display("PC          = %08h",vif.pc);
      $display("Instruction = %08h",vif.instruction);
      $display("WB Enable   = %0b",vif.wb_reg_write);
      $display("WB RD       = %0d",vif.wb_rd);
      $display("WB DATA     = %08h",vif.wb_data);
      $display("--------------------------------------");

    end

  endtask

endclass
