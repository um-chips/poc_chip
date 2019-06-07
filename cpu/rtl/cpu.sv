
// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module cpu
(
  input  logic              i_clk,
  input  logic              i_rst_n,

  output logic              o_uart_tx_dbg,
  input  logic              i_uart_rx_dbg,

  output logic              o_uart_tx_cpu,
  input  logic              i_uart_rx_cpu,

  output logic              o_aib_stb,
  output logic              o_aib_we,
  output logic  [  31 : 0 ] o_aib_addr,
  output logic  [   3 : 0 ] o_aib_sel,
  output logic  [  31 : 0 ] o_aib_wdata,
  input  logic              i_aib_stall,
  input  logic              i_aib_ack,
  input  logic  [  31 : 0 ] i_aib_rdata,

  output logic              o_aib_penable,
  output logic              o_aib_pwrite,
  output logic  [  31 : 0 ] o_aib_paddr,
  output logic  [  31 : 0 ] o_aib_pwdata,
  input  logic              i_aib_pready,
  input  logic  [  31 : 0 ] i_aib_prdata
);
  // ---------------------------------------------------------------------------
  logic         [  31 : 0 ] imem_addr;
  logic         [  31 : 0 ] imem_rdata;
  logic         [   3 : 0 ] imem_sel;
  logic                     imem_stb;
  logic                     imem_stall;
  logic                     imem_ack;

  logic         [  31 : 0 ] dmem_addr;
  logic         [  31 : 0 ] dmem_wdata;
  logic         [  31 : 0 ] dmem_rdata;
  logic         [   3 : 0 ] dmem_sel;
  logic                     dmem_we;
  logic                     dmem_stb;
  logic                     dmem_stall;
  logic                     dmem_ack;

  logic         [  31 : 0 ] soc_addr;
  logic         [  31 : 0 ] soc_data_w;
  logic         [  31 : 0 ] soc_data_r;
  logic                     soc_we;
  logic                     soc_stb;
  logic                     soc_ack;
  logic                     soc_irq;

  logic                     penable;
  logic                     pwrite;
  logic         [  31 : 0 ] paddr;
  logic         [  31 : 0 ] pwdata;
  logic                     pready;
  logic         [  31 : 0 ] prdata;

  logic                     penable_reg;
  logic                     penable_aib;
  logic                     penable_mem;

  logic                     pready_aib;
  logic                     pready_mem;

  logic         [  31 : 0 ] prdata_reg;
  logic         [  31 : 0 ] prdata_aib;
  logic         [  31 : 0 ] prdata_mem;

  logic                     c_cpu_en;
  logic                     c_icache_en;
  logic                     c_colli_dis;

  logic         [  31 : 0 ] c_boot_vector;
  logic         [  31 : 0 ] c_isr_vector;
  logic         [  31 : 0 ] c_clk_khz;
  logic         [  31 : 0 ] c_uart_divisor;

  logic         [  15 : 0 ] c_baud_cyc;

  // ---------------------------------------------------------------------------
  assign /*output*/ o_aib_penable = penable_aib;
  assign /*output*/ o_aib_pwrite  = pwrite;
  assign /*output*/ o_aib_paddr   = paddr;
  assign /*output*/ o_aib_pwdata  = pwdata;

  // ---------------------------------------------------------------------------
  assign penable_reg = penable && (paddr[31:30] == 2'b10);
  assign penable_aib = penable && (paddr[31:30] == 2'b01);
  assign penable_mem = penable && (paddr[31:30] == 2'b00);

  always_comb begin
    pready = 1'b1;
    prdata = 32'b0;

    case (paddr[31:30])
      2'b10: begin
        pready = 1'b1;
        prdata = prdata_reg;
      end

      2'b01: begin
        pready = i_aib_pready;
        prdata = i_aib_prdata;
      end

      default: begin
        pready = pready_mem;
        prdata = prdata_mem;
      end
    endcase
  end

  dbg u_dbg (
    .i_clk      (i_clk),
    .i_rst_n    (i_rst_n),

    .o_tx       (o_uart_tx_dbg),
    .i_rx       (i_uart_rx_dbg),

    .c_baud_cyc (c_baud_cyc),

    .o_penable  (penable),
    .o_pwrite   (pwrite),
    .o_paddr    (paddr),
    .o_pwdata   (pwdata),
    .i_pready   (pready),
    .i_prdata   (prdata)
  );

  // ---------------------------------------------------------------------------
  cpu_reg u_cpu_reg (
    .i_clk                  (i_clk),
    .i_rst_n                (i_rst_n),

    .i_penable              (penable_reg),
    .i_pwrite               (pwrite),
    .i_paddr                (paddr),
    .i_pwdata               (pwdata),
    .o_prdata               (prdata_reg),

    .c_cpu_en               (c_cpu_en),
    .c_icache_en            (c_icache_en),
    .c_colli_dis            (c_colli_dis),

    .c_boot_vector          (c_boot_vector),
    .c_isr_vector           (c_isr_vector),
    .c_clk_khz              (c_clk_khz),
    .c_uart_divisor         (c_uart_divisor),

    .c_baud_cyc             (c_baud_cyc)
  );

  // -----------------------------------------------------------------------------
  cpu_mem u_cpu_mem (
    .i_clk                  (i_clk),
    .i_rst_n                (i_rst_n),

    .i_imem_stb             (imem_stb),
    .o_imem_stall           (imem_stall),
    .o_imem_ack             (imem_ack),
    .i_imem_addr            (imem_addr),
    .i_imem_sel             (imem_sel),
    .o_imem_rdata           (imem_rdata),

    .i_dmem_stb             (dmem_stb),
    .o_dmem_stall           (dmem_stall),
    .o_dmem_ack             (dmem_ack),
    .i_dmem_we              (dmem_we),
    .i_dmem_addr            (dmem_addr),
    .i_dmem_sel             (dmem_sel),
    .i_dmem_wdata           (dmem_wdata),
    .o_dmem_rdata           (dmem_rdata),

    .i_penable              (penable_mem),
    .i_pwrite               (pwrite),
    .i_paddr                (paddr),
    .i_pwdata               (pwdata),
    .o_pready               (pready_mem),
    .o_prdata               (prdata_mem)
  );

  // CPU
  // -----------------------------------------------------------------------------
  logic cpu_rst, cpu_rst_n;

  assign cpu_rst = ~i_rst_n | ~c_cpu_en;

  reset_sync cpu_rst_sync (.i_clk(i_clk), .i_rst_n(~cpu_rst), .o_rst_n(cpu_rst_n));

  cpu_if #(.ENABLE_ICACHE("ENABLED"),
           .ENABLE_DCACHE("DISABLED"),
           .REGISTER_FILE_TYPE("SIMULATION")) u_cpu (
    // General - clocking & reset
    .clk_i                  (i_clk),
    .rst_i                  (~cpu_rst_n),

    .cfg_icache_en          (c_icache_en),
    .cfg_colli_dis          (c_colli_dis),
    .cfg_boot_vector        (c_boot_vector),
    .cfg_isr_vector         (c_isr_vector),

    .fault_o                (),
    .break_o                (),
    .nmi_i                  (1'b0),
    .intr_i                 (soc_irq),

    // Instruction Memory 0 (0x10000000 - 0x10FFFFFF)
    .imem0_addr_o           (imem_addr),
    .imem0_data_i           (imem_rdata),
    .imem0_sel_o            (imem_sel),
    .imem0_stb_o            (imem_stb),
    .imem0_cti_o            (),
    .imem0_cyc_o            (),
    .imem0_stall_i          (imem_stall),
    .imem0_ack_i            (imem_ack),

    // Data Memory 0 (0x10000000 - 0x10FFFFFF)
    .dmem0_addr_o           (dmem_addr),
    .dmem0_data_o           (dmem_wdata),
    .dmem0_data_i           (dmem_rdata),
    .dmem0_sel_o            (dmem_sel),
    .dmem0_we_o             (dmem_we),
    .dmem0_stb_o            (dmem_stb),
    .dmem0_cti_o            (),
    .dmem0_cyc_o            (),
    .dmem0_stall_i          (dmem_stall),
    .dmem0_ack_i            (dmem_ack),

    // Data Memory 1 (0x11000000 - 0x11FFFFFF)
    .dmem1_addr_o           (o_aib_addr),
    .dmem1_data_o           (o_aib_wdata),
    .dmem1_data_i           (i_aib_rdata),
    .dmem1_sel_o            (o_aib_sel),
    .dmem1_we_o             (o_aib_we),
    .dmem1_stb_o            (o_aib_stb),
    .dmem1_cyc_o            (),
    .dmem1_cti_o            (),
    .dmem1_stall_i          (i_aib_stall),
    .dmem1_ack_i            (i_aib_ack),

    // Data Memory 2 (0x12000000 - 0x12FFFFFF)
    .dmem2_addr_o           (soc_addr),
    .dmem2_data_o           (soc_data_w),
    .dmem2_data_i           (soc_data_r),
    .dmem2_sel_o            (),
    .dmem2_we_o             (soc_we),
    .dmem2_stb_o            (soc_stb),
    .dmem2_cyc_o            (),
    .dmem2_cti_o            (),
    .dmem2_stall_i          (1'b0),
    .dmem2_ack_i            (soc_ack)
  );

  // CPU SOC
  // -----------------------------------------------------------------------------
  soc
  #(
    .ENABLE_SYSTICK_TIMER("ENABLED"),
    .ENABLE_HIGHRES_TIMER("ENABLED"),
    .EXTERNAL_INTERRUPTS(1)
  )
  u_soc (
    // General - clocking & reset
    .clk_i                  (i_clk),
    .rst_i                  (~i_rst_n),

    .cfg_clk_khz            (c_clk_khz),
    .cfg_uart_divisor       (c_uart_divisor),

    .ext_intr_i             (1'b0),
    .intr_o                 (soc_irq),

    .uart_tx_o              (o_uart_tx_cpu),
    .uart_rx_i              (i_uart_rx_cpu),

    // Memory Port
    .io_addr_i              (soc_addr),
    .io_data_i              (soc_data_w),
    .io_data_o              (soc_data_r),
    .io_we_i                (soc_we),
    .io_stb_i               (soc_stb),
    .io_ack_o               (soc_ack)
  );

endmodule
