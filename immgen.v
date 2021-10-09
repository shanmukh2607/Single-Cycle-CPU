module immgen( input [31:0] idata,   //instruction
               output [31:0] imm     //immediate value generated
              );
    
    reg [31:0] imm_1;

    always @(idata) begin
        case(idata[6:0])
            
            7'b0110111,7'b0010111 : imm_1 = {idata[31:12], 12'd0};     //LUI,AUIPC
            7'b0000011,7'b1100111 : imm_1 = $signed(idata[31:20]);     //load operations,JALR
            7'b0100011 : imm_1 = $signed({idata[31:25], idata[11:7]}); //store operations            
            7'b0010011 :                                               //immediate operations
                case(idata[14:12])
                    0,2,3,4,6,7 : imm_1 = $signed(idata[31:20]);
                    1,5 : imm_1 = {27'b0, idata[24:20]};
                endcase
            7'b0110011 : imm_1 = 0;                                    //register operations
            7'b1101111 : imm_1 = $signed({idata[31], idata[19:12], idata[20], idata[30:21], 1'b0});   //JAL
            7'b1100011 : imm_1 = $signed({idata[31], idata[7], idata[30:25], idata[11:8], 1'b0});     //Branch operations
            
            default : imm_1= 0;
        endcase
    end
    
    assign imm = imm_1;   //assigning output
    
endmodule