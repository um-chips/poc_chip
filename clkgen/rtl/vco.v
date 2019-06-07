
module vco
(
  input  i_osc_sel_0,
  input  i_osc_sel_1,
  input  i_osc_sel_2,

  input  i_osc_div_0,
  input  i_osc_div_1,

  input  i_en,

  input  i_bypass,
  input  i_bypass_clk,

  output o_clk
);
  // ---------------------------------------------------------------------------
  wire        tie0;
  wire        tie1;

  wire [99:0] osc;

  wire [ 7:0] osc_sel_1hot;

  wire        osc_exit_0;
  wire        osc_exit_1;
  wire        osc_exit_2;
  wire        osc_exit_3;
  wire        osc_exit_4;
  wire        osc_exit_5;
  wire        osc_exit_6;
  wire        osc_exit_7;

  wire [ 6:0] osc_sel_mux;

  wire        osc_clk_div2;
  wire        osc_clk_div4;
  wire        osc_clk_div8;

  wire [ 2:0] osc_div_mux;

  wire        osc_clk;

  // Drive tie1/tie0 through diffusion, not directly tied to the power rail to
  // provide some ESD protection.
  // ---------------------------------------------------------------------------
  TIELO_X1N_A7P5PP96PTS_C16 tielo (.Y(tie0));
  TIEHI_X1N_A7P5PP96PTS_C16 tiehi (.Y(tie1));

  // Convert the binary osc_sel signal to 1-hot
  // ---------------------------------------------------------------------------
  NOR3_X1N_A7P5PP96PTS_C16   osc_sel_1hot_0 (.A (i_osc_sel_0), .B (i_osc_sel_1), .C(i_osc_sel_2), .Y(osc_sel_1hot[0]));
  NOR3B_X1N_A7P5PP96PTS_C16  osc_sel_1hot_1 (.AN(i_osc_sel_0), .B (i_osc_sel_1), .C(i_osc_sel_2), .Y(osc_sel_1hot[1]));
  NOR3B_X1N_A7P5PP96PTS_C16  osc_sel_1hot_2 (.AN(i_osc_sel_1), .B (i_osc_sel_0), .C(i_osc_sel_2), .Y(osc_sel_1hot[2]));
  NOR3BB_X1N_A7P5PP96PTS_C16 osc_sel_1hot_3 (.AN(i_osc_sel_0), .BN(i_osc_sel_1), .C(i_osc_sel_2), .Y(osc_sel_1hot[3]));
  NOR3B_X1N_A7P5PP96PTS_C16  osc_sel_1hot_4 (.AN(i_osc_sel_2), .B (i_osc_sel_0), .C(i_osc_sel_1), .Y(osc_sel_1hot[4]));
  NOR3BB_X1N_A7P5PP96PTS_C16 osc_sel_1hot_5 (.AN(i_osc_sel_0), .BN(i_osc_sel_2), .C(i_osc_sel_1), .Y(osc_sel_1hot[5]));
  NOR3BB_X1N_A7P5PP96PTS_C16 osc_sel_1hot_6 (.AN(i_osc_sel_1), .BN(i_osc_sel_2), .C(i_osc_sel_0), .Y(osc_sel_1hot[6]));
  AND3_X1N_A7P5PP96PTS_C16   osc_sel_1hot_7 (.A (i_osc_sel_0), .B (i_osc_sel_1), .C(i_osc_sel_2), .Y(osc_sel_1hot[7]));

  // Ring oscillator
  // ---------------------------------------------------------------------------
  NAND2_X1N_A7P5PP96PTS_C16 osc_0  (.A(i_en), .B(osc_sel_mux[6]), .Y(osc[ 0]));
  NAND2_X1N_A7P5PP96PTS_C16 osc_1  (.A(tie1), .B(osc[ 0]),        .Y(osc[ 1]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_2  (.A(osc[ 1]), .Y(osc[ 2]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_3  (.A(osc[ 2]), .Y(osc[ 3]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_4  (.A(osc[ 3]), .Y(osc[ 4]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_5  (.A(osc[ 4]), .Y(osc[ 5]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_6  (.A(osc[ 5]), .Y(osc[ 6]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_7  (.A(osc[ 6]), .Y(osc[ 7]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_8  (.A(osc[ 7]), .Y(osc[ 8]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_9  (.A(osc[ 8]), .Y(osc[ 9]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_10 (.A(osc[ 9]), .Y(osc[10]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_11 (.A(osc[10]), .Y(osc[11]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_12 (.A(osc[11]), .Y(osc[12]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_13 (.A(osc[12]), .Y(osc[13]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_14 (.A(osc[13]), .Y(osc[14]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_15 (.A(osc[14]), .Y(osc[15]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_16 (.A(osc[15]), .Y(osc[16]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_17 (.A(osc[16]), .Y(osc[17]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_18 (.A(osc[17]), .Y(osc[18]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_19 (.A(osc[18]), .Y(osc[19]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_20 (.A(osc[19]), .Y(osc[20]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_21 (.A(osc[20]), .Y(osc[21]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_22 (.A(osc[21]), .Y(osc[22]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_23 (.A(osc[22]), .Y(osc[23]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_24 (.A(osc[23]), .Y(osc[24]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_25 (.A(osc[24]), .Y(osc[25]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_26 (.A(osc[25]), .Y(osc[26]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_27 (.A(osc[26]), .Y(osc[27]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_28 (.A(osc[27]), .Y(osc[28]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_29 (.A(osc[28]), .Y(osc[29]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_30 (.A(osc[29]), .Y(osc[30]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_31 (.A(osc[30]), .Y(osc[31]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_32 (.A(osc[31]), .Y(osc[32]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_33 (.A(osc[32]), .Y(osc[33]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_34 (.A(osc[33]), .Y(osc[34]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_35 (.A(osc[34]), .Y(osc[35]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_36 (.A(osc[35]), .Y(osc[36]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_37 (.A(osc[36]), .Y(osc[37]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_38 (.A(osc[37]), .Y(osc[38]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_39 (.A(osc[38]), .Y(osc[39]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_40 (.A(osc[39]), .Y(osc[40]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_41 (.A(osc[40]), .Y(osc[41]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_42 (.A(osc[41]), .Y(osc[42]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_43 (.A(osc[42]), .Y(osc[43]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_44 (.A(osc[43]), .Y(osc[44]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_45 (.A(osc[44]), .Y(osc[45]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_46 (.A(osc[45]), .Y(osc[46]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_47 (.A(osc[46]), .Y(osc[47]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_48 (.A(osc[47]), .Y(osc[48]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_49 (.A(osc[48]), .Y(osc[49]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_50 (.A(osc[49]), .Y(osc[50]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_51 (.A(osc[50]), .Y(osc[51]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_52 (.A(osc[51]), .Y(osc[52]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_53 (.A(osc[52]), .Y(osc[53]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_54 (.A(osc[53]), .Y(osc[54]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_55 (.A(osc[54]), .Y(osc[55]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_56 (.A(osc[55]), .Y(osc[56]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_57 (.A(osc[56]), .Y(osc[57]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_58 (.A(osc[57]), .Y(osc[58]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_59 (.A(osc[58]), .Y(osc[59]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_60 (.A(osc[59]), .Y(osc[60]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_61 (.A(osc[60]), .Y(osc[61]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_62 (.A(osc[61]), .Y(osc[62]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_63 (.A(osc[62]), .Y(osc[63]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_64 (.A(osc[63]), .Y(osc[64]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_65 (.A(osc[64]), .Y(osc[65]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 osc_66 (.A(osc[65]), .Y(osc[66]));

  // Select how many stages in the ring oscillator are used
  // ---------------------------------------------------------------------------
  NAND2_X1N_A7P5PP96PTS_C16 osc_gate_0 (.A(osc_sel_1hot[0]), .B(osc[66]), .Y(osc_exit_0));
  NAND2_X1N_A7P5PP96PTS_C16 osc_gate_1 (.A(osc_sel_1hot[1]), .B(osc[57]), .Y(osc_exit_1));
  NAND2_X1N_A7P5PP96PTS_C16 osc_gate_2 (.A(osc_sel_1hot[2]), .B(osc[51]), .Y(osc_exit_2));
  NAND2_X1N_A7P5PP96PTS_C16 osc_gate_3 (.A(osc_sel_1hot[3]), .B(osc[47]), .Y(osc_exit_3));
  NAND2_X1N_A7P5PP96PTS_C16 osc_gate_4 (.A(osc_sel_1hot[4]), .B(osc[39]), .Y(osc_exit_4));
  NAND2_X1N_A7P5PP96PTS_C16 osc_gate_5 (.A(osc_sel_1hot[5]), .B(osc[35]), .Y(osc_exit_5));
  NAND2_X1N_A7P5PP96PTS_C16 osc_gate_6 (.A(osc_sel_1hot[6]), .B(osc[33]), .Y(osc_exit_6));
  NAND2_X1N_A7P5PP96PTS_C16 osc_gate_7 (.A(osc_sel_1hot[7]), .B(osc[31]), .Y(osc_exit_7));

  MXGL2_X2N_A7P5PP96PTS_C16 osc_sel_0 (.A(osc_exit_0), .B(osc_exit_1), .S0(i_osc_sel_0), .Y(osc_sel_mux[0]));
  MXGL2_X2N_A7P5PP96PTS_C16 osc_sel_1 (.A(osc_exit_2), .B(osc_exit_3), .S0(i_osc_sel_0), .Y(osc_sel_mux[1]));
  MXGL2_X2N_A7P5PP96PTS_C16 osc_sel_2 (.A(osc_exit_4), .B(osc_exit_5), .S0(i_osc_sel_0), .Y(osc_sel_mux[2]));
  MXGL2_X2N_A7P5PP96PTS_C16 osc_sel_3 (.A(osc_exit_6), .B(osc_exit_7), .S0(i_osc_sel_0), .Y(osc_sel_mux[3]));

  MXGL2_X2N_A7P5PP96PTS_C16 osc_sel_4 (.A(osc_sel_mux[0]), .B(osc_sel_mux[1]), .S0(i_osc_sel_1), .Y(osc_sel_mux[4]));
  MXGL2_X2N_A7P5PP96PTS_C16 osc_sel_5 (.A(osc_sel_mux[2]), .B(osc_sel_mux[3]), .S0(i_osc_sel_1), .Y(osc_sel_mux[5]));

  MXGL2_X2N_A7P5PP96PTS_C16 osc_sel_6 (.A(osc_sel_mux[4]), .B(osc_sel_mux[5]), .S0(i_osc_sel_2), .Y(osc_sel_mux[6]));

  // ---------------------------------------------------------------------------
  DFFQN_X2N_A7P5PP96PTS_C16 osc_div2 (.CK(osc_sel_mux[6]), .D(osc_clk_div2), .QN(osc_clk_div2));
  DFFQN_X2N_A7P5PP96PTS_C16 osc_div4 (.CK(osc_clk_div2),   .D(osc_clk_div4), .QN(osc_clk_div4));
  DFFQN_X2N_A7P5PP96PTS_C16 osc_div8 (.CK(osc_clk_div4),   .D(osc_clk_div8), .QN(osc_clk_div8));

  MXGL2_X2N_A7P5PP96PTS_C16 osc_div_0 (.A(osc_sel_mux[6]), .B(osc_clk_div2),   .S0(i_osc_div_0), .Y(osc_div_mux[0]));
  MXGL2_X2N_A7P5PP96PTS_C16 osc_div_1 (.A(osc_clk_div4),   .B(osc_clk_div8),   .S0(i_osc_div_0), .Y(osc_div_mux[1]));
  MXGL2_X2N_A7P5PP96PTS_C16 osc_div_2 (.A(osc_div_mux[0]), .B(osc_div_mux[1]), .S0(i_osc_div_1), .Y(osc_div_mux[2]));

  DFFQN_X3N_A7P5PP96PTS_C16 osc_clk_out (.CK(osc_div_mux[2]), .D(osc_clk), .QN(osc_clk));

  // ---------------------------------------------------------------------------
  MXT2_X6N_A7P5PP96PTS_C16 out_mux (.A(osc_clk), .B(i_bypass_clk), .S0(i_bypass), .Y(o_clk));

endmodule

