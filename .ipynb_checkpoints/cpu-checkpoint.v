module cpu (
    input clk, 
    input reset,
    output [31:0] iaddr,
    output [31:0] daddr,
    input [31:0] drdata,
    input [31:0] idata,
    output [31:0] dwdata,
    output [3:0] dwe
);
    
    reg [31:0] iaddr;
    // dmem ports
    reg [3:0] dwe_r;
    reg [31:0] masked_dwdata;
    // Register file signals
    wire [4:0] rs1, rs2, rd;
    wire [31:0] data1, data2, write_data;
    reg [31:0] drdata_RF;
    // Control instructions
    wire jump, branch;
    wire MemtoReg, AluSrc, RegWrite;
    wire [3:0] ALU_control_out;
    // Immgen
    wire [31:0] ext_imm;
    // ALU
    wire [31:0] ALU_INP2, ALU_INP1;
    wire [31:0] ALU_OUT;
    reg start;
    // PC Signals
    wire [31:0] iaddr_next;
    wire [31:0] jump_addr, beq_addr;
    wire beq_cond;
    wire jalr_cond, jal_cond;
    
    immGen u2(.idata(idata), .imm(ext_imm));
    Control u1(.idata(idata), .reset(reset), .jump(jump), .branch(branch), .MemtoReg(MemtoReg), .AluSrc(AluSrc), .RegWrite(RegWrite), .rs1(rs1), .rs2(rs2), .rd(rd), .ALU_out(ALU_control_out));
    
    always @(posedge clk) begin
        if (reset) begin
            iaddr <= 0;
            start <= 0;
        end 
        else begin
            if(start == 0) begin
                iaddr <=0;
                start <= 1'b1;
            end
            else begin
                start <= 1'b1;
                if(jump == 1'b1 | branch == 1'b1) begin
                    iaddr <= iaddr_next;
                end
                else
                    iaddr <= iaddr + 32'b0100;
            end
        end
    end
    
    assign jalr_cond = ((jump==1'b1)&(idata[6:0]==7'b1100111));
    assign jal_cond = ((jump==1'b1)&(idata[6:0]==7'b1101111));
    assign jump_addr = (jalr_cond==1'b1) ? ((ext_imm+data1) >> 1) << 1 : (jal_cond==1'b1) ? ext_imm + iaddr : iaddr + 32'b0100;
    
    assign beq_cond = branch&((ALU_OUT == 32'b0)&(idata[14:12] == 3'b000) |
                              (ALU_OUT != 32'b0)&(idata[14:12] == 3'b001) |
                              (ALU_OUT == 32'b1)&(idata[14:12] == 3'b100) |
                              (ALU_OUT == 32'b0)&(idata[14:12] == 3'b101) |
                              (ALU_OUT == 32'b1)&(idata[14:12] == 3'b110) |
                              (ALU_OUT == 32'b0)&(idata[14:12] == 3'b111));
    
    assign beq_addr = beq_cond ? ext_imm + iaddr : iaddr + 32'b0100;
    assign iaddr_next = branch ? beq_addr : jump_addr;
    
    regfile u3(.clk(clk), .RegWrite(RegWrite), .rs1(rs1), .rs2(rs2), .rd(rd), .data1(data1), .data2(data2), .write_data(write_data));
    ALU u4(.ALU_control(ALU_control_out), .inp1(ALU_INP1), .inp2(ALU_INP2), .alu_out(ALU_OUT));
    
    assign ALU_INP1 = (idata[6:0]==7'b1101111|idata[6:0]==7'b1100111)?iaddr+32'd4:(idata[6:0]==7'b0010111)?iaddr:data1;
    assign ALU_INP2 = AluSrc ? ext_imm:data2;
    assign write_data = MemtoReg?drdata_RF:ALU_OUT;
    assign dwe = {4{~reset}}&dwe_r;
    assign daddr = ALU_OUT;
    assign dwdata = {32{~reset}}&masked_dwdata;  
        
    
    always @(idata, daddr, data2)
        begin
            // getting dwe value
            if (idata[6:0] == 7'b0100011) 
                begin
                    case(idata[14:12])
                        // SB
                        3'b000: begin
                            masked_dwdata = {4{data2[7:0]}};
                            case(daddr[1:0])
                                2'b00:
                                    dwe_r = 4'b0001;
                                2'b01:
                                    dwe_r = 4'b0010;
                                2'b10:
                                    dwe_r = 4'b0100;
                                2'b11:
                                    dwe_r = 4'b1000;
                            endcase
                        end
                        // SH
                        3'b001: begin
                            masked_dwdata = {2{data2[15:0]}};
                            case(daddr[1:0])
                                2'b00:
                                    dwe_r = 4'b0011;
                                2'b10:
                                    dwe_r = 4'b1100;
                                default:
                                    dwe_r = 4'b0000;
                            endcase
                        end
                        // SW
                        3'b010: begin
                            masked_dwdata = data2;
                            case(daddr[1:0])
                                2'b00:
                                    dwe_r = 4'b1111;
                                default:
                                    dwe_r = 4'b0000;
                            endcase
                        end
                        default: begin
                            masked_dwdata = 32'b0;
                            dwe_r = 4'b0000;
                        end
                    endcase
                end
            else 
                begin
                    masked_dwdata = 32'b0;
                    dwe_r = 4'b0000;
                end 
        end
    
    always @(drdata, idata) begin
        // LOAD Instructions
        if (idata[6:0] == 7'b0000011) begin
            case(idata[14:12])
                // LB
                3'b000: begin
                    case(daddr[1:0])
                        2'b00:
                            drdata_RF = $signed(drdata[7:0]);
                        2'b01:
                            drdata_RF = $signed(drdata[15:8]);
                        2'b10:
                            drdata_RF = $signed(drdata[23:16]);
                        2'b11:
                            drdata_RF = $signed(drdata[31:24]);
                    endcase
                end
                // LH
                3'b001: begin
                    case(daddr[1:0])
                        2'b00:
                            drdata_RF = $signed(drdata[15:0]);
                        2'b10:
                            drdata_RF = $signed(drdata[31:16]);
                        default:
                            drdata_RF = 32'b0;
                    endcase
                end
                // LW
                3'b010: begin
                    drdata_RF = drdata;
                end
                // LBU
                3'b100: begin
                    case(daddr[1:0])
                        2'b00:
                            drdata_RF = drdata[7:0];
                        2'b01:
                            drdata_RF = drdata[15:8];
                        2'b10:
                            drdata_RF = drdata[23:16];
                        2'b11:
                            drdata_RF = drdata[31:24];
                    endcase
                end
                // LHU
                3'b101: begin
                    case(daddr[1:0])
                        2'b00:
                            drdata_RF = drdata[15:0];
                        2'b10:
                            drdata_RF = drdata[31:16];
                        default:
                            drdata_RF = 32'b0;
                    endcase
                end
                default: begin
                    drdata_RF = 32'b0;
                end
            endcase
        end
        else
            drdata_RF = 32'b0;
    end
endmodule

