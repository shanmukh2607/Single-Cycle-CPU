
`define INIT_MEM "init_regfile.mem"
module regfile(
    input [4:0] rs1,     // address of first operand to read - 5 bits
    input [4:0] rs2,     // address of second operand
    input [4:0] rd,      // address of value to write
    input we,            // should write update occur
    input [31:0] wdata,  // value to be written
    output [31:0] rv1,   // First read value
    output [31:0] rv2,   // Second read value
    input clk            // Clock signal - all changes at clock posedge
);
    // Desired function
    // rv1, rv2 are combinational outputs - they will update whenever rs1, rs2 change
    // on clock edge, if we=1, regfile entry for rd will be updated
    reg [31:0] x [0:31];
    initial begin       // synthesised as Distributed RAM using LUTs
        $readmemh(`INIT_MEM, x);
    end
    //Synchronous Write to reg
    always @(posedge clk) begin
        if(we) begin
            if(rd == 5'b0)  x[0] <= 32'b0;
            else            x[rd] <= wdata;
        end
        else begin x[rd] <= 32'b0;end
    end
    //Async read
    assign rv1 = x[rs1];
    assign rv2 = x[rs2];
endmodule