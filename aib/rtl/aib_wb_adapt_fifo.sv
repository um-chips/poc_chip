
module aib_wb_adapt_fifo #(parameter AibMode  = "sdr",
                           parameter AibIoCnt = 20,
                           parameter FifoMode = "async")
(
  input  logic                      i_rst_n,

  input  logic                      i_sys_clk,
  input  logic                      i_aib_clk,

  input  logic                      i_en,

  input  logic                      i_wb_stb,
  input  logic                      i_wb_we,
  input  logic  [          31 : 0 ] i_wb_addr,
  input  logic  [           3 : 0 ] i_wb_sel,
  input  logic  [          31 : 0 ] i_wb_wdata,
  output logic                      o_wb_stall,
  output logic                      o_wb_ack,
  output logic  [          31 : 0 ] o_wb_rdata,

  // Master to slave AIB interface
  output logic                      o_aib_ms_tx,
  output logic  [  AibIoCnt-1 : 0 ] o_aib_ms_tx_data0,
  output logic  [  AibIoCnt-1 : 0 ] o_aib_ms_tx_data1,

  input  logic                      i_aib_sl_rx,
  input  logic  [  AibIoCnt-1 : 0 ] i_aib_sl_rx_data0,
  input  logic  [  AibIoCnt-1 : 0 ] i_aib_sl_rx_data1,

  // Slave to master AIB interface
  input  logic                      i_aib_ms_rx,
  input  logic  [  AibIoCnt-1 : 0 ] i_aib_ms_rx_data0,
  input  logic  [  AibIoCnt-1 : 0 ] i_aib_ms_rx_data1,

  output logic                      o_aib_sl_tx,
  output logic  [  AibIoCnt-1 : 0 ] o_aib_sl_tx_data0,
  output logic  [  AibIoCnt-1 : 0 ] o_aib_sl_tx_data1,

  output logic  [          31 : 0 ] o_sram_addr,
  output logic                      o_sram_write,
  output logic  [          31 : 0 ] o_sram_wdata,
  output logic  [          31 : 0 ] o_sram_wmask,
  output logic                      o_sram_read,
  input  logic  [          31 : 0 ] i_sram_rdata
);
  // round( ceil(69/(AibIoCnt-1))*AibIoCnt, 2*AibIoCnt )
  localparam SysMsDataW = (AibIoCnt == 20) ? 80 : 96;
  // round( ceil(32/(AibIoCnt-1))*AibIoCnt, 2*AibIoCnt )
  localparam SysSlDataW = (AibIoCnt == 20) ? 40 : 48;
  localparam AibDataW   = (AibMode == "sdr") ? AibIoCnt : 2*AibIoCnt;

  // ---------------------------------------------------------------------------
  logic wb_wack_d, wb_wack_q;
  logic wb_rack;

  logic sram_rdata_valid_d, sram_rdata_valid_q;

  // ===========================================================================
  // Master to slave
  // ===========================================================================

  // TX side
  // ---------------------------------------------------------------------------
  logic                       m2s_fifo_tx_full;
  logic                       m2s_fifo_tx_empty;
  logic                       m2s_fifo_tx_write;
  logic [  SysMsDataW-1 : 0 ] m2s_fifo_tx_wdata;
  logic                       m2s_fifo_tx_read;
  logic [    AibDataW-1 : 0 ] m2s_fifo_tx_rdata;

  // FIFO write control
  assign m2s_fifo_tx_write = i_en & i_wb_stb & !m2s_fifo_tx_full;
if (AibIoCnt == 20)
  assign m2s_fifo_tx_wdata = {
    1'b1, 6'b0, i_wb_wdata[31:19],
    1'b1, i_wb_wdata[18:0],
    1'b1, 1'b0, i_wb_sel, i_wb_addr[31:18],
    1'b1, i_wb_addr[17:0], i_wb_we
  };
else
  assign m2s_fifo_tx_wdata = {
    1'b1, 3'b0,              1'b1, i_wb_wdata[31:29],
    1'b1, i_wb_wdata[28:26], 1'b1, i_wb_wdata[25:23],
    1'b1, i_wb_wdata[22:20], 1'b1, i_wb_wdata[19:17],
    1'b1, i_wb_wdata[16:14], 1'b1, i_wb_wdata[13:11],
    1'b1, i_wb_wdata[10: 8], 1'b1, i_wb_wdata[ 7: 5],
    1'b1, i_wb_wdata[ 4: 2], 1'b1, i_wb_wdata[ 1: 0], i_wb_sel[3],
    1'b1, i_wb_sel  [ 2: 0], 1'b1, i_wb_addr [31:29],
    1'b1, i_wb_addr [28:26], 1'b1, i_wb_addr [25:23],
    1'b1, i_wb_addr [22:20], 1'b1, i_wb_addr [19:17],
    1'b1, i_wb_addr [16:14], 1'b1, i_wb_addr [13:11],
    1'b1, i_wb_addr [10: 8], 1'b1, i_wb_addr [ 7: 5],
    1'b1, i_wb_addr [ 4: 2], 1'b1, i_wb_addr [ 1: 0], i_wb_we
  };

  // FIFO read control
  assign m2s_fifo_tx_read = !m2s_fifo_tx_empty;

  // FIFO instance
if (FifoMode == "async")
  DW_asymfifo_s2_sf #(
    .data_in_width (SysMsDataW),
    .data_out_width(AibDataW),
    .depth         (4),
    .push_sync     (1),
    .pop_sync      (1),
    .rst_mode      (0),
    .byte_order    (1)
  ) u_m2s_fifo_tx (
    .rst_n      (i_rst_n),

    .flush_n    (1'b1),
    .ram_full   (/*ignored*/),
    .part_wd    (/*ignored*/),

    .clk_push   (i_sys_clk),
    .data_in    ( m2s_fifo_tx_wdata),
    .push_req_n (~m2s_fifo_tx_write),
    .push_empty (/*ignored*/),
    .push_full  ( m2s_fifo_tx_full),
    .push_ae    (/*ignored*/),
    .push_hf    (/*ignored*/),
    .push_af    (/*ignored*/),
    .push_error (/*ignored*/),

    .clk_pop    (i_aib_clk),
    .data_out   ( m2s_fifo_tx_rdata),
    .pop_req_n  (~m2s_fifo_tx_read),
    .pop_empty  ( m2s_fifo_tx_empty),
    .pop_full   (/*ignored*/),
    .pop_ae     (/*ignored*/),
    .pop_hf     (/*ignored*/),
    .pop_af     (/*ignored*/),
    .pop_error  (/*ignored*/)
  );
else
  fifo_asym #(
    .WidthW(SysMsDataW),
    .WidthR(AibDataW),
    .Depth(4)
  ) u_m2s_fifo_tx (
    .i_rst_n    (i_rst_n),

    .i_wclk     (i_sys_clk),
    .i_write    (m2s_fifo_tx_write),
    .i_wdata    (m2s_fifo_tx_wdata),
    .o_full     (m2s_fifo_tx_full),

    .i_rclk     (i_aib_clk),
    .i_read     (m2s_fifo_tx_read),
    .o_rdata    (m2s_fifo_tx_rdata),
    .o_empty    (m2s_fifo_tx_empty)
  );

  // RX side
  // ---------------------------------------------------------------------------
  logic                       m2s_fifo_rx_empty;
  logic                       m2s_fifo_rx_write;
  logic [    AibDataW-1 : 0 ] m2s_fifo_rx_wdata;
  logic                       m2s_fifo_rx_read;
  logic [  SysMsDataW-1 : 0 ] m2s_fifo_rx_rdata;

  // FIFO write control
  assign m2s_fifo_rx_write = i_aib_sl_rx & i_aib_sl_rx_data0[AibIoCnt-1];
if (AibMode == "sdr")
  assign m2s_fifo_rx_wdata = i_aib_sl_rx_data0;
else
  assign m2s_fifo_rx_wdata = {i_aib_sl_rx_data1, i_aib_sl_rx_data0};

  // FIFO read control
  assign m2s_fifo_rx_read = !m2s_fifo_rx_empty;

if (FifoMode == "async")
  // FIFO instance
  DW_asymfifo_s2_sf #(
    .data_in_width (AibDataW),
    .data_out_width(SysMsDataW),
    .depth         (4),
    .push_sync     (1),
    .pop_sync      (1),
    .rst_mode      (0),
    .byte_order    (1)
  ) u_m2s_fifo_rx (
    .rst_n      (i_rst_n),

    .flush_n    (1'b1),
    .ram_full   (/*ignored*/),
    .part_wd    (/*ignored*/),

    .clk_push   (i_aib_clk),
    .data_in    ( m2s_fifo_rx_wdata),
    .push_req_n (~m2s_fifo_rx_write),
    .push_empty (/*ignored*/),
    .push_full  (/*ignored*/),
    .push_ae    (/*ignored*/),
    .push_hf    (/*ignored*/),
    .push_af    (/*ignored*/),
    .push_error (/*ignored*/),

    .clk_pop    (i_sys_clk),
    .data_out   ( m2s_fifo_rx_rdata),
    .pop_req_n  (~m2s_fifo_rx_read),
    .pop_empty  ( m2s_fifo_rx_empty),
    .pop_full   (/*ignored*/),
    .pop_ae     (/*ignored*/),
    .pop_hf     (/*ignored*/),
    .pop_af     (/*ignored*/),
    .pop_error  (/*ignored*/)
  );
else
  fifo_asym #(
    .WidthW(AibDataW),
    .WidthR(SysMsDataW),
    .Depth(4)
  ) u_m2s_fifo_rx (
    .i_rst_n    (i_rst_n),

    .i_wclk     (i_aib_clk),
    .i_write    (m2s_fifo_rx_write),
    .i_wdata    (m2s_fifo_rx_wdata),
    .o_full     (),

    .i_rclk     (i_sys_clk),
    .i_read     (m2s_fifo_rx_read),
    .o_rdata    (m2s_fifo_rx_rdata),
    .o_empty    (m2s_fifo_rx_empty)
  );

  // ===========================================================================
  // Slave to master
  // ===========================================================================

  // TX side
  // ---------------------------------------------------------------------------
  logic                       s2m_fifo_tx_empty;
  logic                       s2m_fifo_tx_write;
  logic [  SysSlDataW-1 : 0 ] s2m_fifo_tx_wdata;
  logic                       s2m_fifo_tx_read;
  logic [    AibDataW-1 : 0 ] s2m_fifo_tx_rdata;

  // FIFO write control
  assign s2m_fifo_tx_write = sram_rdata_valid_q;
if (AibIoCnt == 20)
  assign s2m_fifo_tx_wdata = {
    1'b1, 6'b0, i_sram_rdata[31:19],
    1'b1, i_sram_rdata[18:0]
  };
else
  assign s2m_fifo_tx_wdata = {
    1'b1, 3'b0,                1'b1, 1'b0, i_sram_rdata[31:30],
    1'b1, i_sram_rdata[29:27], 1'b1,       i_sram_rdata[26:24],
    1'b1, i_sram_rdata[23:21], 1'b1,       i_sram_rdata[20:18],
    1'b1, i_sram_rdata[17:15], 1'b1,       i_sram_rdata[14:12],
    1'b1, i_sram_rdata[11: 9], 1'b1,       i_sram_rdata[ 8: 6],
    1'b1, i_sram_rdata[ 5: 3], 1'b1,       i_sram_rdata[ 2: 0]
  };

  // FIFO read control
  assign s2m_fifo_tx_read = !s2m_fifo_tx_empty;

if (FifoMode == "async")
  // FIFO instance
  DW_asymfifo_s2_sf #(
    .data_in_width (SysSlDataW),
    .data_out_width(AibDataW),
    .depth         (4),
    .push_sync     (1),
    .pop_sync      (1),
    .rst_mode      (0),
    .byte_order    (1)
  ) u_s2m_fifo_tx (
    .rst_n      (i_rst_n),

    .flush_n    (1'b1),
    .ram_full   (/*ignored*/),
    .part_wd    (/*ignored*/),

    .clk_push   (i_sys_clk),
    .data_in    ( s2m_fifo_tx_wdata),
    .push_req_n (~s2m_fifo_tx_write),
    .push_empty (/*ignored*/),
    .push_full  (/*ignored*/),
    .push_ae    (/*ignored*/),
    .push_hf    (/*ignored*/),
    .push_af    (/*ignored*/),
    .push_error (/*ignored*/),

    .clk_pop    (i_aib_clk),
    .data_out   ( s2m_fifo_tx_rdata),
    .pop_req_n  (~s2m_fifo_tx_read),
    .pop_empty  ( s2m_fifo_tx_empty),
    .pop_full   (/*ignored*/),
    .pop_ae     (/*ignored*/),
    .pop_hf     (/*ignored*/),
    .pop_af     (/*ignored*/),
    .pop_error  (/*ignored*/)
  );
else
  fifo_asym #(
    .WidthW(SysSlDataW),
    .WidthR(AibDataW),
    .Depth(4)
  ) u_s2m_fifo_tx (
    .i_rst_n    (i_rst_n),

    .i_wclk     (i_sys_clk),
    .i_write    (s2m_fifo_tx_write),
    .i_wdata    (s2m_fifo_tx_wdata),
    .o_full     (),

    .i_rclk     (i_aib_clk),
    .i_read     (s2m_fifo_tx_read),
    .o_rdata    (s2m_fifo_tx_rdata),
    .o_empty    (s2m_fifo_tx_empty)
  );

  // RX side
  // ---------------------------------------------------------------------------
  logic                       s2m_fifo_rx_empty;
  logic                       s2m_fifo_rx_write;
  logic [    AibDataW-1 : 0 ] s2m_fifo_rx_wdata;
  logic                       s2m_fifo_rx_read;
  logic [  SysSlDataW-1 : 0 ] s2m_fifo_rx_rdata;

  // FIFO write control
  assign s2m_fifo_rx_write = i_aib_ms_rx & i_aib_ms_rx_data0[AibIoCnt-1];
if (AibMode == "sdr")
  assign s2m_fifo_rx_wdata = i_aib_ms_rx_data0;
else
  assign s2m_fifo_rx_wdata = {i_aib_ms_rx_data1, i_aib_ms_rx_data0};

  // FIFO read control
  assign s2m_fifo_rx_read = !s2m_fifo_rx_empty;

if (FifoMode == "async")
  // FIFO instance
  DW_asymfifo_s2_sf #(
    .data_in_width (AibDataW),
    .data_out_width(SysSlDataW),
    .depth         (4),
    .push_sync     (1),
    .pop_sync      (1),
    .rst_mode      (0),
    .byte_order    (1)
  ) u_s2m_fifo_rx (
    .rst_n      (i_rst_n),

    .flush_n    (1'b1),
    .ram_full   (/*ignored*/),
    .part_wd    (/*ignored*/),

    .clk_push   (i_aib_clk),
    .data_in    ( s2m_fifo_rx_wdata),
    .push_req_n (~s2m_fifo_rx_write),
    .push_empty (/*ignored*/),
    .push_full  (/*ignored*/),
    .push_ae    (/*ignored*/),
    .push_hf    (/*ignored*/),
    .push_af    (/*ignored*/),
    .push_error (/*ignored*/),

    .clk_pop    (i_sys_clk),
    .data_out   ( s2m_fifo_rx_rdata),
    .pop_req_n  (~s2m_fifo_rx_read),
    .pop_empty  ( s2m_fifo_rx_empty),
    .pop_full   (/*ignored*/),
    .pop_ae     (/*ignored*/),
    .pop_hf     (/*ignored*/),
    .pop_af     (/*ignored*/),
    .pop_error  (/*ignored*/)
  );
else
  fifo_asym #(
    .WidthW(AibDataW),
    .WidthR(SysSlDataW),
    .Depth(4)
  ) u_s2m_fifo_rx (
    .i_rst_n    (i_rst_n),

    .i_wclk     (i_aib_clk),
    .i_write    (s2m_fifo_rx_write),
    .i_wdata    (s2m_fifo_rx_wdata),
    .o_full     (),

    .i_rclk     (i_sys_clk),
    .i_read     (s2m_fifo_rx_read),
    .o_rdata    (s2m_fifo_rx_rdata),
    .o_empty    (s2m_fifo_rx_empty)
  );

  // ---------------------------------------------------------------------------
  assign /*output*/ o_wb_stall = m2s_fifo_tx_full;
  assign /*output*/ o_wb_ack   = wb_wack_q | wb_rack;
if (AibIoCnt == 20)
  assign /*output*/ o_wb_rdata= {s2m_fifo_rx_rdata[32:20],
                                 s2m_fifo_rx_rdata[18:0]};
else
  assign /*output*/ o_wb_rdata= {
                              s2m_fifo_rx_rdata[41:40],
    s2m_fifo_rx_rdata[38:36], s2m_fifo_rx_rdata[34:32],
    s2m_fifo_rx_rdata[30:28], s2m_fifo_rx_rdata[26:24],
    s2m_fifo_rx_rdata[22:20], s2m_fifo_rx_rdata[18:16],
    s2m_fifo_rx_rdata[14:12], s2m_fifo_rx_rdata[10: 8],
    s2m_fifo_rx_rdata[ 6: 4], s2m_fifo_rx_rdata[ 2: 0]
  };

  assign /*output*/ o_aib_ms_tx       = m2s_fifo_tx_read;
if (AibMode == "sdr") begin
  assign /*output*/ o_aib_ms_tx_data0 = m2s_fifo_tx_rdata;
  assign /*output*/ o_aib_ms_tx_data1 = 'd0;
end
else begin
  assign /*output*/ o_aib_ms_tx_data0 = m2s_fifo_tx_rdata[       0+:AibIoCnt];
  assign /*output*/ o_aib_ms_tx_data1 = m2s_fifo_tx_rdata[AibIoCnt+:AibIoCnt];
end

  assign /*output*/ o_aib_sl_tx       = s2m_fifo_tx_read;
if (AibMode == "sdr") begin
  assign /*output*/ o_aib_sl_tx_data0 = s2m_fifo_tx_rdata;
  assign /*output*/ o_aib_sl_tx_data1 = 'd0;
end
else begin
  assign /*output*/ o_aib_sl_tx_data0 = s2m_fifo_tx_rdata[       0+:AibIoCnt];
  assign /*output*/ o_aib_sl_tx_data1 = s2m_fifo_tx_rdata[AibIoCnt+:AibIoCnt];
end

  assign /*output*/ o_sram_write = m2s_fifo_rx_read &  m2s_fifo_rx_rdata[0];
  assign /*output*/ o_sram_read  = m2s_fifo_rx_read & !m2s_fifo_rx_rdata[0];
if (AibIoCnt == 20) begin
  assign /*output*/ o_sram_addr  = {m2s_fifo_rx_rdata[33:20],
                                    m2s_fifo_rx_rdata[18:1]};
  assign /*output*/ o_sram_wdata = {m2s_fifo_rx_rdata[72:60],
                                    m2s_fifo_rx_rdata[58:40]};
  assign /*output*/ o_sram_wmask = {{8{m2s_fifo_rx_rdata[37]}},
                                    {8{m2s_fifo_rx_rdata[36]}},
                                    {8{m2s_fifo_rx_rdata[35]}},
                                    {8{m2s_fifo_rx_rdata[34]}}};
end
else begin
  assign /*output*/ o_sram_addr  = {
                              m2s_fifo_rx_rdata[42:40],
    m2s_fifo_rx_rdata[38:36], m2s_fifo_rx_rdata[34:32],
    m2s_fifo_rx_rdata[30:28], m2s_fifo_rx_rdata[26:24],
    m2s_fifo_rx_rdata[22:20], m2s_fifo_rx_rdata[18:16],
    m2s_fifo_rx_rdata[14:12], m2s_fifo_rx_rdata[10: 8],
    m2s_fifo_rx_rdata[ 6: 4], m2s_fifo_rx_rdata[ 2: 1]
  };
  assign /*output*/ o_sram_wdata = {
                              m2s_fifo_rx_rdata[90:88],
    m2s_fifo_rx_rdata[86:84], m2s_fifo_rx_rdata[82:80],
    m2s_fifo_rx_rdata[78:76], m2s_fifo_rx_rdata[74:72],
    m2s_fifo_rx_rdata[70:68], m2s_fifo_rx_rdata[66:64],
    m2s_fifo_rx_rdata[62:60], m2s_fifo_rx_rdata[58:56],
    m2s_fifo_rx_rdata[54:52], m2s_fifo_rx_rdata[50:49]
  };
  assign /*output*/ o_sram_wmask = {{8{m2s_fifo_rx_rdata[48]}},
                                    {8{m2s_fifo_rx_rdata[46]}},
                                    {8{m2s_fifo_rx_rdata[45]}},
                                    {8{m2s_fifo_rx_rdata[44]}}};
end

  // ---------------------------------------------------------------------------
  // Notice that stall will be asserted with ack when writing to the last
  // FIFO entry, but OpenRISC seems fine with this behavior
  assign wb_wack_d = i_wb_stb & i_wb_we & !o_wb_stall;
  assign wb_rack   = s2m_fifo_rx_read;

  assign sram_rdata_valid_d = o_sram_read;

  // ---------------------------------------------------------------------------
  always_ff @(posedge i_sys_clk or negedge i_rst_n)
    if (!i_rst_n) begin
      wb_wack_q <= 1'b0;

      sram_rdata_valid_q <= 1'b0;
    end
    else begin
      wb_wack_q <= wb_wack_d;

      sram_rdata_valid_q <= sram_rdata_valid_d;
    end

endmodule

