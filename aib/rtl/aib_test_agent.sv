
module aib_test_agent #(parameter AibIoCnt = 20)
(
  input  logic              i_rst_n,
  input  logic              i_clk,

  input  logic              c_en,
  input  logic  [  15 : 0 ] c_loop_cnt,
  input  logic  [  19 : 0 ] c_pattern0  [8],
  input  logic  [  19 : 0 ] c_pattern1  [8],

  output logic  [  19 : 0 ] o_tx_data0,
  output logic  [  19 : 0 ] o_tx_data1,

  input  logic  [  19 : 0 ] i_rx_data0,
  input  logic  [  19 : 0 ] i_rx_data1,

  output logic              c_test_pass,
  output logic              c_test_fail,
  output logic  [  15 : 0 ] c_test_fail_cnt,
  output logic  [  19 : 0 ] c_test_fail_data0,
  output logic  [  19 : 0 ] c_test_fail_data1,
  output logic              c_test_timeout
);
  logic rst_n;

  reset_sync rst_sync (.i_clk(i_clk), .i_rst_n(i_rst_n), .o_rst_n(rst_n));

  // ---------------------------------------------------------------------------
  typedef enum logic {TX_IDLE, TX_ACTIVE} tx_state;
  typedef enum logic {RX_IDLE, RX_ACTIVE} rx_state;

  tx_state tx_ns, tx_cs;
  rx_state rx_ns, rx_cs;

  logic             en_d, en_q;

  logic [  15 : 0 ] tx_cnt_d, tx_cnt_q;
  logic [  19 : 0 ] tx_data0_d, tx_data0_q;
  logic [  19 : 0 ] tx_data1_d, tx_data1_q;

  logic [  15 : 0 ] rx_cnt_d, rx_cnt_q;

  logic [   7 : 0 ] timeout_cnt_d, timeout_cnt_q;

  logic             test_pass_d, test_pass_q;
  logic             test_fail_d, test_fail_q;
  logic [  15 : 0 ] test_fail_cnt_d, test_fail_cnt_q;
  logic [  19 : 0 ] test_fail_data0_d, test_fail_data0_q;
  logic [  19 : 0 ] test_fail_data1_d, test_fail_data1_q;
  logic             test_timeout_d, test_timeout_q;

  // ---------------------------------------------------------------------------
  assign /*output*/ o_tx_data0 = tx_data0_q;
  assign /*output*/ o_tx_data1 = tx_data1_q;

  assign /*output*/ c_test_pass       = test_pass_q;
  assign /*output*/ c_test_fail       = test_fail_q;
  assign /*output*/ c_test_fail_cnt   = test_fail_cnt_q;
  assign /*output*/ c_test_fail_data0 = test_fail_data0_q;
  assign /*output*/ c_test_fail_data1 = test_fail_data1_q;
  assign /*output*/ c_test_timeout    = test_timeout_q;

  // ---------------------------------------------------------------------------
  SDFFYRPQ2D_X2N_A7P5PP96PTS_C16 DT_en_sync (
    .CK(i_clk), .R(~rst_n), .D(c_en), .Q(en_d), .SI(1'b0), .SE(1'b0)
  );

  // ---------------------------------------------------------------------------
  always_comb begin
    tx_ns    = tx_cs;
    tx_cnt_d = tx_cnt_q;

    case (tx_cs)
      TX_IDLE:
        if (en_d != en_q) begin
          tx_ns    = TX_ACTIVE;
          tx_cnt_d = c_loop_cnt;
        end

      TX_ACTIVE: begin
        if (tx_cnt_q == 0)
          tx_ns = TX_IDLE;
        else
          tx_cnt_d = tx_cnt_q - 1;
      end
    endcase
  end

  always_comb begin
    tx_data0_d = 20'b0;
    tx_data1_d = 20'b0;

    if (tx_cs == TX_ACTIVE) begin
      tx_data0_d = {1'b1, c_pattern0[tx_cnt_q[2:0]][AibIoCnt-2:0]};
      tx_data1_d = {1'b1, c_pattern1[tx_cnt_q[2:0]][AibIoCnt-2:0]};
    end
  end

  // ---------------------------------------------------------------------------
  always_comb begin
    rx_ns    = rx_cs;
    rx_cnt_d = rx_cnt_q;

    timeout_cnt_d = timeout_cnt_q;

    test_pass_d       = test_pass_q;
    test_fail_d       = test_fail_q;
    test_fail_cnt_d   = test_fail_cnt_q;
    test_fail_data0_d = test_fail_data0_q;
    test_fail_data1_d = test_fail_data1_q;
    test_timeout_d    = test_timeout_q;

    case (rx_cs)
      RX_IDLE:
        if (en_d != en_q) begin
          rx_ns    = RX_ACTIVE;
          rx_cnt_d = c_loop_cnt;

          test_pass_d       = 1'b0;
          test_fail_d       = 1'b0;
          test_fail_cnt_d   = 16'b0;
          test_fail_data0_d = 20'b0;
          test_fail_data1_d = 20'b0;
          test_timeout_d    = 1'b0;
        end

      RX_ACTIVE:
        case ({i_rx_data0[AibIoCnt-1], i_rx_data1[AibIoCnt-1]})
          2'b11:
            if (i_rx_data0[AibIoCnt-2:0] == c_pattern0[rx_cnt_q[2:0]][AibIoCnt-2:0] &&
                i_rx_data1[AibIoCnt-2:0] == c_pattern1[rx_cnt_q[2:0]][AibIoCnt-2:0]) begin
              if (rx_cnt_q == 0) begin
                rx_ns = RX_IDLE;

                test_pass_d = 1'b1;
              end
              else
                rx_cnt_d = rx_cnt_q - 1;
            end
            else begin
              rx_ns = RX_IDLE;

              test_fail_d       = 1'b1;
              test_fail_cnt_d   = rx_cnt_q;
              test_fail_data0_d = i_rx_data0;
              test_fail_data1_d = i_rx_data1;
            end

          2'b10, 2'b01: begin
            rx_ns = RX_IDLE;

            test_fail_d       = 1'b1;
            test_fail_cnt_d   = rx_cnt_q;
            test_fail_data0_d = i_rx_data0;
            test_fail_data1_d = i_rx_data1;
          end

          default:
            if (timeout_cnt_q == 8'hff) begin
              rx_ns = RX_IDLE;

              test_fail_cnt_d   = rx_cnt_q;
              test_fail_data0_d = i_rx_data0;
              test_fail_data1_d = i_rx_data1;
              test_timeout_d    = 1'b1;
            end
            else
              timeout_cnt_d = timeout_cnt_q + 1;
        endcase
    endcase
  end

  // ---------------------------------------------------------------------------
  always_ff @(posedge i_clk or negedge rst_n)
    if (!rst_n) begin
      en_q <= 1'b0;

      tx_cs      <= TX_IDLE;
      tx_cnt_q   <= 16'b0;
      tx_data0_q <= 20'b0;
      tx_data1_q <= 20'b0;

      rx_cs    <= RX_IDLE;
      rx_cnt_q <= 16'b0;

      timeout_cnt_q <= 8'b0;

      test_pass_q       <= 1'b0;
      test_fail_q       <= 1'b0;
      test_fail_cnt_q   <= 16'b0;
      test_fail_data0_q <= 20'b0;
      test_fail_data1_q <= 20'b0;
      test_timeout_q    <= 1'b0;
    end
    else begin
      en_q <= en_d;

      tx_cs      <= tx_ns;
      tx_cnt_q   <= tx_cnt_d;
      tx_data0_q <= tx_data0_d;
      tx_data1_q <= tx_data1_d;

      rx_cs    <= rx_ns;
      rx_cnt_q <= rx_cnt_d;

      timeout_cnt_q <= timeout_cnt_d;

      test_pass_q       <= test_pass_d;
      test_fail_q       <= test_fail_d;
      test_fail_cnt_q   <= test_fail_cnt_d;
      test_fail_data0_q <= test_fail_data0_d;
      test_fail_data1_q <= test_fail_data1_d;
      test_timeout_q    <= test_timeout_d;
    end

endmodule

