class driver;

  //----------------------------------------------------
  // Mailbox
  //----------------------------------------------------
  mailbox #(transaction) gen2drv;

  //----------------------------------------------------
  // Virtual Interface
  //----------------------------------------------------
  virtual riscv_if vif;

  //----------------------------------------------------
  // Constructor
  //----------------------------------------------------
  function new(mailbox #(transaction) mb,
               virtual riscv_if vif);

    this.gen2drv = mb;
    this.vif     = vif;

  endfunction

  task run();

  transaction tr;

  // Receive transaction
  gen2drv.get(tr);

  //-----------------------------------
  // Load Program
  //-----------------------------------

  vif.rom[0] = 32'h00500093;   // ADDI x1,x0,5
  vif.rom[1] = 32'h00700113;   // ADDI x2,x0,7
  vif.rom[2] = 32'h002081B3;   // ADD  x3,x1,x2
  vif.rom[3] = 32'h00302423;   // SW   x3,10(x0)
  vif.rom[4] = 32'h00A02203;   // LW   x4,10(x0)
  vif.rom[5] = 32'h0031A463;   // BEQ  x3,x4,+12
  vif.rom[6] = 32'h06300293;   // ADDI x5,x0,99
  vif.rom[7] = 32'h03700293;   // ADDI x5,x0,55

  //-----------------------------------
  // Fill Remaining ROM with NOPs
  //-----------------------------------

  for (int i = 8; i < 256; i++)
    vif.rom[i] = 32'h00000013;   // NOP = ADDI x0,x0,0

  //-----------------------------------
  // Functional Coverage
  //-----------------------------------

  for (int i = 0; i < 8; i++) begin
    tr.instr = vif.rom[i];
    tr.sample();
  end

  //-----------------------------------
  // Display
  //-----------------------------------

  $display("----------------------------------------");
  $display("DRIVER : Program Loaded Successfully");
  $display("----------------------------------------");

endtask

endclass
