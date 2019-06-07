
module clkgen_osc
(
  input  logic        i_en,
  input  logic [ 3:0] i_osc_sel,
  input  logic [ 1:0] i_div0_sel,
  input  logic [ 1:0] i_div1_sel,

  output logic        o_clk0,
  output logic        o_clk1,
  output logic        o_slow_clk,

  input  logic        i_bypass,
  input  logic        i_bypass_clk,

  input  logic        i_forward, // need a 0->1 transition
  input  logic        i_forward_clk
);
  // ---------------------------------------------------------------------------
  localparam OscLen = 26;

  logic [OscLen-1:0] osc;

  logic [15:0] osc_mask;
  logic [15:0] osc_tap;

  logic [14:0] osc_sel_mux;
  logic        osc_clk;

  logic        osc_clk_div2;
  logic        osc_clk_div4;
  logic        osc_clk_div8;

  logic        forward_clk;
  logic        forward_clk_div2;
  logic        forward_clk_div4;
  logic        forward_clk_div8;

  logic [ 3:0] div0_mask;
  logic        div0_clk;

  logic        out_clk0_en;
  logic        out_clk0;
  logic        out_clk0_rst;
  logic        out_clk0_inv;
  logic        out_clk0_mux_byp;
  logic        out_clk0_mux_fwd;

  logic [ 3:0] div1_mask;
  logic        div1_clk;

  logic        out_clk1_en;
  logic        out_clk1;
  logic        out_clk1_rst;
  logic        out_clk1_inv;
  logic        out_clk1_mux_byp;
  logic        out_clk1_mux_fwd;

  logic        fwd_clk;
  logic        fwd_clk_en;

  logic [10:0] slow_clk;

  // ---------------------------------------------------------------------------
  assign /*output*/ o_slow_clk = slow_clk[10];

  // Ring oscillator
  // ---------------------------------------------------------------------------
  always_comb
    osc_mask = 16'b0 | (1<<i_osc_sel);

  generate
    for (genvar gi = 0; gi < OscLen; gi++) begin: ring_osc
      if (gi == 0)
        NAND2_X2N_A7P5PP96PTS_C16 DT_en (.A(i_en), .B(osc_clk), .Y(osc[0]));
      else if (gi == 1)
        NAND2_X2N_A7P5PP96PTS_C16 DT_inv (.A(i_en), .B(osc[0]), .Y(osc[1]));
      else if (gi==9  || gi==10 || gi==11 || gi==12 || gi==13 || gi==14 || gi==15 || gi==16 ||
               gi==17 || gi==18 || gi==19 || gi==20 || gi==21 || gi==22 || gi==23
      ) begin
        localparam Stage =
          (gi==9 )? 0: (gi==10)? 1: (gi==11)? 2 : (gi==12)? 3 : (gi==13)? 4 : (gi==14)? 5 : (gi==15)? 6 : (gi==16)? 7 :
          (gi==17)? 8: (gi==18)? 9: (gi==19)? 10: (gi==20)? 11: (gi==21)? 12: (gi==22)? 13: (gi==23)? 14:
          -1;

        logic g1, g2;

        NAND2_X2N_A7P5PP96PTS_C16 DT_mask (.A(osc_mask[Stage]), .B(osc[gi-1]), .Y(osc_tap[Stage]));

        DLYCLK8S2_X2N_A7P5PP96PTS_C16 DT_dly (.A(osc[gi-1]), .Y(osc[gi]));
      end
      else if (gi == OscLen-1)
        NAND2_X2N_A7P5PP96PTS_C16 DT_mask (.A(osc_mask[15]), .B(osc[gi-1]), .Y(osc_tap[15]));
      else
        DLYCLK8S2_X2N_A7P5PP96PTS_C16 DT_dly (.A(osc[gi-1]), .Y(osc[gi]));
    end
  endgenerate

  // ---------------------------------------------------------------------------
  always_comb
    case (i_osc_sel)
      4'h0:    osc_clk = osc_tap[ 0];
      4'h1:    osc_clk = osc_tap[ 1];
      4'h2:    osc_clk = osc_tap[ 2];
      4'h3:    osc_clk = osc_tap[ 3];
      4'h4:    osc_clk = osc_tap[ 4];
      4'h5:    osc_clk = osc_tap[ 5];
      4'h6:    osc_clk = osc_tap[ 6];
      4'h7:    osc_clk = osc_tap[ 7];
      4'h8:    osc_clk = osc_tap[ 8];
      4'h9:    osc_clk = osc_tap[ 9];
      4'ha:    osc_clk = osc_tap[10];
      4'hb:    osc_clk = osc_tap[11];
      4'hc:    osc_clk = osc_tap[12];
      4'hd:    osc_clk = osc_tap[13];
      4'he:    osc_clk = osc_tap[14];
      default: osc_clk = osc_tap[15];
    endcase

  // ---------------------------------------------------------------------------
  DFFRPQ_X1N_A7P5PP96PTS_C16 DT_osc_clk_div2 (
    .CK(osc_clk), .R(~i_en), .D(~osc_clk_div2), .Q(osc_clk_div2));

  DFFRPQ_X1N_A7P5PP96PTS_C16 DT_osc_clk_div4 (
    .CK(osc_clk_div2), .R(~i_en), .D(~osc_clk_div4), .Q(osc_clk_div4));

  DFFRPQ_X1N_A7P5PP96PTS_C16 DT_osc_clk_div8 (
    .CK(osc_clk_div4), .R(~i_en), .D(~osc_clk_div8), .Q(osc_clk_div8));

  // ---------------------------------------------------------------------------
  BUFH_X16N_A7P5PP96PTS_C16 DT_forward_clk (.A(i_forward_clk), .Y(forward_clk));

  SDFFYRPQ2D_X2N_A7P5PP96PTS_C16 DT_fwd_clk_en (
    .CK(forward_clk), .R(~i_forward), .D(1'b1), .Q(fwd_clk_en), .SI(1'b0), .SE(1'b0)
  );

  DFFRPQ_X1N_A7P5PP96PTS_C16 DT_forward_clk_div2 (
    .CK(forward_clk), .R(~fwd_clk_en), .D(~forward_clk_div2), .Q(forward_clk_div2));

  DFFRPQ_X1N_A7P5PP96PTS_C16 DT_forward_clk_div4 (
    .CK(forward_clk_div2), .R(~fwd_clk_en), .D(~forward_clk_div4), .Q(forward_clk_div4));

  DFFRPQ_X1N_A7P5PP96PTS_C16 DT_forward_clk_div8 (
    .CK(forward_clk_div4), .R(~fwd_clk_en), .D(~forward_clk_div8), .Q(forward_clk_div8));

  // ---------------------------------------------------------------------------
  always_comb begin
    div0_mask = 4'b0 | (1<<i_div0_sel);
    div1_mask = 4'b0 | (1<<i_div1_sel);
  end

  always_comb
    case (i_div0_sel)
      2'd0:    div0_clk = div0_mask[0] & osc_clk;
      2'd1:    div0_clk = div0_mask[1] & osc_clk_div2;
      2'd2:    div0_clk = div0_mask[2] & osc_clk_div4;
      default: div0_clk = div0_mask[3] & osc_clk_div8;
    endcase

  always_comb
    case (i_div1_sel)
      2'd0:    div1_clk = div1_mask[0] & osc_clk;
      2'd1:    div1_clk = div1_mask[1] & osc_clk_div2;
      2'd2:    div1_clk = div1_mask[2] & osc_clk_div4;
      default: div1_clk = div1_mask[3] & osc_clk_div8;
    endcase

  always_comb
    case (i_div1_sel)
      2'd0:    fwd_clk = div1_mask[0] & forward_clk;
      2'd1:    fwd_clk = div1_mask[1] & forward_clk_div2;
      2'd2:    fwd_clk = div1_mask[2] & forward_clk_div4;
      default: fwd_clk = div1_mask[3] & forward_clk_div8;
    endcase

  // ---------------------------------------------------------------------------
  SDFFYRPQ2D_X2N_A7P5PP96PTS_C16 DT_out_clk0_en (
    .CK(div0_clk), .R(~i_en), .D(1'b1), .Q(out_clk0_en), .SI(1'b0), .SE(1'b0)
  );

  NAND2_X1N_A7P5PP96PTS_C16 DT_out0_rst (.A(out_clk0_en), .B(out_clk0),     .Y(out_clk0_rst));
  NAND2_X1N_A7P5PP96PTS_C16 DT_out0_inv (.A(out_clk0_en), .B(out_clk0_rst), .Y(out_clk0_inv));
  DFFQN_X3N_A7P5PP96PTS_C16 DT_out0 (.CK(div0_clk), .D(out_clk0_inv), .QN(out_clk0));

  MXT2_X6N_A7P5PP96PTS_C16  DT_out0_mux_byp (
    .A(out_clk0), .B(i_bypass_clk), .S0(i_bypass), .Y(out_clk0_mux_byp));
  MXT2_X6N_A7P5PP96PTS_C16  DT_out0_mux_fwd (
    .A(out_clk0_mux_byp), .B(forward_clk), .S0(i_forward), .Y(out_clk0_mux_fwd));
  BUFH_X16N_A7P5PP96PTS_C16 DT_out0_buf (.A(out_clk0_mux_fwd), .Y(o_clk0));

  // ---------------------------------------------------------------------------
  SDFFYRPQ2D_X2N_A7P5PP96PTS_C16 DT_out_clk1_en (
    .CK(div1_clk), .R(~i_en), .D(1'b1), .Q(out_clk1_en), .SI(1'b0), .SE(1'b0)
  );

  NAND2_X1N_A7P5PP96PTS_C16 DT_out1_rst (.A(out_clk1_en), .B(out_clk1),     .Y(out_clk1_rst));
  NAND2_X1N_A7P5PP96PTS_C16 DT_out1_inv (.A(out_clk1_en), .B(out_clk1_rst), .Y(out_clk1_inv));
  DFFQN_X3N_A7P5PP96PTS_C16 DT_out1 (.CK(div1_clk), .D(out_clk1_inv), .QN(out_clk1));

  MXT2_X6N_A7P5PP96PTS_C16  DT_out1_mux_byp (
    .A(out_clk1), .B(i_bypass_clk), .S0(i_bypass), .Y(out_clk1_mux_byp));
  MXT2_X6N_A7P5PP96PTS_C16  DT_out1_mux_fwd (
    .A(out_clk1_mux_byp), .B(fwd_clk), .S0(i_forward), .Y(out_clk1_mux_fwd));
  BUFH_X16N_A7P5PP96PTS_C16 DT_out1_buf (.A(out_clk1_mux_fwd), .Y(o_clk1));

  // ---------------------------------------------------------------------------
  DFFRPQN_X1N_A7P5PP96PTS_C16 slow_clk_0  (.CK(div0_clk),    .R(~i_en), .D(slow_clk[ 0]), .QN(slow_clk[ 0]));
  DFFRPQN_X1N_A7P5PP96PTS_C16 slow_clk_1  (.CK(slow_clk[0]), .R(~i_en), .D(slow_clk[ 1]), .QN(slow_clk[ 1]));
  DFFRPQN_X1N_A7P5PP96PTS_C16 slow_clk_2  (.CK(slow_clk[1]), .R(~i_en), .D(slow_clk[ 2]), .QN(slow_clk[ 2]));
  DFFRPQN_X1N_A7P5PP96PTS_C16 slow_clk_3  (.CK(slow_clk[2]), .R(~i_en), .D(slow_clk[ 3]), .QN(slow_clk[ 3]));
  DFFRPQN_X1N_A7P5PP96PTS_C16 slow_clk_4  (.CK(slow_clk[3]), .R(~i_en), .D(slow_clk[ 4]), .QN(slow_clk[ 4]));
  DFFRPQN_X1N_A7P5PP96PTS_C16 slow_clk_5  (.CK(slow_clk[4]), .R(~i_en), .D(slow_clk[ 5]), .QN(slow_clk[ 5]));
  DFFRPQN_X1N_A7P5PP96PTS_C16 slow_clk_6  (.CK(slow_clk[5]), .R(~i_en), .D(slow_clk[ 6]), .QN(slow_clk[ 6]));
  DFFRPQN_X1N_A7P5PP96PTS_C16 slow_clk_7  (.CK(slow_clk[6]), .R(~i_en), .D(slow_clk[ 7]), .QN(slow_clk[ 7]));
  DFFRPQN_X1N_A7P5PP96PTS_C16 slow_clk_8  (.CK(slow_clk[7]), .R(~i_en), .D(slow_clk[ 8]), .QN(slow_clk[ 8]));
  DFFRPQN_X1N_A7P5PP96PTS_C16 slow_clk_9  (.CK(slow_clk[8]), .R(~i_en), .D(slow_clk[ 9]), .QN(slow_clk[ 9]));
  DFFRPQN_X1N_A7P5PP96PTS_C16 slow_clk_10 (.CK(slow_clk[9]), .R(~i_en), .D(slow_clk[10]), .QN(slow_clk[10]));

endmodule

