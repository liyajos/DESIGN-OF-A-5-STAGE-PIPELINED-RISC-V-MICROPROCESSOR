// ============================================================
// pc_regi.v — Program Counter Register
// ============================================================
module pc_regi #(
    parameter RESET_VECTOR = 32'h0000_0000
)(
    input wire clk,
    input wire reset,
    input wire stall,
    input wire [31:0] pc_next,
    output reg [31:0] pc_out
);

always @(posedge clk or posedge reset) begin
    if (reset)
        pc_out <= RESET_VECTOR;
    else if (!stall)
        pc_out <= pc_next;
end

endmodule