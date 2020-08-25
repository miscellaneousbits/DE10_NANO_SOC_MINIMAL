module edge_detector(
input      clk,
input      rst_n,
input      signal_in,
output     pulse_out
);

parameter [3:0] EXTEND = 1'b1;

reg pulse_detect;
reg [3:0] pulse_count;

assign pulse_out = pulse_count != 0;

always @(posedge clk)
begin
	if (!rst_n) begin
      pulse_detect <= 1'b0;
		pulse_count <= 1'b0;
   end
	else begin
      pulse_detect <= signal_in;
	   if (pulse_detect && ~signal_in)
			pulse_count <= EXTEND;
		else begin
	      if (pulse_count)
				pulse_count <= pulse_count - 1'b1;
		end
	end
end
	
endmodule
