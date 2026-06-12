module main_control (
    input wire [6:0] opcode,
    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg mem_to_reg,
    output reg branch,
    output reg alu_src,
    output reg [1:0] alu_op
);

    always @(*) begin
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        mem_to_reg= 1'b0;
        branch    = 1'b0;
        alu_src   = 1'b0;
        alu_op    = 2'b00;

        case (opcode)
            7'b0110011: begin  // R-type
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op    = 2'b10;
            end
            7'b0010011: begin  // I-type ALU
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b10;
            end
            7'b0000011: begin  // LOAD
                reg_write = 1'b1;
                mem_read  = 1'b1;
                mem_to_reg= 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b00;
            end
            7'b0100011: begin  // STORE
                mem_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b00;
            end
            7'b1100011: begin  // BRANCH
                branch    = 1'b1;
                alu_op    = 2'b01;
            end
            7'b0110111: begin  // LUI
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b11;
            end
            7'b0010111: begin  // AUIPC
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b11;
            end
            7'b1101111: begin  // JAL
                reg_write = 1'b1;
                alu_src   = 1'b1;   // ALU will get PC+4 (special case in execute)
                alu_op    = 2'b11;
            end
            7'b1100111: begin  // JALR
                reg_write = 1'b1;
                alu_src   = 1'b1;   // ALU computes target (rs1+imm), but write-back is PC+4
                alu_op    = 2'b10;  // Use ALU normally, execute will override write-back
            end
            default: ;
        endcase
    end
endmodule