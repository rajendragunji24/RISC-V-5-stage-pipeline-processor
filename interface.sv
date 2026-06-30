interface riscv_if(input logic clk, rst);

  //=========================================================
  // Instruction Memory (Driven by Driver)
  //=========================================================
  logic [31:0] rom [0:255];

  //=========================================================
  // Monitor Signals
  // (Connected from DUT in riscv_tb.sv)
  //=========================================================

  // Program Counter
  logic [31:0] pc;

  // Current Instruction
  logic [31:0] instruction;

  // Register Write Back
  logic        wb_reg_write;
  logic [4:0]  wb_rd;
  logic [31:0] wb_data;

  // Memory Interface
  logic        mem_read;
  logic        mem_write;
  logic [31:0] mem_addr;
  logic [31:0] mem_wdata;
  logic [31:0] mem_rdata;

  //=========================================================
  // Driver Modport
  //=========================================================
  modport DRV (
      input  clk,
      input  rst,
      output rom
  );

  //=========================================================
  // Monitor Modport
  //=========================================================
  modport MON (
      input clk,
      input rst,

      input pc,
      input instruction,

      input wb_reg_write,
      input wb_rd,
      input wb_data,

      input mem_read,
      input mem_write,
      input mem_addr,
      input mem_wdata,
      input mem_rdata
  );

endinterface
