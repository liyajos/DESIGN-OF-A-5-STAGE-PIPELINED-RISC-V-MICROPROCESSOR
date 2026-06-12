// ============================================================
// tb_soc_top.v - Testbench for 5-Stage RISC-V Pipeline
// ============================================================
`timescale 1ns/1ps

module tb_soc_top;

    reg clk;
    reg reset;

    always #5 clk = ~clk;   // 100 MHz

    // ?? DUT ?????????????????????????????????????????????????????
    soc_top dut (.clk(clk), .reset(reset));

    // ========== Pipeline Probes ==========
    // IF Stage
    wire [31:0] pc        = dut.core.fetch.pc_inst.pc_out;
    wire [31:0] if_instr  = dut.core.fetch.if_id.id_instruction;

    // ID/EX Register (from decode_top)
    wire [31:0] idex_pc   = dut.core.decode.id_ex.ex_pc;
    wire [31:0] idex_rs1  = dut.core.decode.id_ex.ex_rs1_data;
    wire [31:0] idex_rs2  = dut.core.decode.id_ex.ex_rs2_data;
    wire [31:0] idex_imm  = dut.core.decode.id_ex.ex_imm;
    wire [4:0]  idex_rd   = dut.core.decode.id_ex.ex_rd;
    wire        idex_rw   = dut.core.decode.id_ex.ex_reg_write;
    wire        idex_mem_read = dut.core.decode.id_ex.ex_mem_read;
    wire        idex_mem_write= dut.core.decode.id_ex.ex_mem_write;

    // EX/MEM Register (inside execute_top) - instance name: pipe_ex_mem
    wire [31:0] exmem_alu_result = dut.core.execute.pipe_ex_mem.mem_alu_result;
    wire [31:0] exmem_rs2        = dut.core.execute.pipe_ex_mem.mem_rs2_data;
    wire        exmem_mem_read   = dut.core.execute.pipe_ex_mem.mem_mem_read;
    wire        exmem_mem_write  = dut.core.execute.pipe_ex_mem.mem_mem_write;
    wire [4:0]  exmem_rd         = dut.core.execute.pipe_ex_mem.mem_rd;

    // MEM/WB Register (inside memory_top) - instance name: pipe_mem_wb
    wire [31:0] memwb_alu_result = dut.core.memory.pipe_mem_wb.wb_alu_result;
    wire [31:0] memwb_read_data  = dut.core.memory.pipe_mem_wb.wb_read_data;
    wire [4:0]  memwb_rd         = dut.core.memory.pipe_mem_wb.wb_rd;
    wire        memwb_reg_write  = dut.core.memory.pipe_mem_wb.wb_reg_write;
    wire        memwb_mem_to_reg = dut.core.memory.pipe_mem_wb.wb_mem_to_reg;

    // Writeback stage outputs (final WB)
    wire        wb_reg_write = dut.core.writeback.reg_write;
    wire [4:0]  wb_rd        = dut.core.writeback.rd;
    wire [31:0] wb_wd        = dut.core.writeback.wd;

    // Register file contents (from decode_top)
    wire [31:0] rf_x1  = dut.core.decode.rf.regs[1];
    wire [31:0] rf_x2  = dut.core.decode.rf.regs[2];
    wire [31:0] rf_x3  = dut.core.decode.rf.regs[3];
    wire [31:0] rf_x4  = dut.core.decode.rf.regs[4];
    wire [31:0] rf_x5  = dut.core.decode.rf.regs[5];
    wire [31:0] rf_x6  = dut.core.decode.rf.regs[6];
    wire [31:0] rf_x7  = dut.core.decode.rf.regs[7];
    wire [31:0] rf_x8  = dut.core.decode.rf.regs[8];
    wire [31:0] rf_x10 = dut.core.decode.rf.regs[10];
    wire [31:0] rf_x11 = dut.core.decode.rf.regs[11];

    // Hazard / Branch
    wire stall_sig  = dut.core.stall;
    wire branch_sig = dut.core.branch_taken;

    integer cycle;
    integer instr_cnt;
    reg stop_sim;   // flag to stop simulation

    // ?? Simulation ?????????????????????????????????????????????
    initial begin
        clk = 0; reset = 1; cycle = 0; instr_cnt = 0; stop_sim = 0;
        // Reset for two cycles
        @(posedge clk); #1;
        @(posedge clk); #1;
        reset = 0;

        $display("========================================================");
        $display("  5-Stage RISC-V Pipeline Simulation");
        $display("========================================================");
        $display("");
        $display("TEST PROGRAM (from program.mem):");
        $display("  0x00: ADDI x1, x0, 5");
        $display("  0x04: ADDI x2, x0, 3");
        $display("  0x08: ADD  x3, x1, x2");
        $display("  0x0C: SUB  x4, x1, x2");
        $display("  0x10: AND  x5, x1, x2");
        $display("  0x14: OR   x6, x1, x2");
        $display("  0x18: SLT  x8, x2, x1");
        $display("  0x1C: ADDI x7, x0, 10");
        $display("  0x20: SW   x3, 0(x1)");
        $display("  0x24: SW   x4, 4(x1)");
        $display("  0x28: LW   x10, 0(x1)");
        $display("  0x2C: LW   x11, 4(x1)");
        $display("  0x30: BEQ  x11, x10, 8 (not taken)");
        $display("  0x34: JAL  x0, 8 (jump to 0x3C)");
        $display("  0x38: SW   x3, 8(x1) (skipped)");
        $display("  0x3C: LUI  x10, 0xC");
        $display("  0x40: AUIPC x10, 0x1");
        $display("  0x44: JAL  x1, 16 (jump to 0x54)");
        $display("  0x48: BEQ  x1, x2, 8 (not taken)");
        $display("  0x4C: ADDI x11, x0, 10");
        $display("  0x50: JALR x1, 0(x1) (jump back to 0x48)");
        $display("  0x54: JAL  x0, 0x54 (infinite loop)");
        $display("");
        $display("EXPECTED FINAL REGISTER VALUES (before infinite loop):");
        $display("  x1 = 0x48 (return address from JAL)");
        $display("  x2 = 3");
        $display("  x3 = 8");
        $display("  x4 = 2");
        $display("  x5 = 1");
        $display("  x6 = 7");
        $display("  x7 = 10");
        $display("  x8 = 1");
        $display("  x10 = PC + 0x1000 = 0x1040 (from AUIPC)");
        $display("  x11 = 10 (from ADDI after BEQ)");
        $display("");
        $display("----------------------------------------------------------------");
        $display("CYC | PC   INSTR     | ID/EX:rs1  rs2  imm rd | EX/MEM:alu rd | MEM/WB:alu rd data | WB:rd data");
        $display("----+----------------+-------------------------+--------------+-------------------+-----------");

        // Run for enough cycles
        repeat(80) begin
            @(posedge clk); #1;
            cycle = cycle + 1;

            // Display pipeline snapshot at each cycle
            $display("%3d | %4h %8h | %8h %8h %8h x%02d | %8h x%02d | %8h %8h x%02d | x%02d %8h",
                cycle,
                pc, if_instr,
                idex_rs1, idex_rs2, idex_imm, idex_rd,
                exmem_alu_result, exmem_rd,
                memwb_alu_result, memwb_read_data, memwb_rd,
                wb_rd, wb_wd
            );

            // Stop after we see the infinite loop at 0x54 repeated a few times
            if (pc == 32'h00000054 && cycle > 40) begin
                $display("");
                $display("*** Reached infinite loop at 0x54. Stopping simulation. ***");
                stop_sim = 1;
            end
            if (stop_sim) begin
                // Run one more cycle to let WB finish, then finish
                repeat(5) @(posedge clk);
                $finish;
            end
        end

        $display("");
        $display("========================================================");
        $display("REGISTER FILE - FINAL VALUES vs EXPECTED:");
        $display("========================================================");
        $display(" Reg | Current Value (hex) | Expected (hex) | Status");
        $display("-----+---------------------+----------------+--------");

        // Expected values based on the program
        check("x1",  rf_x1,  32'h00000054);   
        check("x2",  rf_x2,  32'h00000003);
        check("x3",  rf_x3,  32'h00000008);
        check("x4",  rf_x4,  32'h00000002);
        check("x5",  rf_x5,  32'h00000001);
        check("x6",  rf_x6,  32'h00000007);
        check("x7",  rf_x7,  32'h0000000A);
        check("x8",  rf_x8,  32'h00000001);
        check("x10", rf_x10, 32'h00001040);   // PC=0x40 + 0x1000 = 0x1040
        check("x11", rf_x11, 32'h0000000A);

        $display("");
        $display("========================================================");
        $display("SIMULATION COMPLETE");
        $display("========================================================");
        $finish;
    end

    // ?? Helper task ???????????????????????????????????????????
    task check;
        input [15:0] name;
        input [31:0] got;
        input [31:0] exp;
        begin
            if (got === exp)
                $display(" %s  |  %8h        |   %8h    | PASS", name, got, exp);
            else
                $display(" %s  |  %8h        |   %8h    | FAIL <<<", name, got, exp);
        end
    endtask

    // Timeout safety
    initial begin
        #5000;
        $display("TIMEOUT - simulation terminated after 5000 ns");
        $finish;
    end

endmodule