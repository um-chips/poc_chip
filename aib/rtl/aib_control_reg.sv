
module aib_control_reg #(parameter NumIo = 1)
(
  input  logic              i_clk,
  input  logic              i_rst_n,

  input  logic              i_penable,
  input  logic              i_pwrite,
  input  logic  [  31 : 0 ] i_paddr,
  input  logic  [  31 : 0 ] i_pwdata,
  output logic              o_pready,
  output logic  [  31 : 0 ] o_prdata,

  input  logic              i_aib_ready,

  output logic  [   2 : 0 ] c_chn_mode, // [2]: 1 = master mode, 0 = slave mode
                                        // [1]: 1 = DDR mode, 0 = SDR mode
                                        // [0]: 1 = loop back mode, 0 = normal mode
  output logic              c_config_done,
  output logic              c_skip_hrdrst,

  output logic  [  11 : 0 ] c_aib_clkgen_cfg, // [11]:  en
                                              // [10]:  cfg en
                                              // [ 9]:  byp en
                                              // [ 8]:  fwd en
                                              // [7:4]: osc sel
                                              // [3:2]: div1 sel
                                              // [1:0]: div0 sel
  output logic  [  11 : 0 ] c_aux_clkgen_cfg,
  output logic              c_cfg_chg,
  output logic  [  15 : 0 ] c_baud_cyc,
  output logic  [   7 : 0 ] c_dll_tap,

  output logic              c_ddr_mode   [NumIo],
  output logic              c_async_mode [NumIo],
  output logic              c_tx_en      [NumIo],
  output logic              c_pull_en    [NumIo],
  output logic              c_pull_dir   [NumIo],
  output logic  [   2 : 0 ] c_pdrv       [NumIo],
  output logic  [   2 : 0 ] c_ndrv       [NumIo],
  output logic  [   7 : 0 ] c_tx_dly_tap [NumIo],
  output logic  [   7 : 0 ] c_rx_dly_tap [NumIo],

  output logic  [   2 : 0 ] c_rx_wptr_init,
  output logic  [   2 : 0 ] c_rx_rptr_init,
  output logic  [   1 : 0 ] c_fifo_mode,

  output logic              c_agent_en,
  output logic  [  15 : 0 ] c_agent_loop_cnt,
  output logic  [  19 : 0 ] c_agent_pattern0 [8],
  output logic  [  19 : 0 ] c_agent_pattern1 [8],
  input  logic              c_test_pass,
  input  logic              c_test_fail,
  input  logic  [  15 : 0 ] c_test_fail_cnt,
  input  logic  [  19 : 0 ] c_test_fail_data0,
  input  logic  [  19 : 0 ] c_test_fail_data1,
  input  logic              c_test_timeout
);
  logic             pready_d, pready_q;
  logic [  31 : 0 ] prdata_d, prdata_q;

  logic [   2 : 0 ] chn_mode_d,    chn_mode_q;
  logic [   1 : 0 ] fifo_mode_d,   fifo_mode_q;
  logic             config_done_d, config_done_q;
  logic             skip_hrdrst_d, skip_hrdrst_q;

  logic [  11 : 0 ] aib_clkgen_cfg_d, aib_clkgen_cfg_q;
  logic [  11 : 0 ] aux_clkgen_cfg_d, aux_clkgen_cfg_q;
  logic             cfg_chg_d,        cfg_chg_q;
  logic [  15 : 0 ] baud_cyc_d,       baud_cyc_q;
  logic [   7 : 0 ] dll_tap_d,        dll_tap_q;
  logic [   2 : 0 ] rx_wptr_init_d,   rx_wptr_init_q;
  logic [   2 : 0 ] rx_rptr_init_d,   rx_rptr_init_q;

  logic [  26 : 0 ] buffer_config_d [NumIo], buffer_config_q [NumIo];

  logic             agent_en_d, agent_en_q;
  logic [  15 : 0 ] agent_loop_cnt_d, agent_loop_cnt_q;
  logic [  19 : 0 ] agent_pattern0_d [8], agent_pattern0_q [8];
  logic [  19 : 0 ] agent_pattern1_d [8], agent_pattern1_q [8];

  logic             cfg_clkgen;
  logic [   7 : 0 ] cfg_dly_cnt_d, cfg_dly_cnt_q;

  // ---------------------------------------------------------------------------
  assign /*output*/ o_pready = ~(i_penable & !i_pwrite & pready_q);
  assign /*output*/ o_prdata = prdata_q;

  assign /*output*/ c_chn_mode    = chn_mode_q;
  assign /*output*/ c_fifo_mode   = fifo_mode_q;
  assign /*output*/ c_config_done = config_done_q;
  assign /*output*/ c_skip_hrdrst = skip_hrdrst_q;

  assign /*output*/ c_aib_clkgen_cfg = aib_clkgen_cfg_q;
  assign /*output*/ c_aux_clkgen_cfg = aux_clkgen_cfg_q;
  assign /*output*/ c_cfg_chg        = cfg_chg_q;
  assign /*output*/ c_baud_cyc       = baud_cyc_q;
  assign /*output*/ c_dll_tap        = dll_tap_q;
  assign /*output*/ c_rx_wptr_init   = rx_wptr_init_q;
  assign /*output*/ c_rx_rptr_init   = rx_rptr_init_q;

  always_comb
    for (int i = 0; i < NumIo; i++) begin
      c_ddr_mode   [i] /*output*/ = buffer_config_q[i][26];
      c_async_mode [i] /*output*/ = buffer_config_q[i][25];
      c_tx_en      [i] /*output*/ = buffer_config_q[i][24];
      c_pull_en    [i] /*output*/ = buffer_config_q[i][23];
      c_pull_dir   [i] /*output*/ = buffer_config_q[i][22];
      c_pdrv       [i] /*output*/ = buffer_config_q[i][21:19];
      c_ndrv       [i] /*output*/ = buffer_config_q[i][18:16];
      c_tx_dly_tap [i] /*output*/ = buffer_config_q[i][15: 8];
      c_rx_dly_tap [i] /*output*/ = buffer_config_q[i][ 7: 0];
    end

  assign /*output*/ c_agent_en       = agent_en_q;
  assign /*output*/ c_agent_loop_cnt = agent_loop_cnt_q;
  assign /*output*/ c_agent_pattern0 = agent_pattern0_q;
  assign /*output*/ c_agent_pattern1 = agent_pattern1_q;

  // Write data path
  // ---------------------------------------------------------------------------
  always_comb begin
    chn_mode_d    = chn_mode_q;
    fifo_mode_d   = fifo_mode_q;
    config_done_d = config_done_q;
    skip_hrdrst_d = skip_hrdrst_q;

    aib_clkgen_cfg_d = aib_clkgen_cfg_q;
    aux_clkgen_cfg_d = aux_clkgen_cfg_q;
    baud_cyc_d       = baud_cyc_q;
    dll_tap_d        = dll_tap_q;
    rx_wptr_init_d   = rx_wptr_init_q;
    rx_rptr_init_d   = rx_rptr_init_q;

    buffer_config_d = buffer_config_q;

    agent_en_d       = agent_en_q;
    agent_loop_cnt_d = agent_loop_cnt_q;
    agent_pattern0_d = agent_pattern0_q;
    agent_pattern1_d = agent_pattern1_q;

    cfg_clkgen = 1'b0;

    if (i_penable & i_pwrite)
      case (i_paddr[13:12])
        2'd0:
          case (i_paddr[9:2])
            8'h00: chn_mode_d = i_pwdata[2:0];
            8'h01: fifo_mode_d = i_pwdata[1:0];
            8'h04: {skip_hrdrst_d, config_done_d} = i_pwdata[1:0];
          endcase

        2'd1:
          case (i_paddr[9:2])
            8'h00: aib_clkgen_cfg_d = i_pwdata[11:0];
            8'h01: aux_clkgen_cfg_d = i_pwdata[11:0];
            8'h02: cfg_clkgen       = 1'b1;
            8'h08: baud_cyc_d       = i_pwdata[15:0];
            8'h10: dll_tap_d        = i_pwdata[7:0];
            8'h18: begin
              rx_rptr_init_d = i_pwdata[2:0];
              rx_wptr_init_d = i_pwdata[6:4];
            end
          endcase

        2'd2:
          if (i_paddr[9:2] == 8'h80) begin
            // Master mode default IO buffer configuration
            if (chn_mode_q[2]) begin // TODO add false path in synthesis

for (int i = 0; i < NumIo; i++)
       if (i < 28) buffer_config_d[i] = (                                    1<<23 | 6<<19 | 1<<16);
  else if (i < 48) buffer_config_d[i] = (chn_mode_q[1]<<26 |         1<<24 | 1<<23 | 6<<19 | 1<<16);
  else if (i < 50) buffer_config_d[i] = (            1<<26 |         1<<24 | 1<<23 | 6<<19 | 1<<16);
  else if (i < 52) buffer_config_d[i] = (                            1<<24 | 1<<23 | 6<<19 | 1<<16);
  else if (i < 54) buffer_config_d[i] = (            1<<26 |         1<<24 | 1<<23 | 6<<19 | 1<<16);
  else if (i < 56) buffer_config_d[i] = (                    1<<25 | 1<<24 | 1<<23 | 6<<19 | 1<<16);
  else             buffer_config_d[i] = (            1<<26 |         1<<24 | 1<<23 | 6<<19 | 1<<16);

            end
            // Slave mode default IO buffer configuration
            else begin

for (int i = 0; i < NumIo; i++)
       if (i < 20) buffer_config_d[i] = (chn_mode_q[1]<<26 |         1<<24 | 1<<23 | 6<<19 | 1<<16);
  else if (i < 22) buffer_config_d[i] = (            1<<26 |         1<<24 | 1<<23 | 6<<19 | 1<<16);
  else if (i < 24) buffer_config_d[i] = (                            1<<24 | 1<<23 | 6<<19 | 1<<16);
  else if (i < 26) buffer_config_d[i] = (            1<<26 |         1<<24 | 1<<23 | 6<<19 | 1<<16);
  else if (i < 28) buffer_config_d[i] = (                    1<<25 | 1<<24 | 1<<23 | 6<<19 | 1<<16);
  else             buffer_config_d[i] = (                                    1<<23 | 6<<19 | 1<<16);

            end
          end
          else
            buffer_config_d[i_paddr[9:2]] = i_pwdata;

        2'd3:
          case (i_paddr[9:5])
            5'h00: agent_en_d                     = i_pwdata[0]; // paddr[9:2] = 0
            5'h01: agent_loop_cnt_d               = i_pwdata;    // paddr[9:2] = 8
            5'h02: agent_pattern0_d[i_paddr[4:2]] = i_pwdata;    // paddr[9:2] = 16 ~ 23
            5'h03: agent_pattern1_d[i_paddr[4:2]] = i_pwdata;    // paddr[9:2] = 24 ~ 31
          endcase

      endcase
  end

  always_comb begin
    if (cfg_clkgen)
      cfg_dly_cnt_d = '{default: 1};
    else if (cfg_dly_cnt_q)
      cfg_dly_cnt_d = cfg_dly_cnt_q - 1;
    else
      cfg_dly_cnt_d = cfg_dly_cnt_q;

    if (cfg_dly_cnt_q == 1)
      cfg_chg_d = ~cfg_chg_q;
    else
      cfg_chg_d =  cfg_chg_q;
  end

  // Read data path
  // ---------------------------------------------------------------------------
  assign pready_d = o_pready;

  always_comb begin
    prdata_d = prdata_q;

    if (i_penable & ~i_pwrite)
      case (i_paddr[13:12])
        2'd0:
          case (i_paddr[9:2])
            8'h00: prdata_d = chn_mode_q;
            8'h01: prdata_d = fifo_mode_q;
            8'h04: prdata_d = {i_aib_ready, 1'b0, skip_hrdrst_q, config_done_q};
          endcase

        2'd1:
          case (i_paddr[9:2])
            8'h00: prdata_d = aib_clkgen_cfg_q;
            8'h01: prdata_d = aux_clkgen_cfg_q;
            8'h02: prdata_d = 0;//cfg_clkgen;
            8'h08: prdata_d = baud_cyc_q;
            8'h10: prdata_d = dll_tap_q;
            8'h18: prdata_d = {1'b0, rx_wptr_init_q, 1'b0, rx_rptr_init_q};
          endcase

        2'd2:
          prdata_d = buffer_config_q[i_paddr[9:2]];

        2'd3:
          case (i_paddr[9:5])
            5'h00: prdata_d = agent_en_d;                     // paddr[9:2] = 0
            5'h01: prdata_d = agent_loop_cnt_d;               // paddr[9:2] = 8
            5'h02: prdata_d = agent_pattern0_d[i_paddr[4:2]]; // paddr[9:2] = 16 ~ 23
            5'h03: prdata_d = agent_pattern1_d[i_paddr[4:2]]; // paddr[9:2] = 24 ~ 31
            5'h04: prdata_d = {
              c_test_timeout,
              c_test_fail,
              c_test_pass,
              c_test_timeout | c_test_fail | c_test_pass}; // paddr[9:2] = 32
            5'h05: prdata_d = c_test_fail_cnt;   // paddr[9:2] = 40
            5'h06: prdata_d = c_test_fail_data0; // paddr[9:2] = 48
            5'h07: prdata_d = c_test_fail_data1; // paddr[9:2] = 56
          endcase

      endcase
  end

  // ---------------------------------------------------------------------------
  always_ff @(posedge i_clk or negedge i_rst_n)
    if (!i_rst_n) begin
      pready_q <= 1'b1;
      prdata_q <= 32'd0;

      chn_mode_q    <= 3'b100;
      fifo_mode_q   <= 2'b0;
      config_done_q <= 1'b0;
      skip_hrdrst_q <= 1'b0;

      aib_clkgen_cfg_q <= {1'b1, 1'b1, 1'b0, 1'b0, 4'd15, 2'd3, 2'd3};
      aux_clkgen_cfg_q <= {1'b1, 1'b1, 1'b0, 1'b0, 4'd15, 2'd3, 2'd3};
      cfg_chg_q        <= 1'b0;
    `ifdef SYNTHESIS
      baud_cyc_q       <= 16'd433;
    `else
      baud_cyc_q       <= 16'd2;
    `endif
      dll_tap_q        <= 8'b0;
      rx_wptr_init_q   <= 3'd2;
      rx_rptr_init_q   <= 3'd0;

      for (int i = 0; i < NumIo; i++)
        buffer_config_q[i] <= {1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 3'd6, 3'd1, 8'b0, 8'b0};

      agent_en_q       <= 1'b0;
      agent_loop_cnt_q <= 16'd0;
      agent_pattern0_q <= '{8{20'ha_a50f}}; // both [19] and [3] are 1
      agent_pattern1_q <= '{8{20'hc_5af8}}; // both [19] and [3] are 1

      cfg_dly_cnt_q <= 8'b0;
    end
    else begin
      pready_q <= pready_d;
      prdata_q <= prdata_d;

      chn_mode_q    <= chn_mode_d;
      fifo_mode_q   <= fifo_mode_d;
      config_done_q <= config_done_d;
      skip_hrdrst_q <= skip_hrdrst_d;

      aib_clkgen_cfg_q <= aib_clkgen_cfg_d;
      aux_clkgen_cfg_q <= aux_clkgen_cfg_d;
      cfg_chg_q        <= cfg_chg_d;
      baud_cyc_q       <= baud_cyc_d;
      dll_tap_q        <= dll_tap_d;
      rx_wptr_init_q   <= rx_wptr_init_d;
      rx_rptr_init_q   <= rx_rptr_init_d;

      buffer_config_q <= buffer_config_d;

      agent_en_q       <= agent_en_d;
      agent_loop_cnt_q <= agent_loop_cnt_d;
      agent_pattern0_q <= agent_pattern0_d;
      agent_pattern1_q <= agent_pattern1_d;

      cfg_dly_cnt_q <= cfg_dly_cnt_d;
    end

endmodule

