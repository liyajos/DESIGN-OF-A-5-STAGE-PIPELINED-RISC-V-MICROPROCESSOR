// ============================================================
// data_memory.v — Data RAM (stub for IF-ID-EX phase)
// Full MEM stage will activate MemRead/MemWrite later
// ============================================================
module data_memory (
    input  wire        clk,
    input  wire        req,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    input  wire [1:0]  size,       // 00=byte 01=half 10=word
    output reg  [31:0] read_data
);
    reg [31:0] mem [0:255];

    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h0;
    end

    // Synchronous write
    always @(posedge clk) begin
        if (req && mem_write) begin
            case (size)
                2'b00: mem[addr[9:2]][7:0]  <= write_data[7:0]; // byte
                2'b01: mem[addr[9:2]][15:0] <= write_data[15:0];// half
                default: mem[addr[9:2]]     <= write_data;       // word
            endcase
        end
    end

    // Asynchronous read
    always @(*) begin
        if (req && mem_read) begin
            case (size)
                2'b00: read_data = {24'h0, mem[addr[9:2]][7:0]};
                2'b01: read_data = {16'h0, mem[addr[9:2]][15:0]};
                default: read_data = mem[addr[9:2]];
            endcase
        end else begin
            read_data = 32'h0;
        end
    end
endmodule
