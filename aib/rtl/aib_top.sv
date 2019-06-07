
module aib_top
(
  // Channel 0
  // ---------------------------------------------------------------------------
  input  logic              i_ch0_rst_n,

  input  logic              i_ch0_bypass,
  input  logic              i_ch0_bypass_clk,

  output logic              o_ch0_aib_slow_clk,
  output logic              o_ch0_aux_slow_clk,

  output logic              o_ch0_uart_tx_aib,
  input  logic              i_ch0_uart_rx_aib,

  output logic              o_ch0_uart_tx_dbg,
  input  logic              i_ch0_uart_rx_dbg,

  output logic              o_ch0_uart_tx_cpu,
  input  logic              i_ch0_uart_rx_cpu,

  inout  wire   [  57 : 0 ] io_ch0_bump,

  // Channel 1
  // ---------------------------------------------------------------------------
  input  logic              i_ch1_rst_n,

  input  logic              i_ch1_bypass,
  input  logic              i_ch1_bypass_clk,

  output logic              o_ch1_aib_slow_clk,
  output logic              o_ch1_aux_slow_clk,

  output logic              o_ch1_uart_tx_aib,
  input  logic              i_ch1_uart_rx_aib,

  output logic              o_ch1_uart_tx_dbg,
  input  logic              i_ch1_uart_rx_dbg,

  output logic              o_ch1_uart_tx_cpu,
  input  logic              i_ch1_uart_rx_cpu,

  inout  wire   [  57 : 0 ] io_ch1_bump,

  // Channel 2
  // ---------------------------------------------------------------------------
  input  logic              i_ch2_rst_n,

  input  logic              i_ch2_bypass,
  input  logic              i_ch2_bypass_clk,

  output logic              o_ch2_aib_slow_clk,
  output logic              o_ch2_aux_slow_clk,

  output logic              o_ch2_uart_tx_aib,
  input  logic              i_ch2_uart_rx_aib,

  output logic              o_ch2_uart_tx_dbg,
  input  logic              i_ch2_uart_rx_dbg,

  output logic              o_ch2_uart_tx_cpu,
  input  logic              i_ch2_uart_rx_cpu,

  inout  wire   [  57 : 0 ] io_ch2_bump,

  // Channel 3
  // ---------------------------------------------------------------------------
  input  logic              i_ch3_rst_n,

  input  logic              i_ch3_bypass,
  input  logic              i_ch3_bypass_clk,

  output logic              o_ch3_aib_slow_clk,
  output logic              o_ch3_aux_slow_clk,

  output logic              o_ch3_uart_tx_aib,
  input  logic              i_ch3_uart_rx_aib,

  output logic              o_ch3_uart_tx_dbg,
  input  logic              i_ch3_uart_rx_dbg,

  output logic              o_ch3_uart_tx_cpu,
  input  logic              i_ch3_uart_rx_cpu,

  inout  wire   [  57 : 0 ] io_ch3_bump
);
  // Channel 0
  // ---------------------------------------------------------------------------
  aib #(.AibIoCnt(4)) u_aib_ch0 (
    .i_rst_n          (i_ch0_rst_n),

    .i_bypass         (i_ch0_bypass),
    .i_bypass_clk     (i_ch0_bypass_clk),

    .o_aib_slow_clk   (o_ch0_aib_slow_clk),
    .o_aux_slow_clk   (o_ch0_aux_slow_clk),

    .o_uart_tx_aib    (o_ch0_uart_tx_aib),
    .i_uart_rx_aib    (i_ch0_uart_rx_aib),

    .o_uart_tx_dbg    (o_ch0_uart_tx_dbg),
    .i_uart_rx_dbg    (i_ch0_uart_rx_dbg),

    .o_uart_tx_cpu    (o_ch0_uart_tx_cpu),
    .i_uart_rx_cpu    (i_ch0_uart_rx_cpu),

    .io_bump          (io_ch0_bump),

    .o_probe_aib_clk  (),
    .o_probe_aux_clk  (),
    .o_probe_sys_clk  ()
  );

  // Channel 1
  // ---------------------------------------------------------------------------
  aib #(.AibIoCnt(20)) u_aib_ch1 (
    .i_rst_n          (i_ch1_rst_n),

    .i_bypass         (i_ch1_bypass),
    .i_bypass_clk     (i_ch1_bypass_clk),

    .o_aib_slow_clk   (o_ch1_aib_slow_clk),
    .o_aux_slow_clk   (o_ch1_aux_slow_clk),

    .o_uart_tx_aib    (o_ch1_uart_tx_aib),
    .i_uart_rx_aib    (i_ch1_uart_rx_aib),

    .o_uart_tx_dbg    (o_ch1_uart_tx_dbg),
    .i_uart_rx_dbg    (i_ch1_uart_rx_dbg),

    .o_uart_tx_cpu    (o_ch1_uart_tx_cpu),
    .i_uart_rx_cpu    (i_ch1_uart_rx_cpu),

    .io_bump          (io_ch1_bump),

    .o_probe_aib_clk  (),
    .o_probe_aux_clk  (),
    .o_probe_sys_clk  ()
  );

  // Channel 2
  // ---------------------------------------------------------------------------
  aib #(.AibIoCnt(20)) u_aib_ch2 (
    .i_rst_n          (i_ch2_rst_n),

    .i_bypass         (i_ch2_bypass),
    .i_bypass_clk     (i_ch2_bypass_clk),

    .o_aib_slow_clk   (o_ch2_aib_slow_clk),
    .o_aux_slow_clk   (o_ch2_aux_slow_clk),

    .o_uart_tx_aib    (o_ch2_uart_tx_aib),
    .i_uart_rx_aib    (i_ch2_uart_rx_aib),

    .o_uart_tx_dbg    (o_ch2_uart_tx_dbg),
    .i_uart_rx_dbg    (i_ch2_uart_rx_dbg),

    .o_uart_tx_cpu    (o_ch2_uart_tx_cpu),
    .i_uart_rx_cpu    (i_ch2_uart_rx_cpu),

    .io_bump          (io_ch2_bump),

    .o_probe_aib_clk  (),
    .o_probe_aux_clk  (),
    .o_probe_sys_clk  ()
  );

  // Channel 3
  // ---------------------------------------------------------------------------
  aib #(.AibIoCnt(20)) u_aib_ch3 (
    .i_rst_n          (i_ch3_rst_n),

    .i_bypass         (i_ch3_bypass),
    .i_bypass_clk     (i_ch3_bypass_clk),

    .o_aib_slow_clk   (o_ch3_aib_slow_clk),
    .o_aux_slow_clk   (o_ch3_aux_slow_clk),

    .o_uart_tx_aib    (o_ch3_uart_tx_aib),
    .i_uart_rx_aib    (i_ch3_uart_rx_aib),

    .o_uart_tx_dbg    (o_ch3_uart_tx_dbg),
    .i_uart_rx_dbg    (i_ch3_uart_rx_dbg),

    .o_uart_tx_cpu    (o_ch3_uart_tx_cpu),
    .i_uart_rx_cpu    (i_ch3_uart_rx_cpu),

    .io_bump          (io_ch3_bump),

    .o_probe_aib_clk  (),
    .o_probe_aux_clk  (),
    .o_probe_sys_clk  ()
  );

endmodule

