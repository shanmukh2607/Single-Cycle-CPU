module immGen ( input [31:0] idata,     // instruction
                output reg [31:0] iout       // immediate value
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
        case(idata[6:0])
            JAL:
                iout = $signed({idata[20], idata[19:12], idata[20], idata[30:21], 1'b0});
            BXX:
                iout = $signed({idata[31], idata[7], idata[30:25], idata[11:8], 1'b0});
            LUI,
            AUIPC:
                iout = {idata[31:12], 12'd0};
            SXX:
                iout = $signed({idata[31:25], idata[11:7]});
            JALR, 
            LXX:
                iout = $signed(idata[31:20]);
            IXX:
                case(idata[14:12])
                    3'b000,
                    3'b010,
                    3'b011,
                    3'b100,
                    3'b110,
                    3'b111:
                        iout = $signed(idata[31:20]);
                    3'b001,
                    3'b101:  //shamt
                        iout = {27'b0, idata[24:20]};
                endcase
            RXX:
                iout = 32'b0;
            default:
                iout = 32'b0;
        endcase
    end

endmodule