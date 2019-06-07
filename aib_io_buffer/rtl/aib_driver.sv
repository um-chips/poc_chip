
`ifndef SYNTHESIS
module aib_driver
(
  inout  wire               PAD,

  input  logic              C_PU,
  input  logic  [   2 : 0 ] C_PDRV,
  input  logic              PDRV,

  input  logic              C_PD,
  input  logic  [   2 : 0 ] C_NDRV,
  input  logic              NDRV
);
  bufif1 (weak1, weak0) (PAD, 1'b1, ~C_PU);
  bufif1 (weak1, weak0) (PAD, 1'b0,  C_PD);

  assign /*inout*/ PAD = ~PDRV ? 1'b1 :
                          NDRV ? 1'b0 : 1'bz;

endmodule
`endif // SYNTHESIS

