// ============================================================
// pc_mux.v — PC Select MUX (PC+4 vs Branch Target)
// ============================================================
module pc_mux (
    input  wire        branch_taken,
    input  wire [31:0] pc_plus4,
    input  wire [31:0] branch_target,
    output wire [31:0] pc_next
);
    assign pc_next = branch_taken ? branch_target : pc_plus4;
endmodule
