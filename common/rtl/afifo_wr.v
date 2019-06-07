
`ifndef AFIFO_WR_V
`define AFIFO_WR_V

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module afifo_wr #(parameter Width   = 8,
                  parameter Depth   = 4,
                  // Do not modify the following parameters from higher hierarchy
                  parameter PtrMsb  = $clog2(Depth)-1,
                  parameter BusMsb  = (Width*Depth-1))
(
  input                           i_clk,
  input                           i_rst_n,

  input         [         1 : 0 ] cfg_sync_stages,

  output                          o_full,

  input                           i_push,
  input         [   Width-1 : 0 ] i_push_bwe,
  input         [   Width-1 : 0 ] i_push_data,

  output        [   Depth-1 : 0 ] o_wr_toggle,
  input         [   Depth-1 : 0 ] i_rd_toggle,
  output logic  [    BusMsb : 0 ] o_bus
);
  // Signal declarations
  // ---------------------------------------------------------------------------
  logic         [   Width-1 : 0 ] mem_w   [   Depth-1 : 0 ];
  logic         [   Width-1 : 0 ] mem_r   [   Depth-1 : 0 ];

  logic         [    PtrMsb : 0 ] wptr_w;
  logic         [    PtrMsb : 0 ] wptr_r;

  logic         [   Depth-1 : 0 ] wr_toggle_w;
  logic         [   Depth-1 : 0 ] wr_toggle_r;

  logic         [   Depth-1 : 0 ] rd_toggle       [3:0];
  logic         [   Depth-1 : 0 ] rd_toggle_syncd [3:0];
  logic         [   Depth-1 : 0 ] rd_toggle_sel;

  // Output assignments
  // ---------------------------------------------------------------------------
  assign /*output*/ o_full = (wr_toggle_r[wptr_r] != rd_toggle_sel[wptr_r]);

  assign /*output*/ o_wr_toggle = wr_toggle_r;

  always_comb
    for (int i = 0; i < Depth; i++)
      o_bus[Width*i+:Width] = mem_r[i];

  // ---------------------------------------------------------------------------
  always_comb begin
    wptr_w      = wptr_r;
    mem_w       = mem_r;
    wr_toggle_w = wr_toggle_r;

    if (i_push & !o_full) begin
      wptr_w              = wptr_r + 1;
      mem_w[wptr_r]       = (mem_r[wptr_r] & ~i_push_bwe) |
                            (i_push_data & i_push_bwe);
      wr_toggle_w[wptr_r] = ~wr_toggle_r[wptr_r];
    end
  end

  // Select how many stages should the toggle bits be synchronized
  assign rd_toggle_sel = rd_toggle_syncd[cfg_sync_stages];

  always_comb
    for (int i = 0; i < 4; i++)
      if (i == 0)
        rd_toggle[i] = i_rd_toggle;
      else
        rd_toggle[i] = rd_toggle_syncd[i-1];

  sync #(.Depth(Depth)) u_rd_tgl_sync [3:0] (
    .i_clk                  (i_clk),
    .i_rst_n                (i_rst_n),

    .i_in                   (rd_toggle),
    .o_out                  (rd_toggle_syncd)
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
      for (int i = 0; i < Depth; i++)
        mem_r[i]            <= 'd0;
      wptr_r                <= 'd0;
      wr_toggle_r           <= 'd0;
    end
    else begin
      mem_r                 <= mem_w;
      wptr_r                <= wptr_w;
      wr_toggle_r           <= wr_toggle_w;
    end

endmodule

`endif // AFIFO_WR_V

