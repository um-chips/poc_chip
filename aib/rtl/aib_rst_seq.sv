
module aib_rst_seq
(
  input  logic i_aib_clk,
  input  logic i_aux_clk,
  input  logic i_sys_clk,

  input  logic i_rst_n,
  output logic o_cfg_rst_n,
  output logic o_io_rst_n,

  input  logic i_config_done,
  output logic o_sys_rst_n,
  output logic o_adapt_rst_n
);
  SDFFYRPQ2D_X4N_A7P5PP96PTS_C16 DT_cfg_rst_n (
    .CK(i_aux_clk), .R(~i_rst_n), .D(1'b1), .Q(o_cfg_rst_n), .SI(1'b0), .SE(1'b0)
  );
  SDFFYRPQ2D_X4N_A7P5PP96PTS_C16 DT_io_rst_n (
    .CK(i_aib_clk), .R(~i_rst_n), .D(o_cfg_rst_n), .Q(o_io_rst_n), .SI(1'b0), .SE(1'b0)
  );

  SDFFYRPQ2D_X4N_A7P5PP96PTS_C16 DT_sys_rst_n (
    .CK(i_sys_clk), .R(~i_config_done), .D(1'b1), .Q(o_sys_rst_n), .SI(1'b0), .SE(1'b0)
  );
  SDFFYRPQ2D_X4N_A7P5PP96PTS_C16 DT_adapt_rst_n (
    .CK(i_aib_clk), .R(~i_config_done), .D(o_sys_rst_n), .Q(o_adapt_rst_n), .SI(1'b0), .SE(1'b0)
  );

endmodule

