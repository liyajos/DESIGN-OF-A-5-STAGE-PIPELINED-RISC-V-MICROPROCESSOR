// ============================================================
// fetch.v — Fetch Stage Top (IF Stage)
// Instantiates: pc_regi, pc_adder, pc_mux, if_id_reg
// ============================================================
module fetch_top (
    input wire clk,
    input wire reset,
    input wire stall,
    input wire flush,
    input wire branch_taken,
    input wire [31:0] branch_target,
    // Instruction Memory Interface
    output wire instr_req,
    output wire [31:0] instr_addr,
    input wire [31:0] instr_data,
    // Outputs to IF/ID register (passed to decode)
    output wire [31:0] id_pc,
    output wire [31:0] id_instruction
);

wire [31:0] pc_out;
wire [31:0] pc_plus4;
wire [31:0] pc_next;

// PC Register
pc_regi #(.RESET_VECTOR(32'h0000_0000)) pc_inst (
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .pc_next(pc_next),
    .pc_out(pc_out)
);

// PC + 4
pc_adder adder_inst (
    .pc_in(pc_out),
    .pc_plus4(pc_plus4)
);

// PC MUX
pc_mux mux_inst (
    .branch_taken(branch_taken),
    .pc_plus4(pc_plus4),
    .branch_target(branch_target),
    .pc_next(pc_next)
);

// IF/ID Pipeline Register
if_id_reg if_id (
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .flush(flush),
    .if_pc(pc_out),
    .if_instruction(instr_data),
    .id_pc(id_pc),
    .id_instruction(id_instruction)
);

// Instruction memory request: only when not stalled
assign instr_req = ~stall;
assign instr_addr = pc_out;

endmodule