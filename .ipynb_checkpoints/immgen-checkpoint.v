module immGen ( input [31:0] idata, 
                output [31:0] imm);
    
    reg [31:0] imm_r;
    // assigning outputs

    always @(idata) begin
        // immediate value from instruction
        case(idata[6:0])
            //LUI
            7'b0110111: imm_r = idata[31:12] << 12;
            // AUIPC
            7'b0010111: imm_r = idata[31:12] << 12;
            // JAL
            7'b1101111: imm_r = $signed({idata[31], idata[19:12], idata[20], idata[30:21], 1'b0});
            // BRANCH
            7'b1100011: imm_r = $signed({idata[31], idata[7], idata[30:25], idata[11:8], 1'b0});
            // STORE
            7'b0100011: imm_r = $signed({idata[31:25], idata[11:7]});
            // LOAD
            7'b0000011: imm_r = $signed(idata[31:20]);
            // JALR
            7'b1100111: imm_r = $signed(idata[31:20]);
            // IMM
            7'b0010011:
                case(idata[14:12])
                    3'b000: imm_r = $signed(idata[31:20]);
                    3'b010: imm_r = $signed(idata[31:20]);
                    3'b011: imm_r = $signed(idata[31:20]);
                    3'b100: imm_r = $signed(idata[31:20]);
                    3'b110: imm_r = $signed(idata[31:20]);
                    3'b111: imm_r = $signed(idata[31:20]);
                    3'b001: imm_r = {27'b0, idata[24:20]};
                    3'b101: imm_r = {27'b0, idata[24:20]};
                endcase
            // R
            7'b0110011: imm_r = 32'b0;
            default:
                imm_r = 32'b0;
        endcase
    end
    
    assign imm = imm_r;
endmodule