// ============================================================
// hazard_unit.v — Hazard Detection Unit (Load-Use Stall)
// ============================================================
module hazard_unit (
    input  wire [4:0] id_rs1,
    input  wire [4:0] id_rs2,
    input  wire [4:0] ex_rd,
    input  wire       ex_mem_read,    // load instruction in EX
    output reg        stall,
    output reg        flush_id_ex
);
    always @(*) begin
        // Load-use hazard: load in EX, use in ID
        if (ex_mem_read &&
            ((ex_rd == id_rs1) || (ex_rd == id_rs2)) &&
            (ex_rd != 5'b0)) begin
            stall       = 1'b1;
            flush_id_ex = 1'b1;
        end else begin
            stall       = 1'b0;
            flush_id_ex = 1'b0;
        end
    end
endmodule
