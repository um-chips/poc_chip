
module clkgen_cfg #(parameter DefaultOscSel = 0, DefaultDivSel = 0)
(
  input  logic        i_en,
  input  logic        i_chg,
  input  logic [ 3:0] i_osc_sel,
  input  logic [ 1:0] i_div0_sel,
  input  logic [ 1:0] i_div1_sel,

  output logic        o_pause,
  output logic [ 3:0] o_osc_sel,
  output logic [ 1:0] o_div0_sel,
  output logic [ 1:0] o_div1_sel
);
  logic [15:0] osc;

  logic        osc_clk;
  logic        osc_clk_div2;
  logic        osc_clk_div4;

  logic        cfg_clk;

  logic        chg_sync;
  logic        chg_q;
  logic [ 7:0] chg_wait_q;

  logic [ 3:0] osc_sel_q;
  logic [ 1:0] div0_sel_q;
  logic [ 1:0] div1_sel_q;

  // ---------------------------------------------------------------------------
  assign /*output*/ o_pause  = ~chg_wait_q[7];

  assign /*output*/ o_osc_sel  = osc_sel_q;
  assign /*output*/ o_div0_sel = div0_sel_q;
  assign /*output*/ o_div1_sel = div1_sel_q;

  // ---------------------------------------------------------------------------
  NAND2_X1N_A7P5PP96PTS_C16 DT_en    (.A(i_en), .B(osc_clk), .Y(osc[0]));
  DLY10_X2N_A7P5PP96PTS_C16 DT_dly1  (.A(osc[ 0]), .Y(osc[ 1]));
  DLY10_X2N_A7P5PP96PTS_C16 DT_dly2  (.A(osc[ 1]), .Y(osc[ 2]));
  DLY10_X2N_A7P5PP96PTS_C16 DT_dly3  (.A(osc[ 2]), .Y(osc[ 3]));
  DLY10_X2N_A7P5PP96PTS_C16 DT_dly4  (.A(osc[ 3]), .Y(osc[ 4]));
  DLY10_X2N_A7P5PP96PTS_C16 DT_dly5  (.A(osc[ 4]), .Y(osc[ 5]));
  DLY10_X2N_A7P5PP96PTS_C16 DT_dly6  (.A(osc[ 5]), .Y(osc[ 6]));
  DLY10_X2N_A7P5PP96PTS_C16 DT_dly7  (.A(osc[ 6]), .Y(osc[ 7]));
  DLY10_X2N_A7P5PP96PTS_C16 DT_dly8  (.A(osc[ 7]), .Y(osc[ 8]));
  DLY10_X2N_A7P5PP96PTS_C16 DT_dly9  (.A(osc[ 8]), .Y(osc[ 9]));
  DLY10_X2N_A7P5PP96PTS_C16 DT_dly10 (.A(osc[ 9]), .Y(osc[10]));
  DLY10_X2N_A7P5PP96PTS_C16 DT_dly11 (.A(osc[10]), .Y(osc[11]));
  DLY10_X2N_A7P5PP96PTS_C16 DT_dly12 (.A(osc[11]), .Y(osc[12]));
  DLY10_X2N_A7P5PP96PTS_C16 DT_dly13 (.A(osc[12]), .Y(osc[13]));
  DLY10_X2N_A7P5PP96PTS_C16 DT_dly14 (.A(osc[13]), .Y(osc[14]));
  DLY10_X2N_A7P5PP96PTS_C16 DT_dly15 (.A(osc[14]), .Y(osc[15]));

  assign osc_clk = osc[15];

  // ---------------------------------------------------------------------------
  always_ff @(posedge osc_clk or negedge i_en)
    if (!i_en)
      osc_clk_div2 <= 1'b0;
    else
      osc_clk_div2 <= ~osc_clk_div2;

  always_ff @(posedge osc_clk_div2 or negedge i_en)
    if (!i_en)
      osc_clk_div4 <= 1'b0;
    else
      osc_clk_div4 <= ~osc_clk_div4;

  assign cfg_clk = osc_clk_div4;

  // ---------------------------------------------------------------------------
  SDFFYRPQ2D_X2N_A7P5PP96PTS_C16 DT_chg_sync (
    .CK(cfg_clk), .R(~i_en), .D(i_chg), .Q(chg_sync), .SI(1'b0), .SE(1'b0)
  );

  always_ff @(posedge cfg_clk or negedge i_en)
    if (!i_en)
      chg_q <= 1'b0;
    else
      chg_q <= chg_sync;

  always_ff @(posedge cfg_clk or negedge i_en)
    if (!i_en) begin
      osc_sel_q  <= DefaultOscSel;
      div0_sel_q <= DefaultDivSel;
      div1_sel_q <= DefaultDivSel;
    end
    else if (~chg_wait_q[1] & chg_wait_q[0]) begin
      osc_sel_q  <= i_osc_sel;
      div0_sel_q <= i_div0_sel;
      div1_sel_q <= i_div1_sel;
    end

  always_ff @(posedge cfg_clk or negedge i_en)
    if (!i_en)
      chg_wait_q <= -1;
    else if (chg_q != chg_sync)
      chg_wait_q <= 0;
    else
      chg_wait_q <= {chg_wait_q[6:0], 1'b1};

endmodule

