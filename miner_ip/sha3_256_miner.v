
// This file is part of SHA3-256 Miner.
// 
// SHA3-256 Miner is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// SHA3-256 Miner is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with SHA3-256 Miner.  If not, see <https://www.gnu.org/licenses/>.

// Single pipeline stage (or round) simple permutes the input according to
// the SHA3 algorithm and stores the output once per clock.

module round (
   input               clk,
   input      [1599:0] in,
   input         [6:0] rc,
   output reg [1599:0] out);

   wire [1599:0] round_out;
   
   permutation p (in, rc, round_out);

   always @ (posedge clk)
      out <= round_out;
        
endmodule

// The mining engine.
// Due to FPGA size constraints, a full 24 stage pipeline is not possible.
// Instead we use an 8 stage pipeline in three phases. This method will
// generate 1 sha3-256 hash per clock cycle one third of the time.
// An auto incrementing 64 bit nonce is appended to the fixed header hash,
// padded, and used as input to the 1st stage of the pipe. Output hashes
// are checked against the difficulty value and a less than or equal match
// triigers and IRQ and freezes the engine.
   
module sha3_256_miner (
   input                clk,
   input                rst,
   input       [255:0]  header,
   input       [255:0]  difficulty,
   input       [63:0]   start_nonce,
   input       [17:0]   control,
   output reg  [63:0]   solution,
   output      [2:0]    status,
   output reg           irq
);

// Only hashes out of phase 0 are valid except for the
// 1st phase after run is enabled. Skip the 1st 8 cycles
reg [3:0] valid_r;
wire valid_w = valid_r == 8;

// Modulo 24 cycle counter
reg [4:0] cycles_r;

// Filter async signal
reg [1:0] run_r;
always @(posedge clk)
   if (rst)
	   run_r <= 0;
   else
      run_r <= {run_r[0], control[0]};

// Front and back padding values and control signals
wire [7:0] padf_w = control[17:10];
wire [7:0] padl_w = control[9:2];
wire        run_w = run_r[1];
wire       test_w = control[1];

// Current status
assign status = {test_w, run_w, irq};

// Constant 768 bit pad
wire [767:0] pad_w = {56'b0, padf_w, 640'b0, padl_w, 56'b0};

// big and little endian input
wire [319:0] in_le_w = {header, solution};
wire [319:0] in_be_w;

//assign in_be_w = in_le_w;
`define low_pos(w,b)   ((w)*64 + (b)*8)
`define low_pos2(w,b)  `low_pos(w,7-b)
`define high_pos(w,b)  (`low_pos(w,b) + 7)
`define high_pos2(w,b) (`low_pos2(w,b) + 7)

genvar w, b;

// Convert the input data
generate
   for(w = 0; w < 5; w = w + 1) begin : L0
      for(b = 0; b < 8; b = b + 1) begin : L1
         assign in_be_w[`high_pos(w,b):`low_pos(w,b)] = in_le_w[`high_pos2(w,b):`low_pos2(w,b)];
      end
   end
endgenerate

// Convert the difficulty
wire [255:0] diff_w;

generate
   for(w = 0; w < 4; w = w + 1) begin : L2
      for(b = 0; b < 8; b = b + 1) begin : L3
         assign diff_w[`high_pos(w,b):`low_pos(w,b)] = difficulty[`high_pos2(w,b):`low_pos2(w,b)];
      end
   end
endgenerate
 
// Round constantts, bits 63, 31, 15, 7, 3, 1 and 0
wire [6:0] rc_w [0:23];
assign rc_w[0]  = 'h01; assign rc_w[1]  = 'h1a; assign rc_w[2]  = 'h5e; assign rc_w[3]  = 'h70;
assign rc_w[4]  = 'h1f; assign rc_w[5]  = 'h21; assign rc_w[6]  = 'h79; assign rc_w[7]  = 'h55;
assign rc_w[8]  = 'h0e; assign rc_w[9]  = 'h0c; assign rc_w[10] = 'h35; assign rc_w[11] = 'h26;
assign rc_w[12] = 'h3f; assign rc_w[13] = 'h4f; assign rc_w[14] = 'h5d; assign rc_w[15] = 'h53;
assign rc_w[16] = 'h52; assign rc_w[17] = 'h48; assign rc_w[18] = 'h16; assign rc_w[19] = 'h66;
assign rc_w[20] = 'h79; assign rc_w[21] = 'h58; assign rc_w[22] = 'h21; assign rc_w[23] = 'h74;

// State stage interconnections.
wire [1599:0] state_w [0:7];

// Current phase of 8 rounds (0-2). Easy divide by 8.
wire [1:0] pass = cycles_r[4:3];

// Special case, round 0 which has per pass input and simple rc calculation
round r_0(
   .clk(clk),
   .rc(rc_w[{pass, 3'b0}]),
   .in(pass ? state_w[7] : {in_be_w, pad_w, 512'b0}), 
   .out(state_w[0])
);

// Rounds 1-7 differ in that they always take their input from the previous
// round, but use a delayed round calculation of the appropriate round
// constant.   
genvar i;

generate
   for(i = 1; i < 8; i = i + 1)
   begin : L3
      wire [4:0] t0 = cycles_r - i[4:0] + ((cycles_r < i) ? 5'd24 : 5'b0);
      wire [4:0] t1 = {t0[4:3], i[2:0]}; // Calc RC value offset for this stage
      round r_n(
         .clk(clk),
         .rc(rc_w[t1]),
         .in(state_w[i - 1]),
         .out(state_w[i])
      );
   end
endgenerate

// Final hash is the little endian upper 256 bits of sponge.
wire [255:0] out_hash_le_w = state_w[7][1599:1600-256];
wire [255:0] out_hash_w;

generate
   for(w = 0; w < 4; w = w + 1) begin : L4
      for(b = 0; b < 8; b = b + 1) begin : L5
         assign out_hash_w[`high_pos(w,b):`low_pos(w,b)] = out_hash_le_w[`high_pos2(w,b):`low_pos2(w,b)];
      end
   end
endgenerate

// Hash is less than or equal to difficulty
wire match_w = (test_w ? (out_hash_le_w == diff_w) : (out_hash_w <= diff_w))
   && valid_w && (pass == 0);

always @(posedge clk)
begin
   if (rst | ~run_w) begin
      irq <= 0;
      valid_r <= -1;
      cycles_r <= -1;
      solution <= start_nonce;
   end
   else begin
      if (!irq) begin
         // Count up to 8 (end of 1st phase)
         valid_r <= valid_w ? valid_r : valid_r + 1'b1;
         // Modulo 64 cycle count
         cycles_r <= cycles_r == 5'd23 ? 5'b0 : cycles_r + 1'b1;
                           
         if (match_w & valid_w) begin
            solution <= solution - 8; // control[0]Solution is 8 cycles old.
            irq <= 1; // report match with IRQ and halt
         end
         else // Otherwise increment the nonce for the next cycle
            solution <= pass == 0 ? solution + 1 : solution;
      end
   end
end

`undef low_pos
`undef low_pos2
`undef high_pos
`undef high_pos2
        
endmodule
