module alu ( input [4:0] op,      // Format is '<bit denoting only key bit in funct7><funct3><imm(0) or non-imm(1)>
               input [31:0] rv1,    // First operand
               input [31:0] rv2,    // Second operand
               output [31:0] rvout_f  // Output value
             );
    
    reg [31:0] rvout;
    assign rvout_f = rvout;

    always@(*)
    begin
        case(op[3:1])
            3'b000:  //ADD
                if(op[4] == 1'b1 && op[0] == 1'b1) //SUB
                    rvout = rv1 - rv2;
                else
                    rvout = rv1 + rv2;
            3'b010:  //SLT
                if ($signed(rv1) < $signed(rv2))
                    rvout = 32'b1;
                else
                    rvout = 32'b0;
            3'b011:  //SLTU
                if (rv1 < rv2)
                    rvout = 32'b1;
                else
                    rvout = 32'b0;
            3'b100:  //XOR
                rvout = rv1 ^ rv2;
            3'b110:  //OR
                rvout = rv1 | rv2;
            3'b111:  //AND
                rvout = rv1 & rv2;
            3'b001:  //SLL
                rvout = rv1 << rv2;
            3'b101:  //SRL, SLA
                if(op[4] == 1'b0) //SRL
                    rvout = rv1 >> rv2;
                else
                    rvout = $signed(rv1) >>> rv2;
            default:
                rvout = 32'b0;
        endcase
    end


endmodule