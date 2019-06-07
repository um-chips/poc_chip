
module aib_control #(parameter NumIo = 1)
(
  input  logic              i_rst_n,

  output logic              o_io_rst_n,
  output logic              o_sys_rst_n,
  output logic              o_adapt_rst_n,

  output logic              o_uart_tx,
  input  logic              i_uart_rx,

  input  logic              i_bypass,
  input  logic              i_bypass_clk,

  input  logic              i_fwd_clk,

  output logic              o_aib_clk,
  output logic              o_aux_clk,
  output logic              o_sys_clk,

  output logic              o_aib_slow_clk,
  output logic              o_aux_slow_clk,

  input  logic              i_aib_ready,

  output logic  [   2 : 0 ] c_chn_mode,
  output logic              c_config_done,
  output logic              c_skip_hrdrst,

  output logic  [   7 : 0 ] c_dll_tap,

  output logic              c_ddr_mode   [NumIo],
  output logic              c_async_mode [NumIo],
  output logic              c_tx_en      [NumIo],
  output logic              c_pull_en    [NumIo],
  output logic              c_pull_dir   [NumIo],
  output logic  [   2 : 0 ] c_pdrv       [NumIo],
  output logic  [   2 : 0 ] c_ndrv       [NumIo],
  output logic  [   7 : 0 ] c_tx_dly_tap [NumIo],
  output logic  [   7 : 0 ] c_rx_dly_tap [NumIo],

  output logic  [   2 : 0 ] c_rx_wptr_init,
  output logic  [   2 : 0 ] c_rx_rptr_init,
  output logic  [   1 : 0 ] c_fifo_mode,

  output logic              c_agent_en,
  output logic  [  15 : 0 ] c_agent_loop_cnt,
  output logic  [  19 : 0 ] c_agent_pattern0 [8],
  output logic  [  19 : 0 ] c_agent_pattern1 [8],
  input  logic              c_test_pass,
  input  logic              c_test_fail,
  input  logic  [  15 : 0 ] c_test_fail_cnt,
  input  logic  [  19 : 0 ] c_test_fail_data0,
  input  logic  [  19 : 0 ] c_test_fail_data1,
  input  logic              c_test_timeout
);
  // ---------------------------------------------------------------------------
  logic cfg_rst_n;

  aib_rst_seq u_aib_rst_seq (
    .i_aib_clk      (o_aib_clk),
    .i_aux_clk      (o_aux_clk),
    .i_sys_clk      (o_sys_clk),

    .i_rst_n        (i_rst_n),
    .o_cfg_rst_n    (cfg_rst_n),
    .o_io_rst_n     (o_io_rst_n),

    .i_config_done  (c_config_done),
    .o_sys_rst_n    (o_sys_rst_n),
    .o_adapt_rst_n  (o_adapt_rst_n)
  );

  // ---------------------------------------------------------------------------
  logic             penable;
  logic             pwrite;
  logic [  31 : 0 ] paddr;
  logic [  31 : 0 ] pwdata;
  logic             pready;
  logic [  31 : 0 ] prdata;

  logic [  11 : 0 ] aib_clkgen_cfg;
  logic [  11 : 0 ] aux_clkgen_cfg;
  logic             cfg_chg;
  logic [  15 : 0 ] baud_cyc;

  dbg u_dbg (
    .i_clk      (o_aux_clk),
    .i_rst_n    (cfg_rst_n),

    .o_tx       (o_uart_tx),
    .i_rx       (i_uart_rx),

    .c_baud_cyc (baud_cyc),

    .o_penable  (penable),
    .o_pwrite   (pwrite),
    .o_paddr    (paddr),
    .o_pwdata   (pwdata),
    .i_pready   (pready),
    .i_prdata   (prdata)
  );

  aib_control_reg #(.NumIo(NumIo)) u_aib_control_reg (
    .i_clk            (o_aux_clk),
    .i_rst_n          (cfg_rst_n),

    .i_penable        (penable),
    .i_pwrite         (pwrite),
    .i_paddr          (paddr),
    .i_pwdata         (pwdata),
    .o_pready         (pready),
    .o_prdata         (prdata),

    .c_aib_clkgen_cfg (aib_clkgen_cfg),
    .c_aux_clkgen_cfg (aux_clkgen_cfg),
    .c_cfg_chg        (cfg_chg),
    .c_baud_cyc       (baud_cyc),
    .*
  );

  // ---------------------------------------------------------------------------
  clkgen u_aib_clk (
    .i_cfg_en       (i_rst_n & aib_clkgen_cfg[10]),
    .i_cfg_chg      (cfg_chg),
    .i_cfg_osc_sel  (aib_clkgen_cfg[7:4]),
    .i_cfg_div1_sel (aib_clkgen_cfg[3:2]),
    .i_cfg_div0_sel (aib_clkgen_cfg[1:0]),

    .i_osc_en       (i_rst_n & aib_clkgen_cfg[11]),
    .o_osc_clk0     (o_aib_clk),
    .o_osc_clk1     (o_sys_clk),
    .o_osc_slow_clk (o_aib_slow_clk),

    .i_bypass       (i_bypass | aib_clkgen_cfg[9]),
    .i_bypass_clk   (i_bypass_clk),

    .i_forward      (aib_clkgen_cfg[8]),
    .i_forward_clk  (i_fwd_clk)
  );

  clkgen u_aux_clk (
    .i_cfg_en       (i_rst_n & aux_clkgen_cfg[10]),
    .i_cfg_chg      (cfg_chg),
    .i_cfg_osc_sel  (aux_clkgen_cfg[7:4]),
    .i_cfg_div1_sel (aux_clkgen_cfg[3:2]),
    .i_cfg_div0_sel (aux_clkgen_cfg[1:0]),

    .i_osc_en       (i_rst_n & aux_clkgen_cfg[11]),
    .o_osc_clk0     (o_aux_clk),
    .o_osc_clk1     (),
    .o_osc_slow_clk (o_aux_slow_clk),

    .i_bypass       (i_bypass | aux_clkgen_cfg[9]),
    .i_bypass_clk   (i_bypass_clk),

    .i_forward      (aux_clkgen_cfg[8]),
    .i_forward_clk  (i_fwd_clk)
  );

endmodule

