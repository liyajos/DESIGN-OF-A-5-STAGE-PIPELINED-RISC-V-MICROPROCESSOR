// ============================================================
// processor_top.v - CPU Top Module (5-stage pipeline)
// NO LOGIC - ONLY INSTANTIATION
//
// Pipeline: fetch_top ? decode_top ? execute_top ? memory_top ? writeback_top
// All pipeline registers (IF/ID, ID/EX, EX/MEM, MEM/WB) are instantiated
// inside the corresponding stage top modules.
// ============================================================
module processor_top (
    input wire clk,
    input wire reset,

    // Instruction Memory Interface
    output wire instr_req,
    output wire [31:0] instr_addr,
    input wire [31:0] instr_data,

    // Data Memory Interface
    output wire data_req,
    output wire [31:0] data_addr,
    output wire [31:0] data_write,
    output wire data_mem_read,
    output wire data_mem_write,
    output wire [1:0] data_size,
    input wire [31:0] data_read
);

// ------------------------------------------------------------
// IF/ID (internal wires between fetch_top and decode_top)
// ------------------------------------------------------------
wire [31:0] if_id_pc;
wire [31:0] if_id_instr;

// Stall and flush signals
wire stall;
wire flush_ex;          // from hazard unit (load-use) to flush ID/EX
wire branch_taken;
wire [31:0] branch_target;

// ------------------------------------------------------------
// ID/EX (wires from decode_top to execute_top)
// ------------------------------------------------------------
wire [31:0] ex_pc;
wire [31:0] ex_rs1_data;
wire [31:0] ex_rs2_data;
wire [31:0] ex_imm;
wire [4:0]  ex_rs1;
wire [4:0]  ex_rs2;
wire [4:0]  ex_rd;
wire [2:0]  ex_funct3;
wire [6:0]  ex_funct7;
wire        ex_reg_write;
wire        ex_mem_read;
wire        ex_mem_write;
wire        ex_mem_to_reg;
wire        ex_branch;      // not used in execute_top, but kept for consistency
wire        ex_alu_src;
wire [1:0]  ex_alu_op;
wire [6:0]  ex_opcode;

// ------------------------------------------------------------
// EX/MEM (wires from execute_top to memory_top)
// ------------------------------------------------------------
wire [31:0] mem_alu_result;
wire [31:0] mem_rs2_data;
wire        mem_mem_read;
wire        mem_mem_write;
wire [2:0]  mem_funct3;
wire [4:0]  mem_rd;
wire        mem_reg_write;
wire        mem_mem_to_reg;

// ------------------------------------------------------------
// MEM/WB (wires from memory_top to writeback_top)
// ------------------------------------------------------------
wire [31:0] wb_alu_result;
wire [31:0] wb_read_data;
wire [4:0]  wb_rd;
wire        wb_reg_write;
wire        wb_mem_to_reg;

// ------------------------------------------------------------
// Writeback to Register File (output from writeback_top)
// ------------------------------------------------------------
wire        wb_final_reg_write;
wire [4:0]  wb_final_rd;
wire [31:0] wb_final_wd;

// ============================================================
// 1. FETCH STAGE (instantiates PC, adder, mux, IF/ID register)
// ============================================================
fetch_top fetch (
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .flush(branch_taken),          // flush IF/ID on branch
    .branch_taken(branch_taken),
    .branch_target(branch_target),
    .instr_req(instr_req),
    .instr_addr(instr_addr),
    .instr_data(instr_data),
    .id_pc(if_id_pc),
    .id_instruction(if_id_instr)
);

// ============================================================
// 2. DECODE STAGE (instantiates regfile, control, immgen, comparator,
//    hazard unit, and ID/EX register)
// ============================================================
decode_top decode (
    .clk(clk),
    .reset(reset),
    .id_pc(if_id_pc),
    .id_instruction(if_id_instr),
    .wb_reg_write(wb_final_reg_write),
    .wb_rd(wb_final_rd),
    .wb_wd(wb_final_wd),
    .ex_rd(ex_rd),
    .ex_mem_read(ex_mem_read),
    .branch_taken(branch_taken),
    .branch_target(branch_target),
    .stall(stall),
    // Outputs to EX (via ID/EX register)
    .ex_pc_o(ex_pc),
    .ex_rs1_data_o(ex_rs1_data),
    .ex_rs2_data_o(ex_rs2_data),
    .ex_imm_o(ex_imm),
    .ex_rs1_o(ex_rs1),
    .ex_rs2_o(ex_rs2),
    .ex_rd_o(ex_rd),
    .ex_funct3_o(ex_funct3),
    .ex_funct7_o(ex_funct7),
    .ex_reg_write_o(ex_reg_write),
    .ex_mem_read_o(ex_mem_read),
    .ex_mem_write_o(ex_mem_write),
    .ex_mem_to_reg_o(ex_mem_to_reg),
    .ex_branch_o(ex_branch),
    .ex_alu_src_o(ex_alu_src),
    .ex_alu_op_o(ex_alu_op),
    .ex_opcode_o(ex_opcode)
);

// ============================================================
// 3. EXECUTE STAGE (instantiates forwarding unit, ALU, ALU control,
//    and EX/MEM pipeline register)
// ============================================================
execute_top execute (
    .clk(clk),
    .reset(reset),
    // From ID/EX
    .ex_pc(ex_pc),
    .ex_rs1_data(ex_rs1_data),
    .ex_rs2_data(ex_rs2_data),
    .ex_imm(ex_imm),
    .ex_rs1(ex_rs1),
    .ex_rs2(ex_rs2),
    .ex_rd(ex_rd),
    .ex_funct3(ex_funct3),
    .ex_funct7(ex_funct7),
    .ex_alu_src(ex_alu_src),
    .ex_alu_op(ex_alu_op),
    .ex_mem_read(ex_mem_read),
    .ex_mem_write(ex_mem_write),
    .ex_mem_to_reg(ex_mem_to_reg),
    .ex_reg_write(ex_reg_write),
    .ex_opcode(ex_opcode),
    // Forwarding from EX/MEM and MEM/WB
    .exmem_rd(mem_rd),
    .exmem_reg_write(mem_reg_write),
    .exmem_alu_result(mem_alu_result),
    .memwb_rd(wb_rd),
    .memwb_reg_write(wb_reg_write),
    .memwb_wd(wb_final_wd),
    // Outputs to EX/MEM register (go to memory_top)
    .mem_alu_result(mem_alu_result),
    .mem_rs2_data(mem_rs2_data),
    .mem_mem_read(mem_mem_read),
    .mem_mem_write(mem_mem_write),
    .mem_funct3(mem_funct3),
    .mem_rd(mem_rd),
    .mem_reg_write(mem_reg_write),
    .mem_mem_to_reg(mem_mem_to_reg)
);

// ============================================================
// 4. MEMORY STAGE (instantiates memory control and MEM/WB register)
// ============================================================
memory_top memory (
    .clk(clk),
    .reset(reset),
    // From EX/MEM register
    .mem_alu_result(mem_alu_result),
    .mem_rs2_data(mem_rs2_data),
    .mem_mem_read(mem_mem_read),
    .mem_mem_write(mem_mem_write),
    .mem_funct3(mem_funct3),
    .mem_rd(mem_rd),
    .mem_reg_write(mem_reg_write),
    .mem_mem_to_reg(mem_mem_to_reg),
    // Data memory interface (to soc_top)
    .data_req(data_req),
    .data_addr(data_addr),
    .data_write(data_write),
    .data_mem_read(data_mem_read),
    .data_mem_write(data_mem_write),
    .data_size(data_size),
    .data_read(data_read),
    // Outputs to MEM/WB register (go to writeback_top)
    .wb_alu_result(wb_alu_result),
    .wb_read_data(wb_read_data),
    .wb_rd(wb_rd),
    .wb_reg_write(wb_reg_write),
    .wb_mem_to_reg(wb_mem_to_reg)
);

// ============================================================
// 5. WRITEBACK STAGE (instantiates WB mux)
// ============================================================
writeback_top writeback (
    .wb_alu_result(wb_alu_result),
    .wb_read_data(wb_read_data),
    .wb_mem_to_reg(wb_mem_to_reg),
    .wb_reg_write(wb_reg_write),
    .wb_rd(wb_rd),
    .reg_write(wb_final_reg_write),
    .rd(wb_final_rd),
    .wd(wb_final_wd)
);

endmodule