`timescale 1ns/1ps

`include "interface.sv"
`include "environment.sv"

module riscv_tb;

  //--------------------------------------------
  // Clock & Reset
  //--------------------------------------------
  logic clk;
  logic rst;

  //--------------------------------------------
  // Clock Generation
  //--------------------------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  //--------------------------------------------
  // Interface
  //--------------------------------------------
  riscv_if rif(clk,rst);

  //--------------------------------------------
  // DUT
  //--------------------------------------------
  riscv_pipeline dut(
      .clk(clk),
      .rst(rst)
  );

  //--------------------------------------------
  // Connect ROM
  //--------------------------------------------
  genvar i;
  generate
    for(i=0;i<256;i++) begin
      always_comb
        dut.rom[i] = rif.rom[i];
    end
  endgenerate

  //--------------------------------------------
  // Connect DUT Signals to Interface
  //--------------------------------------------

  assign rif.pc           = dut.pc;
  assign rif.instruction  = dut.inst;

  assign rif.wb_reg_write = dut.wb_reg_write;
  assign rif.wb_rd        = dut.wb_rd;
  assign rif.wb_data      = dut.wb_data;

  assign rif.mem_read     = dut.mem_mem_read;
  assign rif.mem_write    = dut.mem_mem_write;
  assign rif.mem_addr     = dut.mem_alu_result;
  assign rif.mem_wdata    = dut.mem_rs2;
  assign rif.mem_rdata    = dut.mem_rdata;

  //--------------------------------------------
  // Assertions
  //--------------------------------------------

  property pc_alignment;
    @(posedge clk)
    disable iff(rst)
    dut.pc[1:0]==2'b00;
  endproperty

  assert property(pc_alignment)
  else
    $error("PC Alignment Error");


  property x0_constant;
    @(posedge clk)
    disable iff(rst)
    dut.u_reg.regs[0]==32'd0;
  endproperty

  assert property(x0_constant)
  else
    $error("x0 Modified");


 property wb_known;

 @(posedge clk)
 disable iff(rst)

 dut.wb_reg_write |-> !$isunknown(dut.wb_data);

endproperty

  assert property(wb_known)
  else
    $error("Unknown WB Data");


  property no_write_x0;
    @(posedge clk)
    disable iff(rst)
    dut.wb_reg_write |-> (dut.wb_rd!=0);
  endproperty

  assert property(no_write_x0)
  else
    $error("Attempt to write x0");


  property mem_rw;
    @(posedge clk)
    disable iff(rst)
    !(dut.mem_mem_read && dut.mem_mem_write);
  endproperty

  assert property(mem_rw)
  else
    $error("Read & Write together");


  //--------------------------------------------
  // Environment
  //--------------------------------------------

  environment env;

  initial begin

    env = new(rif);

    rst = 1;

    #20;

    rst = 0;

    env.run();

  end


  //--------------------------------------------
  // Waveform
  //--------------------------------------------

  initial begin

    $dumpfile("pipeline.vcd");

    $dumpvars(0,riscv_tb);

  end

endmodule
