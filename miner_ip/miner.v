
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


// Avalon MM slave to miner core interface

// 32-bit Word addressable memory mapped, with active high IRQ signal
// on hash condition met.

module miner (
   input             clk,
   input             rst,
   input       [4:0] address,
   input             read,
   input             write,
   input      [31:0] writedata,
   output reg [31:0] readdata,
   output reg        irq,
	output            bsy
);

parameter MINER_CLK_MHZ = "60 MHz";
parameter MINER_MAJ_VER = 0;
parameter MINER_MIN_VER = 0;
parameter STAGES = 8;

// clunky way of converting string to integer
wire [6 * 8 - 1:0] miner_clk_mhz_w = MINER_CLK_MHZ;
wire [7:0] tens = miner_clk_mhz_w[43:40];
wire [3:0] ones = miner_clk_mhz_w[35:32];
wire [7:0] miner_mhz_w = (4'd10 * tens) + ones;

///////////////////////////////////////////////////
// Register map.
// Byte addresses (word address)
// 0x00-0x07 (0-1)   - Solution nonce (64 bits)
// 0x08-0x0b (2)     - STAT_REG status (32 bits)
// 0x0c-0x0f (3)     - fingerprint (32 bits) "SHA3_REG"
// 0x10-0x2f (4-11)  - Header hash (256 bits)
// 0x30-0x4f (12-19) - DIFF_REGiculty (256 bits)
// 0x50-0x57 (20-21) - START_REG nonce (64 bits)
// 0x58-0x5b (22)    - control (32 bits)
//
// Control bits
// 0     - run
// 1     - enable test mode
// 2     - halt
// 23:16 - padding last byte
// 31:24 - padding first byte
//
// STAT_REGus bits
// 0     - found
// 1     - running
// 2     - testing
// 6:3   - # of pipeline stages
// 15:8  - miner freq.
// 19:16 - miner major version
// 23:20 - miner minor version
///////////////////////////////////////////////////

// NOTE: A 64 bit nonce is used, which would not be sufficient
// at higher difficulty, where a 128, or even 256 bit nonce would
// be used.

// Register indices
localparam SOLN_REG  = 0;  // RO
localparam STAT_REG  = 2;  // RO
localparam SHA3_REG  = 3;  // RO
localparam HDR_REG   = 4;  // RW
localparam DIFF_REG  = 12; // RW
localparam START_REG = 20; // RW
localparam CTL_REG   = 22; // RW

// Read/write register file
reg [31:0] data_r [4:22];

// Read only registersminer_clk
wire [63:0] solution_w;
wire [6:0]  status_w;

// IRQ state
wire irq_w;
reg [1:0] irq_r;

// Interrupt sender (clear on read)
always @(posedge clk)
begin
   irq_r <= rst ? 1'b0 : {irq_r[0], irq_w};
   if (rst) begin // Clear outgoing IRQ on reset
      irq <= 0;
   end
   else begin // look for positive edge on incoming IRQ signal
      if (irq_r == 2'b01)
         irq <= 1;
      else    // Clear outgoing IRQ on any ctl reg read operation
         irq <= (read && (address == CTL_REG)) ? 1'b0 : irq;
   end
end

// Read     
always @(posedge clk)
begin
   if (read) begin // read one of the read/write registers
      if (address[4:2])
         readdata <= data_r[address];
      else         // read one of the read/only registers
         case (address[1:0])
            SOLN_REG + 0: readdata <= solution_w[31:0];
            SOLN_REG + 1: readdata <= solution_w[63:32];
            STAT_REG:
               begin
                  readdata[6:0] <= status_w;
                  readdata[15:8] <= miner_mhz_w;
                  readdata[19:16] <= MINER_MAJ_VER;
                  readdata[23:20] <= MINER_MIN_VER;
               end
            SHA3_REG: readdata <= "SHA3";
         endcase
   end
end

// Write    
always @(posedge clk)
begin
   if (rst) // Turn of the run control on reset
      data_r[CTL_REG][0] <= 0;
   else     // Check for writable register and store
      if (write && address[4:2])
         data_r[address]  <= writedata;
end

// Combine register values into signals      
wire [255:0] header_w =
  {data_r[HDR_REG + 0], data_r[HDR_REG + 1], data_r[HDR_REG + 2], data_r[HDR_REG + 3],
   data_r[HDR_REG + 4], data_r[HDR_REG + 5], data_r[HDR_REG + 6], data_r[HDR_REG + 7]};
   
wire [255:0] difficulty_w =
  {data_r[DIFF_REG + 0], data_r[DIFF_REG + 1], data_r[DIFF_REG + 2], data_r[DIFF_REG + 3],
   data_r[DIFF_REG + 4], data_r[DIFF_REG + 5], data_r[DIFF_REG + 6], data_r[DIFF_REG + 7]};
   
wire [63:0] start_nonce_w = {data_r[START_REG + 0], data_r[START_REG + 1]};

// Pack the control data for the miner core
wire [18:0] control_w = {data_r[CTL_REG][31:24], data_r[CTL_REG][23:16], data_r[CTL_REG][2:0]};

wire miner_clk_w;
wire miner_clk_lock_w;

altera_pll #(
   .fractional_vco_multiplier("false"),
   .reference_clock_frequency("50.0 MHz"),
   .operation_mode("direct"),
   .number_of_clocks(1),
   .output_clock_frequency0(MINER_CLK_MHZ),
   .phase_shift0("0 ps"),
   .duty_cycle0(50),
   .pll_type("General"),
   .pll_subtype("General")
) altera_pll_0 (
   .rst(rst),
   .outclk(miner_clk_w),
   .locked(miner_clk_lock_w),
   .fboutclk(),
   .fbclk(1'b0),
   .refclk(clk)
);

// SHA3_REG-256 mining core
sha3_256_miner #(
   .STAGES(STAGES)
)
sha3_256_miner (
   .clk(miner_clk_w & miner_clk_lock_w),
   .rst(rst),
   .header(header_w),
   .difficulty(difficulty_w),
   .start_nonce(start_nonce_w),
   .control(control_w),
   .solution(solution_w),
   .status(status_w),
   .irq(irq_w),
	.bsy(bsy)
);

endmodule

