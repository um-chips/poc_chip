
module aib_io_block #(parameter NumIo = 1)
(
  input  logic              i_rst_n,

  inout  wire   [NumIo-1:0] io_bump,

  input  logic              c_ddr_mode      [NumIo],
  input  logic              c_async_mode    [NumIo],
  input  logic              c_tx_en         [NumIo],
  input  logic              c_pull_en       [NumIo],
  input  logic              c_pull_dir      [NumIo],
  input  logic  [   2 : 0 ] c_pdrv          [NumIo],
  input  logic  [   2 : 0 ] c_ndrv          [NumIo],
  input  logic  [   7 : 0 ] c_tx_dly_tap    [NumIo],
  input  logic  [   7 : 0 ] c_rx_dly_tap    [NumIo],

  input  logic              i_tx_clk        [NumIo],
  input  logic              i_tx_data0      [NumIo],
  input  logic              i_tx_data1      [NumIo],
  input  logic              i_tx_data_async [NumIo],

  input  logic              i_rx_sample_clk [NumIo],
  input  logic              i_rx_retime_clk [NumIo],
  output logic              o_rx_data0      [NumIo],
  output logic              o_rx_data1      [NumIo],
  output logic              o_rx_data_async [NumIo]
);
  logic drv_pmos [NumIo];
  logic drv_nmos [NumIo];
  logic drv_pu   [NumIo];
  logic drv_pd   [NumIo];
  logic drv_data [NumIo];

  generate
    for (genvar gi = 0; gi < NumIo; gi++) begin : io
      assign drv_data[gi] = io_bump[gi];

      aib_io_buffer buffer (
        .i_rst_n          (i_rst_n),

        .c_ddr_mode       (c_ddr_mode     [gi]),
        .c_async_mode     (c_async_mode   [gi]),
        .c_tx_en          (c_tx_en        [gi]),
        .c_pull_en        (c_pull_en      [gi]),
        .c_pull_dir       (c_pull_dir     [gi]),
        .c_tx_dly_tap     (c_tx_dly_tap   [gi]),
        .c_rx_dly_tap     (c_rx_dly_tap   [gi]),

        .i_tx_clk         (i_tx_clk       [gi]),
        .i_tx_data0       (i_tx_data0     [gi]),
        .i_tx_data1       (i_tx_data1     [gi]),
        .i_tx_data_async  (i_tx_data_async[gi]),

        .i_rx_sample_clk  (i_rx_sample_clk[gi]),
        .i_rx_retime_clk  (i_rx_retime_clk[gi]),
        .o_rx_data0       (o_rx_data0     [gi]),
        .o_rx_data1       (o_rx_data1     [gi]),
        .o_rx_data_async  (o_rx_data_async[gi]),

        .o_drv_pmos       (drv_pmos       [gi]),
        .o_drv_nmos       (drv_nmos       [gi]),
        .o_drv_pu         (drv_pu         [gi]),
        .o_drv_pd         (drv_pd         [gi]),
        .i_drv_data       (drv_data       [gi])
      );

    //`ifdef ESD
      aib_driver_esd driver (
        .PAD              (io_bump        [gi]),

        .C_PU             (drv_pu         [gi]),
        .C_PDRV           (c_pdrv         [gi]),
        .PDRV             (drv_pmos       [gi]),

        .C_PD             (drv_pd         [gi]),
        .C_NDRV           (c_ndrv         [gi]),
        .NDRV             (drv_nmos       [gi])
      );
    //`else
    //  aib_driver driver (
    //    .PAD              (io_bump        [gi]),

    //    .C_PU             (drv_pu         [gi]),
    //    .C_PDRV           (c_pdrv         [gi]),
    //    .PDRV             (drv_pmos       [gi]),

    //    .C_PD             (drv_pd         [gi]),
    //    .C_NDRV           (c_ndrv         [gi]),
    //    .NDRV             (drv_nmos       [gi])
    //  );
    //`endif
    end
  endgenerate

endmodule

