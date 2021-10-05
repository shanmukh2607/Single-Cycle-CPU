module regfile ( input [4:0] rs1,     // address of first read register
                 input [4:0] rs2,     // address of second read register
                 input [4:0] rd,      // address of write register
                 input we,            // write enable
                 input [31:0] wdata,  // write data
                 output [31:0] rv1,   // First read value
                 output [31:0] rv2,   // Second read value
                 input clk,            // Clock
                 input reset          // Reset
               );


    reg [31:0] registers [0:31];
    reg [31:0] rv1_r, rv2_r;
	 integer i;

    // combinational read operations
    always @(*) begin
        rv1_r = registers[rs1];
        rv2_r = registers[rs2];
    end
	 
    assign rv1 = rv1_r;
    assign rv2 = rv2_r;

    // synchronous write operations
    always @(posedge clk) begin
        if(reset)
        begin
            for (i=0;i<32;i=i+1)
                registers[i] <= 32'b0;
        end
        else if (we == 1'b1)
            if(rd == 5'b0)
                registers[rd] <= 32'd0;
            else
                registers[rd] <= wdata;
    end
endmodule