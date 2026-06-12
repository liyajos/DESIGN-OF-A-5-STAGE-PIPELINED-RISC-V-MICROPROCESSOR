// ============================================================
// alu_control.v — ALU Control Unit
// ============================================================
// alu_op | meaning
//  00    | add (load/store)
//  01    | sub (branch compare)
//  10    | use funct3/funct7 (R/I type)
//  11    | pass immediate (LUI/AUIPC)
// ── alu_ctrl output ──────────────────────
//  0000  ADD
//  0001  SUB
//  0010  AND
//  0011  OR
//  0100  XOR
//  0101  SLL
//  0110  SRL
//  0111  SRA
//  1000  SLT
//  1001  SLTU
//  1010  PASS B (LUI)
module alu_control (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg  [3:0] alu_ctrl
);
    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = 4'b0000; // ADD for load/store
            2'b01: alu_ctrl = 4'b0001; // SUB for branch
            2'b11: alu_ctrl = 4'b1010; // PASS imm (LUI/AUIPC)
            2'b10: begin
                case (funct3)
                    3'b000: alu_ctrl = (funct7[5]) ? 4'b0001 : 4'b0000; // SUB/ADD
                    3'b111: alu_ctrl = 4'b0010; // AND
                    3'b110: alu_ctrl = 4'b0011; // OR
                    3'b100: alu_ctrl = 4'b0100; // XOR
                    3'b001: alu_ctrl = 4'b0101; // SLL
                    3'b101: alu_ctrl = (funct7[5]) ? 4'b0111 : 4'b0110; // SRA/SRL
                    3'b010: alu_ctrl = 4'b1000; // SLT
                    3'b011: alu_ctrl = 4'b1001; // SLTU
                    default: alu_ctrl = 4'b0000;
                endcase
            end
            default: alu_ctrl = 4'b0000;
        endcase
    end
endmodule
