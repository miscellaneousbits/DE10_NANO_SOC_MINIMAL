module edge_detector(
input      clk,
input      rst_n,
input      signal_in,
output     pulse_out
);

parameter [4:0] PULSE_EXT = 1'b1;

reg [1:0] pulse_detect;
reg [4:0] pulse_count;

assign pulse_out = pulse_count != 0;

always @(posedge clk)
begin
   pulse_detect <= rst_n ? {pulse_detect[0], signal_in} : 2'b0;
	if (!rst_n)
		pulse_count <= 1'b0;
	else
	begin
	   if (pulse_detect == 2'b10)
			pulse_count <= PULSE_EXT;
		else
	      pulse_count <= pulse_count - (pulse_count ? 1'b1 : 1'b0);
	end
end
	
endmodule
