
module aib_adapt
(
  // TX
  input  logic              i_tx_rst_n,

  input  logic              i_tx_clk,
  input  logic  [  19 : 0 ] i_tx_data0,
  input  logic  [  19 : 0 ] i_tx_data1,

  output logic  [  19 : 0 ] o_tx_data0,
  output logic  [  19 : 0 ] o_tx_data1,

  // RX
  input  logic  [   2 : 0 ] c_rx_wptr_init,
  input  logic  [   2 : 0 ] c_rx_rptr_init,

  input  logic              i_rx_rst_n,

  input  logic              i_rx_wr_clk,
  input  logic  [  19 : 0 ] i_rx_data0,
  input  logic  [  19 : 0 ] i_rx_data1,

  input  logic              i_rx_rd_clk,
  output logic  [  19 : 0 ] o_rx_data0,
  output logic  [  19 : 0 ] o_rx_data1
);
  logic tx_rst_n;
  logic rx_wr_rst_n;
  logic rx_rd_rst_n;

  reset_sync tx_rst_sync (.i_clk(i_tx_clk), .i_rst_n(i_tx_rst_n), .o_rst_n(tx_rst_n));
  reset_sync rx_wr_rst_sync (.i_clk(i_rx_wr_clk), .i_rst_n(i_rx_rst_n), .o_rst_n(rx_wr_rst_n));
  reset_sync rx_rd_rst_sync (.i_clk(i_rx_rd_clk), .i_rst_n(i_rx_rst_n), .o_rst_n(rx_rd_rst_n));

  // ---------------------------------------------------------------------------
  logic [  19 : 0 ] tx_data0_q, tx_data1_q;

  assign /*output*/ o_tx_data0 = tx_data0_q;
  assign /*output*/ o_tx_data1 = tx_data1_q;

  always_ff @(posedge i_tx_clk or negedge tx_rst_n)
    if (!tx_rst_n) begin
      tx_data0_q <= 20'b0;
      tx_data1_q <= 20'b0;
    end
    else begin
      tx_data0_q <= i_tx_data0;
      tx_data1_q <= i_tx_data1;
    end

  // ---------------------------------------------------------------------------
  logic [  19 : 0 ] rx_fifo_data0_q[8];
  logic [  19 : 0 ] rx_fifo_data1_q[8];

  logic [   2 : 0 ] rx_fifo_wptr_d, rx_fifo_wptr_q;
  logic [   2 : 0 ] rx_fifo_rptr_d, rx_fifo_rptr_q;

  assign /*output*/ o_rx_data0 = rx_fifo_data0_q[rx_fifo_rptr_q]; // TODO change to sync
  assign /*output*/ o_rx_data1 = rx_fifo_data1_q[rx_fifo_rptr_q];

  always_ff @(posedge i_rx_wr_clk or negedge rx_wr_rst_n)
    if (!rx_wr_rst_n)
      rx_fifo_data0_q <= '{8{20'b0}};
    else
      rx_fifo_data0_q[rx_fifo_wptr_q] <= i_rx_data0;

  always_ff @(posedge i_rx_wr_clk or negedge rx_wr_rst_n)
    if (!rx_wr_rst_n)
      rx_fifo_data1_q <= '{8{20'b0}};
    else
      rx_fifo_data1_q[rx_fifo_wptr_q] <= i_rx_data1;

  always_ff @(posedge i_rx_wr_clk or negedge rx_wr_rst_n)
    if (!rx_wr_rst_n)
      rx_fifo_wptr_q <= c_rx_wptr_init;
    else
      rx_fifo_wptr_q <= rx_fifo_wptr_q + 1;

  always_ff @(posedge i_rx_rd_clk or negedge rx_rd_rst_n)
    if (!rx_rd_rst_n)
      rx_fifo_rptr_q <= c_rx_rptr_init;
    else
      rx_fifo_rptr_q <= rx_fifo_rptr_q + 1;

endmodule

