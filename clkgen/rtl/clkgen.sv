
module clkgen #(parameter DefaultOscSel = 15, DefaultDivSel = 3)
(
  input  logic        i_cfg_en,
  input  logic        i_cfg_chg,
  input  logic [ 3:0] i_cfg_osc_sel,
  input  logic [ 1:0] i_cfg_div0_sel,
  input  logic [ 1:0] i_cfg_div1_sel,

  input  logic        i_osc_en,
  output logic        o_osc_clk0,
  output logic        o_osc_clk1,
  output logic        o_osc_slow_clk,

  input  logic        i_bypass,
  input  logic        i_bypass_clk,

  input  logic        i_forward,
  input  logic        i_forward_clk
);
  logic       pause;

  logic [3:0] osc_sel;
  logic [1:0] div0_sel;
  logic [1:0] div1_sel;

  logic       osc_en;

  clkgen_cfg #(.DefaultOscSel(DefaultOscSel),
               .DefaultDivSel(DefaultDivSel)) cfg (
    .i_en         (i_cfg_en),
    .i_chg        (i_cfg_chg),
    .i_osc_sel    (i_cfg_osc_sel),
    .i_div0_sel   (i_cfg_div0_sel),
    .i_div1_sel   (i_cfg_div1_sel),

    .o_pause      (pause),
    .o_osc_sel    (osc_sel),
    .o_div0_sel   (div0_sel),
    .o_div1_sel   (div1_sel)
  );

  assign osc_en = i_osc_en & !pause;

  clkgen_osc osc (
    .i_en           (osc_en),
    .i_osc_sel      (osc_sel),
    .i_div0_sel     (div0_sel),
    .i_div1_sel     (div1_sel),

    .o_clk0         (o_osc_clk0),
    .o_clk1         (o_osc_clk1),
    .o_slow_clk     (o_osc_slow_clk),

    .i_bypass       (i_bypass),
    .i_bypass_clk   (i_bypass_clk),

    .i_forward      (i_forward),
    .i_forward_clk  (i_forward_clk)
  );

endmodule

