
module aib_io_buffer
(
  //inout  wire               io_bump,

  input  logic              i_rst_n,

  input  logic              c_ddr_mode,
  input  logic              c_async_mode,
  input  logic              c_tx_en,
  //input  logic              c_rx_en,
  //input  logic              c_rx_diff_clk_en,
  //input  logic  [   1 : 0 ] c_pdrv,
  //input  logic  [   1 : 0 ] c_ndrv,
  input  logic              c_pull_en,
  input  logic              c_pull_dir,
  input  logic  [   7 : 0 ] c_tx_dly_tap,
  input  logic  [   7 : 0 ] c_rx_dly_tap,

  input  logic              i_tx_clk,
  input  logic              i_tx_data0,
  input  logic              i_tx_data1,
  input  logic              i_tx_data_async,

  input  logic              i_rx_sample_clk,
  input  logic              i_rx_retime_clk,
  output logic              o_rx_data0,
  output logic              o_rx_data1,
  output logic              o_rx_data_async,

  output logic              o_drv_pmos,
  output logic              o_drv_nmos,
  output logic              o_drv_pu,
  output logic              o_drv_pd,
  input  logic              i_drv_data

  //input  logic              i_clkn,
  //output logic              o_clkp,
  //output logic              o_clkn
);
  // ---------------------------------------------------------------------------
  logic tx_en;

  logic tx_data0_q;
  logic tx_data1_q;
  logic tx_data_ddr_nl;
  logic tx_data_sync;
  logic tx_data;
  logic tx_data_delayed;

  logic rx_data_delayed;
  logic rx_data0_nq;
  logic rx_data0_nq_l;
  logic rx_data0_retime_q;
  logic rx_data1_q;
  logic rx_data1_retime_q;

  // ---------------------------------------------------------------------------
  //assign /*inout*/ io_bump = (i_rst_n & c_tx_en) ? tx_data : 1'bz;

  //`ifndef SYNTHESIS
  //bufif1 (weak1, weak0) (io_bump, 1'b1, c_pull_en &  c_pull_dir);
  //bufif1 (weak1, weak0) (io_bump, 1'b0, c_pull_en & ~c_pull_dir);
  //`endif

  assign /*output*/ o_drv_pmos = ~tx_en | tx_data_delayed;
  assign /*output*/ o_drv_nmos =  tx_en & tx_data_delayed;
  assign /*output*/ o_drv_pu   = ~(c_pull_en &  c_pull_dir);
  assign /*output*/ o_drv_pd   =   c_pull_en & ~c_pull_dir;

  assign /*output*/ o_rx_data0 = rx_data0_retime_q;
  assign /*output*/ o_rx_data1 = rx_data1_retime_q;
  assign /*output*/ o_rx_data_async = rx_data_delayed;//i_drv_data;//io_bump;

  //assign /*output*/ o_clkp = io_bump &  c_rx_diff_clk_en;
  //assign /*output*/ o_clkn = i_clkn  | ~c_rx_diff_clk_en;

  delay_chain u_tx_dly (.c_tap(c_tx_dly_tap), .i_in(~tx_data),   .o_out(tx_data_delayed));
  delay_chain u_rx_dly (.c_tap(c_rx_dly_tap), .i_in(i_drv_data), .o_out(rx_data_delayed));

  // ---------------------------------------------------------------------------
  assign tx_en = c_tx_en & i_rst_n;

  always_ff @(posedge i_tx_clk or negedge i_rst_n)
    if (!i_rst_n) begin
      tx_data0_q <= 1'b0;
      tx_data1_q <= 1'b0;
    end
    else if (c_tx_en) begin
      tx_data0_q <= i_tx_data0;
      tx_data1_q <= i_tx_data1;
    end

  always_latch
    if (!i_rst_n)
      tx_data_ddr_nl <= 1'b0;
    else if (!i_tx_clk)
      tx_data_ddr_nl <= c_ddr_mode ? tx_data1_q : tx_data0_q;

  MXGL2_X4N_A7P5PP96PTS_C16 DT_tx_data_sync (
    .A(tx_data0_q), .B(tx_data_ddr_nl), .S0(i_tx_clk), .Y(tx_data_sync)
  );
  //assign tx_data_sync = i_tx_clk ? tx_data_ddr_nl : tx_data0_q;

  MXGL2_X4N_A7P5PP96PTS_C16 DT_tx_data (
    .A(tx_data_sync), .B(i_tx_data_async), .S0(c_async_mode), .Y(tx_data)
  );
  //assign tx_data = c_async_mode ? i_tx_data_async : tx_data_sync;

  // ---------------------------------------------------------------------------
  always_ff @(posedge i_rx_sample_clk or negedge i_rst_n)
    if (!i_rst_n)
      rx_data1_q <= 1'b0;
    else
      rx_data1_q <= rx_data_delayed;//i_drv_data;//io_bump;

  always_ff @(negedge i_rx_sample_clk or negedge i_rst_n)
    if (!i_rst_n)
      rx_data0_nq <= 1'b0;
    else
      rx_data0_nq <= rx_data_delayed;//i_drv_data;//io_bump;

  always_latch
    if (!i_rst_n)
      rx_data0_nq_l <= 1'b0;
    else if (i_rx_sample_clk)
      rx_data0_nq_l <= rx_data0_nq;

  always_ff @(posedge i_rx_retime_clk or negedge i_rst_n)
    if (!i_rst_n) begin
      rx_data0_retime_q <= 1'b0;
      rx_data1_retime_q <= 1'b0;
    end
    else begin
      rx_data0_retime_q <= rx_data0_nq_l;
      rx_data1_retime_q <= rx_data1_q;
    end

endmodule

