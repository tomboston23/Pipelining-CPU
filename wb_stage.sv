module wb_stage
import rv32i_types::*;
(
  input mem_wb_t      mem_wb_reg,
  output logic [31:0] wb_rd_v,
  output logic [4:0]  wb_rd_s,
  output logic        wb_regf_we
);

  logic [4:0] rd_addr;
  assign rd_addr = wb_rd_s;
  always_comb begin
    if (mem_wb_reg.regf_we & mem_wb_reg.valid) begin
      wb_rd_v     = mem_wb_reg.rd_v;
      wb_rd_s     = mem_wb_reg.rd_s;
      wb_regf_we  = 1'b1;
    end else begin
      wb_rd_v     = 32'b0;
      wb_rd_s     = 5'b0;
      wb_regf_we  = 1'b0;
    end
  end
endmodule : wb_stage
