
module aib_hrdrst_osc
(
  input  logic i_aux_clk,
  input  logic i_rst_n,

  output logic o_done,

  output logic c_ms_osc_transfer_en,

  input  logic c_sl_osc_transfer_en
);
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    FSM_RESET,
    FSM_WAIT_CLK,
    FSM_WAIT_SL_EN,
    FSM_READY
  } fsm_state;

  fsm_state fsm_ns, fsm_cs;

  logic [   3 : 0 ] fsm_cnt_d, fsm_cnt_q;

  logic ms_osc_transfer_en_d, ms_osc_transfer_en_q;

  assign /*output*/ o_done = (fsm_cs == FSM_READY);

  assign /*output*/ c_ms_osc_transfer_en = ms_osc_transfer_en_q;

  always_comb begin
    fsm_ns    = fsm_cs;
    fsm_cnt_d = fsm_cnt_q;

    ms_osc_transfer_en_d = ms_osc_transfer_en_q;

    case (fsm_cs)
      FSM_RESET:
        fsm_ns = FSM_WAIT_CLK;

      FSM_WAIT_CLK: begin
        fsm_cnt_d = fsm_cnt_q - 1;

        if (fsm_cnt_q == 0) begin
          fsm_ns = FSM_WAIT_SL_EN;

          ms_osc_transfer_en_d = 1'b1;
        end
      end

      FSM_WAIT_SL_EN:
        if (c_sl_osc_transfer_en)
          fsm_ns = FSM_READY;

      FSM_READY:
        fsm_ns = FSM_READY;
    endcase
  end

  always_ff @(posedge i_aux_clk or negedge i_rst_n)
    if (!i_rst_n) begin
      fsm_cs    <= FSM_RESET;
      fsm_cnt_q <= '{default: 1};

      ms_osc_transfer_en_q <= 1'b0;
    end
    else begin
      fsm_cs    <= fsm_ns;
      fsm_cnt_q <= fsm_cnt_d;

      ms_osc_transfer_en_q <= ms_osc_transfer_en_d;
    end

endmodule

