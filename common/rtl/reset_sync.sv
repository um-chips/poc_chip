
`ifndef RESET_SYNC_SV // this module can be included in multiple file lists
`define RESET_SYNC_SV // use an include guard to avoid duplicated module declaration

module reset_sync
(
  input  logic i_clk,
  input  logic i_rst_n,

  output logic o_rst_n
);
  wire rst = ~i_rst_n;

  SDFFYRPQ2D_X4N_A7P5PP96PTS_C16 DT_rst_sync (
    .CK(i_clk), .R(rst), .D(1'b1), .Q(o_rst_n), .SI(1'b0), .SE(1'b0)
  );

endmodule

`endif // RESET_SYNC_SV

