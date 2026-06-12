// ============================================================
// forwarding_unit.v — Data Forwarding Unit (EX stage)
// Resolves RAW hazards via forwarding from EX/MEM and MEM/WB
// ============================================================
// forwardA/B:
//  00 = use ID/EX register file data (no forward)
//  01 = forward from MEM/WB
//  10 = forward from EX/MEM
module forwarding_unit (
    input  wire [4:0] ex_rs1,
    input  wire [4:0] ex_rs2,
    // EX/MEM stage
    input  wire [4:0] exmem_rd,
    input  wire       exmem_reg_write,
    // MEM/WB stage
    input  wire [4:0] memwb_rd,
    input  wire       memwb_reg_write,
    output reg  [1:0] forwardA,
    output reg  [1:0] forwardB
);
    always @(*) begin
        // Forward A
        if (exmem_reg_write && (exmem_rd != 5'b0) && (exmem_rd == ex_rs1))
            forwardA = 2'b10; // from EX/MEM
        else if (memwb_reg_write && (memwb_rd != 5'b0) && (memwb_rd == ex_rs1))
            forwardA = 2'b01; // from MEM/WB
        else
            forwardA = 2'b00; // no forward

        // Forward B
        if (exmem_reg_write && (exmem_rd != 5'b0) && (exmem_rd == ex_rs2))
            forwardB = 2'b10;
        else if (memwb_reg_write && (memwb_rd != 5'b0) && (memwb_rd == ex_rs2))
            forwardB = 2'b01;
        else
            forwardB = 2'b00;
    end
endmodule
