module registers( input [4:0] rs1,          //source register 1 address
                  input [4:0] rs2,          //source register 2 address
                  input [4:0] rd,           //destination register address 
                  input clk,                //clock
                  input we,                 //write enable
                  input [31:0] indata,      //data to be written into register
                  output [31:0] ro1,        //value in rs1
                  output [31:0] ro2         //value in rs2
                );
    
    reg [31:0] register [0:31];
    
    integer i;
    initial begin                         //initialising all registers to zero
        for (i=0;i<32;i=i+1)
            register[i] = 32'b0;
    end
    
    always @(posedge clk) begin          //writing into registers
        if(we) begin
            if(rd==5'd0)
                register[rd] <= 32'b0;   //register zero always holds zero
            else
                register[rd] <= indata;
        end
    end
    
    assign ro1 = register[rs1];          //reading from registers
    assign ro2 = register[rs2];          
    
endmodule