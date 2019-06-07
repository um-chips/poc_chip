
`ifndef FIFO_ASYM_SV // this module can be included in multiple file lists
`define FIFO_ASYM_SV // use an include guard to avoid duplicated module declaration

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module fifo_asym #(parameter WidthW = 16,
                   parameter WidthR = 8,
                   parameter Depth  = 8)
(
  input  logic                  i_rst_n,

  input  logic                  i_wclk,
  input  logic                  i_write,
  input  logic [ WidthW-1 : 0 ] i_wdata,
  output logic                  o_full,

  input  logic                  i_rclk,
  input  logic                  i_read,
  output logic [ WidthR-1 : 0 ] o_rdata,
  output logic                  o_empty
);
  // ---------------------------------------------------------------------------
  localparam Width = (WidthW>WidthR) ? WidthW : WidthR;

  localparam Ratio = (WidthW>WidthR) ? WidthW/WidthR : WidthR/WidthW;
  localparam RatioBits = $clog2(Ratio);

  localparam PosBitsW = (WidthW>WidthR) ? $clog2(Depth) + 1 :
                                          $clog2(Depth) + RatioBits + 1;
  localparam PosMsbW  = PosBitsW - 1;
  localparam PtrMsbW  = PosMsbW - 1;

  localparam PosBitsR = (WidthW>WidthR) ? $clog2(Depth) + RatioBits + 1 :
                                          $clog2(Depth) + 1;
  localparam PosMsbR  = PosBitsR - 1;
  localparam PtrMsbR  = PosMsbR - 1;

  // Signal declarations
  // ---------------------------------------------------------------------------
  logic [ Width-1 : 0 ] mem_d [Depth];
  logic [ Width-1 : 0 ] mem_q [Depth];

  logic [ PosMsbW : 0 ] wpos_d, wpos_q;
  logic [ PosMsbR : 0 ] rpos_d, rpos_q;

  wire  [ PtrMsbW : 0 ] wptr = wpos_q[PtrMsbW:0];
  wire  [ PtrMsbR : 0 ] rptr = rpos_q[PtrMsbR:0];

  wire  [ PtrMsbW : 0 ] wptr_d = wpos_d[PtrMsbW:0];
  wire  [ PtrMsbR : 0 ] rptr_d = rpos_d[PtrMsbR:0];

  logic                 full_d, full_q;
  logic                 empty_d, empty_q;
  logic [ Width-1 : 0 ] rdata_d, rdata_q;

  wire                  do_write = i_write & !o_full;
  wire                  do_read  = i_read  & !o_empty;

  // Output assignments
  // ---------------------------------------------------------------------------
//if (WidthW>WidthR) begin
//  assign /*output*/ o_full  = (wpos_q[PosMsbW] != rpos_q[PosMsbR]) &&
//                              (wptr==rptr[PtrMsbR:RatioBits]);
//
//  assign /*output*/ o_empty = (wpos_q[PosMsbW] == rpos_q[PosMsbR]) &&
//                              (wptr==rptr[PtrMsbR:RatioBits]);
//
//  assign /*output*/ o_rdata = 
//    mem_q[rptr[PtrMsbR:RatioBits]][rptr[RatioBits-1:0]*WidthR+:WidthR];
//end
//else begin
//  assign /*output*/ o_full  = (wpos_q[PosMsbW] != rpos_q[PosMsbR]) &&
//                              (wptr[PtrMsbW:RatioBits]==rptr);
//
//  assign /*output*/ o_empty = (wpos_q[PosMsbW] == rpos_q[PosMsbR]) &&
//                              (wptr[PtrMsbW:RatioBits]==rptr);
//
//  assign /*output*/ o_rdata = mem_q[rptr];
//end

  //assign /*output*/ o_full  = (wptr == rptr) && (wpos_q[PosMsbW] != rpos_q[PosMsbR]);
  //assign /*output*/ o_empty = (wptr == rptr) && (wpos_q[PosMsbW] == rpos_q[PosMsbR]);

  // Use synchronous flags to prevent glitches when the two clocks are different
  assign /*output*/ o_full  = full_q;
  assign /*output*/ o_empty = empty_q;

  assign /*output*/ o_rdata = rdata_q;

if (WidthW>WidthR) begin
  assign full_d  = (wpos_d[PosMsbW] != rpos_d[PosMsbR]) &&
                   (wptr_d==rptr_d[PtrMsbR:RatioBits]);

  assign empty_d = (wpos_d[PosMsbW] == rpos_d[PosMsbR]) &&
                   (wptr_d==rptr_d[PtrMsbR:RatioBits]);

  assign rdata_d = 
    mem_d[rptr_d[PtrMsbR:RatioBits]][rptr_d[RatioBits-1:0]*WidthR+:WidthR];
end
else begin
  assign full_d  = (wpos_d[PosMsbW] != rpos_d[PosMsbR]) &&
                   (wptr_d[PtrMsbW:RatioBits]==rptr_d);

  assign empty_d = (wpos_d[PosMsbW] == rpos_d[PosMsbR]) &&
                   (wptr_d[PtrMsbW:RatioBits]==rptr_d);

  assign rdata_d = mem_d[rptr_d];
end

  // ---------------------------------------------------------------------------
if (Ratio == 1 || WidthW>WidthR) begin
  always_comb begin
    mem_d = mem_q;

    if (do_write)
      mem_d[wptr] = i_wdata;
  end
end
else begin
  always_comb begin
    mem_d = mem_q;

    if (do_write)
      mem_d[wptr[PtrMsbW:RatioBits]][wptr[RatioBits-1:0]*WidthW+:WidthW] = i_wdata;
  end
end

if (Ratio == 1 || WidthW>WidthR)
  always_comb begin
    wpos_d = wpos_q;

    if (do_write)
      wpos_d = wpos_q + 1;
  end
else
  always_comb begin
    wpos_d = wpos_q;

    if (do_write) begin
      if (wptr[RatioBits-1:0] == Ratio-1)
        wpos_d = (wpos_q[PosMsbW:RatioBits]+1) << RatioBits;
      else
        wpos_d = wpos_q + 1;
    end
  end

if (Ratio == 1 || WidthR>WidthW)
  always_comb begin
    rpos_d = rpos_q;

    if (do_read)
      rpos_d = rpos_q + 1;
  end
else
  always_comb begin
    rpos_d = rpos_q;

    if (do_read) begin
      if (rptr[RatioBits-1:0] == Ratio-1)
        rpos_d = (rpos_q[PosMsbR:RatioBits]+1) << RatioBits;
      else
        rpos_d = rpos_q + 1;
    end
  end

  // Flip flops
  // ---------------------------------------------------------------------------
  always_ff @(posedge i_wclk or negedge i_rst_n)
    if (!i_rst_n) begin
      mem_q  <= '{default: 0};
      wpos_q <= 'd0;
      full_q <= 1'b0;
    end
    else begin
      mem_q  <= mem_d;
      wpos_q <= wpos_d;
      full_q <= full_d;
    end

  always_ff @(posedge i_rclk or negedge i_rst_n)
    if (!i_rst_n) begin
      rpos_q  <= 'd0;
      empty_q <= 1'b1;
      rdata_q <= 'b0;
    end
    else begin
      rpos_q  <= rpos_d;
      empty_q <= empty_d;
      rdata_q <= rdata_d;
    end

endmodule

`endif // FIFO_ASYM_SV

