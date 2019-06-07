
`ifndef DELAY_CHAIN_SV
`define DELAY_CHAIN_SV

module delay_chain
(
  input  logic  [   7 : 0 ] c_tap,

  input  logic              i_in,
  output logic              o_out
);
  logic [14:0] bdly;
  logic [ 4:0] bmux;

  logic [ 2:0] mdly;
  logic        mmux;

  logic [ 2:0] sdly;
  logic        smux;

  assign /*output*/ o_out = smux;

  // ---------------------------------------------------------------------------
  DLY10_X4N_A7P5PP96PTS_C16 DT_bdly0  (.A(i_in    ), .Y(bdly[0 ]));
  DLY10_X4N_A7P5PP96PTS_C16 DT_bdly1  (.A(bdly[0 ]), .Y(bdly[1 ]));
  DLY10_X4N_A7P5PP96PTS_C16 DT_bdly2  (.A(bdly[1 ]), .Y(bdly[2 ]));
  DLY10_X4N_A7P5PP96PTS_C16 DT_bdly3  (.A(bdly[2 ]), .Y(bdly[3 ]));
  DLY10_X4N_A7P5PP96PTS_C16 DT_bdly4  (.A(bdly[3 ]), .Y(bdly[4 ]));
  DLY10_X4N_A7P5PP96PTS_C16 DT_bdly5  (.A(bdly[4 ]), .Y(bdly[5 ]));
  DLY10_X4N_A7P5PP96PTS_C16 DT_bdly6  (.A(bdly[5 ]), .Y(bdly[6 ]));
  DLY10_X4N_A7P5PP96PTS_C16 DT_bdly7  (.A(bdly[6 ]), .Y(bdly[7 ]));
  DLY10_X4N_A7P5PP96PTS_C16 DT_bdly8  (.A(bdly[7 ]), .Y(bdly[8 ]));
  DLY10_X4N_A7P5PP96PTS_C16 DT_bdly9  (.A(bdly[8 ]), .Y(bdly[9 ]));
  DLY10_X4N_A7P5PP96PTS_C16 DT_bdly10 (.A(bdly[9 ]), .Y(bdly[10]));
  DLY10_X4N_A7P5PP96PTS_C16 DT_bdly11 (.A(bdly[10]), .Y(bdly[11]));
  DLY10_X4N_A7P5PP96PTS_C16 DT_bdly12 (.A(bdly[11]), .Y(bdly[12]));
  DLY10_X4N_A7P5PP96PTS_C16 DT_bdly13 (.A(bdly[12]), .Y(bdly[13]));
  DLY10_X4N_A7P5PP96PTS_C16 DT_bdly14 (.A(bdly[13]), .Y(bdly[14]));

  MXT4_X4N_A7P5PP96PTS_C16 DT_bmux0 (
    .A(i_in    ), .B(bdly[ 0]), .C(bdly[ 1]), .D(bdly[ 2]), .S0(c_tap[4]), .S1(c_tap[5]), .Y(bmux[0])
  );
  MXT4_X4N_A7P5PP96PTS_C16 DT_bmux1 (
    .A(bdly[ 3]), .B(bdly[ 4]), .C(bdly[ 5]), .D(bdly[ 6]), .S0(c_tap[4]), .S1(c_tap[5]), .Y(bmux[1])
  );
  MXT4_X4N_A7P5PP96PTS_C16 DT_bmux2 (
    .A(bdly[ 7]), .B(bdly[ 8]), .C(bdly[ 9]), .D(bdly[10]), .S0(c_tap[4]), .S1(c_tap[5]), .Y(bmux[2])
  );
  MXT4_X4N_A7P5PP96PTS_C16 DT_bmux3 (
    .A(bdly[11]), .B(bdly[12]), .C(bdly[13]), .D(bdly[14]), .S0(c_tap[4]), .S1(c_tap[5]), .Y(bmux[3])
  );

  MXT4_X4N_A7P5PP96PTS_C16 DT_bmux (
    .A(bmux[0]), .B(bmux[1]), .C(bmux[2]), .D(bmux[3]), .S0(c_tap[6]), .S1(c_tap[7]), .Y(bmux[4])
  );

  // ---------------------------------------------------------------------------
  DLY2_X4N_A7P5PP96PTS_C16 DT_mdly0 (.A(bmux[4]), .Y(mdly[0]));
  DLY2_X4N_A7P5PP96PTS_C16 DT_mdly1 (.A(mdly[0]), .Y(mdly[1]));
  DLY2_X4N_A7P5PP96PTS_C16 DT_mdly2 (.A(mdly[1]), .Y(mdly[2]));

  MXT4_X4N_A7P5PP96PTS_C16 DT_mmux (
    .A(bmux[4]), .B(mdly[0]), .C(mdly[1]), .D(mdly[2]), .S0(c_tap[2]), .S1(c_tap[3]), .Y(mmux)
  );

  // ---------------------------------------------------------------------------
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 DT_sdly0 (.A(mmux   ), .Y(sdly[0]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 DT_sdly1 (.A(sdly[0]), .Y(sdly[1]));
  DLYCLK8S2_X2N_A7P5PP96PTS_C16 DT_sdly2 (.A(sdly[1]), .Y(sdly[2]));

  MXT4_X4N_A7P5PP96PTS_C16 DT_smux (
    .A(mmux), .B(sdly[0]), .C(sdly[1]), .D(sdly[2]), .S0(c_tap[0]), .S1(c_tap[1]), .Y(smux)
  );

endmodule

`endif // DELAY_CHAIN

