
module control(
input [5:0] op,             // 6-bit op from decoder
input [31:0] r_rv2,         // value at rs2 register in regfile (used in case of store instructions)
input [31:0] drdata,        // Data read from DMEM
input [31:0] rvout,         // ALU output, used for Daddr calculation in Load and Store and Iaddr calc in Branch
input [31:0] imm_val,       // immediate used for PC increment (conditional branch & JAL), and for AUIPC, LUI
input [31:0] PC_curr,       // current PC value, from cpu
output rwe,                 // regfile write enable
output [31:0] dwdata,       // Data to be written to DMEM (Store)
output [31:0] reg_wdata,    // Data to be written to regfile (Load)
output [31:0] daddr,        // Address (to read/write) of DMEM location
output [3:0] dwe,           // DMEM Write enable
output [5:0] alu_op,        // 6-bit op sent to ALU
output [31:0] PC_next       // next Iaddr, iaddr is set to PC_next in CPU
);
reg [31:0] dwdata;
reg [31:0] reg_wdata;
reg [31:0] daddr;
reg [31:0] PC_next;
reg [3:0] dwe;
reg [5:0] alu_op;
reg rwe;

/*    NOTE:
            Control signals must have a definite value (0 or 1) for ALL possible input combinations
            alu_op = op if instr is ALU type
                   = op(addi) if instr is load/store (+ JALR)
                   = op(sub)  (BEQ and BNE)
                   = op(SLT)  (BLT, BGE)
                   = op(SLTU) (BLTU, BGEU)
                   = Dont care (JAL, AUIPC, LUI)
           reg_wdata = rvout for ALU operations
                     = drdata for load (rwe = 1 for both)
                     and rwe  = 0 for all other instr
           in case of Load/Store Operation, daddr = rvout;
*/

    always @* begin
   
    if(op[3] == 1'b1) begin   // ALU operation
        alu_op = op;
        reg_wdata = rvout;
        rwe = 1;
        daddr = 32'b0;
        dwe = 0;
        dwdata = 0;
        PC_next = PC_curr + 4;
        
    end
    else if (op[4:3] == 2'b10) begin    // if load or store instr
        alu_op = 6'b001000;   // op(addi)
        daddr = rvout;
        PC_next = PC_curr + 4;
        case(op)
            6'b010000 :   begin
                rwe = 1;
                dwe = 0;
                dwdata = 0;
                case(daddr[1:0])    // last two bits of address indicate the byte to be addressed
                    2'b00:  reg_wdata = {{24{drdata[7]}}, drdata[7:0]};   //Byte 0
                    2'b01:  reg_wdata = {{24{drdata[15]}}, drdata[15:8]}; //Byte 1
                    2'b10:  reg_wdata = {{24{drdata[23]}}, drdata[23:16]};//Byte 2
                    2'b11:  reg_wdata = {{24{drdata[31]}}, drdata[31:24]};//Byte 3
                    default: reg_wdata = 32'b0;
                endcase
            end               //LB
            6'b010001 :   begin
                rwe = 1;
                dwe = 0;
                dwdata = 0;
                case(daddr[1:0])    // last two bits of address indicate the byte to be addressed
                    2'b00:  begin reg_wdata = {{16{drdata[15]}}, drdata[15:0]};end //HW 0
                    2'b10:  begin reg_wdata = {{16{drdata[31]}}, drdata[31:16]};end //HW 1
                    default: reg_wdata = 32'b0;
                endcase
            end             //LH
            6'b010010 :   begin
                rwe = 1;
                dwe = 0;
                dwdata = 0;
                case(daddr[1:0])    // last two bits of address indicate the byte to be addressed
                    2'b00: begin  reg_wdata = drdata;end
                    default: reg_wdata = 32'b0;
                endcase
            end           //LW
            6'b010100 :   begin
                rwe = 1;
                dwe = 0;
                dwdata = 0;
                case(daddr[1:0])    // last two bits of address indicate the byte to be addressed
                    2'b00:  reg_wdata = {24'b0, drdata[7:0]};   //Byte 0
                    2'b01:  reg_wdata = {24'b0, drdata[15:8]};  //Byte 1
                    2'b10:  reg_wdata = {24'b0, drdata[23:16]}; //Byte 2
                    2'b11:  reg_wdata = {24'b0, drdata[31:24]}; //Byte 3
                    default: reg_wdata = 32'b0;
                endcase
            end         //LBU
            6'b010101 :   begin
                rwe = 1;
                dwe = 0;
                dwdata = 0;
                case(daddr[1:0])    // last two bits of address indicate the byte to be addressed
                    2'b00: begin  reg_wdata = {16'b0, drdata[15:0]}; end//HW 0
                    2'b10:  begin reg_wdata = {16'b0, drdata[31:16]};end //HW 1
                    default reg_wdata = 32'b0;
                endcase
            end         //LHU
            6'b110000 :  begin
                 rwe = 0;
                 reg_wdata = 32'b0;
                case(daddr[1:0])
                   
                    2'b00:  begin dwe = 4'b0001;
                        dwdata = r_rv2; end
                    2'b01:  begin dwe = 4'b0010;
                        dwdata = {r_rv2<<8}; end
                    2'b10:  begin dwe = 4'b0100;
                        dwdata = {r_rv2<<16}; end
                    2'b11:  begin dwe = 4'b1000;
                        dwdata = {r_rv2<<24}; end
                    default: begin dwe = 32'b0;
                        dwdata = {32'b0}; end
                endcase
            end         //SB
            6'b110001 :  begin
                rwe = 0;
                reg_wdata = 32'b0;
                case(daddr[1:0])
                    2'b00:  begin dwe = 4'b0011;
                        dwdata = r_rv2; end
                    2'b10:  begin dwe = 4'b1100;
                        dwdata = {r_rv2<<16}; end
                    default: begin dwe = 32'b0;
                        dwdata = 32'b0; end
                endcase
            end     //SH
            6'b110010 :   begin
                rwe = 0;
                reg_wdata = 32'b0;
                case(daddr[1:0])
                    2'b00:  begin dwe = 4'b1111;
                        dwdata = r_rv2; end
                    default: begin dwe = 32'b0;
                        dwdata = 32'b0; end
                endcase
            end     //SW
            
            default: begin
                rwe = 0;
                reg_wdata = 32'b0;
                dwdata = 32'b0;
                dwe = 32'b0;end

        endcase
    end // end else
    else if (op[5:3] == 3'b100) begin   // Conditional Branch
        rwe = 0;
         reg_wdata = 32'b0;
         dwdata = 32'b0;
         dwe = 32'b0;
         daddr = 0;
        
        case (op[2:0])
            3'b000 : begin
                alu_op = 6'b111000; //op(SUB)
                if (rvout == 0)begin  PC_next = PC_curr + imm_val;end
                    else  begin PC_next = PC_curr+4;end
            end   //BEQ
            3'b001 : begin
                alu_op = 6'b111000; //op(SUB)
                if(rvout != 0) begin PC_next = PC_curr + imm_val;end
                else  begin PC_next = PC_curr+4;end
            end    //BNE
            3'b100 : begin
                alu_op = 6'b101010; //op(SLT)
                if(rvout[0])begin PC_next = PC_curr + imm_val;end
                else  begin PC_next = PC_curr+4;end
            end    //BLT
            3'b101 : begin
                alu_op = 6'b101010; //op(SLT)
                if (!rvout[0])begin PC_next = PC_curr + imm_val;end 
                else  begin PC_next = PC_curr+4;end
            end    //BGE
            3'b110 : begin
                alu_op = 6'b101011; //op(SLTU)
                if (rvout[0])begin PC_next = PC_curr + imm_val ;end 
                else  begin PC_next = PC_curr+4;end
            end    //BLTU
            3'b111 : begin
                alu_op = 6'b101011; //op(SLTU)
                if (!rvout[0]) begin PC_next = PC_curr + imm_val;end
                else begin PC_next = PC_curr+4;end 
            end //BGEU
            
            default : begin alu_op = 0; PC_next = PC_curr + 8;end
        endcase
    end
    else if (op[5:3] == 3'b0) begin
        rwe = 1;
        dwe = 0;
        dwdata = 0;
        daddr = 0;
        case(op[2:0])
            3'b100 :  begin
                alu_op = 6'b001000;   // op(addi)
                reg_wdata = PC_curr + 4;                // Not using ALU here to avoid routing
                PC_next = {rvout[31:1], 1'b0};   //ALU input rv1 thro' control (hardware still simple)
            end   // JALR
            3'b101 :   begin
                alu_op = 0;
                reg_wdata = PC_curr + 4;
                PC_next = PC_curr + imm_val;
            end // JAL
            3'b010 :begin  alu_op = 0; PC_next = PC_curr + 4;reg_wdata = PC_curr + imm_val;end              // AUIPC
            3'b110 :begin  alu_op = 0; PC_next = PC_curr + 4;reg_wdata = imm_val; end // LUI
            default: begin alu_op = 0; PC_next = PC_curr + 8;reg_wdata = 32'b0;end            
        endcase
    end
    else begin
        PC_next = PC_curr+4;
        reg_wdata = 32'b0;
        alu_op = 0;
        rwe = 0;
        dwe = 0;
        dwdata = 0;
        daddr = 0;
        
        
    end 
end // end always block
endmodule
