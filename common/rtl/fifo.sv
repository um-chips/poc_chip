
`ifndef FIFO_SV // this module can be included in multiple file lists
`define FIFO_SV // use an include guard to avoid duplicated module declaration

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module fifo #(parameter Width = 8,
              parameter Depth = 8)
(
  input  logic                 i_clk,
  input  logic                 i_rst_n,

  output logic                 o_full,
  output logic                 o_empty,

  input  logic                 i_write,
  input  logic [ Width-1 : 0 ] i_wdata,

  input  logic                 i_read,
  output logic [ Width-1 : 0 ] o_rdata
);
  // ---------------------------------------------------------------------------
  localparam PosBits = $clog2(Depth) + 1;
  localparam PosMsb  = PosBits - 1;

  localparam PtrMsb  = PosMsb - 1;

  // Signal declarations
  // ---------------------------------------------------------------------------
  logic [ Width-1 : 0 ] mem_d [Depth];
  logic [ Width-1 : 0 ] mem_q [Depth];

  logic [  PosMsb : 0 ] wpos_d, wpos_q;
  logic [  PosMsb : 0 ] rpos_d, rpos_q;

  wire  [  PtrMsb : 0 ] wptr = wpos_q[PtrMsb:0];
  wire  [  PtrMsb : 0 ] rptr = rpos_q[PtrMsb:0];

  wire                  do_write = i_write & !o_full;
  wire                  do_read  = i_read  & !o_empty;

  // Output assignments
  // ---------------------------------------------------------------------------
  assign /*output*/ o_full  = (wptr == rptr) && (wpos_q[PosMsb] != rpos_q[PosMsb]);
  assign /*output*/ o_empty = (wptr == rptr) && (wpos_q[PosMsb] == rpos_q[PosMsb]);

  assign /*output*/ o_rdata = mem_q[rptr];

  // ---------------------------------------------------------------------------
  always_comb begin
    mem_d = mem_q;

    wpos_d = wpos_q;
    rpos_d = rpos_q;

    if (do_write) begin
      mem_d[wptr] = i_wdata;

      wpos_d = wpos_d + 1;
    end

    if (do_read) begin
      rpos_d = rpos_d + 1;
    end
  end

  // Flip flops
  // ---------------------------------------------------------------------------
  `infer_ff_begin
  `infer_ff_default_all0(mem_)
  `infer_ff_default_all0(wpos_)
  `infer_ff_default_all0(rpos_)
  `infer_ff_end

endmodule

`endif // FIFO_SV

