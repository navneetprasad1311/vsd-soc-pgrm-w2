`timescale 1ns / 1ps

module tb_rvmyth;
	// Inputs
	reg clk, reset;
	// Outputs
	wire [9:0] out;

        // Instantiate the Unit Under Test (UUT)
	rvmyth uut (
		.CLK(clk),
		.reset(reset),
		.OUT(out)
	);

	initial begin
        $dumpfile("tb_rvmyth.vcd");
        $dumpvars(0,tb_rvmyth);
        clk = 1;
        reset = 0;
        #2 reset = 1;
	#10 reset = 0;
        #2000 $finish;
        end
        always #1 clk = ~clk;

endmodule
