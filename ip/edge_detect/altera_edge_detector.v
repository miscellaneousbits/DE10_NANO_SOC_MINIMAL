module altera_edge_detector #(
parameter PULSE_EXT = 0 // 0, 1 = edge detection generate single cycle pulse, >1 = pulse extended for specified clock cycle
) (
input      clk,
input      rst_n,
input      signal_in,
output     pulse_out
);

localparam IDLE = 0, ARM = 1, CAPT = 2;
localparam SIGNAL_ASSERT   = 1'b1;
localparam SIGNAL_DEASSERT = 1'b0;

reg [1:0] state, next_state;
reg       pulse_detect;

assign reset_qual_n = rst_n | pulse_out;

generate
if (PULSE_EXT > 1) begin: pulse_extend
  integer i;
  reg [PULSE_EXT-1:0] extend_pulse;
  always @(posedge clk or negedge reset_qual_n) begin
    if (!reset_qual_n)
      extend_pulse <= {{PULSE_EXT}{1'b0}};
    else begin
      for (i = 1; i < PULSE_EXT; i = i+1) begin
        extend_pulse[i] <= extend_pulse[i-1];
        end
      extend_pulse[0] <= pulse_detect;
      end
    end
  assign pulse_out = |extend_pulse;
end
endgenerate

always @(posedge clk) begin
  if (!rst_n)
    state <= IDLE;
  else
    state <= next_state;
end

// edge detect
always @(*) begin
  next_state = state;
  pulse_detect = 1'b0;
  case (state)
    IDLE : begin
           pulse_detect = 1'b0;
           if (signal_in == SIGNAL_DEASSERT) next_state = ARM;
           else next_state = IDLE;
           end
    ARM  : begin
           pulse_detect = 1'b0;
           if (signal_in == SIGNAL_ASSERT)   next_state = CAPT;
           else next_state = ARM;
           end
    CAPT : begin
           pulse_detect = 1'b1;
           if (signal_in == SIGNAL_DEASSERT) next_state = ARM;
           else next_state = IDLE;
           end
    default : begin
           pulse_detect = 1'b0;
           next_state = IDLE;
           end
  endcase
end

endmodule
