module control (  //MemRead not used
    input [31:0] idata,
    input reset,
    output reg MemtoReg,
    output reg [4:0] ALUOp,
    output reg MemWrite,
    output reg ALUSrc,
    output reg RegWrite,  //RegWrite to dwe needs to done in cpu.v due to unavailability of daddr in control
    output reg PCSrc
);
    
    // localparam statements for opcodes
    localparam LUI = 7'b0110111;
    localparam AUIPC = 7'b0010111;
    localparam JAL = 7'b1101111;
    localparam JALR = 7'b1100111;
    localparam BXX = 7'b1100011;
    localparam LXX = 7'b0000011; //Load
    localparam SXX = 7'b0100011; //Store
    localparam IXX = 7'b0010011; //Immediate ALU
    localparam RXX = 7'b0110011; //Non-immediate ALU

    always @(*) begin
        if(reset) begin
            MemtoReg = 1'b0;
            ALUOp = 5'b0;
            MemWrite = 1'b0;
            ALUSrc = 1'b0;
            RegWrite = 1'b0;
            PCSrc = 1'b0; 
        end else begin
            case(idata[6:0])
                JAL, 
                JALR: begin
                    MemtoReg = 1'b0;
                    ALUOp = 5'b0;
                    MemWrite = 1'b0;
                    ALUSrc = 1'b0;
                    RegWrite = 1'b1;
                    PCSrc = 1'b1;                
                end
                LUI,
                AUIPC: begin
                    MemtoReg = 1'b0;
                    ALUOp = 5'b0; //ADDI
                    MemWrite = 1'b0;
                    ALUSrc = 1'b1; //Use immediate
                    RegWrite = 1'b1;
                    PCSrc = 1'b0;
                end
                BXX: begin
                    case (idata[14:12])
                        3'b000, //BEQ, BNE
                        3'b001: begin
                            MemtoReg = 1'b0;
                            ALUOp = 5'b01000;  //XOR
                            MemWrite = 1'b0;
                            ALUSrc = 1'b0;
                            RegWrite = 1'b0;
                            PCSrc = 1'b1;                          
                        end 
                        3'b100, //BLT, BGE
                        3'b101: begin
                            MemtoReg = 1'b0;
                            ALUOp = 5'b00100;  //SLT
                            MemWrite = 1'b0;
                            ALUSrc = 1'b0;
                            RegWrite = 1'b0;
                            PCSrc = 1'b1;   
                        end 
                        3'b110, //BLTU, BGEU
                        3'b111: begin
                            MemtoReg = 1'b0;
                            ALUOp = 5'b00110;  //SLTU
                            MemWrite = 1'b0;
                            ALUSrc = 1'b0;
                            RegWrite = 1'b0;
                            PCSrc = 1'b1;   
                        end 
                        default: begin
                            MemtoReg = 1'b0;
                            ALUOp = 5'b00000;
                            MemWrite = 1'b0;
                            ALUSrc = 1'b0;
                            RegWrite = 1'b0;
                            PCSrc = 1'b0;
                        end
                    endcase
                end
                LXX: begin
                    MemtoReg = 1'b1;
                    ALUOp = 5'b0; //ADDI
                    MemWrite = 1'b0;
                    ALUSrc = 1'b1; //Use immediate
                    RegWrite = 1'b1;
                    PCSrc = 1'b0;
                end
                SXX: begin
                    MemtoReg = 1'b1;
                    ALUOp = 5'b0; //ADDI
                    MemWrite = 1'b1;
                    ALUSrc = 1'b1; //Use immediate
                    RegWrite = 1'b0;
                    PCSrc = 1'b0;
                end
                IXX: begin
                    MemtoReg = 1'b0;
                    ALUOp = {idata[30], idata[14:12], idata[5]};
                    MemWrite = 1'b0;
                    ALUSrc = 1'b1; //Use immediate
                    RegWrite = 1'b1;
                    PCSrc = 1'b0;
                end
                RXX: begin
                    MemtoReg = 1'b0;
                    ALUOp = {idata[30], idata[14:12], idata[5]};
                    MemWrite = 1'b0;
                    ALUSrc = 1'b0; //Use non immediate
                    RegWrite = 1'b1;
                    PCSrc = 1'b0;
                end
                default: begin
                    MemtoReg = 1'b0;
                    ALUOp = 5'b0;
                    MemWrite = 1'b0;
                    ALUSrc = 1'b0;
                    RegWrite = 1'b0;
                    PCSrc = 1'b0;
                end
            endcase
        end
    end

endmodule