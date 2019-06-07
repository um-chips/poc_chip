
module aib_hrdrst
(
  input  logic i_aux_clk,

  input  logic i_rst_n,

  output logic o_hrdrst_done,

  output logic c_ms_osc_transfer_en,
  output logic c_ms_tx_dcd_cal_done,
  output logic c_ms_tx_transfer_en,
  output logic c_ms_rx_dll_lock,
  output logic c_ms_rx_dcd_cal_done,
  output logic c_ms_rx_transfer_en,
  output logic c_ms_rx_align_done,

  input  logic c_sl_osc_transfer_en,
  input  logic c_sl_rx_transfer_en,
  input  logic c_sl_rx_dll_lock,
  input  logic c_sl_tx_transfer_en,
  input  logic c_sl_tx_dcd_cal_done
);
  logic hrdrst_osc_done;
  logic hrdrst_m2s_done;
  logic hrdrst_s2m_done;

  assign /*output*/ o_hrdrst_done = hrdrst_s2m_done;

  aib_hrdrst_osc u_aib_hrdrst_osc (
    .i_aux_clk            (i_aux_clk),
    .i_rst_n              (i_rst_n),

    .o_done               (hrdrst_osc_done),

    .c_ms_osc_transfer_en (c_ms_osc_transfer_en),
    .c_sl_osc_transfer_en (c_sl_osc_transfer_en)
  );

  aib_hrdrst_m2s u_aib_hrdrst_m2s (
    .i_aux_clk            (i_aux_clk),
    .i_rst_n              (i_rst_n),

    .i_start              (hrdrst_osc_done),
    .o_done               (hrdrst_m2s_done),

    .c_ms_tx_dcd_cal_done (c_ms_tx_dcd_cal_done),
    .c_ms_tx_transfer_en  (c_ms_tx_transfer_en),

    .c_sl_rx_transfer_en  (c_sl_rx_transfer_en),
    .c_sl_rx_dll_lock     (c_sl_rx_dll_lock)
  );

  aib_hrdrst_s2m u_aib_hrdrst_s2m (
    .i_aux_clk            (i_aux_clk),
    .i_rst_n              (i_rst_n),

    .i_start              (hrdrst_m2s_done),
    .o_done               (hrdrst_s2m_done),

    .c_ms_rx_dll_lock     (c_ms_rx_dll_lock),
    .c_ms_rx_dcd_cal_done (c_ms_rx_dcd_cal_done),
    .c_ms_rx_transfer_en  (c_ms_rx_transfer_en),
    .c_ms_rx_align_done   (c_ms_rx_align_done),

    .c_sl_tx_transfer_en  (c_sl_tx_transfer_en),
    .c_sl_tx_dcd_cal_done (c_sl_tx_dcd_cal_done)
  );

endmodule

