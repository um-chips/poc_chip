
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module aib_sram
(
  input  logic              i_clk,
  input  logic              i_rst_n,

  input  logic  [  31 : 0 ] i_mem_addr,
  input  logic              i_mem_write,
  input  logic  [  31 : 0 ] i_mem_wdata,
  input  logic  [  31 : 0 ] i_mem_wmask,
  input  logic              i_mem_read,
  output logic  [  31 : 0 ] o_mem_rdata,

  input  logic              i_penable,
  input  logic              i_pwrite,
  input  logic  [  31 : 0 ] i_paddr,
  input  logic  [  31 : 0 ] i_pwdata,
  output logic              o_pready,
  output logic  [  31 : 0 ] o_prdata
);
  // -----------------------------------------------------------------------------
  logic             pready_d, pready_q;

  logic             sram_cen;
  logic             sram_gwen;
  logic [  31 : 0 ] sram_wen;
  logic [  11 : 0 ] sram_a;
  logic [  31 : 0 ] sram_d;
  logic [  31 : 0 ] sram_q;

  // -----------------------------------------------------------------------------
  assign /*output*/ o_mem_rdata = sram_q;

  assign /*output*/ o_pready = ~(i_penable & !i_pwrite & pready_q);
  assign /*output*/ o_prdata = sram_q;

  // -----------------------------------------------------------------------------
  assign pready_d = o_pready;

  always_comb
    // Bus access
    if (i_mem_write | i_mem_read) begin
      sram_cen  = ~(i_mem_write | i_mem_read);
      sram_gwen = ~i_mem_write;
      sram_a    =  i_mem_addr;
      sram_wen  = ~i_mem_wmask;
      sram_d    =  i_mem_wdata;
    end
    // APB access
    else if (i_penable) begin
      sram_cen  =  1'b0;
      sram_gwen = ~i_pwrite;
      sram_a    =  i_paddr[31:2];
      sram_wen  = ~{32{i_pwrite}};
      sram_d    =  i_pwdata;
    end
    else begin
      sram_cen  = 1'b1;
      sram_gwen = {32{1'b1}};
      sram_a    = 12'b0;
      sram_wen  = 1'b1;
      sram_d    = 32'b0;
    end

  aib_mem u_aib_mem (
    .CLK   (i_clk),
    .CEN   (sram_cen),
    .GWEN  (sram_gwen),
    .A     (sram_a),
    .WEN   (sram_wen),
    .D     (sram_d),
    .Q     (sram_q),

    .STOV  (1'b0),
    .EMA   (3'd2),
    .EMAW  (2'd1),
    .EMAS  (1'b0),
    .RET1N (1'b1)
  );

  // Flip flops
  // -----------------------------------------------------------------------------
  always @(posedge i_clk or negedge i_rst_n)
    if (!i_rst_n)
      pready_q <= 1'b0;
    else
      pready_q <= pready_d;

endmodule

