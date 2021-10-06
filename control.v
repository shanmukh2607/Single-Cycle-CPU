module Control(input [31:0] idata,
               input reset,
               output jump, 
               output branch, 
               output MemtoReg, 
               output AluSrc, 
               output RegWrite,
               output [4:0] rs1,
               output [4:0] rs2,
               output [4:0] rd,
               output [3:0] ALU_out);
    
    
    reg jump_r, branch_r, MemtoReg_r, AluSrc_r, RegWrite_r;
    reg [4:0] rs1_r, rs2_r, rd_r;
    reg [3:0] ALU_out_r;
    
    always @(idata)
        begin
            case(idata[6:0])
                // LUI
                7'b0110111: begin
                    jump_r = 1'b0;
                    branch_r = 1'b0;
                    MemtoReg_r = 1'b0;
                    AluSrc_r = 1'b1;
                    RegWrite_r = 1'b1;
                    rs1_r = 5'b0;
                    rs2_r = 5'b0;
                    rd_r = idata[11:7];
                    ALU_out_r = 4'b0010;
                end
                // AUIPC
                7'b0010111: begin
                    jump_r = 1'b0;
                    branch_r = 1'b0;
                    MemtoReg_r = 1'b0;
                    AluSrc_r = 1'b1;
                    RegWrite_r = 1'b1;
                    rs1_r = 5'b0;
                    rs2_r = 5'b0;
                    rd_r = idata[11:7];
                    ALU_out_r = 4'b0010; 
                end
                // JAL
                7'b1101111: begin
                    jump_r = 1'b1;
                    branch_r = 1'b0;
                    MemtoReg_r = 1'b0;
                    AluSrc_r = 1'b0;
                    RegWrite_r = 1'b1;
                    rs1_r = 5'b0;
                    rs2_r = 5'b0;
                    rd_r = idata[11:7];
                    ALU_out_r = 4'b0010; 
                end
                // JALR
                7'b1100111: begin
                    jump_r = 1'b1;
                    branch_r = 1'b0;
                    MemtoReg_r = 1'b0;
                    AluSrc_r = 1'b0;
                    RegWrite_r = 1'b1;
                    rs1_r = idata[19:15];
                    rs2_r = 5'b0;
                    rd_r = idata[11:7];
                    ALU_out_r = 4'b0010; 
                end
                // BRANCH
                7'b1100011: begin
                    jump_r = 1'b0;
                    branch_r = 1'b1;
                    MemtoReg_r = 1'b0;
                    AluSrc_r = 1'b0;
                    RegWrite_r = 1'b0;
                    rs1_r = idata[19:15];
                    rs2_r = idata[24:20];
                    rd_r = 5'b0;
                    case(idata[14:12])
                        3'b000:   // BEQ
                            ALU_out_r = 4'b0110;
                        3'b001:   // BNE
                            ALU_out_r = 4'b0110;
                        3'b100:   // BLT
                            ALU_out_r = 4'b0011;
                        3'b101:   // BGE
                            ALU_out_r = 4'b0011;
                        3'b110:   // BLTU
                            ALU_out_r = 4'b0111;
                        3'b111:   // BGEU
                            ALU_out_r = 4'b0111;
                        default:
                            ALU_out_r = 4'b1111;
                    endcase
                end
                // LOAD
                7'b0000011: begin
                    jump_r = 1'b0;
                    branch_r = 1'b0;
                    MemtoReg_r = 1'b1;
                    AluSrc_r = 1'b1;
                    RegWrite_r = 1'b1;
                    rs1_r = idata[19:15];
                    rs2_r = 5'b0;
                    rd_r = idata[11:7];
                    ALU_out_r = 4'b0010;
                end
                // STORE
                7'b0100011: begin
                    jump_r = 1'b0;
                    branch_r = 1'b0;
                    MemtoReg_r = 1'b0;
                    AluSrc_r = 1'b1;
                    RegWrite_r = 1'b0;
                    rs1_r = idata[19:15];
                    rs2_r = idata[24:20];
                    rd_r = 5'b0;
                    ALU_out_r = 4'b0010;
                end
                // R
                7'b0110011: begin
                    jump_r = 1'b0;
                    branch_r = 1'b0;
                    MemtoReg_r = 1'b0;
                    AluSrc_r = 1'b0;
                    RegWrite_r = 1'b1;
                    rs1_r = idata[19:15];
                    rs2_r = idata[24:20];
                    rd_r = idata[11:7];
                    case(idata[14:12])
                        // ADD or SUB
                        3'b000: begin
                            if(idata[31:25] == 7'b0100000)
                                ALU_out_r = 4'b0110;
                            else if(idata[31:25] == 7'b0000000)
                                ALU_out_r = 4'b0010;
                            else
                                ALU_out_r = 4'b1111;
                        end
                        // SLL
                        3'b001: ALU_out_r = 4'b0101;
                        // SLT
                        3'b010: ALU_out_r = 4'b0011;
                        // SLTU
                        3'b011: ALU_out_r = 4'b0111;
                        // XOR
                        3'b100: ALU_out_r = 4'b1100;
                        // SRL or SRA
                        3'b101: begin
                            if(idata[31:25] == 7'b0100000)
                                ALU_out_r = 4'b1000;
                            else if(idata[31:25] == 7'b0000000)
                                ALU_out_r = 4'b0100;
                            else
                                ALU_out_r = 4'b1111;
                        end
                        // OR
                        3'b110: ALU_out_r = 4'b0001;
                        // AND
                        3'b111: ALU_out_r = 4'b0000;
                        default: ALU_out_r = 4'b1111;
                    endcase
                end
                // IMM
                7'b0010011: begin
                    jump_r = 1'b0;
                    branch_r = 1'b0;
                    MemtoReg_r = 1'b0;
                    AluSrc_r = 1'b1;
                    RegWrite_r = 1'b1;
                    rs1_r = idata[19:15];
                    rs2_r = 5'b0;
                    rd_r = idata[11:7];
                    case (idata[14:12])
                        // ADDI
                        3'b000: ALU_out_r = 4'b0010;
                        // SLTI
                        3'b010: ALU_out_r = 4'b0011;
                        // SLTU
                        3'b011: ALU_out_r = 4'b0111;
                        // XORI
                        3'b100: ALU_out_r = 4'b1100;
                        // ORI
                        3'b110: ALU_out_r = 4'b0001;
                        // ANDI
                        3'b111: ALU_out_r = 4'b0000;
                        // SLLI
                        3'b001: ALU_out_r = 4'b0101;
                        // SRLI or SRAI
                        3'b101: begin
                                if(idata[31:25] == 7'b0100000)
                                    ALU_out_r = 4'b1000;
                                else
                                    ALU_out_r = 4'b0100;
                            end
                        // default
                        default: ALU_out_r = 4'b1111;
                    endcase
                end
                default : begin
                    jump_r = 1'b0;
                    branch_r = 1'b0;
                    MemtoReg_r = 1'b0;
                    AluSrc_r = 1'b0;
                    RegWrite_r = 1'b0;
                    rs1_r = 5'b0;
                    rs2_r = 5'b0;
                    rd_r = 5'b0;
                    ALU_out_r = 4'b1111; 
                end
            endcase
        end
   
    assign branch = branch_r;
    assign jump = jump_r;
    assign MemtoReg = MemtoReg_r;
    assign rs1 = rs1_r;
    assign rs2 = rs2_r;
    assign rd = rd_r;
    assign AluSrc = AluSrc_r;
    assign RegWrite = RegWrite_r;
    assign ALU_out = ALU_out_r;
endmodule
