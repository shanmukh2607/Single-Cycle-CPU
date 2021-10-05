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
    reg [31:0] iaddr;
    reg [31:0] daddr;
    reg [31:0] dwdata;
    reg [3:0]  dwe;

    //Register File ports
    wire rwe;
    wire [31:0] rv1;
    wire [31:0] rv2;
    reg [31:0] rwdata;

    //Immediate ports
    wire [31:0] immediate;

    //ALU ports
    wire [4:0] ALUOp;
    wire [31:0] ALUOut;
    reg [31:0] rv2_f;

    //Control ports
    wire MemtoReg, ALUSrc, PCSrc, MemWrite;


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

    alu a1(
        .op(ALUOp),
        .rv1(rv1),
        .rv2(rv2_f),
        .rvout_f(ALUOut)
    );

    immGen i1(
        .idata(idata),
        .iout(immediate)
    );

    control c1(
    .idata(idata),
    .reset(reset),
    .MemtoReg(MemtoReg),
    .ALUOp(ALUOp),
    .MemWrite(MemWrite),
    .ALUSrc(ALUSrc),
    .RegWrite(rwe),
    .PCSrc(PCSrc)
    );

    regfile r1(
        .clk(clk),
        .reset(reset),
        .rs1(idata[19:15]),
        .rs2(idata[24:20]),
        .rd(idata[11:7]),
        .we(rwe),
        .wdata(rwdata),
        .rv1(rv1),
        .rv2(rv2)
    );

    //Combinatorial assignments
    always @(*) begin
        daddr = ALUOut;
        if(ALUSrc == 1'b0)
            rv2_f = rv2;
        else
            rv2_f = immediate;
        
        if(idata[6:0] == LUI) begin
            rwdata = immediate;                
        end
        else if(idata[6:0] == AUIPC) begin
            rwdata = immediate + iaddr;
        end
        else if(idata[6:0] == JALR || idata[6:0] == JAL) begin
            rwdata = iaddr + 4;
        end
        else if (idata[6:0] == LXX) begin
            case(idata[14:12])
                // LB
                3'b000: begin
                    case(daddr[1:0])
                        2'b00:
                            rwdata = $signed(drdata[7:0]);
                        2'b01:
                            rwdata = $signed(drdata[15:8]);
                        2'b10:
                            rwdata = $signed(drdata[23:16]);
                        2'b11:
                            rwdata = $signed(drdata[31:24]);
                    endcase
                end
                // LH
                3'b001: begin
                    case(daddr[1:0])
                        2'b00:
                            rwdata = $signed(drdata[15:0]);
                        2'b10:
                            rwdata = $signed(drdata[31:16]);
                        default:
                            rwdata = 32'b0;
                    endcase
                end
                // LW
                3'b010: begin
                    rwdata = drdata;
                end
                // LBU
                3'b100: begin
                    case(daddr[1:0])
                        2'b00:
                            rwdata = drdata[7:0];
                        2'b01:
                            rwdata = drdata[15:8];
                        2'b10:
                            rwdata = drdata[23:16];
                        2'b11:
                            rwdata = drdata[31:24];
                    endcase
                end
                // LHU
                3'b101: begin
                    case(daddr[1:0])
                        2'b00:
                            rwdata = drdata[15:0];
                        2'b10:
                            rwdata = drdata[31:16];
                        default:
                            rwdata = 32'b0;
                    endcase
                end
                default: begin
                    rwdata = drdata;
                end
            endcase
        end
        else if (idata[6:0] == SXX) begin
            
            case(idata[14:12])
                // SB
                3'b000: begin
                    dwdata = {4{rv2[7:0]}};     // repeat the last byte 4 times as write data
                    case(daddr[1:0])
                        2'b00:
                            dwe = 4'b0001;
                        2'b01:
                            dwe = 4'b0010;
                        2'b10:
                            dwe = 4'b0100;
                        2'b11:
                            dwe = 4'b1000;
                    endcase
                end
                // SH
                3'b001: begin
                    dwdata = {2{rv2[15:0]}};     // repeat last half-word 2 times as write data
                    case(daddr[1:0])
                        2'b00:
                            dwe = 4'b0011;
                        2'b10:
                            dwe = 4'b1100;
                        default:
                            dwe = 4'b0000;
                    endcase
                end
                // SW
                3'b010: begin
                    dwdata = rv2;
                    case(daddr[1:0])
                        2'b00:
                            dwe = 4'b1111;
                        default:
                            dwe = 4'b0000;
                    endcase
                end
                default:
                    dwe = 4'b0000;
            endcase
        end
        else begin
            dwe = 4'b0000;

            if(MemtoReg == 1'b0)
                rwdata = ALUOut;
            
        end

    end

    always @(posedge clk) begin
        //$display("%x, %x, %b, %x, %x\n", iaddr, idata[14:12], idata[6:0], rv1, rv2);
        if (reset) begin
            iaddr <= 0;
            daddr <= 0;
            dwdata <= 0;
            dwe <= 0;
        end 
        else begin 
            case (idata[6:0])
                JAL:
                    iaddr <= immediate + iaddr;
                JALR:
                    iaddr <= ((immediate+rv1) >> 1) << 1; //Set LSB as 0
                BXX:
                    if(idata[14:12] == 3'b000)
                        if(ALUOut == 32'b0) //BEQ
                            iaddr <= immediate + iaddr;
                        else
                            iaddr <= iaddr + 4;
                    else if(idata[14:12] == 3'b001)
                        if(ALUOut != 32'b0) //BNE
                            iaddr <= immediate + iaddr;
                        else
                            iaddr <= iaddr + 4;
                    else if(idata[12] != ALUOut[0])
                        iaddr <= immediate + iaddr;
                    else
                        iaddr <= iaddr + 4;
                default: 
                    iaddr <= iaddr + 4;
            endcase
        end
    end

endmodule