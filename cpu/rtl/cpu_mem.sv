
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module cpu_mem
(
  input  logic              i_clk,
  input  logic              i_rst_n,

  input  logic              i_imem_stb,
  output logic              o_imem_stall,
  output logic              o_imem_ack,
  input  logic  [  31 : 0 ] i_imem_addr,
  input  logic  [   3 : 0 ] i_imem_sel,
  output logic  [  31 : 0 ] o_imem_rdata,

  input  logic              i_dmem_stb,
  output logic              o_dmem_stall,
  output logic              o_dmem_ack,
  input  logic              i_dmem_we,
  input  logic  [  31 : 0 ] i_dmem_addr,
  input  logic  [   3 : 0 ] i_dmem_sel,
  input  logic  [  31 : 0 ] i_dmem_wdata,
  output logic  [  31 : 0 ] o_dmem_rdata,

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
  logic             sram_wen;
  logic [  31 : 0 ] sram_gwen;
  logic [  13 : 0 ] sram_a;
  logic [  31 : 0 ] sram_d;
  logic [  31 : 0 ] sram_q;

  // -----------------------------------------------------------------------------
  assign /*output*/ o_imem_stall = 1'b0;
  assign /*output*/ o_dmem_stall = i_imem_stb;

  assign /*output*/ o_imem_rdata = sram_q;
  assign /*output*/ o_dmem_rdata = sram_q;

  assign /*output*/ o_pready = ~(i_penable & !i_pwrite & pready_q);
  assign /*output*/ o_prdata = sram_q;

  // -----------------------------------------------------------------------------
  assign pready_d = o_pready;

  always_comb
    // Instruction memory access
    if (i_imem_stb) begin
      sram_cen  =  1'b0;
      sram_wen  =  1'b1;
      sram_gwen =  {32{1'b1}};
      sram_a    =  i_imem_addr[31:2];
      sram_d    =  32'b0;
    end
    // Data memory access
    else if (i_dmem_stb) begin
      sram_cen  =  1'b0;
      sram_wen  = ~i_dmem_we;
      sram_gwen =  i_dmem_we ? ~{{8{i_dmem_sel[3]}},
                                 {8{i_dmem_sel[2]}},
                                 {8{i_dmem_sel[1]}},
                                 {8{i_dmem_sel[0]}}} : {32{1'b1}};
      sram_a    =  i_dmem_addr[31:2];
      sram_d    =  i_dmem_wdata;
    end
    // APB access
    else if (i_penable) begin
      sram_cen  =  1'b0;
      sram_wen  = ~i_pwrite;
      sram_gwen = ~{32{i_pwrite}};
      sram_a    =  i_paddr[31:2];
      sram_d    =  i_pwdata;
    end
    else begin
      sram_cen  =  1'b1;
      sram_wen  =  1'b1;
      sram_gwen =  {32{1'b1}};
      sram_a    =  i_imem_addr[31:2];
      sram_d    =  i_dmem_wdata;
    end

  // Flip flops
  // -----------------------------------------------------------------------------
  always @(posedge i_clk or negedge i_rst_n)
    if (!i_rst_n) begin
      pready_q <= 1'b1;

      o_imem_ack <= 1'b0;
      o_dmem_ack <= 1'b0;
    end
    else begin
      pready_q <= pready_d;

      o_imem_ack <= i_imem_stb;
      o_dmem_ack <= i_dmem_stb & !o_dmem_stall;
    end

  sys_mem u_code_mem (
    .CLK   (i_clk),
    .CEN   (sram_cen),
    .GWEN  (sram_wen),
    .A     (sram_a),
    .WEN   (sram_gwen),
    .D     (sram_d),
    .Q     (sram_q),

    .STOV  (1'b0),
    .EMA   (3'd2),
    .EMAW  (2'd1),
    .EMAS  (1'b0),
    .RET1N (1'b1)
  );

endmodule

