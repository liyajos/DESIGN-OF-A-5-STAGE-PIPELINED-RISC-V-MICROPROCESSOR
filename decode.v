// ============================================================
// decode.v — Decode Stage Top (ID Stage)
// Instantiates: register_file, main_control, immediate_gen,
//               branch_comparator, hazard_unit, id_ex_reg
// ============================================================
module decode_top (
    input  wire        clk,
    input  wire        reset,
    // From IF/ID register
    input  wire [31:0] id_pc,
    input  wire [31:0] id_instruction,
    // WB writeback
    input  wire        wb_reg_write,
    input  wire [4:0]  wb_rd,
    input  wire [31:0] wb_wd,
    // Hazard info from EX
    input  wire [4:0]  ex_rd,
    input  wire        ex_mem_read,
    // Outputs to fetch (branch)
    output wire        branch_taken,
    output wire [31:0] branch_target,
    // Stall to fetch
    output wire        stall,
    // ID/EX register outputs (go to execute stage)
    output wire [31:0] ex_pc_o,
    output wire [31:0] ex_rs1_data_o,
    output wire [31:0] ex_rs2_data_o,
    output wire [31:0] ex_imm_o,
    output wire [4:0]  ex_rs1_o,
    output wire [4:0]  ex_rs2_o,
    output wire [4:0]  ex_rd_o,
    output wire [2:0]  ex_funct3_o,
    output wire [6:0]  ex_funct7_o,
    output wire        ex_reg_write_o,
    output wire        ex_mem_read_o,
    output wire        ex_mem_write_o,
    output wire        ex_mem_to_reg_o,
    output wire        ex_branch_o,
    output wire        ex_alu_src_o,
    output wire [1:0]  ex_alu_op_o,
    output wire [6:0]  ex_opcode_o
);
    // Field extraction
    wire [6:0] opcode  = id_instruction[6:0];
    wire [4:0] rd      = id_instruction[11:7];
    wire [2:0] funct3  = id_instruction[14:12];
    wire [4:0] rs1     = id_instruction[19:15];
    wire [4:0] rs2     = id_instruction[24:20];
    wire [6:0] funct7  = id_instruction[31:25];

    // Control signals
    wire        ctrl_reg_write, ctrl_mem_read, ctrl_mem_write;
    wire        ctrl_mem_to_reg, ctrl_branch, ctrl_alu_src;
    wire [1:0]  ctrl_alu_op;

    // Register file outputs
    wire [31:0] rs1_data, rs2_data;

    // Immediate
    wire [31:0] imm;

    // Hazard
    wire flush_id_ex;

    // ── Register File ──────────────────────────────────────
    register_file rf (
        .clk      (clk),
        .we       (wb_reg_write),
        .rs1      (rs1),
        .rs2      (rs2),
        .rd       (wb_rd),
        .wd       (wb_wd),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data)
    );

    // ── Control Unit ───────────────────────────────────────
    main_control ctrl (
        .opcode      (opcode),
        .reg_write   (ctrl_reg_write),
        .mem_read    (ctrl_mem_read),
        .mem_write   (ctrl_mem_write),
        .mem_to_reg  (ctrl_mem_to_reg),
        .branch      (ctrl_branch),
        .alu_src     (ctrl_alu_src),
        .alu_op      (ctrl_alu_op)
    );

    // ── Immediate Generator ────────────────────────────────
    immediate_gen immgen (
        .instruction (id_instruction),
        .imm_out     (imm)
    );

    // ── Branch Comparator ──────────────────────────────────
    branch_comparator bc (
        .rs1_data    (rs1_data),
        .rs2_data    (rs2_data),
        .funct3      (funct3),
        .branch_ctrl (ctrl_branch),
        .branch_taken(branch_taken)
    );

    // Branch target = PC + imm (B-type immediate already has *2 built in)
    assign branch_target = id_pc + imm;

    // ── Hazard Detection ───────────────────────────────────
    hazard_unit hazard (
        .id_rs1       (rs1),
        .id_rs2       (rs2),
        .ex_rd        (ex_rd),
        .ex_mem_read  (ex_mem_read),
        .stall        (stall),
        .flush_id_ex  (flush_id_ex)
    );

    // ── ID/EX Pipeline Register ────────────────────────────
    id_ex_reg id_ex (
        .clk          (clk),
        .reset        (reset),
        .flush        (flush_id_ex),
        .id_pc        (id_pc),
        .id_rs1_data  (rs1_data),
        .id_rs2_data  (rs2_data),
        .id_imm       (imm),
        .id_rs1       (rs1),
        .id_rs2       (rs2),
        .id_rd        (rd),
        .id_funct3    (funct3),
        .id_funct7    (funct7),
        .id_reg_write (ctrl_reg_write),
        .id_mem_read  (ctrl_mem_read),
        .id_mem_write (ctrl_mem_write),
        .id_mem_to_reg(ctrl_mem_to_reg),
        .id_branch    (ctrl_branch),
        .id_alu_src   (ctrl_alu_src),
        .id_alu_op    (ctrl_alu_op),
        .id_opcode    (opcode),
        .ex_pc        (ex_pc_o),
        .ex_rs1_data  (ex_rs1_data_o),
        .ex_rs2_data  (ex_rs2_data_o),
        .ex_imm       (ex_imm_o),
        .ex_rs1       (ex_rs1_o),
        .ex_rs2       (ex_rs2_o),
        .ex_rd        (ex_rd_o),
        .ex_funct3    (ex_funct3_o),
        .ex_funct7    (ex_funct7_o),
        .ex_reg_write (ex_reg_write_o),
        .ex_mem_read  (ex_mem_read_o),
        .ex_mem_write (ex_mem_write_o),
        .ex_mem_to_reg(ex_mem_to_reg_o),
        .ex_branch    (ex_branch_o),
        .ex_alu_src   (ex_alu_src_o),
        .ex_alu_op    (ex_alu_op_o),
        .ex_opcode    (ex_opcode_o)
    );

endmodule
