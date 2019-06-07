
`ifndef AFIFO_RD_V
`define AFIFO_RD_V

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module afifo_rd #(parameter Width   = 8,
                  parameter Depth   = 4,
                  // Do not modify the following parameters from higher hierarchy
                  parameter PtrMsb  = $clog2(Depth)-1,
                  parameter BusMsb  = (Width*Depth-1))
(
  input                           i_clk,
  input                           i_rst_n,

  input         [         1 : 0 ] cfg_sync_stages,

  output                          o_empty,

  input                           i_pop,
  output        [   Width-1 : 0 ] o_pop_data,

  input         [   Depth-1 : 0 ] i_wr_toggle,
  output        [   Depth-1 : 0 ] o_rd_toggle,
  input         [    BusMsb : 0 ] i_bus
);
  // Signal declarations
  // ---------------------------------------------------------------------------
  logic         [    PtrMsb : 0 ] rptr_w;
  logic         [    PtrMsb : 0 ] rptr_r;

  logic         [   Width-1 : 0 ] rdata_w;
  logic         [   Width-1 : 0 ] rdata_r;

  logic         [   Depth-1 : 0 ] wr_toggle       [3:0];
  logic         [   Depth-1 : 0 ] wr_toggle_syncd [3:0];
  logic         [   Depth-1 : 0 ] wr_toggle_sel;

  logic         [   Depth-1 : 0 ] rd_toggle_w;
  logic         [   Depth-1 : 0 ] rd_toggle_r;

  logic                           capture_rdata;

  // Output assignments
  // ---------------------------------------------------------------------------
  assign /*output*/ o_empty = (wr_toggle_sel[rptr_r] == rd_toggle_r[rptr_r]);

`ifdef SINGLE_CLK
  assign /*output*/ o_pop_data = i_bus[Width*rptr_r+:Width];
`else
  assign /*output*/ o_pop_data = rdata_r;//i_bus[Width*rptr_r+:Width];
`endif

  assign /*output*/ o_rd_toggle = rd_toggle_r;

  // ---------------------------------------------------------------------------
  always_comb begin
    rptr_w      = rptr_r;
    rd_toggle_w = rd_toggle_r;

    if (i_pop & !o_empty) begin
      rptr_w              = rptr_r + 1;
      rd_toggle_w[rptr_r] = ~rd_toggle_r[rptr_r];
    end
  end

  always_comb begin
    capture_rdata = 1'b0;

    for (int i = 0; i < 4; i++)
      if (wr_toggle[i] != rd_toggle_r || wr_toggle_syncd[i] != rd_toggle_r)
        capture_rdata = 1'b1;
  end

  assign rdata_w = capture_rdata ? i_bus[Width*rptr_w +: Width] : rdata_r;

  // Select how many stages should the toggle bits be synchronized
  assign wr_toggle_sel = wr_toggle_syncd[cfg_sync_stages];

  always_comb
    for (int i = 0; i < 4; i++)
      if (i == 0)
        wr_toggle[i] = i_wr_toggle;
      else
        wr_toggle[i] = wr_toggle_syncd[i-1];

  sync #(.Depth(Depth)) u_wr_tgl_sync [3:0] (
    .i_clk                  (i_clk),
    .i_rst_n                (i_rst_n),

    .i_in                   (wr_toggle),
    .o_out                  (wr_toggle_syncd)
  );

  // Flip flops
  // ---------------------------------------------------------------------------
`ifdef FPGA
  always_ff @(posedge i_clk or negedge i_rst_n)
`else
  // synopsys sync_set_reset "i_rst_n"
  always_ff @(posedge i_clk)
`endif
    if (!i_rst_n) begin
      rptr_r                <= 'd0;
      rdata_r               <= 'd0;
      rd_toggle_r           <= 'd0;
    end
    else begin
      rptr_r                <= rptr_w;
      rdata_r               <= rdata_w;
      rd_toggle_r           <= rd_toggle_w;
    end

endmodule

`endif // AFIFO_RD_V

