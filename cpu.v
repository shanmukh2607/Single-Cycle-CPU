module cpu (
    input clk, 
    input reset,
    output [31:0] iaddr,
    input [31:0] idata,
    output [31:0] daddr,
    input [31:0] drdata,
    output [31:0] dwdata,
    output [3:0] dwe
);
    reg [31:0] iaddr;    // iaddr gets updated inside always block
    reg [31:0] daddr;   // Connected to output of ALU
    reg [31:0] dwdata;  // final masked data to be written into dmem
    reg [3:0]  dwe;     // masking signal
    
    // Control signals 
    reg MemtoReg,ALUSrc,RegWrite,CondBr; 
    // MemtoReg when asserted reads from dmem to Register write and when deasserted reads from ALU Output
    // ALUSrc when asserted sends immediate value to ALU and when deasserted sends register value
    // RegWrite when asserted enables writing into register 
    // CondBr is a flag check for all Conditional Branches
    
    
    reg [4:0] rs1_addr, rs2_addr, rd_addr;  // address of registers in Regfile
    
    reg [3:0] ALUOp4;   // Encodes the type of ALU Operation in 4 bits in an always block
    
    
    reg [31:0] immgen;  // Immediate Value
    
    // Reg file ports
    wire [31:0] rs1_regfile, rs2_regfile;      // Output data to ALU
    wire [31:0] wdata_regfile;                 // Input data to Regfile to write in data
    
    // ALU ports
    wire [3:0] ALUOp4_wire;         // Net type equivalent for ALUOp4
    wire [31:0] rs1,rs2;           // decided by control signals and type of instruction
    reg [31:0] outALU;             // output of ALU
    
    // Dmem
    reg [31:0] drdata_regfile;     // Data read from dmem and sent to regfile via a MUX when MemtoReg is asserted
    
     // Some parameters defined for better readability of code
    localparam ALUR = 7'b0110011;
    localparam ALUI = 7'b0010011;
    localparam S = 7'b0100011;
    localparam L = 7'b0000011;
    localparam LUI = 7'b0110111;
    localparam AUIPC = 7'b0010111;
    localparam JAL = 7'b1101111;
    localparam JALR = 7'b1100111;
    localparam B = 7'b1100011;

    // Part 0 : Program Counter 
    always @(posedge clk) begin
        if (reset) 
            begin
                iaddr <= 0;           // Non blocking assignment of iaddr
                //daddr <= 0;
                //dwdata <= 0;
                //dwe <= 0;
            end 
        else                          // pc gets updated
            begin 
                case(idata[6:0])
                    JAL:                                    // JAL Type instruction
                        iaddr <= immgen + iaddr;
                    JALR:                                   // JALR type instruction, last bit of target addr is made 0
                        iaddr <= ((rs1_regfile + immgen) >> 1) << 1;
                    B:                                      // Conditional Branching
                        begin
                            if(CondBr)                      // Flag check for branching, flag takes values in Part 1
                                iaddr <= immgen + iaddr;
                            else
                                iaddr <= iaddr + 32'd4;   
                        end
                    default:
                        iaddr <= iaddr + 32'd4;             // Default case pc + 4 is updated
                endcase
            end
    end
    
    // Part 1: Generate Control signals used in CPU from idata
    always @(*)
        begin
            case (idata[6:0])   //opcode checked for type of Instr
                JAL:
                    begin
                        MemtoReg = 1'b0;        // outALU is sent to Regfile
                        ALUSrc = 1'b0;          // rs2 in ALU takes value from regfile
                        RegWrite = 1'b1;        // write enable set in rd
                        CondBr = 1'b0;          // No conditional branching
                        ALUOp4 =  4'd0;         // Addition
                        rs1_addr = 5'd0;        // rs1_addr is redundant as rs1 of ALU takes pc + 4 value
                        rs2_addr = 5'd0;        // rs2_addr set to 0.
                        rd_addr = idata[11:7];  // rd_addr
                    end
                
                JALR:
                    begin
                        MemtoReg = 1'b0;       // outALU is sent to Regfile for writing
                        ALUSrc = 1'b0;         // rs2 in ALU takes value from regfile
                        RegWrite = 1'b1;       // write enable set in rd
                        CondBr = 1'b0;         // No conditional branching
                        ALUOp4 = 4'd0;         // Addition
                        rs1_addr = idata[19:15]; // rs1 addr
                        rs2_addr = 5'd0;          // rs2 addr set to 0.
                        rd_addr = idata[11:7];   // rd addr
                    end
                
                B:
                    begin
                        MemtoReg = 1'b0;        // outALU is sent to Regfile for writing
                        ALUSrc = 1'b0;          // rs2 in ALU takes value from regfile
                        RegWrite = 1'b0;        // No writing into rd.
                        rs1_addr = idata[19:15];  // rs 1 and rs 2 addr
                        rs2_addr = idata[24:20];
                        rd_addr = 5'd0;
                        case(idata[14:12])               // ALUOp4 and CondBr are decided based on funct3 of instr
                            3'd0:              // BEQ
                                begin
                                    ALUOp4 = 4'd8;                 // SUB operation
                                    CondBr = (outALU == 32'b0) ? 1 : 0;
                                end
                            3'd1:              // BNE
                                begin
                                    ALUOp4 = 4'd8;                 // SUB operation
                                    CondBr = (outALU != 32'b0) ? 1 : 0;
                                end
                            3'd4:              // BLT
                                begin
                                    ALUOp4 = 4'd2;                 // SLT Operation
                                    CondBr = (outALU == 32'b1) ? 1 : 0;
                                end
                            3'd5:              // BGE
                                begin
                                    ALUOp4 = 4'd2;                 // SLT Operation
                                    CondBr = (outALU == 32'b0) ? 1 : 0;
                                end
                            3'd6:              // BLTU
                                begin
                                    ALUOp4 = 4'd3;                 // SLTU Operation
                                    CondBr = (outALU == 32'b1) ? 1 : 0;
                                end
                            3'd7:             // BGEU
                                begin
                                    ALUOp4 = 4'd3;                 // SLTU Operation
                                    CondBr = (outALU == 32'b0) ? 1 : 0;
                                end
                            default:
                                begin
                                    ALUOp4 = 4'd0;
                                    CondBr = 0;
                                end
                        endcase
                    end
                    
                ALUR:           // R type instruction
                    begin
                        CondBr = 1'b0;
                        MemtoReg = 1'b0;   // outALU is sent to regfile write
                        ALUSrc = 1'b0;     // regfile value is sent to r2 in ALU
                        RegWrite = 1'b1;   // write enabled in regfile
                        case (idata[14:12])          //funct3
                            3'd1,3'd2,3'd3,3'd4,3'd6,3'd7 :
                                ALUOp4 = {1'b0,idata[14:12]};     // respective numbers extended by a bit
                            3'd0 :
                                ALUOp4 = (idata[30])? 4'd8 : 4'd0; // 8 -sub, 0 -add
                            3'd5 :
                                ALUOp4 = (idata[30])? 4'd9 : 4'd5; // 9 -sra, 5 -srl
                            default :
                                ALUOp4 = {1'b0,idata[14:12]};
                        endcase
                        rs1_addr = idata[19:15];   // Addresses of registers required in instr
                        rs2_addr = idata[24:20];   // from Regfile
                        rd_addr  = idata[11:7];
                    end
                
                ALUI:                            // I type instruction
                    begin
                        CondBr = 1'b0;
                        MemtoReg = 1'b0;         // outALU is chosen to regfile write
                        ALUSrc = 1'b1;           // immediate value sent to r2 in ALU 
                        RegWrite = 1'b1;         // write enabled in regfile
                        case (idata[14:12])
                            3'd0,3'd1,3'd2,3'd3,3'd4,3'd6,3'd7 :
                                ALUOp4 = {1'b0,idata[14:12]};
                            3'd5:
                                ALUOp4 = (idata[30])? 4'd9 :4'd5; // 9-srai,  5-srli
                            default:
                                ALUOp4 = {1'b0,idata[14:12]};
                        endcase
                        rs1_addr = idata[19:15];  // Addresses of registers required in instr
                        rs2_addr = 5'd0;          // hardwired to 0
                        rd_addr  = idata[11:7];    
                    end
                S:
                    begin
                        CondBr = 1'b0;
                        MemtoReg = 1'b0;         
                        ALUSrc = 1'b1;   // immediate value sent to r2 in ALU
                        RegWrite = 0;   // Write enable set to 0
                        rs1_addr = idata[19:15];
                        rs2_addr = idata[24:20];   // addresses
                        rd_addr = 5'd0;
                        ALUOp4 = 4'd0;   // ALUOp4 =0 implies addition
                    end
                L:
                    begin
                        CondBr = 1'b0;
                        MemtoReg = 1'b1;   // Dmem value is sent to regfile write
                        ALUSrc = 1'b1;     // Immediate value is sent to r2 in ALU
                        RegWrite = 1'b1;   // write enabled
                        rs1_addr = idata[19:15];     
                        rs2_addr = 5'd0;             
                        rd_addr =  idata[11:7];     // register addresses
                        ALUOp4 = 4'd0;
                    end
                
                LUI, AUIPC:
                    begin
                        CondBr = 1'b0;
                        MemtoReg = 1'b0;
                        ALUSrc = 1'b1;       // Imm value to r2 of ALU
                        RegWrite = 1'b1;
                        rs1_addr = 5'd0;    // Zero register is read out 
                        rs2_addr = 5'd0;    // from Register file
                        rd_addr = idata[11:7];   // destination register address
                        ALUOp4 = 4'd0;      // 0 implies addition
                    end
                default:
                    begin
                        CondBr = 1'b0;
                        MemtoReg = 1'b0;
                        RegWrite = 1'b0; 
                        ALUSrc = 1'b0;
                        ALUOp4 = 4'd0;
                        rs1_addr = 5'd0;  
                        rs2_addr = 5'd0;
                        rd_addr = 5'd0;
                    end
            endcase
    
        end
    
    // Part 2: Immediate Value Generation
    
    always @(*)
        begin
            case(idata[6:0])       // Sign extensions are done based on type of instruction 
                JAL:
                    immgen = {{12{idata[31]}},idata[19:12],idata[20],idata[30:21],1'b0};
                
                JALR:
                    immgen = {{20{idata[31]}},idata[31:20]};
                
                B:
                    immgen = {{20{idata[31]}},idata[7],idata[30:25],idata[11:8],1'b0};
                
                ALUI:
                    case(idata[14:12])
                        3'd0,3'd2,3'd3,3'd4,3'd6,3'd7:
                            immgen = {{20{idata[31]}},idata[31:20]};
                        3'd1,3'd5:
                            immgen = {27'd0,idata[24:20]};
                        default:
                            immgen = 32'd0;
                    endcase
                ALUR:
                    immgen = 32'd0;
                S:
                    immgen = {{20{idata[31]}},idata[31:25],idata[11:7]};
                L:
                    immgen = {{20{idata[31]}},idata[31:20]};
                LUI, AUIPC:
                    immgen = {idata[31:12],12'd0};
                default:
                    immgen = 32'd0;
            endcase
        end
    
    
    // Part 3 : Instantiation of Register File module
    
    regfile inst1(.clk(clk), .reset(reset), .rs1_addr(rs1_addr), .rs2_addr(rs2_addr), .rd_addr(rd_addr), .wreg(wdata_regfile), .we(RegWrite), .rs1(rs1_regfile), .rs2(rs2_regfile));
    
    

    
    // Connecting the reg type variables with some control flags and assigning to net type variables
    
    assign rs2 = ALUSrc ? immgen : rs2_regfile;           // MUX between ALU and Regfile + Immediate Generator
     // In AUIPC instr, iaddr is sent directly to ALU r1
    
    assign rs1 = (idata[6:0] == JAL | idata[6:0] == JALR) ? iaddr+32'd4 : (idata[6:0] == AUIPC) ? iaddr : rs1_regfile;
                
    assign wdata_regfile = MemtoReg ? drdata_regfile : outALU;  // Data to be written in regfile
    
    
    // Part 4: ALU Function
    assign ALUOp4_wire = ALUOp4;
    
    always @(*)
        begin
            case(ALUOp4_wire)
                4'd0:                               // ADD
                    outALU = rs1 + rs2;
                
                4'd1:                               // SLL
                    outALU = rs1 << rs2[4:0];
                
                4'd2:                               // SLT
                    begin
                        if ($signed(rs1) < $signed(rs2))
                            outALU = 32'b1;
                        else
                            outALU = 32'b0;
                    end
                
                4'd3:                               // SLTU
                    begin
                        if (rs1 < rs2)
                            outALU = 32'b1;
                        else
                            outALU = 32'b0;
                    end
                
                4'd4:                               // XOR
                    outALU = rs1 ^ rs2;
                
                4'd5:                               // SRL
                    outALU = rs1 >> rs2[4:0];
                
                4'd6:                               // OR
                    outALU = rs1 | rs2;           
                
                4'd7:                               // AND
                    outALU = rs1 & rs2;
                
                4'd8:                               // SUB
                    outALU = rs1 - rs2;
                
                4'd9:                               // SRA
                    outALU = $signed(rs1)>>>rs2[4:0];

                default:
                    outALU = 0;
            endcase     
        end
    
    // Part 5: DMEM 
    
    // Connecting the reg type variables with reset flag and assigning to net type variables
    // These net type vars are ports of the CPU Module
    // Note: daddr, dwdata and dwe are updated combinationally and not synchronously


    always @(*)
        begin
            if(reset)                    // Reset set high
                begin
                    daddr = 32'd0;       // Asynchronously set to 0
                    dwdata = 32'd0;
                    dwe = 4'd0;
                    drdata_regfile = 32'd0;
                end
            else
                begin
                    daddr = outALU;      // Data address is computed by ALU 
                    case (idata[6:0])                     // Load type Instructions
                        L:
                            begin
                                dwe = 4'd0;                // No writing happens
                                dwdata = rs2_regfile;      // No writing happens 
                                case(idata[14:12])
                                    3'd0:                        // Load byte
                                        begin
                                            case(daddr[1:0])   // All addresses are valid for LB
                                                2'd0:
                                                    drdata_regfile = $signed(drdata[7:0]);
                                                2'd1:
                                                    drdata_regfile = $signed(drdata[15:8]);
                                                2'd2:
                                                    drdata_regfile = $signed(drdata[23:16]);
                                                2'd3:
                                                    drdata_regfile = $signed(drdata[31:24]);
                                                default:
                                                    drdata_regfile = 32'd0;
                                            endcase
                                        end

                                    3'd1:                       // Load Half word
                                        begin
                                            case(daddr[1:0])   // Last bit should be 0 for valid address in LH
                                                2'd0:
                                                    drdata_regfile = $signed(drdata[15:0]);
                                                2'd2:
                                                    drdata_regfile = $signed(drdata[31:16]);
                                                default:
                                                    drdata_regfile = 32'd0;
                                            endcase
                                        end

                                    3'd2:                     // Load Word
                                        begin
                                            case(daddr[1:0])  // Last 2 bits should be 0 for valid address in LW
                                                2'd0:
                                                    drdata_regfile = drdata;
                                                default:
                                                    drdata_regfile = 32'd0;
                                            endcase
                                        end

                                    3'd4:                     // Load Byte Unsigned
                                        begin
                                            case(daddr[1:0])
                                                2'd0:
                                                    drdata_regfile = $unsigned(drdata[7:0]);
                                                2'd1:
                                                    drdata_regfile = $unsigned(drdata[15:8]);
                                                2'd2:
                                                    drdata_regfile = $unsigned(drdata[23:16]);
                                                2'd3:
                                                    drdata_regfile = $unsigned(drdata[31:24]);
                                                default:
                                                    drdata_regfile = 32'd0;
                                            endcase
                                        end

                                    3'd5:                       // Load Halfword Unsigned
                                        begin
                                            case(daddr[1:0])
                                                2'd0:
                                                    drdata_regfile = $unsigned(drdata[15:0]);
                                                2'd2:
                                                    drdata_regfile = $unsigned(drdata[31:16]);
                                                default:
                                                    drdata_regfile = 32'd0;
                                            endcase
                                        end
                                    default:
                                        drdata_regfile = 32'd0;
                                endcase 
                            end

                        S:                  // Store Type Instructions 
                            begin
                                drdata_regfile = 32'd0;   // No reading from dmem required for store instr
                                case(idata[14:12])
                                    3'd0:                        // Store Byte
                                        begin
                                            dwdata = {4{rs2_regfile[7:0]}};
                                            case(daddr[1:0])
                                                2'd0:
                                                    dwe = 4'b0001;     // dwe is set appropriately based on d-addr
                                                2'd1:
                                                    dwe = 4'b0010;
                                                2'd2:
                                                    dwe = 4'b0100;
                                                2'd3:
                                                    dwe = 4'b1000;
                                                default:
                                                    dwe = 4'd0;
                                            endcase
                                        end

                                    3'd1:                      // Store Half word
                                        begin
                                            dwdata = {2{rs2_regfile[15:0]}};
                                            case(daddr[1:0])
                                                2'd0:
                                                    dwe = 4'b0011;
                                                2'd2:
                                                    dwe = 4'b1100;
                                                default:
                                                    dwe = 4'd0;
                                            endcase
                                        end

                                    3'd2:                      // Store word
                                        begin
                                            dwdata = rs2_regfile;
                                            case(daddr[1:0])
                                                2'd0:
                                                    dwe = 4'b1111;
                                                default:
                                                    dwe = 4'd0;
                                            endcase
                                        end
                                    default:
                                        begin
                                            dwe = 4'd0;
                                            dwdata = rs2_regfile;
                                        end
                                endcase
                            end
                        default:               // Neither Load nor store
                            begin
                                dwe = 4'd0;            // Write enable set to 0
                                dwdata = rs2_regfile;
                                drdata_regfile = drdata; //drdata_regfile not chosen, MemtoReg is deasserted for other inst
                            end
                    endcase
                end
        end
   
    
endmodule

