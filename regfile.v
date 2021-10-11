// This module contains the Register file

module regfile(input clk,input reset, input [4:0] rs1_addr, input [4:0] rs2_addr, input [4:0] rd_addr, input [31:0] wreg, input we,
               output [31:0] rs1, output [31:0] rs2);
    
    
    // Let's declare the 32 register bank, each having 32 bits.
    
    reg [31:0] registerbank [0:31];
    
    integer index;
    initial
        begin
            for (index=0; index < 32; index++)
                registerbank[index] = {32{1'b0}};
        end
    
    // Asynchronous Read data from Reg file to ALU
    
    assign rs1 = registerbank[rs1_addr];
    assign rs2 = registerbank[rs2_addr];
    
    // Writing of data into register bank is synchronous
    
    integer j;
    
    always @(posedge clk)                                   // Register gets updated at clk edge
        begin                                               // x0 is hardwired to zero in RISC-V
            if(reset)
                begin
                    for(j =0; j<32; j=j+1)
                        registerbank[j] <= {32{1'b0}};
                end
            else
                begin
                    if(we)                                // we flag should be high for writing into regfile
                        begin
                            if(rd_addr != 0)
                                registerbank[rd_addr] <= wreg;
                            else
                                registerbank[5'd0] <= {32{1'b0}};
 
                        end
                    else
                        begin
                            registerbank[5'd0] <= {32{1'b0}};
                        end
                end
        end 
        
    
endmodule



