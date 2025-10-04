package rv32i_types;
  typedef enum logic [6:0] {
    op_lui       = 7'b0110111, // load upper imemediate (U type)
    op_auipc     = 7'b0010111, // add upper imemediate PC (U type)
    op_jal       = 7'b1101111, // jump and link (J type)
    op_jalr      = 7'b1100111, // jump and link register (I type)
    op_br        = 7'b1100011, // branch (B type)
    op_load      = 7'b0000011, // load (I type)
    op_store     = 7'b0100011, // store (S type)
    op_imm       = 7'b0010011, // arith ops with register/imemediate operands (I type)
    op_reg       = 7'b0110011  // arith ops with register operands (R type)
  } rv32i_opcode;

  typedef enum logic [2:0] {
    beq  = 3'b000,
    bne  = 3'b001,
    blt  = 3'b100,
    bge  = 3'b101,
    bltu = 3'b110,
    bgeu = 3'b111
  } branch_funct3_t;

  typedef enum logic [2:0] {
    lb  = 3'b000,
    lh  = 3'b001,
    lw  = 3'b010,
    lbu = 3'b100,
    lhu = 3'b101
  } load_funct3_t;

  typedef enum logic [2:0] {
    sb = 3'b000,
    sh = 3'b001,
    sw = 3'b010
  } store_funct3_t;

  typedef enum logic [2:0] {
    add  = 3'b000, //check logic 30 for sub if op_reg opcode
    sll  = 3'b001,
    slt  = 3'b010,
    sltu = 3'b011,
    axor = 3'b100,
    sr   = 3'b101, //check logic 30 for logical/arithmetic
    aor  = 3'b110,
    aand = 3'b111
  } arith_funct3_t;

  typedef enum logic [2:0] {
    alu_add = 3'b000,
    alu_sll = 3'b001,
    alu_sra = 3'b010,
    alu_sub = 3'b011,
    alu_xor = 3'b100,
    alu_srl = 3'b101,
    alu_or  = 3'b110,
    alu_and = 3'b111
  } alu_ops;

  typedef enum logic {
    rs1_out = 1'b0,
    pc_out  = 1'b1
  } alu_m1_sel_t;

  typedef struct packed {
    logic valid;
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] inst;
  } if_id_t;

  typedef struct packed {
    logic valid;
    logic regf_we;       // 1 if write to regfile, 0 for no write
    logic mem_we;       // 1 if write to memory, 0 for no write
    logic mem_rd;       // 1 if read from memory, 0 for no read
    logic [31:0] pc;
    logic  [31:0] pc_next;
    logic  [6:0]  opcode;
    logic  [2:0]  funct3;
    logic  [4:0]  rd_s;
    logic  [6:0]  funct7;
    logic  [31:0] i_imm;
    logic  [31:0] s_imm;
    logic  [31:0] b_imm;
    logic  [31:0] u_imm;
    logic  [31:0] j_imm;
    logic  [31:0] rs1_v, rs2_v;
    logic [4:0]  rs1_s, rs2_s;
    logic [31:0] inst;
  } id_ex_t;

  typedef struct packed {
    logic valid;
    logic [31:0] rd_v;
    logic [2:0] funct3;
    logic [4:0]  rd_s;
    logic regf_we;       // 1 if write to regfile, 0 for no write
    logic mem_we;       // 1 if write to memory, 0 for no write
    logic mem_rd;       // 1 if read from memory, 0 for no read
    logic [31:0] inst;
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic  [31:0] rs1_v, rs2_v;
    logic [4:0]  rs1_s, rs2_s;
    logic [3:0] load_mask; // {lb, lh, lbu, lhu}
    logic load_half_s; // tells us how to sign extend
    logic load_byte_s;
    logic load_half_u;
    logic load_byte_u;
    logic [3:0] dmem_wmask;
    logic [3:0] dmem_rmask;
    logic [31:0] dmem_wdata;
    logic [31:0] dmem_addr;
  } ex_mem_t;

  typedef struct packed {
    logic valid;
    logic [4:0]  rd_s;
    logic [31:0] rd_v;
    logic regf_we;       
    logic [31:0] inst;
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic  [31:0] rs1_v, rs2_v;
    logic [4:0]  rs1_s, rs2_s;
    logic [3:0] dmem_wmask;
    logic [3:0] dmem_rmask;
    logic [31:0] dmem_rdata;
    logic [31:0] dmem_wdata;
    logic [31:0] dmem_addr;
    
  } mem_wb_t;

  // For forwarding register data
  typedef struct packed {
    logic [4:0] rd_s;
    logic [31:0] rd_v;
    logic regf_we;
  } fwd_t;

endpackage
