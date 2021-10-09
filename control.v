module control( input [31:0] idata,   //instruction
                input reset,          //reset
                output [3:0] ALUOp,   //ALU operation code
                output [4:0] rs1,     //source register 1 address
                output [4:0] rs2,     //source register 2 address 
                output [4:0] rd,      //destination register address
                output RegWrite,      //write enable for registers 
                output MemtoReg,      //wether to write from data mem to registers
                output ALUSrc,        //wether ALU takes rs2 or immediate value as input
                output branch,        //wether to branch to another instruction
                output jump           //wether to jump to another instruction
              );
    
    reg MemtoReg_1, RegWrite_1, ALUSrc_1,branch_1,jump_1;
    reg [3:0] ALUOp_1;
    reg [4:0] rs1_1,rs2_1,rd_1;
    
    always @(idata) begin
            case(idata[6:0])

                7'b0110111,7'b0010111 : begin   //LUI,AUIPC - writes a value into a register
                    ALUOp_1 = 0;
                    rs1_1 = 0;
                    rs2_1 = 0;
                    rd_1 = idata[11:7];
                    RegWrite_1 = 1;
                    MemtoReg_1 = 0;
                    ALUSrc_1 = 1;
                    branch_1 = 0;
                    jump_1 = 0;
                               
                end

                7'b0000011 : begin              //load instructions
                    ALUOp_1 = 0;
                    rs1_1 = idata[19:15];
                    rs2_1 = 0;
                    rd_1 = idata[11:7];
                    RegWrite_1 = 1;
                    MemtoReg_1 = 1;
                    ALUSrc_1 = 1;
                    branch_1 = 0;
                    jump_1 = 0;
                end

                7'b0100011 : begin              //store instructions
                    ALUOp_1 = 0;
                    rs1_1 = idata[19:15];
                    rs2_1 = idata[24:20];
                    rd_1 = 0;
                    RegWrite_1 = 0;
                    MemtoReg_1 = 0;
                    ALUSrc_1 = 1;
                    branch_1 = 0;
                    jump_1 = 0;
                end

                7'b0010011 : begin              //immediate operations
                    case (idata[14:12])
                        0 : ALUOp_1 = 0;
                        1 : ALUOp_1 = 4;
                        2 : ALUOp_1 = 2;
                        3 : ALUOp_1 = 3;
                        4 : ALUOp_1 = 9;
                        5 : ALUOp_1 = (idata[30])? 6:5;
                        6 : ALUOp_1 = 8;
                        7 : ALUOp_1 = 7;
                        default : ALUOp_1 = 0;
                    endcase
                    rs1_1 = idata[19:15];
                    rs2_1 = 0;
                    rd_1 = idata[11:7];
                    RegWrite_1 = 1;
                    MemtoReg_1 = 0;
                    ALUSrc_1 = 1;
                    branch_1 = 0;
                    jump_1 = 0;
                end 

                7'b0110011 : begin              //register operations
                    case(idata[14:12])
                        0 : ALUOp_1 = (idata[30])? 1:0;
                        1 : ALUOp_1 = 4;
                        2 : ALUOp_1 = 2;
                        3 : ALUOp_1 = 3;
                        4 : ALUOp_1 = 9;
                        5 : ALUOp_1 = (idata[30])? 6:5;
                        6 : ALUOp_1 = 8;
                        7 : ALUOp_1 = 7;
                        default : ALUOp_1 = 0;
                    endcase
                    rs1_1 = idata[19:15];
                    rs2_1 = idata[24:20];
                    rd_1 = idata[11:7];
                    RegWrite_1 = 1;
                    MemtoReg_1 = 0;
                    ALUSrc_1 = 0;
                    branch_1 = 0;
                    jump_1 = 0;
                end
                
                7'b1101111 : begin              //JAL
                    ALUOp_1 = 0;
                    rs1_1 = 0;
                    rs2_1 = 0;
                    rd_1 = idata[11:7];
                    RegWrite_1 = 1;
                    MemtoReg_1 = 0;
                    ALUSrc_1 = 0;
                    branch_1 = 0;
                    jump_1 = 1;
                end
                
                7'b1100111 : begin              //JALR
                    ALUOp_1 = 0;
                    rs1_1 = idata[19:15];
                    rs2_1 = 0;
                    rd_1 = idata[11:7];
                    RegWrite_1 = 1;
                    MemtoReg_1 = 0;
                    ALUSrc_1 = 0;
                    branch_1 = 0;
                    jump_1 = 1;
                end
                
                7'b1100011 : begin              //branch operations
                    case(idata[14:12])
                        0 : ALUOp_1 = 1;
                        1 : ALUOp_1 = 1;
                        4 : ALUOp_1 = 2;
                        5 : ALUOp_1 = 2;
                        6 : ALUOp_1 = 3;
                        7 : ALUOp_1 = 3;
                        default : ALUOp_1 = 0;
                    endcase
                    rs1_1 = idata[19:15];
                    rs2_1 = idata[24:20];
                    rd_1 = 0;
                    RegWrite_1 = 0;
                    MemtoReg_1 = 0;
                    ALUSrc_1 = 0;
                    branch_1 = 1;
                    jump_1 = 0;
                end

                default : begin
                    ALUOp_1 = 0;
                    rs1_1 = 0;
                    rs2_1 = 0;
                    rd_1 = 0;
                    RegWrite_1 = 0;
                    MemtoReg_1 = 0;
                    ALUSrc_1 = 0;
                    branch_1 = 0;
                    jump_1 = 0;
                end
            endcase
    end
    
    assign ALUOp = ~reset & ALUOp_1;
    assign rs1 = ~reset & rs1_1;
    assign rs2 = ~reset & rs2_1;
    assign rd = ~reset & rd_1;
    assign RegWrite = ~reset & RegWrite_1;
    assign MemtoReg = ~reset & MemtoReg_1;
    assign ALUSrc = ~reset & ALUSrc_1;
    assign branch = ~reset & branch_1;
    assign jump = ~reset & jump_1;               //assigning outputs
    
endmodule