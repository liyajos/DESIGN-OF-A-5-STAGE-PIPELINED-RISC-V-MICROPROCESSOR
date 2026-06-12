// ============================================================
// if_id_reg.v — IF/ID Pipeline Register
// ============================================================
module if_id_reg (
    input  wire        clk,
    input  wire        reset,
    input  wire        stall,
    input  wire        flush,
    input  wire [31:0] if_pc,
    input  wire [31:0] if_instruction,
    output reg  [31:0] id_pc,
    output reg  [31:0] id_instruction
);
    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            id_pc          <= 32'h0;
            id_instruction <= 32'h0000_0013; // NOP (ADDI x0, x0, 0)
        end else if (!stall) begin
            id_pc          <= if_pc;
            id_instruction <= if_instruction;
        end
    end
endmodule
