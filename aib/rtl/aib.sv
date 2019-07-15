
`ifdef NOESD
module aib_noesd #(parameter NumIo = 58)
`elsif ESD
module aib_esd #(parameter NumIo = 58)
`elsif INTERPOSER
module aib_interposer #(parameter NumIo = 58)
`else
module aib #(parameter NumIo = 58)
`endif
(
  input  logic                  i_rst_n,

  input  logic                  i_bypass,
  input  logic                  i_bypass_clk,

  output logic                  o_aib_slow_clk,
  output logic                  o_aux_slow_clk,

  output logic                  o_uart_tx_aib,
  input  logic                  i_uart_rx_aib,

  output logic                  o_uart_tx_dbg,
  input  logic                  i_uart_rx_dbg,

  output logic                  o_uart_tx_cpu,
  input  logic                  i_uart_rx_cpu,

  inout  wire   [ NumIo-1 : 0 ] io_bump,

  // Probing signals for the testbench, should not be connected anywhere else
  output logic                  o_probe_aib_clk,
  output logic                  o_probe_aux_clk,
  output logic                  o_probe_sys_clk
);
  // ---------------------------------------------------------------------------
  logic                     aib_clk;
  logic                     aux_clk;

  logic                     sys_clk;
  logic                     sys_rst_n;
  logic                     adapt_rst_n;

  logic [           2 : 0 ] chn_mode;
  logic [           1 : 0 ] fifo_mode;

  logic                     aib_stb;
  logic                     aib_we;
  logic [          31 : 0 ] aib_addr;
  logic [           3 : 0 ] aib_sel;
  logic [          31 : 0 ] aib_wdata;
  logic                     aib_stall;
  logic                     aib_ack;
  logic [          31 : 0 ] aib_rdata;

  logic                     aib_penable;
  logic                     aib_pwrite;
  logic [          31 : 0 ] aib_paddr;
  logic [          31 : 0 ] aib_pwdata;
  logic                     aib_pready;
  logic [          31 : 0 ] aib_prdata;

  logic                     ms_tx_valid;
  logic [   `AIB_IO-1 : 0 ] ms_tx_data0;
  logic [   `AIB_IO-1 : 0 ] ms_tx_data1;

  logic                     sl_tx_valid;
  logic [   `AIB_IO-1 : 0 ] sl_tx_data0;
  logic [   `AIB_IO-1 : 0 ] sl_tx_data1;

  logic [          19 : 0 ] tx_data0;
  logic [          19 : 0 ] tx_data1;

  logic [          19 : 0 ] rx_data0;
  logic [          19 : 0 ] rx_data1;

  logic [          31 : 0 ] mem_addr;
  logic                     mem_write;
  logic [          31 : 0 ] mem_wdata;
  logic [          31 : 0 ] mem_wmask;
  logic                     mem_read;
  logic [          31 : 0 ] mem_rdata;

  // ---------------------------------------------------------------------------
  assign /*output*/ o_probe_aib_clk = aib_clk;
  assign /*output*/ o_probe_aux_clk = aux_clk;
  assign /*output*/ o_probe_sys_clk = sys_clk;

  // ---------------------------------------------------------------------------
if (`AIB_IO == 20) begin
  assign tx_data0 = chn_mode[2] ? {20{ms_tx_valid}} & ms_tx_data0 :
                                  {20{sl_tx_valid}} & sl_tx_data0;
  assign tx_data1 = chn_mode[2] ? {20{ms_tx_valid}} & ms_tx_data1 :
                                  {20{sl_tx_valid}} & sl_tx_data1;
end
else begin
  assign tx_data0 = chn_mode[2] ? {20{ms_tx_valid}} & {16'b0, ms_tx_data0} :
                                  {20{sl_tx_valid}} & {16'b0, sl_tx_data0};
  assign tx_data1 = chn_mode[2] ? {20{ms_tx_valid}} & {16'b0, ms_tx_data1} :
                                  {20{sl_tx_valid}} & {16'b0, sl_tx_data1};
end

  aib_channel #(.NumIo(NumIo), .AibIoCnt(`AIB_IO)) u_aib_channel (
    .i_rst_n        (i_rst_n),

    .o_uart_tx      (o_uart_tx_aib),
    .i_uart_rx      (i_uart_rx_aib),

    .i_bypass       (i_bypass),
    .i_bypass_clk   (i_bypass_clk),

    .o_aib_slow_clk (o_aib_slow_clk),
    .o_aux_slow_clk (o_aux_slow_clk),

    .io_bump        (io_bump),

    .o_aib_clk      (aib_clk),
    .o_aux_clk      (aux_clk),

    .o_sys_clk      (sys_clk),
    .o_sys_rst_n    (sys_rst_n),
    .o_adapt_rst_n  (adapt_rst_n),

    .o_ready        (),

    .c_chn_mode     (chn_mode),
    .c_fifo_mode    (fifo_mode),

    .i_tx_data0     (tx_data0),
    .i_tx_data1     (tx_data1),

    .o_rx_data0     (rx_data0),
    .o_rx_data1     (rx_data1)
  );

  // ---------------------------------------------------------------------------
  cpu u_cpu (
    .i_clk          (sys_clk),
    .i_rst_n        (sys_rst_n),

    .o_uart_tx_dbg  (o_uart_tx_dbg),
    .i_uart_rx_dbg  (i_uart_rx_dbg),

    .o_uart_tx_cpu  (o_uart_tx_cpu),
    .i_uart_rx_cpu  (i_uart_rx_cpu),

    .o_aib_stb      (aib_stb),
    .o_aib_we       (aib_we),
    .o_aib_addr     (aib_addr),
    .o_aib_sel      (aib_sel),
    .o_aib_wdata    (aib_wdata),
    .i_aib_stall    (aib_stall),
    .i_aib_ack      (aib_ack),
    .i_aib_rdata    (aib_rdata),

    .o_aib_penable  (aib_penable),
    .o_aib_pwrite   (aib_pwrite),
    .o_aib_paddr    (aib_paddr),
    .o_aib_pwdata   (aib_pwdata),
    .i_aib_pready   (aib_pready),
    .i_aib_prdata   (aib_prdata)
  );

  // ---------------------------------------------------------------------------
  aib_wb_adapt #(.AibIoCnt(`AIB_IO)) u_aib_wb_adapt (
    .i_rst_n            (adapt_rst_n),

    .c_fifo_sel         (fifo_mode),

    // System clock domain
    // -------------------------------------------------------------------------
    .i_sys_clk          (sys_clk),

    .i_wb_stb           (aib_stb),
    .i_wb_we            (aib_we),
    .i_wb_addr          (aib_addr),
    .i_wb_sel           (aib_sel),
    .i_wb_wdata         (aib_wdata),
    .o_wb_stall         (aib_stall),
    .o_wb_ack           (aib_ack),
    .o_wb_rdata         (aib_rdata),

    .o_sram_addr        (mem_addr),
    .o_sram_write       (mem_write),
    .o_sram_wdata       (mem_wdata),
    .o_sram_wmask       (mem_wmask),
    .o_sram_read        (mem_read),
    .i_sram_rdata       (mem_rdata),

    // AIB clock domain
    // -------------------------------------------------------------------------
    .i_aib_clk          (aib_clk),

    // Master side
    .o_aib_ms_tx        (ms_tx_valid),
    .o_aib_ms_tx_data0  (ms_tx_data0),
    .o_aib_ms_tx_data1  (ms_tx_data1),

    .i_aib_ms_rx        (chn_mode[2]),
    .i_aib_ms_rx_data0  (rx_data0[`AIB_IO-1:0]),
    .i_aib_ms_rx_data1  (rx_data1[`AIB_IO-1:0]),

    // Slave side
    .o_aib_sl_tx        (sl_tx_valid),
    .o_aib_sl_tx_data0  (sl_tx_data0),
    .o_aib_sl_tx_data1  (sl_tx_data1),

    .i_aib_sl_rx        (~chn_mode[2]),
    .i_aib_sl_rx_data0  (rx_data0[`AIB_IO-1:0]),
    .i_aib_sl_rx_data1  (rx_data1[`AIB_IO-1:0])
  );

  // ---------------------------------------------------------------------------
  aib_sram u_aib_sram (
    .i_clk              (sys_clk),
    .i_rst_n            (sys_rst_n),

    .i_mem_addr         (mem_addr),
    .i_mem_write        (mem_write),
    .i_mem_wdata        (mem_wdata),
    .i_mem_wmask        (mem_wmask),
    .i_mem_read         (mem_read),
    .o_mem_rdata        (mem_rdata),

    .i_penable          (aib_penable),
    .i_pwrite           (aib_pwrite),
    .i_paddr            (aib_paddr),
    .i_pwdata           (aib_pwdata),
    .o_pready           (aib_pready),
    .o_prdata           (aib_prdata)
  );
endmodule

