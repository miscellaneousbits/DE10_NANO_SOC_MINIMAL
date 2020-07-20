
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
