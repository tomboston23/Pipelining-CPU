module mem_stage
import rv32i_types::*;
(
  input ex_mem_t      ex_mem_reg,
  output mem_wb_t     mem_wb_reg_next,
  input logic [31:0]  dmem_rdata
);

  logic read_req;
  logic write_req;
  logic request;
  assign read_req = |ex_mem_reg.dmem_rmask;
  assign write_req = |ex_mem_reg.dmem_wmask;
  assign request = read_req | write_req;


  always_comb begin
    mem_wb_reg_next = '0;
    mem_wb_reg_next.valid     = ex_mem_reg.valid;
    mem_wb_reg_next.rd_v = ex_mem_reg.rd_v;
    mem_wb_reg_next.rd_s         = ex_mem_reg.rd_s;
    mem_wb_reg_next.regf_we    = ex_mem_reg.regf_we;
    mem_wb_reg_next.valid      = ex_mem_reg.valid;

    //rvfi signals
    mem_wb_reg_next.pc_next    = ex_mem_reg.pc_next;
    mem_wb_reg_next.pc         = ex_mem_reg.pc;
    mem_wb_reg_next.inst       = ex_mem_reg.inst;
    mem_wb_reg_next.rs1_v     = ex_mem_reg.rs1_v;
    mem_wb_reg_next.rs2_v     = ex_mem_reg.rs2_v;
    mem_wb_reg_next.rs1_s     = ex_mem_reg.rs1_s;
    mem_wb_reg_next.rs2_s     = ex_mem_reg.rs2_s;
    
    mem_wb_reg_next.dmem_wdata = ex_mem_reg.dmem_wdata;
    mem_wb_reg_next.dmem_addr  = ex_mem_reg.dmem_addr;
    mem_wb_reg_next.dmem_wmask = ex_mem_reg.dmem_wmask;
    mem_wb_reg_next.dmem_rmask = ex_mem_reg.dmem_rmask;
    mem_wb_reg_next.dmem_rdata = '0; // default to 0

    if (ex_mem_reg.mem_rd & ex_mem_reg.valid) begin // read from reg file and send to wb stage

      mem_wb_reg_next.rd_v = dmem_rdata; // lw case
      mem_wb_reg_next.dmem_rdata = dmem_rdata;

      if(ex_mem_reg.load_mask[0]) begin // lb case

        case(ex_mem_reg.dmem_rmask)
          4'b0001: mem_wb_reg_next.rd_v = {{24{dmem_rdata[7]}}, dmem_rdata[7:0]};
          4'b0010: mem_wb_reg_next.rd_v = {{24{dmem_rdata[15]}}, dmem_rdata[15:8]};
          4'b0100: mem_wb_reg_next.rd_v = {{24{dmem_rdata[23]}}, dmem_rdata[23:16]};
          4'b1000: mem_wb_reg_next.rd_v = {{24{dmem_rdata[31]}}, dmem_rdata[31:24]};
          default: mem_wb_reg_next.valid = 1'b0;
        endcase

      end else if(ex_mem_reg.load_mask[1]) begin // lh case

        case (ex_mem_reg.dmem_rmask)
          4'b0011: mem_wb_reg_next.rd_v = {{16{dmem_rdata[15]}}, dmem_rdata[15:0]};
          4'b1100: mem_wb_reg_next.rd_v = {{16{dmem_rdata[31]}}, dmem_rdata[31:16]};
          default: mem_wb_reg_next.valid = 1'b0;
        endcase

      end else if(ex_mem_reg.load_mask[2]) begin // lbu case
        case(ex_mem_reg.dmem_rmask)
          4'b0001: mem_wb_reg_next.rd_v = {{24'h0}, dmem_rdata[7:0]};
          4'b0010: mem_wb_reg_next.rd_v = {{24'h0}, dmem_rdata[15:8]};
          4'b0100: mem_wb_reg_next.rd_v = {{24'h0}, dmem_rdata[23:16]};
          4'b1000: mem_wb_reg_next.rd_v = {{24'h0}, dmem_rdata[31:24]};
          default: mem_wb_reg_next.valid = 1'b0;
        endcase
      end else if(ex_mem_reg.load_mask[3]) begin // lhu case

        case (ex_mem_reg.dmem_rmask)
          4'b0011: mem_wb_reg_next.rd_v = {{16'h0}, dmem_rdata[15:0]};
          4'b1100: mem_wb_reg_next.rd_v = {{16'h0}, dmem_rdata[31:16]};
          default: mem_wb_reg_next.valid = 1'b0;
        endcase
      end
    end else if (ex_mem_reg.regf_we & ex_mem_reg.valid) begin
      mem_wb_reg_next.rd_v = ex_mem_reg.rd_v; // Write ALU result to regfile
    end else begin
      mem_wb_reg_next.rd_v = '0; 
    end

    if (ex_mem_reg.mem_we & ex_mem_reg.valid) begin
      mem_wb_reg_next.rd_v = '0; // No writeback on store
    end
  end
endmodule : mem_stage
