module execute_top (
    input wire clk,
    input wire reset,
    // From ID/EX register
    input wire [31:0] ex_pc,
    input wire [31:0] ex_rs1_data,
    input wire [31:0] ex_rs2_data,
    input wire [31:0] ex_imm,
    input wire [4:0] ex_rs1,
    input wire [4:0] ex_rs2,
    input wire [4:0] ex_rd,
    input wire [2:0] ex_funct3,
    input wire [6:0] ex_funct7,
    input wire ex_alu_src,
    input wire [1:0] ex_alu_op,
    input wire ex_mem_read,
    input wire ex_mem_write,
    input wire ex_mem_to_reg,
    input wire ex_reg_write,
    input wire [6:0] ex_opcode,          // <-- ADD THIS LINE

    // Forwarding from later stages
    input wire [4:0] exmem_rd,
    input wire exmem_reg_write,
    input wire [31:0] exmem_alu_result,
    input wire [4:0] memwb_rd,
    input wire memwb_reg_write,
    input wire [31:0] memwb_wd,

    // Outputs to MEM stage (via EX/MEM register)
    output wire [31:0] mem_alu_result,
    output wire [31:0] mem_rs2_data,
    output wire mem_mem_read,
    output wire mem_mem_write,
    output wire [2:0] mem_funct3,
    output wire [4:0] mem_rd,
    output wire mem_reg_write,
    output wire mem_mem_to_reg
);

    // Forwarding unit
    wire [1:0] forwardA, forwardB;
    forwarding_unit fwd (
        .ex_rs1(ex_rs1), .ex_rs2(ex_rs2),
        .exmem_rd(exmem_rd), .exmem_reg_write(exmem_reg_write),
        .memwb_rd(memwb_rd), .memwb_reg_write(memwb_reg_write),
        .forwardA(forwardA), .forwardB(forwardB)
    );

    // Operand A mux
    reg [31:0] alu_in_a;
    always @(*) begin
        case (forwardA)
            2'b10: alu_in_a = exmem_alu_result;
            2'b01: alu_in_a = memwb_wd;
            default: alu_in_a = ex_rs1_data;
        endcase
    end

    // Operand B pre-mux
    reg [31:0] alu_in_b_pre;
    always @(*) begin
        case (forwardB)
            2'b10: alu_in_b_pre = exmem_alu_result;
            2'b01: alu_in_b_pre = memwb_wd;
            default: alu_in_b_pre = ex_rs2_data;
        endcase
    end

    wire [31:0] alu_in_b = ex_alu_src ? ex_imm : alu_in_b_pre;
    wire [31:0] rs2_fwd = alu_in_b_pre;

    // ALU control and ALU
    wire [3:0] alu_ctrl;
    alu_control alu_ctrl_inst (
        .alu_op(ex_alu_op),
        .funct3(ex_funct3),
        .funct7(ex_funct7),
        .alu_ctrl(alu_ctrl)
    );

    wire [31:0] alu_result_raw;
    wire alu_zero;
    alu alu_inst (
        .a(alu_in_a),
        .b(alu_in_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result_raw),
        .zero(alu_zero)
    );

    // ---------- Special handling for AUIPC, JAL, JALR ----------
    reg [31:0] final_alu_result;
    always @(*) begin
        case (ex_opcode)
            7'b0010111:  // AUIPC: result = PC + imm
                final_alu_result = ex_pc + ex_imm;
            7'b1101111:  // JAL: result = PC + 4
                final_alu_result = ex_pc + 32'd4;
            7'b1100111:  // JALR: result = PC + 4 (target is rs1+imm, but that's used for PC update)
                final_alu_result = ex_pc + 32'd4;
            default:
                final_alu_result = alu_result_raw;
        endcase
    end

    // EX/MEM pipeline register
    ex_mem_reg pipe_ex_mem (
        .clk(clk), .reset(reset), .flush(1'b0),
        .ex_alu_result(final_alu_result),
        .ex_alu_zero(alu_zero),
        .ex_rs2_data(rs2_fwd),
        .ex_rd(ex_rd),
        .ex_reg_write(ex_reg_write),
        .ex_mem_read(ex_mem_read),
        .ex_mem_write(ex_mem_write),
        .ex_mem_to_reg(ex_mem_to_reg),
        .ex_funct3(ex_funct3),
        .mem_alu_result(mem_alu_result),
        .mem_alu_zero(),
        .mem_rs2_data(mem_rs2_data),
        .mem_rd(mem_rd),
        .mem_reg_write(mem_reg_write),
        .mem_mem_read(mem_mem_read),
        .mem_mem_write(mem_mem_write),
        .mem_mem_to_reg(mem_mem_to_reg),
        .mem_funct3(mem_funct3)
    );

endmodule