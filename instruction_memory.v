// ============================================================
// instruction_memory.v — Instruction ROM
// Loads program from program.mem (hex format, word-addressed)
// ============================================================
module instruction_memory (
    input  wire        req,
    input  wire [31:0] addr,
    output reg  [31:0] instr
);
    reg [31:0] mem [0:255]; // 256 words = 1KB

    initial begin
        $readmemh("program.mem", mem);
    end

    // Word-addressed read (addr is byte address, ignore lower 2 bits)
    always @(*) begin
        if (req)
            instr = mem[addr[9:2]];
        else
            instr = 32'h0000_0013; // NOP
    end
endmodule
