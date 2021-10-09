module cpu ( input clk,             //clock
             input reset,           //reset
             output [31:0] iaddr,   //program counter
             input [31:0] idata,    //instruction
             output [31:0] daddr,   //data memory address 
             input [31:0] drdata,   //data memory read value
             output [31:0] dwdata,  //data memory write value
             output [3:0] dwe       //data memory write enable
           );

    reg [31:0] iaddr;               //program counter
    reg ctr = 0;                    //a dummy register to prevent 1st instruction from being skipped when reset occurs at a clock edge

    wire MemtoReg,ALUSrc,jump,branch,we_reg;
    wire [3:0] ALUOp;              //control signals

    wire [4:0] rs1, rs2, rd;        //register addresses
    wire [31:0] indata, ro1, ro2;   //values to read from or write into registers
    
    reg [31:0] drdata_1;            //data read from memory
    reg [31:0] dwdata_1;            //data to write into memory
    reg [3:0] dwe_1;                //write enable for data memory
    
    wire [31:0] i1, i2, out;        //inputs and output of ALU

    wire [31:0] imm;                //immediate value generated

    always @(posedge clk) begin     //program counter

        if (reset) begin 
            iaddr <= 0;            //at next clk cycle instruction 0 executed
            ctr <= 1;              //ctr is set to 1 during reset
        end
        
        else if(ctr) begin          //execute 1st instruction on next clock edge after reset is off
            iaddr <= 0;             
            ctr <= 0;               
        end
        
        else if (jump) begin                     //if jump
            if (idata[6:0]==7'b1100111)          //JALR
                iaddr <= imm+ro1;                //put pc = imm + value in register
            else if (idata[6:0]==7'b1101111)     //JAL
                iaddr <= imm + iaddr;            //put pc = pc + imm
        end
        
        else if (branch) begin                   //if branch
            iaddr <= iaddr + 4;              
            case(idata[14:12])
                3'b000: begin                      // BEQ
                    if (out == 0)
                        iaddr <= imm + iaddr;
                end
                3'b001: begin                      // BNE
                    if (out != 0)
                        iaddr <= imm + iaddr;
                end
                3'b100: begin                      // BLT
                    if (out == 1)
                        iaddr <= imm + iaddr;
                end
                3'b101: begin                      // BGE
                    if (out == 0)
                        iaddr <= imm + iaddr;
                end
                3'b110: begin                      // BLTU
                    if (out == 1)
                        iaddr <= imm + iaddr;
                end
                3'b111: begin                      // BGEU
                    if (out == 0)
                        iaddr <= imm + iaddr;
                end
                default:
                    iaddr <= iaddr + 4;
            endcase
        end
        
        else 
            iaddr <= iaddr + 4;              //next instruction in sequence
    end
        
     
    //instantiating ALU
    alu alu_1(
        .op(ALUOp),
        .i1(i1),
        .i2(i2),
        .out(out)
    );
    
    //instantiating control module
    control control_1(
        .idata(idata),
        .reset(reset),
        .MemtoReg(MemtoReg),
        .ALUOp(ALUOp),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .ALUSrc(ALUSrc),
        .RegWrite(we_reg),
        .branch(branch),
        .jump(jump)
    );

    //instantiating immediate generator
    immgen immgen_1(
        .idata(idata),
        .imm(imm)
    );

    //instantiating registers
    registers registers_1(
        .clk(clk),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .we(~ctr&we_reg),                //to prevent executing the first instruction twice, and ~ctr with write enable for registers
        .indata(indata),
        .ro1(ro1),
        .ro2(ro2)
    );

    always @(idata, daddr) begin
        
        case(idata[6:0])
            
            7'b0100011: begin
                
                drdata_1 = 0;
            
                case(idata[14:12]) 

                    3'b000: begin                   //one byte
                        dwdata_1 = {4{ro2[7:0]}};   //repeat the byte 4 times
                        case(daddr[1:0])            //appropriate masking
                            2'b00:
                                dwe_1 = 4'b0001;
                            2'b01:
                                dwe_1 = 4'b0010;
                            2'b10:
                                dwe_1 = 4'b0100;
                            2'b11:
                                dwe_1 = 4'b1000;
                            default:
                                dwe_1 = 0;
                        endcase
                    end

                    3'b001: begin                   //half word
                        dwdata_1 = {2{ro2[15:0]}};  //repeat half word 2 times   
                        case(daddr[1:0])            //appropriate masking
                            2'b00:
                                dwe_1 = 4'b0011;
                            2'b10:
                                dwe_1 = 4'b1100;
                            default:
                                dwe_1 = 4'b0000;
                        endcase
                    end

                    3'b010: begin                   //word
                        dwdata_1 = ro2; 
                        case(daddr[1:0])            //no masking needed
                            2'b00:
                                dwe_1 = 4'b1111;
                            default:
                                dwe_1 = 4'b0000;
                        endcase
                    end

                    default: begin
                        dwdata_1 = 0;
                        dwe_1 = 4'b0000;
                    end
                endcase           
            end
            
            7'b0000011: begin
                
                dwe_1 =0;
                dwdata_1 = 0;
            
                case(idata[14:12])

                    3'b000: begin                      //one byte
                        case(daddr[1:0])               //read which byte
                            2'b00:
                                drdata_1 = $signed(drdata[7:0]);
                            2'b01:
                                drdata_1 = $signed(drdata[15:8]);
                            2'b10:
                                drdata_1 = $signed(drdata[23:16]);
                            2'b11:
                                drdata_1 = $signed(drdata[31:24]);
                            default:
                                drdata_1 = 0;
                        endcase
                    end

                    3'b001: begin                      //half word
                        case(daddr[1:0])               //read upper or lower half          
                            2'b00:           
                                drdata_1 = $signed(drdata[15:0]);
                            2'b10:
                                drdata_1 = $signed(drdata[31:16]);
                            default:
                                drdata_1 = 32'b0;
                        endcase
                    end
                    
                    3'b010: begin                     //word
                        drdata_1 = drdata;
                    end

                    3'b100: begin
                        case(daddr[1:0])              //byte unsigned
                            2'b00:                    //read which byte
                                drdata_1 = drdata[7:0];
                            2'b01:
                                drdata_1 = drdata[15:8];
                            2'b10:
                                drdata_1 = drdata[23:16];
                            2'b11:
                                drdata_1 = drdata[31:24];
                            default:
                                drdata_1 = 0;
                        endcase
                    end

                    3'b101: begin                       //half word unsigned
                        case(daddr[1:0])                //read upper or lower half word
                            2'b00:
                                drdata_1 = drdata[15:0];
                            2'b10:
                                drdata_1 = drdata[31:16];
                            default:
                                drdata_1 = 32'b0;
                        endcase
                    end
                   
                    default: begin
                        drdata_1 = 32'b0; 
                    end
                endcase
            end
            
            default: begin
                dwe_1 = 0;
                drdata_1 = 0;
                dwdata_1 = 0;
            end
        endcase
    end           
    
    assign i1 = (idata[6:0] == 7'b1101111 | idata[6:0] == 7'b1100111) ? iaddr + 4 : (idata[6:0] == 7'b0010111) ? iaddr : ro1; //if JAL or JALR : give return address to ALU, if AUIPC : PC value as input to ALU
    assign i2 = (ALUSrc) ? imm : ro2;             //immediate or register as input to ALU
    assign indata = (MemtoReg) ? drdata_1 : out;  //write ALU output or from data memory to registers
    assign dwe = ~reset & dwe_1;
    assign daddr = out;
    assign dwdata = ~reset & dwdata_1;      //assigning outputs


endmodule