class transaction;

  //--------------------------------------------------
  // Random Instruction
  //--------------------------------------------------

rand bit [31:0] instr;

  string instr_name;

  //--------------------------------------------------
  // Expected Results
  //--------------------------------------------------

  bit [31:0] exp_x1;
  bit [31:0] exp_x2;
  bit [31:0] exp_x3;
  bit [31:0] exp_x4;
  bit [31:0] exp_x5;
  bit [31:0] exp_mem10;

  //--------------------------------------------------
  // Constraints
  //--------------------------------------------------

  constraint supported_instr
  {
      instr[6:0] inside
      {
          7'b0110011,   // ADD/SUB
          7'b0010011,   // ADDI
          7'b0000011,   // LW
          7'b0100011,   // SW
          7'b1100011    // BEQ
      };
  }

  //--------------------------------------------------
  // Functional Coverage
  //--------------------------------------------------

  covergroup instr_cg;

      option.per_instance = 1;

      //------------------------------------------

      opcode_cp : coverpoint instr[6:0]
      {
          bins add_sub = {7'b0110011};
          bins addi    = {7'b0010011};
          bins lw      = {7'b0000011};
          bins sw      = {7'b0100011};
          bins beq     = {7'b1100011};
      }

      //------------------------------------------

      funct3_cp : coverpoint instr[14:12]
      {
          bins add_sub = {3'b000};
          bins lw      = {3'b010};
          bins sw      = {3'b010};
          bins beq     = {3'b000};
      }

      //------------------------------------------

      rd_cp : coverpoint instr[11:7]
      {
          bins low_regs[]={[1:5]};
      }

      //------------------------------------------

      rs1_cp : coverpoint instr[19:15]
      {
          bins regs[]={[0:31]};
      }

      //------------------------------------------

      rs2_cp : coverpoint instr[24:20]
      {
          bins regs[]={[0:31]};
      }

      //------------------------------------------

      opcode_rd_cross :
      cross opcode_cp, rd_cp;

  endgroup

  //--------------------------------------------------
  // Constructor
  //--------------------------------------------------

  function new();

      instr_cg = new();

  endfunction

  //--------------------------------------------------
  // Sample Coverage
  //--------------------------------------------------

  function void sample();

      instr_cg.sample();

  endfunction

  //--------------------------------------------------
  // Display
  //--------------------------------------------------

  function void display();

      $display("---------------------------------------");
      $display("Instruction = %s",instr_name);
      $display("Instruction Hex = %08h",instr);
      $display("---------------------------------------");

  endfunction

  //--------------------------------------------------
  // Copy
  //--------------------------------------------------

  function transaction copy();

      transaction tr;

      tr = new();

      tr.instr      = this.instr;
      tr.instr_name = this.instr_name;

      tr.exp_x1     = this.exp_x1;
      tr.exp_x2     = this.exp_x2;
      tr.exp_x3     = this.exp_x3;
      tr.exp_x4     = this.exp_x4;
      tr.exp_x5     = this.exp_x5;

      tr.exp_mem10  = this.exp_mem10;

      return tr;

  endfunction

endclass
