
module aib_hrdrst_m2s
(
  input  logic i_aux_clk,
  input  logic i_rst_n,

  input  logic i_start,
  output logic o_done,

  output logic c_ms_tx_dcd_cal_done,
  output logic c_ms_tx_transfer_en,

  input  logic c_sl_rx_transfer_en,
  input  logic c_sl_rx_dll_lock
);
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    FSM_RESET,
    FSM_MS_TX_DCD_CAL_DONE,
    FSM_WAIT_SL_RX_DLL_LOCK,
    FSM_WAIT_SL_RX_TRANSFER_EN,
    FSM_READY
  } fsm_state;

  fsm_state fsm_ns, fsm_cs;

  logic ms_tx_dcd_cal_done_d, ms_tx_dcd_cal_done_q;

  assign /*output*/ o_done = (fsm_cs == FSM_READY);

  assign /*output*/ c_ms_tx_dcd_cal_done = ms_tx_dcd_cal_done_q;
  assign /*output*/ c_ms_tx_transfer_en  = (fsm_cs == FSM_READY);

  always_comb begin
    fsm_ns = fsm_cs;

    ms_tx_dcd_cal_done_d = ms_tx_dcd_cal_done_q;

    case (fsm_cs)
      FSM_RESET:
        if (i_start)
          fsm_ns = FSM_MS_TX_DCD_CAL_DONE;

      FSM_MS_TX_DCD_CAL_DONE: begin
        fsm_ns = FSM_WAIT_SL_RX_DLL_LOCK;

        ms_tx_dcd_cal_done_d = 1'b1;
      end

      FSM_WAIT_SL_RX_DLL_LOCK:
        if (c_sl_rx_dll_lock)
          fsm_ns = FSM_WAIT_SL_RX_TRANSFER_EN;

      FSM_WAIT_SL_RX_TRANSFER_EN:
        if (c_sl_rx_transfer_en)
          fsm_ns = FSM_READY;

      FSM_READY:
        fsm_ns = FSM_READY;
    endcase
  end

  always_ff @(posedge i_aux_clk or negedge i_rst_n)
    if (!i_rst_n) begin
      fsm_cs <= FSM_RESET;

      ms_tx_dcd_cal_done_q <= 1'b0;
    end
    else begin
      fsm_cs <= fsm_ns;

      ms_tx_dcd_cal_done_q <= ms_tx_dcd_cal_done_d;
    end

endmodule

