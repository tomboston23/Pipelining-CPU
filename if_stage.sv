module if_stage
import rv32i_types::*;
(
  input   logic   [31:0]  pc, pc_next,
  input   logic           imem_resp,
  input   logic   [31:0]  imem_rdata,
  input   logic   load_hazard,
  input   logic   global_stall,

  output  logic   [31:0]  imem_addr,
  output  logic   [3:0]   imem_mask,
  output  logic           imem_stall,
  output  if_id_t         if_id_reg_next
);
  always_comb begin
      if_id_reg_next = '0;
      imem_stall = ~imem_resp;
      imem_mask       = 4'b1111; // Always read full word
      if (~global_stall && ~load_hazard) begin
        imem_addr = pc_next;
      end else begin
        imem_addr = pc;
      end

      if_id_reg_next = '0;

      if (imem_resp) begin
        if_id_reg_next.pc       = pc;
        if_id_reg_next.pc_next  = pc_next;
        if_id_reg_next.valid = '1;
        if_id_reg_next.inst = imem_rdata;
      end else begin
        if_id_reg_next.valid = '0;
      end

  end
endmodule : if_stage
