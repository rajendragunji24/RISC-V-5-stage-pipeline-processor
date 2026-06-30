class scoreboard;

  //--------------------------------------------------
  // Mailbox (kept for compatibility with environment)
  //--------------------------------------------------
  mailbox #(transaction) mon2scb;

  //--------------------------------------------------
  // Constructor
  //--------------------------------------------------
  function new(mailbox #(transaction) mb);
    mon2scb = mb;
  endfunction

  //--------------------------------------------------
  // Run
  //--------------------------------------------------
  task run();

    int errors = 0;

    // Wait for the program to complete
    repeat (25) @(posedge $root.riscv_tb.clk);

    $display("\n=====================================");
    $display("          SCOREBOARD");
    $display("=====================================");

    //----------------------------
    // Register x1
    //----------------------------
    if ($root.riscv_tb.dut.u_reg.regs[1] == 32'd5)
      $display("PASS : x1 = %0d", $root.riscv_tb.dut.u_reg.regs[1]);
    else begin
      $display("FAIL : x1 Expected=5 Actual=%0d",
               $root.riscv_tb.dut.u_reg.regs[1]);
      errors++;
    end

    //----------------------------
    // Register x2
    //----------------------------
    if ($root.riscv_tb.dut.u_reg.regs[2] == 32'd7)
      $display("PASS : x2 = %0d", $root.riscv_tb.dut.u_reg.regs[2]);
    else begin
      $display("FAIL : x2 Expected=7 Actual=%0d",
               $root.riscv_tb.dut.u_reg.regs[2]);
      errors++;
    end

    //----------------------------
    // Register x3
    //----------------------------
    if ($root.riscv_tb.dut.u_reg.regs[3] == 32'd12)
      $display("PASS : x3 = %0d", $root.riscv_tb.dut.u_reg.regs[3]);
    else begin
      $display("FAIL : x3 Expected=12 Actual=%0d",
               $root.riscv_tb.dut.u_reg.regs[3]);
      errors++;
    end

    //----------------------------
    // Register x4
    //----------------------------
    if ($root.riscv_tb.dut.u_reg.regs[4] == 32'd12)
      $display("PASS : x4 = %0d", $root.riscv_tb.dut.u_reg.regs[4]);
    else begin
      $display("FAIL : x4 Expected=12 Actual=%0d",
               $root.riscv_tb.dut.u_reg.regs[4]);
      errors++;
    end

    //----------------------------
    // Register x5
    //----------------------------
    if ($root.riscv_tb.dut.u_reg.regs[5] == 32'd55)
      $display("PASS : x5 = %0d", $root.riscv_tb.dut.u_reg.regs[5]);
    else begin
      $display("FAIL : x5 Expected=55 Actual=%0d",
               $root.riscv_tb.dut.u_reg.regs[5]);
      errors++;
    end

    //----------------------------
    // Memory Check
    //----------------------------
    if ($root.riscv_tb.dut.u_dmem.ram[10>>2] == 32'd12)
      $display("PASS : MEM[10] = %0d",
               $root.riscv_tb.dut.u_dmem.ram[10>>2]);
    else begin
      $display("FAIL : MEM[10] Expected=12 Actual=%0d",
               $root.riscv_tb.dut.u_dmem.ram[10>>2]);
      errors++;
    end

    //-----------------------------------------
    // Coverage
    //-----------------------------------------
    $display("-------------------------------------");
    $display("Functional Coverage = %0.2f%%",
             $get_coverage());

    //-----------------------------------------
    // Final Result
    //-----------------------------------------
    if (errors == 0)
      $display("\n******** TEST PASSED ********");
    else
      $display("\n******** TEST FAILED (%0d Errors) ********", errors);

    $display("=====================================\n");

    $finish;

  endtask

endclass
