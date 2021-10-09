module alu( input [3:0] op,    //encoded instruction
            input [31:0] i1,   //input 1
            input [31:0] i2,   //input 2
            output [31:0] out  // ALU output       
          );
    
    reg [31:0] out_1;
    
    always @(op,i1,i2) begin
        case(op)
            0 : out_1 = i1 + i2;                      //add
            1 : out_1 = i1 - i2;                      //sub
            2 : out_1 = ($signed(i1) < $signed(i2));  //signed less than
            3 : out_1 = (i1 < i2);                    //unsigned less than
            4 : out_1 = i1 << i2;                     //logical left shift
            5 : out_1 = i1 >> i2;                     //logical right shift
            6 : out_1 = $signed(i1) >>> i2;           //arithmetic right shift
            7 : out_1 = i1 & i2;                      //AND
            8 : out_1 = i1 | i2;                      //OR
            9 : out_1 = i1 ^ i2;                      //XOR
            default : out_1 = 0;
            
        endcase
    end
    
    assign out = out_1;   //assigning output
    
endmodule