
module aib_hrdrst_s2m
(
  input  logic i_aux_clk,
  input  logic i_rst_n,

  input  logic i_start,
  output logic o_done,

  output logic c_ms_rx_dll_lock,
  output logic c_ms_rx_dcd_cal_done,
  output logic c_ms_rx_transfer_en,
  output logic c_ms_rx_align_done,

  input  logic c_sl_tx_transfer_en,
  input  logic c_sl_tx_dcd_cal_done
);
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    FSM_RESET,
    FSM_MS_RX_DCD_CAL_DONE,
    FSM_WAIT_SL_TX_DCD_CAL_DONE,
    FSM_MS_RX_DLL_LOCK,
    FSM_MS_RX_FIFO_READY,
    FSM_MS_RX_TRANSFER_EN,
    FSM_WAIT_SL_TX_TRANSFER_EN,
    FSM_READY
  } fsm_state;

  fsm_state fsm_ns, fsm_cs;

  logic ms_rx_dll_lock_d, ms_rx_dll_lock_q;
  logic ms_rx_dcd_cal_done_d, ms_rx_dcd_cal_done_q;
  logic ms_rx_align_done_d, ms_rx_align_done_q;
  logic ms_rx_transfer_en_d, ms_rx_transfer_en_q;

  assign /*output*/ o_done = (fsm_cs == FSM_READY);

  assign /*output*/ c_ms_rx_dll_lock     = ms_rx_dll_lock_q;
  assign /*output*/ c_ms_rx_dcd_cal_done = ms_rx_dcd_cal_done_q;
  assign /*output*/ c_ms_rx_align_done   = ms_rx_align_done_q;
  assign /*output*/ c_ms_rx_transfer_en  = ms_rx_transfer_en_q;

  always_comb begin
    fsm_ns = fsm_cs;

    ms_rx_dll_lock_d     = ms_rx_dll_lock_q;
    ms_rx_dcd_cal_done_d = ms_rx_dcd_cal_done_q;
    ms_rx_align_done_d   = ms_rx_align_done_q;
    ms_rx_transfer_en_d  = ms_rx_transfer_en_q;

    case (fsm_cs)
      FSM_RESET:
        if (i_start)
          fsm_ns = FSM_MS_RX_DCD_CAL_DONE;

      FSM_MS_RX_DCD_CAL_DONE: begin
        fsm_ns = FSM_WAIT_SL_TX_DCD_CAL_DONE;

        ms_rx_dcd_cal_done_d = 1'b1;
      end

      FSM_WAIT_SL_TX_DCD_CAL_DONE:
        if (c_sl_tx_dcd_cal_done)
          fsm_ns = FSM_MS_RX_DLL_LOCK;

      FSM_MS_RX_DLL_LOCK: begin
        fsm_ns = FSM_MS_RX_FIFO_READY;

        ms_rx_dll_lock_d = 1'b1;
      end

      FSM_MS_RX_FIFO_READY: begin
        fsm_ns = FSM_MS_RX_TRANSFER_EN;

        ms_rx_align_done_d = 1'b1;
      end

      FSM_MS_RX_TRANSFER_EN: begin
        fsm_ns = FSM_WAIT_SL_TX_TRANSFER_EN;

        ms_rx_transfer_en_d = 1'b1;
      end

      FSM_WAIT_SL_TX_TRANSFER_EN:
        if (c_sl_tx_transfer_en)
          fsm_ns = FSM_READY;

      FSM_READY:
        fsm_ns = FSM_READY;
    endcase
  end

  always_ff @(posedge i_aux_clk or negedge i_rst_n)
    if (!i_rst_n) begin
      fsm_cs <= FSM_RESET;

      ms_rx_dll_lock_q     <= 1'b0;
      ms_rx_dcd_cal_done_q <= 1'b0;
      ms_rx_align_done_q   <= 1'b0;
      ms_rx_transfer_en_q  <= 1'b0;
    end
    else begin
      fsm_cs <= fsm_ns;

      ms_rx_dll_lock_q     <= ms_rx_dll_lock_d;
      ms_rx_dcd_cal_done_q <= ms_rx_dcd_cal_done_d;
      ms_rx_align_done_q   <= ms_rx_align_done_d;
      ms_rx_transfer_en_q  <= ms_rx_transfer_en_d;
    end

endmodule

