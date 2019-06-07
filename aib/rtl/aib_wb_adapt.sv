
module aib_wb_adapt #(parameter AibIoCnt = 20)
(
  input  logic                      i_rst_n,

  input  logic  [           1 : 0 ] c_fifo_sel,

  // System clock domain
  // ---------------------------------------------------------------------------
  input  logic                      i_sys_clk,

  input  logic                      i_wb_stb,
  input  logic                      i_wb_we,
  input  logic  [          31 : 0 ] i_wb_addr,
  input  logic  [           3 : 0 ] i_wb_sel,
  input  logic  [          31 : 0 ] i_wb_wdata,
  output logic                      o_wb_stall,
  output logic                      o_wb_ack,
  output logic  [          31 : 0 ] o_wb_rdata,

  output logic  [          31 : 0 ] o_sram_addr,
  output logic                      o_sram_write,
  output logic  [          31 : 0 ] o_sram_wdata,
  output logic  [          31 : 0 ] o_sram_wmask,
  output logic                      o_sram_read,
  input  logic  [          31 : 0 ] i_sram_rdata,

  // AIB clock domain
  // ---------------------------------------------------------------------------
  input  logic                      i_aib_clk,

  // Master side
  output logic                      o_aib_ms_tx,
  output logic  [  AibIoCnt-1 : 0 ] o_aib_ms_tx_data0,
  output logic  [  AibIoCnt-1 : 0 ] o_aib_ms_tx_data1,

  input  logic                      i_aib_ms_rx,
  input  logic  [  AibIoCnt-1 : 0 ] i_aib_ms_rx_data0,
  input  logic  [  AibIoCnt-1 : 0 ] i_aib_ms_rx_data1,

  // Slave side
  output logic                      o_aib_sl_tx,
  output logic  [  AibIoCnt-1 : 0 ] o_aib_sl_tx_data0,
  output logic  [  AibIoCnt-1 : 0 ] o_aib_sl_tx_data1,

  input  logic                      i_aib_sl_rx,
  input  logic  [  AibIoCnt-1 : 0 ] i_aib_sl_rx_data0,
  input  logic  [  AibIoCnt-1 : 0 ] i_aib_sl_rx_data1
);
  logic rst_n;

  // System clock is always behind AIB clock so let's synchronize to that
  reset_sync rst_sync (.i_clk(i_sys_clk), .i_rst_n(i_rst_n), .o_rst_n(rst_n));

  // ---------------------------------------------------------------------------
  logic                      wb_stall         [4];
  logic                      wb_ack           [4];
  logic  [          31 : 0 ] wb_rdata         [4];

  logic                      aib_ms_tx        [4];
  logic  [  AibIoCnt-1 : 0 ] aib_ms_tx_data0  [4];
  logic  [  AibIoCnt-1 : 0 ] aib_ms_tx_data1  [4];

  logic                      aib_sl_tx        [4];
  logic  [  AibIoCnt-1 : 0 ] aib_sl_tx_data0  [4];
  logic  [  AibIoCnt-1 : 0 ] aib_sl_tx_data1  [4];

  logic  [          31 : 0 ] sram_addr        [4];
  logic                      sram_write       [4];
  logic  [          31 : 0 ] sram_wdata       [4];
  logic  [          31 : 0 ] sram_wmask       [4];
  logic                      sram_read        [4];

  logic  [           3 : 0 ] sel_fifo;

  // ---------------------------------------------------------------------------
  assign /*output*/ o_wb_stall = wb_stall[c_fifo_sel];
  assign /*output*/ o_wb_ack   = wb_ack  [c_fifo_sel];
  assign /*output*/ o_wb_rdata = wb_rdata[c_fifo_sel];

  assign /*output*/ o_aib_ms_tx       = aib_ms_tx      [c_fifo_sel];
  assign /*output*/ o_aib_ms_tx_data0 = aib_ms_tx_data0[c_fifo_sel];
  assign /*output*/ o_aib_ms_tx_data1 = aib_ms_tx_data1[c_fifo_sel];

  assign /*output*/ o_aib_sl_tx       = aib_sl_tx      [c_fifo_sel];
  assign /*output*/ o_aib_sl_tx_data0 = aib_sl_tx_data0[c_fifo_sel];
  assign /*output*/ o_aib_sl_tx_data1 = aib_sl_tx_data1[c_fifo_sel];

  assign /*output*/ o_sram_addr  = sram_addr [c_fifo_sel];
  assign /*output*/ o_sram_write = sram_write[c_fifo_sel];
  assign /*output*/ o_sram_wdata = sram_wdata[c_fifo_sel];
  assign /*output*/ o_sram_wmask = sram_wmask[c_fifo_sel];
  assign /*output*/ o_sram_read  = sram_read [c_fifo_sel];

  assign sel_fifo[0] = (c_fifo_sel == 2'd0);
  assign sel_fifo[1] = (c_fifo_sel == 2'd1);
  assign sel_fifo[2] = (c_fifo_sel == 2'd2);
  assign sel_fifo[3] = (c_fifo_sel == 2'd3);

  // ===========================================================================
  // FIFO Selection 0 - Asynchronous FIFOs for SDR mode
  // ===========================================================================

  aib_wb_adapt_fifo #(
    .AibMode("sdr"), .AibIoCnt(AibIoCnt), .FifoMode("async"))
  u_fifo0 (
    .i_rst_n            (rst_n),

    .i_sys_clk          (i_sys_clk),
    .i_aib_clk          (i_aib_clk),

    .i_en               (sel_fifo[0]),

    .i_wb_stb           (i_wb_stb),
    .i_wb_we            (i_wb_we),
    .i_wb_addr          (i_wb_addr),
    .i_wb_sel           (i_wb_sel),
    .i_wb_wdata         (i_wb_wdata),
    .o_wb_stall         (wb_stall[0]),
    .o_wb_ack           (wb_ack  [0]),
    .o_wb_rdata         (wb_rdata[0]),

    .o_aib_ms_tx        (aib_ms_tx      [0]),
    .o_aib_ms_tx_data0  (aib_ms_tx_data0[0]),
    .o_aib_ms_tx_data1  (aib_ms_tx_data1[0]),

    .i_aib_sl_rx        (i_aib_sl_rx),
    .i_aib_sl_rx_data0  (i_aib_sl_rx_data0),
    .i_aib_sl_rx_data1  (i_aib_sl_rx_data1),

    .i_aib_ms_rx        (i_aib_ms_rx),
    .i_aib_ms_rx_data0  (i_aib_ms_rx_data0),
    .i_aib_ms_rx_data1  (i_aib_ms_rx_data1),

    .o_aib_sl_tx        (aib_sl_tx      [0]),
    .o_aib_sl_tx_data0  (aib_sl_tx_data0[0]),
    .o_aib_sl_tx_data1  (aib_sl_tx_data1[0]),

    .o_sram_addr        (sram_addr [0]),
    .o_sram_write       (sram_write[0]),
    .o_sram_wdata       (sram_wdata[0]),
    .o_sram_wmask       (sram_wmask[0]),
    .o_sram_read        (sram_read [0]),
    .i_sram_rdata       (i_sram_rdata)
  );

  // ===========================================================================
  // FIFO Selection 1 - Asynchronous FIFOs for DDR mode
  // ===========================================================================

  aib_wb_adapt_fifo #(
    .AibMode("ddr"), .AibIoCnt(AibIoCnt), .FifoMode("async"))
  u_fifo1 (
    .i_rst_n            (rst_n),

    .i_sys_clk          (i_sys_clk),
    .i_aib_clk          (i_aib_clk),

    .i_en               (sel_fifo[1]),

    .i_wb_stb           (i_wb_stb),
    .i_wb_we            (i_wb_we),
    .i_wb_addr          (i_wb_addr),
    .i_wb_sel           (i_wb_sel),
    .i_wb_wdata         (i_wb_wdata),
    .o_wb_stall         (wb_stall[1]),
    .o_wb_ack           (wb_ack  [1]),
    .o_wb_rdata         (wb_rdata[1]),

    .o_aib_ms_tx        (aib_ms_tx      [1]),
    .o_aib_ms_tx_data0  (aib_ms_tx_data0[1]),
    .o_aib_ms_tx_data1  (aib_ms_tx_data1[1]),

    .i_aib_sl_rx        (i_aib_sl_rx),
    .i_aib_sl_rx_data0  (i_aib_sl_rx_data0),
    .i_aib_sl_rx_data1  (i_aib_sl_rx_data1),

    .i_aib_ms_rx        (i_aib_ms_rx),
    .i_aib_ms_rx_data0  (i_aib_ms_rx_data0),
    .i_aib_ms_rx_data1  (i_aib_ms_rx_data1),

    .o_aib_sl_tx        (aib_sl_tx      [1]),
    .o_aib_sl_tx_data0  (aib_sl_tx_data0[1]),
    .o_aib_sl_tx_data1  (aib_sl_tx_data1[1]),

    .o_sram_addr        (sram_addr [1]),
    .o_sram_write       (sram_write[1]),
    .o_sram_wdata       (sram_wdata[1]),
    .o_sram_wmask       (sram_wmask[1]),
    .o_sram_read        (sram_read [1]),
    .i_sram_rdata       (i_sram_rdata)
  );

  // ===========================================================================
  // FIFO Selection 2 - Synchronous FIFOs for SDR mode
  // ===========================================================================

  aib_wb_adapt_fifo #(
    .AibMode("sdr"), .AibIoCnt(AibIoCnt), .FifoMode("sync"))
  u_fifo2 (
    .i_rst_n            (rst_n),

    .i_sys_clk          (i_sys_clk),
    .i_aib_clk          (i_aib_clk),

    .i_en               (sel_fifo[2]),

    .i_wb_stb           (i_wb_stb),
    .i_wb_we            (i_wb_we),
    .i_wb_addr          (i_wb_addr),
    .i_wb_sel           (i_wb_sel),
    .i_wb_wdata         (i_wb_wdata),
    .o_wb_stall         (wb_stall[2]),
    .o_wb_ack           (wb_ack  [2]),
    .o_wb_rdata         (wb_rdata[2]),

    .o_aib_ms_tx        (aib_ms_tx      [2]),
    .o_aib_ms_tx_data0  (aib_ms_tx_data0[2]),
    .o_aib_ms_tx_data1  (aib_ms_tx_data1[2]),

    .i_aib_sl_rx        (i_aib_sl_rx),
    .i_aib_sl_rx_data0  (i_aib_sl_rx_data0),
    .i_aib_sl_rx_data1  (i_aib_sl_rx_data1),

    .i_aib_ms_rx        (i_aib_ms_rx),
    .i_aib_ms_rx_data0  (i_aib_ms_rx_data0),
    .i_aib_ms_rx_data1  (i_aib_ms_rx_data1),

    .o_aib_sl_tx        (aib_sl_tx      [2]),
    .o_aib_sl_tx_data0  (aib_sl_tx_data0[2]),
    .o_aib_sl_tx_data1  (aib_sl_tx_data1[2]),

    .o_sram_addr        (sram_addr [2]),
    .o_sram_write       (sram_write[2]),
    .o_sram_wdata       (sram_wdata[2]),
    .o_sram_wmask       (sram_wmask[2]),
    .o_sram_read        (sram_read [2]),
    .i_sram_rdata       (i_sram_rdata)
  );

  // ===========================================================================
  // FIFO Selection 3 - Synchronous FIFOs for DDR mode
  // ===========================================================================

  aib_wb_adapt_fifo #(
    .AibMode("ddr"), .AibIoCnt(AibIoCnt), .FifoMode("sync"))
  u_fifo3 (
    .i_rst_n            (rst_n),

    .i_sys_clk          (i_sys_clk),
    .i_aib_clk          (i_aib_clk),

    .i_en               (sel_fifo[3]),

    .i_wb_stb           (i_wb_stb),
    .i_wb_we            (i_wb_we),
    .i_wb_addr          (i_wb_addr),
    .i_wb_sel           (i_wb_sel),
    .i_wb_wdata         (i_wb_wdata),
    .o_wb_stall         (wb_stall[3]),
    .o_wb_ack           (wb_ack  [3]),
    .o_wb_rdata         (wb_rdata[3]),

    .o_aib_ms_tx        (aib_ms_tx      [3]),
    .o_aib_ms_tx_data0  (aib_ms_tx_data0[3]),
    .o_aib_ms_tx_data1  (aib_ms_tx_data1[3]),

    .i_aib_sl_rx        (i_aib_sl_rx),
    .i_aib_sl_rx_data0  (i_aib_sl_rx_data0),
    .i_aib_sl_rx_data1  (i_aib_sl_rx_data1),

    .i_aib_ms_rx        (i_aib_ms_rx),
    .i_aib_ms_rx_data0  (i_aib_ms_rx_data0),
    .i_aib_ms_rx_data1  (i_aib_ms_rx_data1),

    .o_aib_sl_tx        (aib_sl_tx      [3]),
    .o_aib_sl_tx_data0  (aib_sl_tx_data0[3]),
    .o_aib_sl_tx_data1  (aib_sl_tx_data1[3]),

    .o_sram_addr        (sram_addr [3]),
    .o_sram_write       (sram_write[3]),
    .o_sram_wdata       (sram_wdata[3]),
    .o_sram_wmask       (sram_wmask[3]),
    .o_sram_read        (sram_read [3]),
    .i_sram_rdata       (i_sram_rdata)
  );

endmodule

