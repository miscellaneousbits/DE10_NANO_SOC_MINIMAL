module altera_edge_detector #(
parameter [4:0] PULSE_EXT = 0 // 0, 1 = edge detection generate single cycle pulse, >1 = pulse extended for specified clock cycle
) (
input      clk,
input      rst_n,
input      signal_in,
output     pulse_out
);

localparam IDLE = 0, ARM = 1, CAPT = 2;
localparam SIGNAL_ASSERT   = 1'b1;
localparam SIGNAL_DEASSERT = 1'b0;

reg [1:0] pulse_detect;
always @(posedge clk)
   pulse_detect <= rst_n ? {pulse_detect[0], signal_in} : 2'b0;

reg [4:0] pulse_count;
always @(posedge clk)
begin
	if (!rst_n)
		pulse_count <= 1'b0;
	else
	begin
	   if (pulse_detect == 2'b10)
			pulse_count <= PULSE_EXT;
		else
	      pulse_count <= pulse_count ? pulse_count - 1'b1 : 1'b0;
	end
end
	
assign pulse_out = | pulse_count;

endmodule
