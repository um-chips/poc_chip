
module iomux
(
  input  logic  [   2 : 0 ] pad_sw_Y,
  output logic  [   2 : 0 ] pad_sw_A,
  output logic  [   2 : 0 ] pad_sw_OE,
  output logic  [   2 : 0 ] pad_sw_IE,
  output logic  [   2 : 0 ] pad_sw_DS0,
  output logic  [   2 : 0 ] pad_sw_DS1,
  output logic  [   2 : 0 ] pad_sw_SR,
  output logic  [   2 : 0 ] pad_sw_PE,
  output logic  [   2 : 0 ] pad_sw_PS,
  output logic  [   2 : 0 ] pad_sw_IS,
  output logic  [   2 : 0 ] pad_sw_POE,

  input  logic  [  10 : 0 ] pad_io_Y,
  output logic  [  10 : 0 ] pad_io_A,
  output logic  [  10 : 0 ] pad_io_OE,
  output logic  [  10 : 0 ] pad_io_IE,
  output logic  [  10 : 0 ] pad_io_DS0,
  output logic  [  10 : 0 ] pad_io_DS1,
  output logic  [  10 : 0 ] pad_io_SR,
  output logic  [  10 : 0 ] pad_io_PE,
  output logic  [  10 : 0 ] pad_io_PS,
  output logic  [  10 : 0 ] pad_io_IS,
  output logic  [  10 : 0 ] pad_io_POE,

  output logic  p1_clkgen_bypass_i,
  output logic  p1_clkgen_bypass_clk_i,
  output logic  p1_chip_rst_n_i,
  output logic  p1_scan_phi_i,
  output logic  p1_scan_phi_bar_i,
  output logic  p1_scan_load_chip_i,
  output logic  p1_scan_load_chain_i,
  output logic  p1_scan_data_in_i,
  input  logic  p1_scan_data_out_o,
  input  logic  p1_clkgen_osc_slow_clk_o,

  output logic  p2_clk,
  output logic  p2_rst,
  output logic  p2_phi,
  output logic  p2_phi_bar,
  output logic  p2_load_chip,
  output logic  p2_load_chain,
  output logic  p2_data_in,
  output logic  p2_en,
  input  logic  p2_data_out,
  input  logic  p2_done,

  output logic  p3_s_en,
  output logic  p3_s_clk,
  output logic  p3_mosi,
  input  logic  p3_miso,

  output logic  p4_1_i_rst_n,
  output logic  p4_1_i_bypass,
  output logic  p4_1_i_bypass_clk,
  output logic  p4_1_i_uart_rx_aib,
  output logic  p4_1_i_uart_rx_dbg,
  output logic  p4_1_i_uart_rx_cpu,
  input  logic  p4_1_o_aib_slow_clk,
  input  logic  p4_1_o_aux_slow_clk,
  input  logic  p4_1_o_uart_tx_aib,
  input  logic  p4_1_o_uart_tx_dbg,
  input  logic  p4_1_o_uart_tx_cpu,

  output logic  p4_2_i_rst_n,
  output logic  p4_2_i_bypass,
  output logic  p4_2_i_bypass_clk,
  output logic  p4_2_i_uart_rx_aib,
  output logic  p4_2_i_uart_rx_dbg,
  output logic  p4_2_i_uart_rx_cpu,
  input  logic  p4_2_o_aib_slow_clk,
  input  logic  p4_2_o_aux_slow_clk,
  input  logic  p4_2_o_uart_tx_aib,
  input  logic  p4_2_o_uart_tx_dbg,
  input  logic  p4_2_o_uart_tx_cpu,

  output logic  p4_3_i_rst_n,
  output logic  p4_3_i_bypass,
  output logic  p4_3_i_bypass_clk,
  output logic  p4_3_i_uart_rx_aib,
  output logic  p4_3_i_uart_rx_dbg,
  output logic  p4_3_i_uart_rx_cpu,
  input  logic  p4_3_o_aib_slow_clk,
  input  logic  p4_3_o_aux_slow_clk,
  input  logic  p4_3_o_uart_tx_aib,
  input  logic  p4_3_o_uart_tx_dbg,
  input  logic  p4_3_o_uart_tx_cpu,

  output logic  p4_4_i_rst_n,
  output logic  p4_4_i_bypass,
  output logic  p4_4_i_bypass_clk,
  output logic  p4_4_i_uart_rx_aib,
  output logic  p4_4_i_uart_rx_dbg,
  output logic  p4_4_i_uart_rx_cpu,
  input  logic  p4_4_o_aib_slow_clk,
  input  logic  p4_4_o_aux_slow_clk,
  input  logic  p4_4_o_uart_tx_aib,
  input  logic  p4_4_o_uart_tx_dbg,
  input  logic  p4_4_o_uart_tx_cpu
);
  // Switch pads
  // ---------------------------------------------------------------------------
  wire  [   2 : 0 ] sw = pad_sw_Y;

  assign /*output*/ pad_sw_A   = {3{1'b0}};
  assign /*output*/ pad_sw_OE  = {3{1'b0}};
  assign /*output*/ pad_sw_IE  = {3{1'b1}};
  assign /*output*/ pad_sw_DS0 = {3{1'b0}};
  assign /*output*/ pad_sw_DS1 = {3{1'b0}};
  assign /*output*/ pad_sw_SR  = {3{1'b1}};
  assign /*output*/ pad_sw_PE  = {3{1'b0}};
  assign /*output*/ pad_sw_PS  = {3{1'b0}};
  assign /*output*/ pad_sw_IS  = {3{1'b0}};
  assign /*output*/ pad_sw_POE = {3{1'b0}};

  // Regular IO pads
  // ---------------------------------------------------------------------------

  // DS0 DS1  SR Drive Slew
  //   0   0   0   2mA fast
  //   0   1   0   4mA fast
  //   1   0   0   8mA fast
  //   1   1   0  12mA fast
  //   0   0   1   2mA slow
  //   0   1   1   4mA slow
  //   1   0   1   8mA slow
  //   1   1   1  12mA slow

  assign /*output*/ pad_io_DS0 = {3{1'b1}};
  assign /*output*/ pad_io_DS1 = {3{1'b0}};
  assign /*output*/ pad_io_SR  = {3{1'b0}};
  assign /*output*/ pad_io_PE  = {3{1'b0}};
  assign /*output*/ pad_io_PS  = {3{1'b0}};
  assign /*output*/ pad_io_IS  = {3{1'b0}};
  assign /*output*/ pad_io_POE = {3{1'b0}};

  wire sel_p1   = (sw == 3'd0);
  wire sel_p2   = (sw == 3'd1);
  wire sel_p3   = (sw == 3'd2);
  wire sel_p4_1 = (sw == 3'd3);
  wire sel_p4_2 = (sw == 3'd4);
  wire sel_p4_3 = (sw == 3'd5);
  wire sel_p4_4 = (sw == 3'd6);

  always_comb begin
    pad_io_OE = 11'b0;
    pad_io_IE = 11'b0;

    case (sw)
      3'd0: begin
        pad_io_OE = 11'b000_0000_0011;
        pad_io_IE = 11'b011_1111_1100;
      end

      3'd1: begin
        pad_io_OE = 11'b000_0000_1100;
        pad_io_IE = 11'b011_1111_0011;
      end

      3'd2: begin
        pad_io_OE = 11'b000_0001_0000;
        pad_io_IE = 11'b000_0000_0111;
      end

      3'd3, 3'd4, 3'd5, 3'd6: begin
        pad_io_OE = 11'b011_1110_0000;
        pad_io_IE = 11'b100_0001_1111;
      end
    endcase
  end

  // Partition 1
  // ---------------------------------------------------------------------------
  assign p1_clkgen_bypass_i     = sel_p1 ? pad_io_Y[2] : 1'b0;
  assign p1_clkgen_bypass_clk_i = sel_p1 ? pad_io_Y[3] : 1'b0;
  assign p1_chip_rst_n_i        = sel_p1 ? pad_io_Y[4] : 1'b0;
  assign p1_scan_phi_i          = sel_p1 ? pad_io_Y[5] : 1'b0;
  assign p1_scan_phi_bar_i      = sel_p1 ? pad_io_Y[6] : 1'b0;
  assign p1_scan_load_chip_i    = sel_p1 ? pad_io_Y[7] : 1'b0;
  assign p1_scan_load_chain_i   = sel_p1 ? pad_io_Y[8] : 1'b0;
  assign p1_scan_data_in_i      = sel_p1 ? pad_io_Y[9] : 1'b0;

  assign pad_io_A[0] = sel_p1 ? p1_scan_data_out_o       : 1'b0;
  assign pad_io_A[1] = sel_p1 ? p1_clkgen_osc_slow_clk_o : 1'b0;

  // Partition 2
  // ---------------------------------------------------------------------------
  assign p2_clk        = sel_p2 ? pad_io_Y[8] : 1'b0;
  assign p2_rst        = sel_p2 ? pad_io_Y[0] : 1'b1;
  assign p2_phi        = sel_p2 ? pad_io_Y[1] : 1'b0;
  assign p2_phi_bar    = sel_p2 ? pad_io_Y[4] : 1'b0;
  assign p2_load_chip  = sel_p2 ? pad_io_Y[5] : 1'b0;
  assign p2_load_chain = sel_p2 ? pad_io_Y[6] : 1'b0;
  assign p2_data_in    = sel_p2 ? pad_io_Y[7] : 1'b0;
  assign p2_en         = sel_p2 ? pad_io_Y[9] : 1'b0;

  assign pad_io_A[2] = sel_p2 ? p2_data_out : 1'b0;
  assign pad_io_A[3] = sel_p2 ? p2_done     : 1'b0;

  // Partition 3
  // ---------------------------------------------------------------------------
  assign p3_s_en  = sel_p3 ? pad_io_Y[0] : 1'b0;
  assign p3_s_clk = sel_p3 ? pad_io_Y[1] : 1'b0;
  assign p3_mosi  = sel_p3 ? pad_io_Y[2] : 1'b0;

  assign pad_io_A[4] = sel_p3 ? p3_miso : 1'b0;

  // Partition 4
  // ---------------------------------------------------------------------------
  // Subpartition 1
  assign p4_1_i_rst_n       = sel_p4_1 ? pad_io_Y[ 0] : 1'b0;
  assign p4_1_i_bypass      = sel_p4_1 ? pad_io_Y[ 1] : 1'b0;
  assign p4_1_i_bypass_clk  = sel_p4_1 ? pad_io_Y[ 2] : 1'b0;
  assign p4_1_i_uart_rx_aib = sel_p4_1 ? pad_io_Y[ 3] : 1'b1;
  assign p4_1_i_uart_rx_dbg = sel_p4_1 ? pad_io_Y[ 4] : 1'b1;
  assign p4_1_i_uart_rx_cpu = sel_p4_1 ? pad_io_Y[10] : 1'b1;

  // Subpartition 2
  assign p4_2_i_rst_n       = sel_p4_2 ? pad_io_Y[ 0] : 1'b0;
  assign p4_2_i_bypass      = sel_p4_2 ? pad_io_Y[ 1] : 1'b0;
  assign p4_2_i_bypass_clk  = sel_p4_2 ? pad_io_Y[ 2] : 1'b0;
  assign p4_2_i_uart_rx_aib = sel_p4_2 ? pad_io_Y[ 3] : 1'b1;
  assign p4_2_i_uart_rx_dbg = sel_p4_2 ? pad_io_Y[ 4] : 1'b1;
  assign p4_2_i_uart_rx_cpu = sel_p4_2 ? pad_io_Y[10] : 1'b1;

  // Subpartition 3
  assign p4_3_i_rst_n       = sel_p4_3 ? pad_io_Y[ 0] : 1'b0;
  assign p4_3_i_bypass      = sel_p4_3 ? pad_io_Y[ 1] : 1'b0;
  assign p4_3_i_bypass_clk  = sel_p4_3 ? pad_io_Y[ 2] : 1'b0;
  assign p4_3_i_uart_rx_aib = sel_p4_3 ? pad_io_Y[ 3] : 1'b1;
  assign p4_3_i_uart_rx_dbg = sel_p4_3 ? pad_io_Y[ 4] : 1'b1;
  assign p4_3_i_uart_rx_cpu = sel_p4_3 ? pad_io_Y[10] : 1'b1;

  // Subpartition 4
  assign p4_4_i_rst_n       = sel_p4_4 ? pad_io_Y[ 0] : 1'b0;
  assign p4_4_i_bypass      = sel_p4_4 ? pad_io_Y[ 1] : 1'b0;
  assign p4_4_i_bypass_clk  = sel_p4_4 ? pad_io_Y[ 2] : 1'b0;
  assign p4_4_i_uart_rx_aib = sel_p4_4 ? pad_io_Y[ 3] : 1'b1;
  assign p4_4_i_uart_rx_dbg = sel_p4_4 ? pad_io_Y[ 4] : 1'b1;
  assign p4_4_i_uart_rx_cpu = sel_p4_4 ? pad_io_Y[10] : 1'b1;

  always_comb begin
    pad_io_A[5] = 1'b0;
    pad_io_A[6] = 1'b0;
    pad_io_A[7] = 1'b0;
    pad_io_A[8] = 1'b0;
    pad_io_A[9] = 1'b0;

    case (sw)
      3'd3: begin
        pad_io_A[5] = p4_1_o_aib_slow_clk;
        pad_io_A[6] = p4_1_o_aux_slow_clk;
        pad_io_A[7] = p4_1_o_uart_tx_aib;
        pad_io_A[8] = p4_1_o_uart_tx_dbg;
        pad_io_A[9] = p4_1_o_uart_tx_cpu;
      end

      3'd4: begin
        pad_io_A[5] = p4_2_o_aib_slow_clk;
        pad_io_A[6] = p4_2_o_aux_slow_clk;
        pad_io_A[7] = p4_2_o_uart_tx_aib;
        pad_io_A[8] = p4_2_o_uart_tx_dbg;
        pad_io_A[9] = p4_2_o_uart_tx_cpu;
      end

      3'd5: begin
        pad_io_A[5] = p4_3_o_aib_slow_clk;
        pad_io_A[6] = p4_3_o_aux_slow_clk;
        pad_io_A[7] = p4_3_o_uart_tx_aib;
        pad_io_A[8] = p4_3_o_uart_tx_dbg;
        pad_io_A[9] = p4_3_o_uart_tx_cpu;
      end

      3'd6: begin
        pad_io_A[5] = p4_4_o_aib_slow_clk;
        pad_io_A[6] = p4_4_o_aux_slow_clk;
        pad_io_A[7] = p4_4_o_uart_tx_aib;
        pad_io_A[8] = p4_4_o_uart_tx_dbg;
        pad_io_A[9] = p4_4_o_uart_tx_cpu;
      end
    endcase
  end

  assign pad_io_A[10] = 1'b0;

endmodule

