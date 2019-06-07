
module aib_channel #(parameter NumIo    = 58,
                     parameter AibIoCnt = 20)
(
  input  logic              i_rst_n,

  output logic              o_uart_tx,
  input  logic              i_uart_rx,

  input  logic              i_bypass,
  input  logic              i_bypass_clk,

  output logic              o_aib_slow_clk,
  output logic              o_aux_slow_clk,

  inout  wire   [NumIo-1:0] io_bump,

  output logic              o_aib_clk,
  output logic              o_aux_clk,

  output logic              o_sys_clk,
  output logic              o_sys_rst_n,
  output logic              o_adapt_rst_n,

  output logic              o_ready,

  output logic  [   2 : 0 ] c_chn_mode,
  output logic  [   1 : 0 ] c_fifo_mode,

  input  logic  [  19 : 0 ] i_tx_data0,
  input  logic  [  19 : 0 ] i_tx_data1,

  output logic  [  19 : 0 ] o_rx_data0,
  output logic  [  19 : 0 ] o_rx_data1
);
  logic             aib_clk;
  logic             aux_clk;

  logic             io_rst_n;
  logic             adapt_rst_n;

  logic [   2 : 0 ] chn_mode;
  logic             config_done;
  logic             skip_hrdrst;

  logic [   7 : 0 ] dll_tap;

  logic             ddr_mode      [NumIo];
  logic             async_mode    [NumIo];
  logic             tx_en         [NumIo];
  logic             pull_en       [NumIo];
  logic             pull_dir      [NumIo];
  logic [   2 : 0 ] pdrv          [NumIo];
  logic [   2 : 0 ] ndrv          [NumIo];
  logic [   7 : 0 ] tx_dly_tap    [NumIo];
  logic [   7 : 0 ] rx_dly_tap    [NumIo];

  logic             tx_clk        [NumIo];
  logic             tx_data0      [NumIo];
  logic             tx_data1      [NumIo];
  logic             tx_data_async [NumIo];

  logic             rx_sample_clk [NumIo];
  logic             rx_retime_clk [NumIo];
  logic             rx_data0      [NumIo];
  logic             rx_data1      [NumIo];
  logic             rx_data_async [NumIo];

  logic [   2 : 0 ] rx_wptr_init;
  logic [   2 : 0 ] rx_rptr_init;

  logic [  19 : 0 ] agent_tx_data0;
  logic [  19 : 0 ] agent_tx_data1;

  logic [  19 : 0 ] agent_rx_data0;
  logic [  19 : 0 ] agent_rx_data1;

  logic [  19 : 0 ] phy_tx_data0;
  logic [  19 : 0 ] phy_tx_data1;

  logic [  19 : 0 ] phy_rx_data0;
  logic [  19 : 0 ] phy_rx_data1;

  logic [  19 : 0 ] adapt_tx_data0;
  logic [  19 : 0 ] adapt_tx_data1;

  logic [  19 : 0 ] adapt_rx_data0;
  logic [  19 : 0 ] adapt_rx_data1;

  logic             rx_clk;
  logic             rx_clk_delayed;
  logic             fwd_clk;

  logic             ms_sr_data;
  logic             ms_sr_load;

  logic             sl_sr_clk;
  logic             sl_sr_clkb;
  logic             sl_sr_data;
  logic             sl_sr_load;

  logic             hrdrst_done;

  logic             ms_osc_transfer_en;
  logic             ms_tx_dcd_cal_done;
  logic             ms_tx_transfer_en;
  logic             ms_rx_dll_lock;
  logic             ms_rx_dcd_cal_done;
  logic             ms_rx_transfer_en;
  logic             ms_rx_align_done;

  logic             sl_osc_transfer_en;
  logic             sl_rx_transfer_en;
  logic             sl_rx_dll_lock;
  logic             sl_tx_transfer_en;
  logic             sl_tx_dcd_cal_done;

  logic             agent_en;
  logic [  15 : 0 ] agent_loop_cnt;
  logic [  19 : 0 ] agent_pattern0 [8];
  logic [  19 : 0 ] agent_pattern1 [8];
  logic             agent_test_pass;
  logic             agent_test_fail;
  logic [  15 : 0 ] agent_test_fail_cnt;
  logic [  19 : 0 ] agent_test_fail_data0;
  logic [  19 : 0 ] agent_test_fail_data1;
  logic             agent_test_timeout;

  // ---------------------------------------------------------------------------
  assign /*output*/ o_aib_clk = aib_clk;
  assign /*output*/ o_aux_clk = aux_clk;

  assign /*output*/ o_adapt_rst_n = adapt_rst_n;

  assign /*output*/ o_ready = config_done & (hrdrst_done | skip_hrdrst);

  assign /*output*/ c_chn_mode = chn_mode;

  assign /*output*/ o_rx_data0 = chn_mode[0] ? 20'b0 : phy_rx_data0;
  assign /*output*/ o_rx_data1 = chn_mode[0] ? 20'b0 : phy_rx_data1;

  // ---------------------------------------------------------------------------
  // Pass the forwarded clock to clkgen in slave chiplet
  MXT2_X4N_A7P5PP96PTS_C16 DT_fwd_clk (
    .A(rx_data_async[57]), .B(1'b0), .S0(chn_mode[2]), .Y(fwd_clk));

  // TODO add ms_rst_n
  aib_control #(.NumIo(NumIo)) u_aib_control (
    .i_rst_n            (i_rst_n),

    .o_io_rst_n         (io_rst_n),
    .o_sys_rst_n        (o_sys_rst_n),
    .o_adapt_rst_n      (adapt_rst_n),

    .o_uart_tx          (o_uart_tx),
    .i_uart_rx          (i_uart_rx),

    .i_bypass           (i_bypass),
    .i_bypass_clk       (i_bypass_clk),

    .i_fwd_clk          (fwd_clk),

    .o_aib_clk          (aib_clk),
    .o_aux_clk          (aux_clk),
    .o_sys_clk          (o_sys_clk),

    .o_aib_slow_clk     (o_aib_slow_clk),
    .o_aux_slow_clk     (o_aux_slow_clk),

    .i_aib_ready        (o_ready),

    .c_chn_mode         (chn_mode),
    .c_config_done      (config_done),
    .c_skip_hrdrst      (skip_hrdrst),

    .c_dll_tap          (dll_tap),

    .c_ddr_mode         (ddr_mode),
    .c_async_mode       (async_mode),
    .c_tx_en            (tx_en),
    .c_pull_en          (pull_en),
    .c_pull_dir         (pull_dir),
    .c_pdrv             (pdrv),
    .c_ndrv             (ndrv),
    .c_tx_dly_tap       (tx_dly_tap),
    .c_rx_dly_tap       (rx_dly_tap),

    .c_rx_wptr_init     (rx_wptr_init),
    .c_rx_rptr_init     (rx_rptr_init),
    .c_fifo_mode        (c_fifo_mode),

    .c_agent_en         (agent_en),
    .c_agent_loop_cnt   (agent_loop_cnt),
    .c_agent_pattern0   (agent_pattern0),
    .c_agent_pattern1   (agent_pattern1),
    .c_test_pass        (agent_test_pass),
    .c_test_fail        (agent_test_fail),
    .c_test_fail_cnt    (agent_test_fail_cnt),
    .c_test_fail_data0  (agent_test_fail_data0),
    .c_test_fail_data1  (agent_test_fail_data1),
    .c_test_timeout     (agent_test_timeout)
  );

  // ---------------------------------------------------------------------------
  assign agent_rx_data0 = chn_mode[0] ? phy_rx_data0 : 20'b0;
  assign agent_rx_data1 = chn_mode[0] ? phy_rx_data1 : 20'b0;

  aib_test_agent #(.AibIoCnt(AibIoCnt)) u_aib_test_agent (
    .i_rst_n            (adapt_rst_n), // TODO check if this is ok
    .i_clk              (aib_clk),

    .c_en               (agent_en),
    .c_loop_cnt         (agent_loop_cnt),
    .c_pattern0         (agent_pattern0),
    .c_pattern1         (agent_pattern1),

    .o_tx_data0         (agent_tx_data0),
    .o_tx_data1         (agent_tx_data1),

    .i_rx_data0         (agent_rx_data0),
    .i_rx_data1         (agent_rx_data1),

    .c_test_pass        (agent_test_pass),
    .c_test_fail        (agent_test_fail),
    .c_test_fail_cnt    (agent_test_fail_cnt),
    .c_test_fail_data0  (agent_test_fail_data0),
    .c_test_fail_data1  (agent_test_fail_data1),
    .c_test_timeout     (agent_test_timeout)
  );

  // ---------------------------------------------------------------------------
  assign phy_tx_data0 = chn_mode[0] ? chn_mode[2] ? agent_tx_data0 :
                                                    phy_rx_data0 :
                                      i_tx_data0;
  assign phy_tx_data1 = chn_mode[0] ? chn_mode[2] ? agent_tx_data1 :
                                                    phy_rx_data1 :
                                      i_tx_data1;

  aib_adapt u_aib_adapt (
    .i_tx_rst_n     (adapt_rst_n),

    .i_tx_clk       (aib_clk),
    .i_tx_data0     (phy_tx_data0),
    .i_tx_data1     (phy_tx_data1),

    .o_tx_data0     (adapt_tx_data0),
    .o_tx_data1     (adapt_tx_data1),

    .c_rx_wptr_init (rx_wptr_init),
    .c_rx_rptr_init (rx_rptr_init),

    .i_rx_rst_n     (adapt_rst_n),

    .i_rx_wr_clk    (rx_clk),
    .i_rx_data0     (adapt_rx_data0),
    .i_rx_data1     (adapt_rx_data1),

    .i_rx_rd_clk    (aib_clk),
    .o_rx_data0     (phy_rx_data0),
    .o_rx_data1     (phy_rx_data1)
  );

  // ---------------------------------------------------------------------------
  `define Pack2Unpack(unpack, pack) \
    begin \
      automatic logic [57:0] packed_array = pack; \
      for (int i = 0; i < NumIo; i++) \
        unpack[i] = packed_array[i]; \
    end

  always_comb begin
    `Pack2Unpack(tx_clk,  {
      {2{aib_clk}}, 2'b0, {4{aux_clk}}, {2{aib_clk}}, {20{aib_clk}},
                    2'b0, {4{aux_clk}}, {2{aib_clk}}, {20{aib_clk}}});

    case (chn_mode[2:1])
      // Slave SDR mode
      2'b00: begin
        `Pack2Unpack(tx_data0, {2'b0, 2'b0, 4'b0, 2'b0,  20'b0,
                                      2'b0, 4'b0, 2'b01, adapt_tx_data0});
        `Pack2Unpack(tx_data1, {2'b0, 2'b0, 4'b0, 2'b0,  20'b0,
                                      2'b0, 4'b0, 2'b10, 20'b0});
        `Pack2Unpack(tx_data_async, {2'b0, 2'b0, 4'b0, 2'b0, 20'b0,
                                           2'b0, 4'b0, 2'b0, 20'b0});

        adapt_rx_data0 = {<<{rx_data0[28:47]}};
        adapt_rx_data1 = 20'b0;
      end
      // Slave DDR mode
      2'b01: begin
        `Pack2Unpack(tx_data0, {2'b0, 2'b0, 4'b0, 2'b0,  20'b0,
                                      2'b0, 4'b0, 2'b01, adapt_tx_data0});
        `Pack2Unpack(tx_data1, {2'b0, 2'b0, 4'b0, 2'b0,  20'b0,
                                      2'b0, 4'b0, 2'b10, adapt_tx_data1});
        `Pack2Unpack(tx_data_async, {2'b0, 2'b0, 4'b0, 2'b0, 20'b0,
                                           2'b0, 4'b0, 2'b0, 20'b0});

        adapt_rx_data0 = {<<{rx_data0[28:47]}};
        adapt_rx_data1 = {<<{rx_data1[28:47]}};
      end
      // Master SDR mode
      2'b10: begin
        `Pack2Unpack(tx_data0, {
          2'b01, 2'b0, {2'b01, ms_sr_data, ms_sr_load}, 2'b01, adapt_tx_data0,
                 2'b0, 4'b0, 2'b0, 20'b0});
        `Pack2Unpack(tx_data1, {2'b10, 2'b0, {2'b10, 2'b0}, 2'b10, 20'b0,
                                       2'b0, 4'b0, 2'b0, 20'b0});
        `Pack2Unpack(tx_data_async, {2'b0, 2'b11, 4'b0, 2'b0, 20'b0,
                                           2'b0,  4'b0, 2'b0, 20'b0});

        adapt_rx_data0 = {<<{rx_data0[0:19]}};
        adapt_rx_data1 = 20'd0;
      end
      // Master DDR mode
      default: begin
        `Pack2Unpack(tx_data0, {
          2'b01, 2'b0, {2'b01, ms_sr_data, ms_sr_load}, 2'b01, adapt_tx_data0,
                 2'b0, 4'b0, 2'b0, 20'b0});
        `Pack2Unpack(tx_data1, {2'b10, 2'b0, {2'b10, 2'b0}, 2'b10, adapt_tx_data1,
                                       2'b0, 4'b0, 2'b0, 20'b0});
        `Pack2Unpack(tx_data_async, {2'b0, 2'b11, 4'b0, 2'b0, 20'b0,
                                           2'b0,  4'b0, 2'b0, 20'b0});

        adapt_rx_data0 = {<<{rx_data0[0:19]}};
        adapt_rx_data1 = {<<{rx_data1[0:19]}};
      end
    endcase

    `Pack2Unpack(rx_sample_clk, {
      2'b0, 2'b0, 4'b0, {2{rx_clk_delayed}}, {20{rx_clk_delayed}},
            2'b0, 4'b0, {2{rx_clk_delayed}}, {20{rx_clk_delayed}}});

    `Pack2Unpack(rx_retime_clk, {
      2'b0, 2'b0, 4'b0, {2{rx_clk}}, {20{rx_clk}},
            2'b0, 4'b0, {2{rx_clk}}, {20{rx_clk}}});
  end

  //assign rx_clk = chn_mode[2] ? rx_data_async[21] : rx_data_async[49];
  MXT2_X4N_A7P5PP96PTS_C16 DT_rx_clk (
    .A(rx_data_async[49]), .B(rx_data_async[21]), .S0(chn_mode[2]), .Y(rx_clk));

  aib_io_block #(.NumIo(NumIo)) u_aib_io_block (
    .i_rst_n          (io_rst_n),

    .io_bump          (io_bump),

    .c_ddr_mode       (ddr_mode),
    .c_async_mode     (async_mode),
    .c_tx_en          (tx_en),
    .c_pull_en        (pull_en),
    .c_pull_dir       (pull_dir),
    .c_pdrv           (pdrv),
    .c_ndrv           (ndrv),
    .c_tx_dly_tap     (tx_dly_tap),
    .c_rx_dly_tap     (rx_dly_tap),

    .i_tx_clk         (tx_clk),
    .i_tx_data0       (tx_data0),
    .i_tx_data1       (tx_data1),
    .i_tx_data_async  (tx_data_async),

    .i_rx_sample_clk  (rx_sample_clk),
    .i_rx_retime_clk  (rx_retime_clk),
    .o_rx_data0       (rx_data0),
    .o_rx_data1       (rx_data1),
    .o_rx_data_async  (rx_data_async)
  );

  // ---------------------------------------------------------------------------
  aib_io_buffer u_aib_fake_dll (
    .i_rst_n          (io_rst_n),

    .c_ddr_mode       (1'b0),
    .c_async_mode     (1'b0),
    .c_tx_en          (1'b0),
    .c_pull_en        (1'b0),
    .c_pull_dir       (1'b0),
    .c_tx_dly_tap     (8'd0),
    .c_rx_dly_tap     (dll_tap),

    .i_tx_clk         (1'b0),
    .i_tx_data0       (1'b0),
    .i_tx_data1       (1'b0),
    .i_tx_data_async  (1'b0),

    .i_rx_sample_clk  (1'b0),
    .i_rx_retime_clk  (1'b0),
    .o_rx_data0       (),
    .o_rx_data1       (),
    .o_rx_data_async  (rx_clk_delayed),

    .o_drv_pmos       (),
    .o_drv_nmos       (),
    .o_drv_pu         (),
    .o_drv_pd         (),
    .i_drv_data       (rx_clk)
  );

  // ---------------------------------------------------------------------------
  `ifndef SYNTHESIS
  logic [7:0] sr_cnt_d, sr_cnt_q;

  assign sl_sr_clk  = aux_clk;
  assign sl_sr_data = 1'b1;
  assign sl_sr_load = (sr_cnt_q == 72);

  always_ff @(posedge aux_clk or negedge i_rst_n)
    if (!i_rst_n)
      sr_cnt_q <= 7'd0;
    else if (sr_cnt_q == 72)
      sr_cnt_q <= 0;
    else
      sr_cnt_q <= sr_cnt_q + 1;
  `else
  assign sl_sr_clk  = rx_data0[25];
  assign sl_sr_clkb = rx_data0[24];
  assign sl_sr_data = rx_data0[23];
  assign sl_sr_load = rx_data0[22];
  `endif

  aib_shift_reg u_aib_shift_reg (
    .i_aux_clk            (aux_clk),
    .i_rst_n              (adapt_rst_n),

    .i_ms_sr_clk          (aux_clk),
    .o_ms_sr_data         (ms_sr_data),
    .o_ms_sr_load         (ms_sr_load),

    .c_ms_osc_transfer_en (ms_osc_transfer_en),
    .c_ms_tx_dcd_cal_done (ms_tx_dcd_cal_done),
    .c_ms_tx_transfer_en  (ms_tx_transfer_en),
    .c_ms_rx_dll_lock     (ms_rx_dll_lock),
    .c_ms_rx_dcd_cal_done (ms_rx_dcd_cal_done),
    .c_ms_rx_transfer_en  (ms_rx_transfer_en),
    .c_ms_rx_align_done   (ms_rx_align_done),

    .i_sl_sr_clk          (sl_sr_clk),
    .i_sl_sr_data         (sl_sr_data),
    .i_sl_sr_load         (sl_sr_load),

    .c_sl_osc_transfer_en (sl_osc_transfer_en),
    .c_sl_rx_transfer_en  (sl_rx_transfer_en),
    .c_sl_rx_dll_lock     (sl_rx_dll_lock),
    .c_sl_tx_transfer_en  (sl_tx_transfer_en),
    .c_sl_tx_dcd_cal_done (sl_tx_dcd_cal_done)
  );

  // ---------------------------------------------------------------------------
  aib_hrdrst u_aib_hrdrst (
    .i_aux_clk            (aux_clk),
    .i_rst_n              (adapt_rst_n),

    .o_hrdrst_done        (hrdrst_done),

    .c_ms_osc_transfer_en (ms_osc_transfer_en),
    .c_ms_tx_dcd_cal_done (ms_tx_dcd_cal_done),
    .c_ms_tx_transfer_en  (ms_tx_transfer_en),
    .c_ms_rx_dll_lock     (ms_rx_dll_lock),
    .c_ms_rx_dcd_cal_done (ms_rx_dcd_cal_done),
    .c_ms_rx_transfer_en  (ms_rx_transfer_en),
    .c_ms_rx_align_done   (ms_rx_align_done),

    .c_sl_osc_transfer_en (sl_osc_transfer_en),
    .c_sl_rx_transfer_en  (sl_rx_transfer_en),
    .c_sl_rx_dll_lock     (sl_rx_dll_lock),
    .c_sl_tx_transfer_en  (sl_tx_transfer_en),
    .c_sl_tx_dcd_cal_done (sl_tx_dcd_cal_done)
  );

endmodule

