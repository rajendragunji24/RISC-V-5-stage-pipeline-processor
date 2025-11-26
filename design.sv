`timescale 1ns/1ps

//==========================================================
// Program Counter
//==========================================================
module pc(input logic clk, rst,
          input logic [31:0] pc_next,
          output logic [31:0] pc_out);

  always_ff @(posedge clk or posedge rst) begin
    if (rst) pc_out <= 0;
    else     pc_out <= pc_next;
  end
endmodule

//==========================================================
// IF/ID Pipeline Register (with stall + flush)
//==========================================================
module if_id(input logic clk, rst,
             input logic stall,
             input logic flush,
             input logic [31:0] pc_in, inst_in,
             output logic [31:0] pc_out, inst_out);

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      pc_out   <= 0;
      inst_out <= 0;
    end
    else if (flush) begin
      pc_out   <= 0;
      inst_out <= 0;
    end
    else if (stall) begin
      pc_out   <= pc_out;   // hold
      inst_out <= inst_out;
    end
    else begin
      pc_out   <= pc_in;
      inst_out <= inst_in;
    end
  end
endmodule

//==========================================================
// Register File (with debug print)
//==========================================================
module reg_file(input logic clk,
                input logic we,
                input logic [4:0] r1, r2, rd,
                input logic [31:0] wdata,
                output logic [31:0] d1, d2);

  logic [31:0] regs[0:31];

  initial begin
    for (int i=0; i<32; i++) regs[i] = 0;
  end

  assign d1 = regs[r1];
  assign d2 = regs[r2];

  always_ff @(posedge clk) begin
    if (we && rd != 0) begin
      regs[rd] <= wdata;
      $display("[%0t] REGFILE WRITE: rd=%0d wdata=0x%08h (dec %0d) we=%b", $time, rd, wdata, wdata, we);
    end
  end
endmodule

//==========================================================
// Immediate Generator
//==========================================================
module imm_gen(input logic [31:0] inst,
               output logic [31:0] imm);

  always_comb begin
    case (inst[6:0])
      7'b0000011: imm = {{20{inst[31]}}, inst[31:20]};                 // LW
      7'b0010011: imm = {{20{inst[31]}}, inst[31:20]};                 // ADDI
      7'b0100011: imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};     // SW
      7'b1100011: imm = {{19{inst[31]}}, inst[31], inst[7],
                         inst[30:25], inst[11:8], 1'b0};               // BEQ
      default:    imm = 0;
    endcase
  end
endmodule

//==========================================================
// ALU
//==========================================================
module alu(input logic [31:0] a, b,
           input logic [3:0] alu_ctrl,
           output logic [31:0] result,
           output logic zero);

  always_comb begin
    case (alu_ctrl)
      4'b0000: result = a + b;
      4'b1000: result = a - b;
      default: result = 0;
    endcase
  end

  assign zero = (result == 0);
endmodule

//==========================================================
// Data Memory (word indexed) with optional debug prints
//==========================================================
module data_mem(input logic clk,
                input logic mem_read, mem_write,
                input logic [31:0] addr, wdata,
                output logic [31:0] rdata);

  logic [31:0] ram[0:255];   // 256 words

  assign rdata = mem_read ? ram[addr[31:2]] : 0;

  always_ff @(posedge clk) begin
    if (mem_write) begin
      ram[addr[31:2]] <= wdata;
      $display("[%0t] DATA_MEM WRITE: addr_byte=%0d word_index=%0d data=%0d (0x%08h)", $time, addr, addr[31:2], wdata, wdata);
    end
    if (mem_read) begin
      $display("[%0t] DATA_MEM READ : addr_byte=%0d word_index=%0d data=%0d (0x%08h)", $time, addr, addr[31:2], ram[addr[31:2]], ram[addr[31:2]]);
    end
  end

  initial begin
    for (int i=0; i<256; i++)
      ram[i] = 0;
  end
endmodule

//==========================================================
// TOP: 5-Stage RISC-V Pipeline (with Forwarding + Stall)
//==========================================================
module riscv_pipeline(input logic clk, rst);

// IF stage
logic [31:0] pc, pc_next, inst;

// ROM (instruction memory)
logic [31:0] rom[0:255];
assign inst = rom[pc[31:2]];

// IF/ID pipeline regs
logic [31:0] id_pc, id_inst;

// ID stage
logic [4:0]  id_rs1, id_rs2, id_rd;
logic [31:0] id_rs1_data, id_rs2_data, id_imm;
logic [6:0]  id_opcode;
logic        id_f7_30;
logic        id_mem_read, id_mem_write, id_reg_write;
logic        id_alu_src, id_branch;
logic [3:0]  id_alu_ctrl;

// EX stage regs
logic [31:0] ex_pc;
logic [4:0]  ex_rs1, ex_rs2;
logic [4:0]  ex_rd;
logic [31:0] ex_rs1_data, ex_rs2_data, ex_imm;
logic        ex_mem_read, ex_mem_write, ex_reg_write;
logic        ex_alu_src, ex_branch;
logic [3:0]  ex_alu_ctrl;

logic [31:0] alu_op1, alu_op2, ex_alu_in2, ex_alu_result;
logic        ex_zero;

// Forwarding
logic [1:0] forwardA, forwardB;
logic [31:0] ex_rs2_fwd;

// MEM stage regs
logic [31:0] mem_alu_result, mem_rs2;
logic [4:0]  mem_rd;
logic        mem_mem_read, mem_mem_write, mem_reg_write;
logic [31:0] mem_rdata;

// WB stage regs
logic [31:0] wb_data;
logic [4:0]  wb_rd;
logic        wb_reg_write;

// Stall + Flush
logic stall, flush, branch_taken;

// Module instantiation (explicit)
pc u_pc(.clk(clk), .rst(rst), .pc_next(pc_next), .pc_out(pc));

if_id u_ifid(.clk(clk), .rst(rst), .stall(stall), .flush(flush),
             .pc_in(pc), .inst_in(inst), .pc_out(id_pc), .inst_out(id_inst));

reg_file u_reg(.clk(clk), .we(wb_reg_write),
               .r1(id_rs1), .r2(id_rs2),
               .rd(wb_rd), .wdata(wb_data),
               .d1(id_rs1_data), .d2(id_rs2_data));

imm_gen u_imm(.inst(id_inst), .imm(id_imm));

alu u_alu(.a(alu_op1), .b(ex_alu_in2), .alu_ctrl(ex_alu_ctrl),
          .result(ex_alu_result), .zero(ex_zero));

data_mem u_dmem(.clk(clk), .mem_read(mem_mem_read), .mem_write(mem_mem_write),
                .addr(mem_alu_result), .wdata(mem_rs2), .rdata(mem_rdata));

// DECODE
assign id_rs1 = id_inst[19:15];
assign id_rs2 = id_inst[24:20];
assign id_rd  = id_inst[11:7];
assign id_opcode = id_inst[6:0];
assign id_f7_30  = id_inst[30];

always_comb begin
  id_mem_read  = 0;
  id_mem_write = 0;
  id_reg_write = 0;
  id_alu_src   = 0;
  id_branch    = 0;
  id_alu_ctrl  = 4'b0000;

  case (id_opcode)
    7'b0110011: begin               // ADD, SUB
      id_reg_write = 1;
      id_alu_ctrl  = id_f7_30 ? 4'b1000 : 4'b0000;
    end

    7'b0010011: begin               // ADDI
      id_reg_write = 1;
      id_alu_src   = 1;
    end

    7'b0000011: begin               // LW
      id_reg_write = 1;
      id_mem_read  = 1;
      id_alu_src   = 1;
    end

    7'b0100011: begin               // SW
      id_mem_write = 1;
      id_alu_src   = 1;
    end

    7'b1100011: begin               // BEQ
      id_branch   = 1;
      id_alu_ctrl = 4'b1000;        // SUB for comparison
    end
  endcase
end

// Hazard detection (load-use)
always_comb begin
  stall = 0;
  if (ex_mem_read && (ex_rd != 0) &&
      ((ex_rd == id_rs1) || (ex_rd == id_rs2)))
    stall = 1;
end

// ID->EX pipeline
always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
      ex_pc        <= 0;
      ex_rs1       <= 0;
      ex_rs2       <= 0;
      ex_rs1_data  <= 0;
      ex_rs2_data  <= 0;
      ex_imm       <= 0;
      ex_rd        <= 0;
      ex_mem_read  <= 0;
      ex_mem_write <= 0;
      ex_reg_write <= 0;
      ex_alu_src   <= 0;
      ex_branch    <= 0;
      ex_alu_ctrl  <= 0;
  end
  else if (!stall) begin   // <------ FIX!!
      ex_pc        <= id_pc;
      ex_rs1       <= id_rs1;
      ex_rs2       <= id_rs2;
      ex_rs1_data  <= id_rs1_data;
      ex_rs2_data  <= id_rs2_data;
      ex_imm       <= id_imm;
      ex_rd        <= id_rd;
      ex_mem_read  <= id_mem_read;
      ex_mem_write <= id_mem_write;
      ex_reg_write <= id_reg_write;
      ex_alu_src   <= id_alu_src;
      ex_branch    <= id_branch;
      ex_alu_ctrl  <= id_alu_ctrl;
  end
  // else: HOLD PREVIOUS EX VALUES (stall)
end

// Forwarding unit
always_comb begin
  forwardA = 2'b00;
  forwardB = 2'b00;

  if (mem_reg_write && mem_rd != 0 && mem_rd == ex_rs1)
    forwardA = 2'b10;

  if (mem_reg_write && mem_rd != 0 && mem_rd == ex_rs2)
    forwardB = 2'b10;

  if (wb_reg_write && wb_rd != 0 && wb_rd == ex_rs1 && forwardA == 0)
    forwardA = 2'b01;

  if (wb_reg_write && wb_rd != 0 && wb_rd == ex_rs2 && forwardB == 0)
    forwardB = 2'b01;
end

// Operand selection via forwarding
always_comb begin
  case (forwardA)
    2'b00: alu_op1 = ex_rs1_data;
    2'b10: alu_op1 = mem_alu_result;
    2'b01: alu_op1 = wb_data;
    default: alu_op1 = ex_rs1_data;
  endcase

  case (forwardB)
    2'b00: alu_op2 = ex_rs2_data;
    2'b10: alu_op2 = mem_alu_result;
    2'b01: alu_op2 = wb_data;
    default: alu_op2 = ex_rs2_data;
  endcase
end

// store-data forwarding
always_comb begin
  case (forwardB)
    2'b00: ex_rs2_fwd = ex_rs2_data;
    2'b10: ex_rs2_fwd = mem_alu_result;
    2'b01: ex_rs2_fwd = wb_data;
    default: ex_rs2_fwd = ex_rs2_data;
  endcase
end

assign ex_alu_in2 = ex_alu_src ? ex_imm : alu_op2;

// Branch logic
assign branch_taken = ex_branch && ex_zero;
assign flush = branch_taken || stall;

always_comb begin
  if (stall)           pc_next = pc;
  else if (flush)      pc_next = ex_pc + ex_imm;
  else                 pc_next = pc + 4;
end

// EX->MEM pipeline
always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
    mem_alu_result <= 0;
    mem_rs2        <= 0;
    mem_rd         <= 0;
    mem_mem_read   <= 0;
    mem_mem_write  <= 0;
    mem_reg_write  <= 0;
  end
  else begin
    mem_alu_result <= ex_alu_result;
    mem_rs2        <= ex_rs2_fwd;
    mem_rd         <= ex_rd;
    mem_mem_read   <= ex_mem_read;
    mem_mem_write  <= ex_mem_write;
    mem_reg_write  <= ex_reg_write;
  end
end

// MEM->WB pipeline (with debug print)
always_ff @(posedge clk or posedge rst) begin
  if (rst) begin
    wb_data       <= 0;
    wb_rd         <= 0;
    wb_reg_write  <= 0;
  end
  else begin
    wb_data       <= mem_mem_read ? mem_rdata : mem_alu_result;
    wb_rd         <= mem_rd;
    wb_reg_write  <= mem_reg_write;

    $display("[%0t] WB_STAGE : mem_mem_read=%b mem_mem_write=%b mem_rd=%0d mem_reg_write=%b mem_rdata=0x%08h mem_alu_result=0x%08h | wb_data=0x%08h wb_rd=%0d wb_reg_write=%b",
             $time, mem_mem_read, mem_mem_write, mem_rd, mem_reg_write, mem_rdata, mem_alu_result,
             (mem_mem_read ? mem_rdata : mem_alu_result), mem_rd, mem_reg_write);
  end
end

endmodule

