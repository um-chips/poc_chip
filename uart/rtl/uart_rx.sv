
`ifndef UART_RX_SV // this module can be included in multiple file lists
`define UART_RX_SV // use an include guard to avoid duplicated module declaration

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module uart_rx #(parameter FifoDepth   = 4,
                 parameter BaudCycBits = 16)
(
  input  logic                       i_clk,
  input  logic                       i_rst_n,

  input  logic [ BaudCycBits-1 : 0 ] c_baud_cyc,

  input  logic                       i_rx,

  output logic                       o_busy,

  output logic                       o_fifo_empty,
  input  logic                       i_fifo_read,
  output logic [             7 : 0 ] o_fifo_rdata
);
  // ---------------------------------------------------------------------------
  typedef enum logic [1:0] {
    FSM_IDLE,
    FSM_START_BIT,
    FSM_DATA_BITS,
    FSM_STOP_BIT
  } fsm_state;

  fsm_state fsm_ns, fsm_cs;

  // Signal declarations
  // ---------------------------------------------------------------------------
  logic                       rx_sync;
  logic                       rx_sync_inv;

  logic                       tick_baud;
  logic                       tick_sample;

  logic [ BaudCycBits-1 : 0 ] cyc_cnt_d, cyc_cnt_q;
  logic [             2 : 0 ] bit_cnt_d, bit_cnt_q;

  logic                       fifo_write;
  logic [             7 : 0 ] fifo_wdata_d, fifo_wdata_q;

  // Output assignments
  // ---------------------------------------------------------------------------
  assign /*output*/ o_busy = (fsm_cs != FSM_IDLE);

  // ---------------------------------------------------------------------------
  //sync #(.NumStage(2), .ResetValue(1)) u_rx_sync (
  //  .i_clk,
  //  .i_rst_n,

  //  .i_async_in (i_rx),
  //  .o_sync_out (rx_sync)
  //);

  // ARM's synchronizer resets to 0, so we need to double invert the signal
  SDFFYRPQ2D_X2N_A7P5PP96PTS_C16 DT_rx (
    .CK(i_clk), .R(~i_rst_n), .D(~i_rx), .Q(rx_sync), .SI(1'b0), .SE(1'b0)
  );
  assign rx_sync_inv = ~rx_sync;

  // ---------------------------------------------------------------------------
  assign tick_baud   = (fsm_cs != FSM_IDLE) && (cyc_cnt_q == 0);
  assign tick_sample = (fsm_cs != FSM_IDLE) && (cyc_cnt_q == (c_baud_cyc+1)/2);

  // ---------------------------------------------------------------------------
  always_comb begin
    fsm_ns = fsm_cs;

    cyc_cnt_d = cyc_cnt_q;
    bit_cnt_d = bit_cnt_q;

    fifo_write   = 1'b0;
    fifo_wdata_d = fifo_wdata_q;

    case (fsm_cs)
      FSM_IDLE:
        if (!rx_sync_inv) begin
          fsm_ns = FSM_START_BIT;

          cyc_cnt_d = c_baud_cyc;
        end

      FSM_START_BIT:
        if (tick_baud) begin
          fsm_ns = FSM_DATA_BITS;

          cyc_cnt_d = c_baud_cyc;
        end
        else
          cyc_cnt_d = cyc_cnt_q - 1;

      FSM_DATA_BITS: begin
        if (tick_baud) begin
          if (bit_cnt_q == 7)
            fsm_ns = FSM_STOP_BIT;

          cyc_cnt_d = c_baud_cyc;
          bit_cnt_d = bit_cnt_q + 1;
        end
        else
          cyc_cnt_d = cyc_cnt_q - 1;

        if (tick_sample)
          fifo_wdata_d = {rx_sync_inv, fifo_wdata_q[7:1]};
      end

      FSM_STOP_BIT:
        // Exit stop bit at sample time to be ready for the next start bit
        if (tick_sample) begin
          fsm_ns = FSM_IDLE;

          cyc_cnt_d = '0;

          fifo_write = 1'b1;
        end
        else
          cyc_cnt_d = cyc_cnt_q - 1;
    endcase
  end

  // ---------------------------------------------------------------------------
  fifo #(.Width(8), .Depth(FifoDepth)) u_fifo (
    .i_clk,
    .i_rst_n,

    .o_full  (),
    .o_empty (o_fifo_empty),

    .i_write (fifo_write),
    .i_wdata (fifo_wdata_q),

    .i_read  (i_fifo_read),
    .o_rdata (o_fifo_rdata)
  );

  // Flip flops
  // ---------------------------------------------------------------------------
  `infer_ff_begin
  `infer_ff(0, i_clk, i_rst_n, fsm_cs, fsm_ns, FSM_IDLE)
  `infer_ff_default_all0(cyc_cnt_)
  `infer_ff_default_all0(bit_cnt_)
  `infer_ff_default_all0(fifo_wdata_)
  `infer_ff_end

endmodule

`endif // UART_RX_SV

