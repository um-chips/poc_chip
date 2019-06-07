
`ifndef UART_SV // this module can be included in multiple file lists
`define UART_SV // use an include guard to avoid duplicated module declaration

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module uart #(parameter TxFifoDepth = 8,
              parameter RxFifoDepth = 2,
              parameter BaudCycBits = 16)
(
  input  logic                       i_clk,
  input  logic                       i_rst_n,

  input  logic [ BaudCycBits-1 : 0 ] c_baud_cyc,

  output logic                       o_tx,
  input  logic                       i_rx,

  output logic                       o_fifo_full,
  input  logic                       i_fifo_write,
  input  logic [             7 : 0 ] i_fifo_wdata,

  output logic                       o_fifo_empty,
  input  logic                       i_fifo_read,
  output logic [             7 : 0 ] o_fifo_rdata
);
  // Signal declarations
  // ---------------------------------------------------------------------------
  logic                       tx_busy;
  logic                       rx_busy;

  logic [ BaudCycBits-1 : 0 ] baud_cyc;

  // ---------------------------------------------------------------------------
  uart_cfg #(.BaudCycBits(BaudCycBits)) u_uart_cfg (
    .i_clk,
    .i_rst_n,

    .i_tx_busy (tx_busy),
    .i_rx_busy (rx_busy),

    .c_baud_cyc,

    .o_baud_cyc (baud_cyc)
  );

  // ---------------------------------------------------------------------------
  uart_tx #(.FifoDepth(TxFifoDepth), .BaudCycBits(BaudCycBits)) u_uart_tx (
    .i_clk,
    .i_rst_n,

    .o_tx,

    .o_busy (tx_busy),

    .c_baud_cyc (baud_cyc),

    .o_fifo_full,
    .i_fifo_write,
    .i_fifo_wdata
  );

  // ---------------------------------------------------------------------------
  uart_rx #(.FifoDepth(RxFifoDepth), .BaudCycBits(BaudCycBits)) u_uart_rx (
    .i_clk,
    .i_rst_n,

    .i_rx,

    .o_busy (rx_busy),

    .c_baud_cyc (baud_cyc),

    .o_fifo_empty,
    .i_fifo_read,
    .o_fifo_rdata
  );

endmodule

`endif // UART_SV

