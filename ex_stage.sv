module ex_stage
import rv32i_types::*;
(
  input   id_ex_t         id_ex_reg,
  output  ex_mem_t        ex_mem_reg_next,

  output  logic   [3:0]   dmem_rmask,
  output  logic   [3:0]   dmem_wmask,
  output  logic   [31:0]  dmem_wdata,
  output  logic   [31:0]  dmem_addr,  // Address to send to data memory
  output logic [31:0] pc_next,
  output logic jmp,
  output logic br_taken,
  output logic br_not_taken,
  input fwd_t mem_fwd, wb_fwd

);

  // ALU and comparator signals
  logic   [31:0]  a;
  logic   [31:0]  b;
  logic   [2:0]   aluop;
  logic   [2:0]   cmpop;
  logic   [31:0]  aluout;
  logic           cmpout;

  // Comparator
  cmp cmp_i (
    .a      (a),
    .b      (b),
    .cmpop  (cmpop),
    .cmpout (cmpout)
  );

  // ALU
  alu alu(
    .a      (a),
    .b      (b),
    .aluop  (aluop),
    .aluout (aluout)
  );

  logic [1:0] byte_align;

  logic [31:0] fwd_rs1, fwd_rs2;

  always_comb begin
    // Initialize signals to alu, cmp, and ex_mem_reg_next
    ex_mem_reg_next = '0;
    // ex_mem_reg_next.rs1_v = a;

    a = id_ex_reg.rs1_v;
    b = id_ex_reg.rs2_v;

    if(id_ex_reg.rs1_s != 0 && id_ex_reg.rs1_s == mem_fwd.rd_s && mem_fwd.regf_we) begin
      fwd_rs1 = mem_fwd.rd_v;
    end else if (id_ex_reg.rs1_s != 0 && id_ex_reg.rs1_s == wb_fwd.rd_s && wb_fwd.regf_we) begin
      fwd_rs1 = wb_fwd.rd_v;
    end else begin
      fwd_rs1 = id_ex_reg.rs1_v;
    end

    if(id_ex_reg.rs2_s != 0 && id_ex_reg.rs2_s == mem_fwd.rd_s && mem_fwd.regf_we) begin
      fwd_rs2 = mem_fwd.rd_v;
    end else if (id_ex_reg.rs2_s != 0 && id_ex_reg.rs2_s == wb_fwd.rd_s && wb_fwd.regf_we) begin
      fwd_rs2 = wb_fwd.rd_v;
    end else begin
      fwd_rs2 = id_ex_reg.rs2_v;
    end

    ex_mem_reg_next.mem_rd = id_ex_reg.mem_rd;
    ex_mem_reg_next.mem_we = id_ex_reg.mem_we;
    ex_mem_reg_next.rd_s     = id_ex_reg.rd_s;
    ex_mem_reg_next.regf_we = id_ex_reg.regf_we;
    ex_mem_reg_next.rd_v = 32'd0;


    
    aluop = alu_add; // Default to ADD operation
    cmpop = beq; // Default to BEQ operation
    ex_mem_reg_next.valid = id_ex_reg.valid;
    byte_align = 2'b0;

    //rvfi signals
    ex_mem_reg_next.pc = id_ex_reg.pc;
    ex_mem_reg_next.pc_next = id_ex_reg.pc_next;
    ex_mem_reg_next.inst = id_ex_reg.inst;
    ex_mem_reg_next.rs1_v = fwd_rs1;
    ex_mem_reg_next.rs2_v = fwd_rs2;
    ex_mem_reg_next.rs1_s = id_ex_reg.rs1_s;
    ex_mem_reg_next.rs2_s = id_ex_reg.rs2_s;
    ex_mem_reg_next.load_mask = 4'h0;
    ex_mem_reg_next.dmem_addr = dmem_addr;

    ex_mem_reg_next.dmem_rmask = dmem_rmask;



    ex_mem_reg_next.funct3 = id_ex_reg.funct3;

    dmem_rmask = 4'b0000;
    dmem_wmask = 4'b0000;
    dmem_addr  = 32'd0;
    dmem_wdata = 32'd0;
    jmp = '0;
    br_taken = '0;
    br_not_taken = '0;
    pc_next = id_ex_reg.pc_next;

    ex_mem_reg_next.dmem_wdata = dmem_wdata; // zero by default
    ex_mem_reg_next.dmem_wmask = dmem_wmask;

    

    case(id_ex_reg.opcode)
      op_imm: begin
        a = fwd_rs1;
        b = id_ex_reg.i_imm;
        ex_mem_reg_next.rs1_v = fwd_rs1;
        ex_mem_reg_next.rs2_v = '0;
        ex_mem_reg_next.rs2_s = '0;
        case(id_ex_reg.funct3)
          3'b000: begin // ADDI
            case(id_ex_reg.funct7[5])
              1'b0: begin
                aluop = alu_add;
              end
              1'b1: begin
                aluop = alu_add; // Default to ADDI behavior
              end
            endcase
            ex_mem_reg_next.rd_v = aluout;
            
          end
          3'b010: begin // SLTI
            cmpop = blt;
            case(cmpout)
              1'b1: begin
                ex_mem_reg_next.rd_v = 32'd1;
              end
              1'b0: begin
                ex_mem_reg_next.rd_v = 32'd0;
              end
            endcase
          end
          3'b011: begin // SLTIU
            cmpop = bltu;
            case(cmpout)
              1'b1: begin
                ex_mem_reg_next.rd_v = 32'd1;
              end
              1'b0: begin
                ex_mem_reg_next.rd_v = 32'd0;
              end
            endcase
          end
          3'b100: begin // XORI
            aluop = alu_xor;
            ex_mem_reg_next.rd_v = aluout;
          end
          3'b110: begin // ORI
            aluop = alu_or;
            ex_mem_reg_next.rd_v = aluout;
          end
          3'b111: begin // ANDI
            aluop = alu_and;
            ex_mem_reg_next.rd_v = aluout;
          end
          3'b001: begin // SLLI
            aluop = alu_sll;
            ex_mem_reg_next.rd_v = aluout;
          end
          3'b101: begin // SRLI, SRAI
            if (id_ex_reg.funct7[5]) begin // SRAI
              aluop = alu_sra;
            end else begin // SRLI
              aluop = alu_srl;
            end
            ex_mem_reg_next.rd_v = aluout;
          end
          default: begin
            aluop = alu_add; // Default to ADDI behavior
            b     = 0;
            ex_mem_reg_next.rd_v = aluout;
            ex_mem_reg_next.valid = 1'b0;
          end

        endcase

      end
      op_reg: begin
        a = fwd_rs1;
        b = fwd_rs2;
        ex_mem_reg_next.rs1_v = fwd_rs1;
        ex_mem_reg_next.rs2_v = fwd_rs2;
        case(id_ex_reg.funct3)
          3'b000: begin // ADD, SUB
            if (id_ex_reg.funct7[5]) begin // SUB
              aluop = alu_sub;
            end else begin // ADD
              aluop = alu_add;
            end
            ex_mem_reg_next.rd_v = aluout;
          end
          3'b001: begin // SLL
            aluop = alu_sll;
            ex_mem_reg_next.rd_v = aluout;
          end
          3'b010: begin // SLT
            cmpop = blt;
            case(cmpout)
              1'b1: begin
                ex_mem_reg_next.rd_v = 32'd1;
              end
              1'b0: begin
                ex_mem_reg_next.rd_v = 32'd0;
              end
            endcase
          end
          3'b011: begin // SLTU
            cmpop = bltu;
            case(cmpout)
              1'b1: begin
                ex_mem_reg_next.rd_v = 32'd1;
              end
              1'b0: begin
                ex_mem_reg_next.rd_v = 32'd0;
              end
            endcase
          end
          3'b100: begin // XOR
            aluop = alu_xor;
            ex_mem_reg_next.rd_v = aluout;
          end
          3'b110: begin // OR
            aluop = alu_or;
            ex_mem_reg_next.rd_v = aluout;
          end
          3'b111: begin // AND
            aluop = alu_and;
            ex_mem_reg_next.rd_v = aluout;
          end
          3'b101: begin // SRL, SRA
            if (id_ex_reg.funct7[5]) begin // SRA
              aluop = alu_sra;
            end else begin // SRL
              aluop = alu_srl;
            end
            ex_mem_reg_next.rd_v = aluout;
          end
          default: begin
            aluop = alu_add; // Default to ADD behavior
            b     = 0;
            ex_mem_reg_next.rd_v = aluout;
            ex_mem_reg_next.valid = 1'b0;
          end
        endcase
      end
      op_load: begin
        a = fwd_rs1;
        ex_mem_reg_next.rs1_v = fwd_rs1;
        ex_mem_reg_next.rs2_s = '0;
        ex_mem_reg_next.dmem_wmask = '0;
        aluop = alu_add; // Calculate address
        b     = id_ex_reg.i_imm;
        ex_mem_reg_next.rd_v = {aluout[31:2], 2'b00};
        dmem_addr = {aluout[31:2], 2'b00}; // Address to send to data memory
        ex_mem_reg_next.dmem_addr = {aluout[31:2], 2'b00};
        byte_align = aluout[1:0];
        case(id_ex_reg.funct3)
          lb: begin
            dmem_rmask = 4'b0001 << byte_align;
            ex_mem_reg_next.load_mask[0] = 1'b1;
            ex_mem_reg_next.dmem_rmask = 4'b0001 << byte_align;
          end
          lh: begin
            dmem_rmask = 4'b0011 << {byte_align[1], 1'b0};
            ex_mem_reg_next.load_mask[1] = 1'b1;
            ex_mem_reg_next.dmem_rmask = 4'b0011 << {byte_align[1], 1'b0};
          end
          lw: begin
            dmem_rmask = 4'b1111;
            ex_mem_reg_next.dmem_rmask = 4'b1111;
          end
          lbu: begin
            dmem_rmask = 4'b0001 << byte_align;
            ex_mem_reg_next.load_mask[2] = 1'b1;
            ex_mem_reg_next.dmem_rmask = 4'b0001 << byte_align;
          end
          lhu: begin
            dmem_rmask = 4'b0011 << {byte_align[1], 1'b0};
            ex_mem_reg_next.load_mask[3] = 1'b1;
            ex_mem_reg_next.dmem_rmask = 4'b0011 << {byte_align[1], 1'b0};
          end
          default: begin
            dmem_rmask = 4'b0000;
            ex_mem_reg_next.valid = 1'b0;
            ex_mem_reg_next.dmem_rmask =  4'b0000;
          end
        endcase
      end
      op_store: begin
        a = fwd_rs1;
        ex_mem_reg_next.rs1_v = fwd_rs1;
        ex_mem_reg_next.dmem_rmask = '0;
        ex_mem_reg_next.rd_s = '0;
        aluop = alu_add; // Calculate address
        b     = id_ex_reg.s_imm;
        ex_mem_reg_next.rs2_v = fwd_rs2;
        ex_mem_reg_next.rd_v = aluout;
        dmem_addr = {aluout[31:2], 2'b00}; // Address to send to data memory
        ex_mem_reg_next.dmem_addr = {aluout[31:2], 2'b00};
        byte_align = aluout[1:0];

        // ex_mem_reg_next.rs2_v = id_ex_reg.rs2_v; // Value to store
        dmem_wdata = fwd_rs2;
        case(id_ex_reg.funct3)
          sb: begin
            case (byte_align)
            2'b00: begin 
              dmem_wmask = 4'b0001; 
              dmem_wdata = {24'h000000, dmem_wdata[7:0]};
              ex_mem_reg_next.dmem_wmask = dmem_wmask;
              ex_mem_reg_next.dmem_wdata = dmem_wdata;
            end
            2'b01: begin 
              dmem_wmask = 4'b0010; 
              dmem_wdata = {16'h0000, dmem_wdata[7:0], 8'h00};
              ex_mem_reg_next.dmem_wmask = dmem_wmask;
              ex_mem_reg_next.dmem_wdata = dmem_wdata;
            end
            2'b10: begin 
              dmem_wmask = 4'b0100; 
              dmem_wdata = {8'h00, dmem_wdata[7:0], 16'h0000};
              ex_mem_reg_next.dmem_wmask = dmem_wmask;
              ex_mem_reg_next.dmem_wdata = dmem_wdata;
            end
            2'b11: begin 
              dmem_wmask = 4'b1000; 
              dmem_wdata = {dmem_wdata[7:0], 24'h000000};
              ex_mem_reg_next.dmem_wmask = dmem_wmask;
              ex_mem_reg_next.dmem_wdata = dmem_wdata;
            end
            endcase
          end
          sh: begin
            case(byte_align)
            2'b00: begin
              dmem_wmask = 4'b0011;
              dmem_wdata = {16'h0, dmem_wdata[15:0]};
              ex_mem_reg_next.dmem_wmask = dmem_wmask;
              ex_mem_reg_next.dmem_wdata = dmem_wdata;
            end
            2'b10: begin
              dmem_wmask = 4'b1100;
              dmem_wdata = {dmem_wdata[15:0], 16'h0};
              ex_mem_reg_next.dmem_wmask = dmem_wmask;
              ex_mem_reg_next.dmem_wdata = dmem_wdata;
            end
            default:begin
              dmem_wmask = 4'b0000;
              ex_mem_reg_next.dmem_wmask = 4'h0;
              ex_mem_reg_next.valid = 1'b0;
            end

            endcase
          end
          sw: begin
            dmem_wmask = 4'b1111;
            ex_mem_reg_next.dmem_wmask = dmem_wmask;
            ex_mem_reg_next.dmem_wdata = dmem_wdata;
          end
          default: begin
            dmem_wmask = 4'b0000;
            ex_mem_reg_next.dmem_wmask = 4'h0;
            ex_mem_reg_next.valid = 1'b0;
          end

        endcase
      end
      op_lui: begin
        ex_mem_reg_next.rd_v = id_ex_reg.u_imm;
        ex_mem_reg_next.rs2_v = '0;
        ex_mem_reg_next.rs2_s = '0;
        ex_mem_reg_next.rs1_v = '0;
        ex_mem_reg_next.rs1_s = '0;
      end
      op_auipc: begin
        aluop = alu_add;
        a     = id_ex_reg.pc;
        b     = id_ex_reg.u_imm;
        ex_mem_reg_next.rd_v = aluout;
        ex_mem_reg_next.rs1_v = '0;
        ex_mem_reg_next.rs1_s = '0;
        ex_mem_reg_next.rs2_v = '0;
        ex_mem_reg_next.rs2_s = '0;
      end
      op_jal: begin
        aluop = alu_add;
        a = id_ex_reg.pc;
        b     = id_ex_reg.j_imm;
        pc_next = aluout; // Target address
        ex_mem_reg_next.pc_next = pc_next;
        ex_mem_reg_next.rd_v = id_ex_reg.pc + 'd4; // PC + 4 to go to rd
        ex_mem_reg_next.rs2_v = '0;
        ex_mem_reg_next.rs2_s = '0;
        jmp = '1 & id_ex_reg.valid;
      end
      op_jalr: begin
        a = fwd_rs1;
        ex_mem_reg_next.rs1_v = fwd_rs1;
        ex_mem_reg_next.rs2_v = '0;
        ex_mem_reg_next.rs2_s = '0;
        aluop = alu_add;
        b     = id_ex_reg.i_imm;
        pc_next = aluout & ~32'd1; // Target address
        ex_mem_reg_next.pc_next = pc_next;
        ex_mem_reg_next.rd_v = id_ex_reg.pc + 'd4; // PC + 4 to go to rd
        jmp = '1 & id_ex_reg.valid;
      end
      op_br: begin
        a = fwd_rs1;
        b = fwd_rs2;
        ex_mem_reg_next.rs1_v = fwd_rs1;
        ex_mem_reg_next.rs2_v = fwd_rs2;
        ex_mem_reg_next.rd_s = '0;
        case(id_ex_reg.funct3)
          beq: begin // BEQ
            cmpop = beq;
          end
          bne: begin // BNE
            cmpop = bne;
          end
          blt: begin // BLT
            cmpop = blt;
          end
          bge: begin // BGE
            cmpop = bge;
          end
          bltu: begin // BLTU
            cmpop = bltu;
          end
          bgeu: begin // BGEU
            cmpop = bgeu;
          end
          default: begin
            cmpop = beq; // Default to BEQ behavior
            b     = 0;
            ex_mem_reg_next.valid = 1'b0;
          end
        endcase
        if (cmpout) begin
          pc_next = id_ex_reg.pc + id_ex_reg.b_imm; // Branch taken
          br_taken = '1 & id_ex_reg.valid;
          jmp = '1 & id_ex_reg.valid;
        end else begin
          ex_mem_reg_next.pc_next = id_ex_reg.pc_next; // Branch not taken, go to next instruction
          br_not_taken = '1 & id_ex_reg.valid;
        end
        ex_mem_reg_next.pc_next = pc_next;
      end
      default: begin
        ex_mem_reg_next.rs2_v = '0;
        ex_mem_reg_next.rs2_s = '0;
        aluop = alu_add; // Default to ADDI behavior
        b     = 0;
        ex_mem_reg_next.rd_v = aluout;
        ex_mem_reg_next.valid = 1'b0;
      end
      

    endcase
  end
endmodule : ex_stage
