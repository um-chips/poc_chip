
`ifndef DBG_SV // this module can be included in multiple file lists
`define DBG_SV // use an include guard to avoid duplicated module declaration

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module dbg
(
  input  logic            i_clk,
  input  logic            i_rst_n,

  output logic            o_tx,
  input  logic            i_rx,

  input  logic [ 15 : 0 ] c_baud_cyc,

  output logic            o_penable,
  output logic            o_pwrite,
  output logic [ 31 : 0 ] o_paddr,
  output logic [ 31 : 0 ] o_pwdata,
  input  logic            i_pready,
  input  logic [ 31 : 0 ] i_prdata
);
  // ---------------------------------------------------------------------------
  logic           fifo_full;
  logic           fifo_write;
  logic [ 7 : 0 ] fifo_wdata;

  logic           fifo_empty;
  logic           fifo_read;
  logic [ 7 : 0 ] fifo_rdata;

  // ---------------------------------------------------------------------------
  uart u_uart (
    .i_clk,
    .i_rst_n,

    .o_tx,
    .i_rx,

    .c_baud_cyc,

    .o_fifo_full  (fifo_full),
    .i_fifo_write (fifo_write),
    .i_fifo_wdata (fifo_wdata),

    .o_fifo_empty (fifo_empty),
    .i_fifo_read  (fifo_read),
    .o_fifo_rdata (fifo_rdata)
  );

  // ---------------------------------------------------------------------------
  dbg_cmd u_dbg_cmd (
    .i_clk,
    .i_rst_n,

    .i_fifo_empty (fifo_empty),
    .o_fifo_read  (fifo_read),
    .i_fifo_rdata (fifo_rdata),

    .i_fifo_full  (fifo_full),
    .o_fifo_write (fifo_write),
    .o_fifo_wdata (fifo_wdata),

    .o_penable,
    .o_pwrite,
    .o_paddr,
    .o_pwdata,
    .i_pready,
    .i_prdata
  );

endmodule

`endif // DBG_V

