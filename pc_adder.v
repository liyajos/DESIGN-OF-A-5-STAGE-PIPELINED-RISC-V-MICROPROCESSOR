// ============================================================
// pc_adder.v — PC + 4 Adder
// ============================================================
module pc_adder (
    input  wire [31:0] pc_in,
    output wire [31:0] pc_plus4
);
    assign pc_plus4 = pc_in + 32'd4;
endmodule
