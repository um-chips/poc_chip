
`define MS_SYNC(name) \
  logic name; \
  SDFFYQ3D_X2N_A7P5PP96PTS_C16 DT_``name``( \
    .CK(i_ms_sr_clk), .D(c_``name``), .Q(``name``), .SI(1'b0), .SE(1'b0) \
  );

`define SL_SYNC(name, idx) \
  logic name; \
  SDFFYQ3D_X2N_A7P5PP96PTS_C16 DT_``name``( \
    .CK(i_aux_clk), .D(sl_sr_capture_q[idx]), .Q(c_``name``), .SI(1'b0), .SE(1'b0) \
  );

module aib_shift_reg
(
  input  logic i_aux_clk,
  input  logic i_rst_n,

  // Master
  input  logic i_ms_sr_clk,
  output logic o_ms_sr_data,
  output logic o_ms_sr_load,

  input  logic c_ms_osc_transfer_en,  // [80]
  input  logic c_ms_tx_dcd_cal_done,  // [79]
  input  logic c_ms_tx_transfer_en,   // [78]
  input  logic c_ms_rx_dll_lock,      // [77]
  input  logic c_ms_rx_dcd_cal_done,  // [76]
  input  logic c_ms_rx_transfer_en,   // [75]
  input  logic c_ms_rx_align_done,    // [73]

  // Slave
  input  logic i_sl_sr_clk,
  input  logic i_sl_sr_data,
  input  logic i_sl_sr_load,

  output logic c_sl_osc_transfer_en,  // [72]
  output logic c_sl_rx_transfer_en,   // [70]
  output logic c_sl_rx_dll_lock,      // [68]
  output logic c_sl_tx_transfer_en,   // [64]
  output logic c_sl_tx_dcd_cal_done   // [31]
);
  // ---------------------------------------------------------------------------
  logic [   7 : 0 ] ms_cnt_q;
  logic             ms_load_q;
  logic [  80 : 0 ] ms_sr_d, ms_sr_q;

  assign /*output*/ o_ms_sr_data = ms_sr_q[80];
  assign /*output*/ o_ms_sr_load = ms_load_q;

  `MS_SYNC(ms_osc_transfer_en)
  `MS_SYNC(ms_tx_dcd_cal_done)
  `MS_SYNC(ms_tx_transfer_en)
  `MS_SYNC(ms_rx_dll_lock)
  `MS_SYNC(ms_rx_dcd_cal_done)
  `MS_SYNC(ms_rx_transfer_en)
  `MS_SYNC(ms_rx_align_done)

  assign ms_sr_d = {
    ms_osc_transfer_en, // [80]
    ms_tx_dcd_cal_done, // [79]
    ms_tx_transfer_en,  // [78]
    ms_rx_dll_lock,     // [77]
    ms_rx_dcd_cal_done, // [76]
    ms_rx_transfer_en,  // [75]
    ms_rx_dll_lock,     // [74] ms_hrdrst_rx_dll_lock
    ms_rx_align_done,   // [73]
    4'b0,
    ms_tx_dcd_cal_done, // [68] ms_hrdrst_tx_dcd_cal_done
    60'b0,
    ms_rx_dcd_cal_done, // [ 7] ms_hrdrst_rx_dcd_cal_done
    7'b0
  };

  always_ff @(posedge i_ms_sr_clk or negedge i_rst_n)
    if (!i_rst_n)
      ms_cnt_q <= 8'd80;
    else if (ms_cnt_q == 8'd0)
      ms_cnt_q <= 8'd80;
    else
      ms_cnt_q <= ms_cnt_q - 1;

  always_ff @(posedge i_ms_sr_clk or negedge i_rst_n)
    if (!i_rst_n)
      ms_load_q <= 1'b0;
    else
      ms_load_q <= (ms_cnt_q == 8'd0);

  always_ff @(posedge i_ms_sr_clk or negedge i_rst_n)
    if (!i_rst_n)
      ms_sr_q <= 81'b0;
    else if (ms_cnt_q == 8'd0)
      ms_sr_q <= ms_sr_d;
    else
      ms_sr_q <= {ms_sr_q[79:0], ms_sr_q[0]};

  // ---------------------------------------------------------------------------
  logic [  72 : 0 ] sl_sr_q;
  logic [  72 : 0 ] sl_sr_capture_q;

  `SL_SYNC(sl_osc_transfer_en, 72);
  `SL_SYNC(sl_rx_transfer_en,  70);
  `SL_SYNC(sl_rx_dll_lock,     68);
  `SL_SYNC(sl_tx_transfer_en,  64);
  `SL_SYNC(sl_tx_dcd_cal_done, 31);

  always_ff @(posedge i_sl_sr_clk or negedge i_rst_n)
    if (!i_rst_n)
      sl_sr_q <= 73'b0;
    else
      sl_sr_q <= {sl_sr_q[71:0], i_sl_sr_data};

  always_ff @(posedge i_sl_sr_clk or negedge i_rst_n)
    if (!i_rst_n)
      sl_sr_capture_q <= 73'b0;
    else if (i_sl_sr_load)
      sl_sr_capture_q <= sl_sr_q;

endmodule

