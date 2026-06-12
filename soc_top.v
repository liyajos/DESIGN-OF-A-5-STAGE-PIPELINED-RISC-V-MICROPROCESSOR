// ============================================================
// soc_top.v — System Top
// Integrates: processor_top, instruction_memory, data_memory
// ============================================================
module soc_top (
    input wire clk,
    input wire reset
);
    // Instruction memory wires
    wire        instr_req;
    wire [31:0] instr_addr;
    wire [31:0] instr_data;

    // Data memory wires
    wire        data_req;
    wire [31:0] data_addr;
    wire [31:0] data_write;
    wire [31:0] data_read;
    wire        data_mem_read;
    wire        data_mem_write;
    wire [1:0]  data_size;

    // ── Processor Core ────────────────────────────────────────
    processor_top core (
        .clk           (clk),
        .reset         (reset),
        .instr_req     (instr_req),
        .instr_addr    (instr_addr),
        .instr_data    (instr_data),
        .data_req      (data_req),
        .data_addr     (data_addr),
        .data_write    (data_write),
        .data_mem_read (data_mem_read),
        .data_mem_write(data_mem_write),
        .data_size     (data_size),
        .data_read     (data_read)
    );

    // ── Instruction Memory (ROM) ───────────────────────────────
    instruction_memory imem (
        .req   (instr_req),
        .addr  (instr_addr),
        .instr (instr_data)
    );

    // ── Data Memory (RAM) ──────────────────────────────────────
    // Present and wired. LW/SW will be active when MEM stage added.
    data_memory dmem (
        .clk        (clk),
        .req        (data_req),
        .mem_read   (data_mem_read),
        .mem_write  (data_mem_write),
        .addr       (data_addr),
        .write_data (data_write),
        .size       (data_size),
        .read_data  (data_read)
    );

endmodule
