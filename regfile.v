module regfile(
    input clk,
    input RegWrite,
    input[4:0] rs1, input[4:0] rs2, input[4:0] rd,
    output[31:0] data1, output[31:0] data2,
    input[31:0] write_data);
    
    reg[31:0] Register_File[0:31];
        
    integer i;
    initial begin
        for (i=0;i<32;i=i+1)
            Register_File[i] = 32'b0;
    end
    
    always @(posedge clk)
    begin
        if(RegWrite == 1'b1)
            begin
                if(rd == 5'b0)
                    Register_File[rd] <= 32'b0;
                else
                    Register_File[rd] <= write_data;
            end
    end
    
    assign data1 = Register_File[rs1];
    assign data2 = Register_File[rs2];
endmodule