// ============================================================
// register_file.v — 32 x 32-bit RISC-V Register File
// x0 is hardwired to 0
// ============================================================
module register_file (
    input  wire        clk,
    input  wire        we,          // Write Enable (from WB)
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] wd,          // Write Data
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);
    reg [31:0] regs [31:0];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'h0;
    end

    // Synchronous write (write at posedge)
    always @(posedge clk) begin
        if (we && rd != 5'b0)
            regs[rd] <= wd;
    end

    // Asynchronous read with WB forward (write-first on same cycle collision)
    // If WB is writing to the same register we are reading, forward the new value
    assign rs1_data = (rs1 == 5'b0) ? 32'h0 :
                      (we && rd == rs1 && rd != 5'b0) ? wd : regs[rs1];
    assign rs2_data = (rs2 == 5'b0) ? 32'h0 :
                      (we && rd == rs2 && rd != 5'b0) ? wd : regs[rs2];

endmodule
