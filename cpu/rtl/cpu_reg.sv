
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module cpu_reg
(
  input  logic              i_clk,
  input  logic              i_rst_n,

  // APB interface
  // ---------------------------------------------------------------------------
  input  logic              i_penable,
  input  logic              i_pwrite,
  input  logic  [  31 : 0 ] i_paddr,
  input  logic  [  31 : 0 ] i_pwdata,
  output logic  [  31 : 0 ] o_prdata,

  // Configuration output
  // ---------------------------------------------------------------------------
  output logic              c_cpu_en,
  output logic              c_icache_en,
  output logic              c_colli_dis,

  output logic  [  31 : 0 ] c_boot_vector,
  output logic  [  31 : 0 ] c_isr_vector,
  output logic  [  31 : 0 ] c_clk_khz,
  output logic  [  31 : 0 ] c_uart_divisor,

  output logic  [  15 : 0 ] c_baud_cyc
);
  // ---------------------------------------------------------------------------
  logic         [  31 : 0 ] regs_w [6];
  logic         [  31 : 0 ] regs_r [6];

  // ---------------------------------------------------------------------------
  assign /*output*/ c_cpu_en       = regs_r[0][0];
  assign /*output*/ c_icache_en    = regs_r[0][1];
  assign /*output*/ c_colli_dis    = regs_r[0][2];

  assign /*output*/ c_boot_vector  = regs_r[1];
  assign /*output*/ c_isr_vector   = regs_r[2];
  assign /*output*/ c_clk_khz      = regs_r[3];
  assign /*output*/ c_uart_divisor = regs_r[4];

  assign /*output*/ c_baud_cyc     = regs_r[5][15:0];

  // Register reads
  // ---------------------------------------------------------------------------
  //always_comb begin
  //  o_prdata = 32'b0;

  //  if (i_penable & !i_pwrite) begin
  //    o_prdata = regs_r[i_paddr[7:2]];
  //  end
  //end
  assign o_prdata = regs_r[i_paddr[7:2]];

  // Register writes
  // ---------------------------------------------------------------------------
  always_comb begin
    regs_w = regs_r;

    if (i_penable & i_pwrite)
      regs_w[i_paddr[7:2]] = i_pwdata;
  end

  // Flip flops
  // ---------------------------------------------------------------------------
  // synopsys sync_set_reset "i_rst_n"
  always_ff @(posedge i_clk)
    if (!i_rst_n) begin
      regs_r[0]             <= 32'b0;
      regs_r[1]             <= 32'b0;       // c_boot_vector
      regs_r[2]             <= 32'b0;       // c_isr_vector
      regs_r[3]             <= 32'd50000;   // c_clk_khz
    `ifdef SYNTHESIS
      regs_r[4]             <= 32'd433;     // c_uart_divisor
      regs_r[5]             <= 16'd433;     // c_baud_cyc
    `else
      regs_r[4]             <= 32'd2;       // c_uart_divisor
      regs_r[5]             <= 16'd2;       // c_baud_cyc
    `endif
    end
    else
      regs_r                <= regs_w;

endmodule

