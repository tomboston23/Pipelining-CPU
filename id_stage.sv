module id_stage
import rv32i_types::*;
(
  output logic [4:0] rs1_s,
  output logic [4:0] rs2_s,
  input logic [31:0] rs1_v,
  input logic [31:0] rs2_v,
  input if_id_t      if_id_reg,
  output id_ex_t     id_ex_reg_next

);

  logic   [6:0]   opcode;

  assign opcode = if_id_reg.inst[6:0];



  logic [31:0] i_imm, j_imm, s_imm, u_imm, b_imm;
  assign i_imm = {{21{if_id_reg.inst[31]}}, if_id_reg.inst[30:20]};
  assign j_imm = {{12{if_id_reg.inst[31]}}, if_id_reg.inst[19:12], if_id_reg.inst[20], if_id_reg.inst[30:21], 1'b0};
  assign s_imm = {{21{if_id_reg.inst[31]}}, if_id_reg.inst[30:25], if_id_reg.inst[11:7]};
  assign u_imm = {if_id_reg.inst[31:12], 12'h000};
  assign b_imm = {{20{if_id_reg.inst[31]}}, if_id_reg.inst[7], if_id_reg.inst[30:25], if_id_reg.inst[11:8], 1'b0};

  always_comb begin
    id_ex_reg_next = '0;
    id_ex_reg_next.mem_rd = 1'b0;
    id_ex_reg_next.mem_we = 1'b0;
    id_ex_reg_next.regf_we = 1'b0;
    
    id_ex_reg_next.funct3 = if_id_reg.inst[14:12];
    id_ex_reg_next.funct7 = if_id_reg.inst[31:25];
    id_ex_reg_next.opcode = opcode;
    id_ex_reg_next.rd_s   = if_id_reg.inst[11:7];


    id_ex_reg_next.i_imm  = i_imm;
    id_ex_reg_next.s_imm  = s_imm;
    id_ex_reg_next.b_imm  = b_imm;
    id_ex_reg_next.u_imm  = u_imm;
    id_ex_reg_next.j_imm  = j_imm;

    rs1_s  = if_id_reg.inst[19:15];
    rs2_s  = if_id_reg.inst[24:20];

    //rvfi 
    id_ex_reg_next.pc = if_id_reg.pc;
    id_ex_reg_next.pc_next = if_id_reg.pc_next;
    
    id_ex_reg_next.inst = if_id_reg.inst;

    id_ex_reg_next.valid = if_id_reg.valid;
    id_ex_reg_next.rs1_v = rs1_v;
    id_ex_reg_next.rs2_v = rs2_v;

    case(opcode)
      op_lui: begin // U-type
        id_ex_reg_next.regf_we = 1'b1;
        rs1_s = '0;
        rs2_s = '0;
      end
      op_auipc: begin // U-type
        id_ex_reg_next.regf_we = 1'b1;
        rs1_s = '0;
        rs2_s = '0;
      end
      op_jal: begin // J-type
        id_ex_reg_next.regf_we = 1'b1;
        rs1_s = '0;
        rs2_s = '0;
      end
      op_jalr: begin // I-type
        id_ex_reg_next.regf_we = 1'b1;
        rs2_s = '0;
      end
      op_br: begin // B-type -- do no reads or writes
        id_ex_reg_next.regf_we = 1'b0;
        rs2_s = rs2_s;
      end
      op_load: begin // I-type
        id_ex_reg_next.regf_we = 1'b1;
        id_ex_reg_next.mem_rd = 1'b1;
        rs2_s = '0;
      end
      op_store: begin // S-type
        id_ex_reg_next.mem_we = 1'b1;
      end
      op_imm: begin // I-type
        id_ex_reg_next.regf_we = 1'b1;
        rs2_s = '0;
      end
      op_reg: begin // R-type
        id_ex_reg_next.regf_we = 1'b1;
      end
      default: begin
        id_ex_reg_next.valid      = 1'b0;
      end
    endcase
  
    id_ex_reg_next.rs1_s = rs1_s;
    id_ex_reg_next.rs2_s = rs2_s;
  end
endmodule : id_stage
