module ALU(input [3:0] ALU_control,
           input [31:0] inp1,
           input [31:0] inp2,
           output [31:0] alu_out);
    
    reg [31:0] out;
    
    // 0000 : AND
    // 0001 : OR
    // 0010 : ADD
    // 0110 : SUB
    // 0111 : SET LESS THAN UNSIGNED
    // 0011 : SET LESS THAN
    // 1100 : XOR
    // 0101 : SHIFT LEFT LOGICAL
    // 0100 : SHIFT RIGHT LOGICAL
    // 1000 : SHIFT RIGHT ARITHMETIC
    
    always @(inp1, inp2, ALU_control)
        begin
            case(ALU_control)
                // AND
                4'b0000 : begin
                            out=inp1&inp2; 
                          end
                // OR
                4'b0001 : begin
                            out=inp1|inp2; 
                          end
                // ADD
                4'b0010 : begin
                            out = inp1 + inp2; 
                          end
                // SLT
                4'b0011 : begin
                            if(inp1<inp2)
                                begin
                                    out=32'b01;
                                end
                            else
                                begin
                                    out=32'b0;
                                end
                          end
                // SRL
                4'b0100 : begin
                            out=inp1>>inp2;
                          end
                // SLL
                4'b0101 : begin
                            out=inp1<<inp2;
                          end
                // SUB
                4'b0110 : begin
                            out=inp1-inp2; 
                          end
                // SLTU
                4'b0111 : begin
                            if($unsigned(inp1)<$unsigned(inp2))
                                out=32'b01;
                            else
                                out=32'b0;
                          end
                // SRA
                4'b1000 : begin
                            out=$signed(inp1)>>>inp2;
                          end
                // XOR
                4'b1100 : begin
                            out=inp1^inp2;
                          end
                default : begin 
                            out=32'b0; 
                          end
            endcase
        end
        assign alu_out = out;
endmodule