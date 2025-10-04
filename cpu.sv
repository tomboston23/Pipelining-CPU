module cpu
import rv32i_types::*;
(
    input logic         clk,
    input logic         rst,

    output logic [31:0] imem_addr,
    output logic [3:0]  imem_rmask,
    input logic [31:0]  imem_rdata,
    input logic         imem_resp,

    output logic [31:0] dmem_addr,
    output logic [3:0]  dmem_rmask,
    output logic [3:0]  dmem_wmask,
    input logic [31:0]  dmem_rdata,
    output logic [31:0] dmem_wdata,
    input logic         dmem_resp
);
  // ----
  // Signal Declarations & Logic
  // ----

  // Stall Signals
  logic           global_stall;
  logic           imem_stall;
  logic           dmem_stall;
  logic rvfi_valid;



  // PC
  logic [31:0]    pc, pc_next, pc_jmp;

  // Regfile Signals
  logic [4:0]     rs1_s, rs2_s, wb_rd_s;
  logic           wb_regf_we;
  logic [31:0]    rs1_v, rs2_v, wb_rd_v;

  // Stage registers
  if_id_t  if_id_reg,  if_id_reg_next;
  id_ex_t  id_ex_reg,  id_ex_reg_next;
  ex_mem_t ex_mem_reg, ex_mem_reg_next;
  mem_wb_t mem_wb_reg, mem_wb_reg_next;

  fwd_t mem_fwd, wb_fwd;

  assign mem_fwd.rd_v = ex_mem_reg.rd_v; 
  assign mem_fwd.rd_s = ex_mem_reg.rd_s;
  assign mem_fwd.regf_we = ex_mem_reg.valid & ex_mem_reg.regf_we & (~ex_mem_reg.mem_rd);

  assign wb_fwd.rd_v = mem_wb_reg.rd_v;
  assign wb_fwd.rd_s = mem_wb_reg.rd_s;
  assign wb_fwd.regf_we = mem_wb_reg.valid & mem_wb_reg.regf_we;

  logic load_hazard;

  assign load_hazard = (id_ex_reg.mem_rd & ((rs1_s == id_ex_reg.rd_s) | (rs2_s == id_ex_reg.rd_s)) & (|id_ex_reg.rd_s));

  logic inst_latched;
  
  logic jmp, br_taken, br_not_taken;

  logic [31:0] inst_latch;

  
  logic if_id_st, pc_st, id_ex_st;
  logic if_id_clr, id_ex_clr;

  always_comb begin

    if_id_st = '0;
    if_id_clr = '0;
    id_ex_clr = '0;
    id_ex_st = '0;
    pc_st = '0;

    if (jmp) begin
      if_id_clr = '1;
      id_ex_clr = '1;
    end 
    if (load_hazard) begin
      id_ex_clr = '1;
      if_id_st = '1;
      pc_st = '1;
    end
  end


  logic [63:0] rvfi_order;

  logic dmem_req;
  assign dmem_req = (|ex_mem_reg.dmem_rmask) | (|ex_mem_reg.dmem_wmask);
  logic [3:0] dmem_rmask_ex;
  logic [3:0] dmem_wmask_ex;
  logic [31:0] dmem_addr_ex, dmem_wdata_ex;



  
  assign dmem_stall = ex_mem_reg.valid & dmem_req & ~dmem_resp;

  always_comb begin

    if (!global_stall) begin
      dmem_rmask = dmem_rmask_ex;
      dmem_wmask = dmem_wmask_ex;
      dmem_wdata = dmem_wdata_ex;
      dmem_addr = dmem_addr_ex;
    end else begin
      dmem_rmask = ex_mem_reg.dmem_rmask;
      dmem_wmask = ex_mem_reg.dmem_wmask;
      dmem_wdata = ex_mem_reg.dmem_wdata;
      dmem_addr = ex_mem_reg.dmem_addr;
    end

  end

  assign global_stall = imem_stall || dmem_stall;

  assign pc_next = jmp ? pc_jmp : pc + 'd4;
  always_ff @(posedge clk) begin
    if (rst) begin
      pc <= 32'haaaa_a000;
      if_id_reg <= '0;
      id_ex_reg <= '0;
      ex_mem_reg <= '0;
      mem_wb_reg <= '0;

    end else if (!global_stall) begin
      ex_mem_reg <= ex_mem_reg_next;
      mem_wb_reg <= mem_wb_reg_next;


      if(if_id_clr) begin
        if_id_reg <= '0;
      end else if(if_id_st) begin 
        if_id_reg <= if_id_reg;
      end else begin
        if_id_reg <= if_id_reg_next;
      end


      if (id_ex_clr) begin 
        id_ex_reg <= '0;
      end else if (id_ex_st) begin
        id_ex_reg <= id_ex_reg;
      end else begin
        id_ex_reg <= id_ex_reg_next;
      end

      if(pc_st) begin 
        pc <= pc;
      end else begin
        pc        <= pc_next;
      end

      
    end else begin
      pc        <= pc;
      if_id_reg  <= if_id_reg;
      id_ex_reg  <= id_ex_reg;
      ex_mem_reg <= ex_mem_reg;
      mem_wb_reg <= mem_wb_reg;
      
    end
  end

  // ----
  // Module instantiations
  // ----




  regfile regfile_i (
    .clk     (clk),
    .rst     (rst),

    .regf_we (wb_regf_we),
    .rd_s    (wb_rd_s),
    .rd_v    (wb_rd_v),

    .rs1_s   (rs1_s),
    .rs2_s   (rs2_s),
    .rs1_v   (rs1_v),
    .rs2_v   (rs2_v)
  );

  if_stage if_stage_i (
    .imem_addr      (imem_addr),
    .imem_mask      (imem_rmask),
    .imem_stall     (imem_stall),
    .imem_resp      (imem_resp),
    .pc             (pc),
    .pc_next        (pc_next),
    .if_id_reg_next (if_id_reg_next),
    .imem_rdata     (imem_rdata),
    .load_hazard    (load_hazard),
    .global_stall   (global_stall)
  );


  id_stage id_stage_i (
    .if_id_reg      (if_id_reg),
    .id_ex_reg_next (id_ex_reg_next),
    .rs1_s          (rs1_s),
    .rs2_s          (rs2_s),
    .rs1_v          (rs1_v),
    .rs2_v          (rs2_v)
  );

  ex_stage ex_stage_i (
    .id_ex_reg       (id_ex_reg),
    .ex_mem_reg_next (ex_mem_reg_next),
    .dmem_rmask      (dmem_rmask_ex),
    .dmem_wmask      (dmem_wmask_ex),
    .dmem_wdata      (dmem_wdata_ex),
    .dmem_addr       (dmem_addr_ex),
    .pc_next        (pc_jmp),
    .jmp            (jmp),
    .br_taken       (br_taken),
    .br_not_taken   (br_not_taken),
    .mem_fwd         (mem_fwd),
    .wb_fwd          (wb_fwd)

  );

  mem_stage mem_stage_i (
    .ex_mem_reg      (ex_mem_reg),
    .mem_wb_reg_next (mem_wb_reg_next),
    .dmem_rdata      (dmem_rdata)

  );

  wb_stage wb_stage_i (
    .mem_wb_reg     (mem_wb_reg),
    .wb_rd_v        (wb_rd_v),
    .wb_rd_s        (wb_rd_s),
    .wb_regf_we     (wb_regf_we)
  );


  logic [31:0] rvfi_pc;
  logic [31:0] rvfi_pc_next;
  logic [31:0] rvfi_inst;
  logic [3:0] rvfi_dmem_rmask;
  logic [3:0]  rvfi_dmem_wmask;
  logic [31:0] rvfi_dmem_addr;
  logic [31:0] rvfi_dmem_wdata;
  logic [31:0] rvfi_dmem_rdata;

  assign rvfi_dmem_rmask = mem_wb_reg.dmem_rmask;
  assign rvfi_dmem_wmask = mem_wb_reg.dmem_wmask;
  assign rvfi_dmem_addr  = mem_wb_reg.dmem_addr;
  assign rvfi_dmem_wdata = mem_wb_reg.dmem_wdata;
  assign rvfi_dmem_rdata = mem_wb_reg.dmem_rdata;


  assign rvfi_pc = mem_wb_reg.pc;
  assign rvfi_pc_next = mem_wb_reg.pc_next;
  assign rvfi_inst = mem_wb_reg.inst;
  assign rvfi_valid = mem_wb_reg.valid & !global_stall;

  always_ff @ (posedge clk) begin
    if (rst) begin
      rvfi_order <= 64'd0;
    end else if (rvfi_valid) begin
      rvfi_order <= rvfi_order + 64'd1;
    end
  end
endmodule : cpu
