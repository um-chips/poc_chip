
`ifndef DBG_CMD_SV // this module can be included in multiple file lists
`define DBG_CMD_SV // use an include guard to avoid duplicated module declaration

// -----------------------------------------------------------------------------
// -----------------------------------------------------------------------------
module dbg_cmd
(
  input  logic            i_clk,
  input  logic            i_rst_n,

  input  logic            i_fifo_empty,
  output logic            o_fifo_read,
  input  logic [  7 : 0 ] i_fifo_rdata,

  input  logic            i_fifo_full,
  output logic            o_fifo_write,
  output logic [  7 : 0 ] o_fifo_wdata,

  output logic            o_penable,
  output logic            o_pwrite,
  output logic [ 31 : 0 ] o_paddr,
  output logic [ 31 : 0 ] o_pwdata,
  input  logic            i_pready,
  input  logic [ 31 : 0 ] i_prdata
);
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    FSM_IDLE,
    FSM_ADDR,
    FSM_WRITE,
    FSM_READ_CMD,
    //FSM_READ_DATA,
    FSM_READ_SEND
  } fsm_state;

  fsm_state fsm_ns, fsm_cs;

  // Signal declarations
  // ---------------------------------------------------------------------------
  logic            write_d, write_q;

  logic [  1 : 0 ] byte_cnt_d, byte_cnt_q;

  logic [  6 : 0 ] burst_cnt_d, burst_cnt_q;

  logic [ 31 : 0 ] addr_d, addr_q;

  logic [ 31 : 0 ] data_d, data_q;

  logic            penable_d, penable_q;
  logic            pwrite_d, pwrite_q;
  logic [ 31 : 0 ] pwdata_d, pwdata_q;

  // Output assignments
  // ---------------------------------------------------------------------------
  assign /*output*/ o_fifo_wdata = o_fifo_write ? data_q[31:24] : 8'b0;

  assign /*output*/ o_penable = penable_q;
  assign /*output*/ o_pwrite  = pwrite_q;
  assign /*output*/ o_paddr   = addr_q;
  assign /*output*/ o_pwdata  = pwdata_q;

  // ---------------------------------------------------------------------------
  always_comb begin
    o_fifo_read  = 1'b0;
    o_fifo_write = 1'b0;

    write_d     = write_q;
    byte_cnt_d  = byte_cnt_q;
    burst_cnt_d = burst_cnt_q;
    addr_d      = addr_q;
    data_d      = data_q;

    penable_d = 1'b0;
    pwrite_d  = 1'b0;
    pwdata_d  = pwdata_q;

    case (fsm_cs)
      FSM_IDLE:
        if (!i_fifo_empty) begin
          o_fifo_read = 1'b1;

          write_d     = i_fifo_rdata[7];
          burst_cnt_d = i_fifo_rdata[6:0];
        end

      FSM_ADDR:
        if (!i_fifo_empty) begin
          o_fifo_read = 1'b1;

          byte_cnt_d = byte_cnt_q + 1;
          addr_d = {addr_q[23:0], i_fifo_rdata};

          if (byte_cnt_q == 2'd3)
            if (!write_q)
              penable_d = 1'b1;
        end

      FSM_WRITE: begin
        if (!i_fifo_empty) begin
          o_fifo_read = 1'b1;

          byte_cnt_d = byte_cnt_q + 1;
          data_d = {data_q[23:0], i_fifo_rdata};

          if (byte_cnt_q == 2'd3) begin
            burst_cnt_d = burst_cnt_q - 1;

            penable_d = 1'b1;
            pwrite_d  = write_q;
            pwdata_d  = data_d;
          end
        end

        if (penable_q)
          addr_d = addr_q + 4; //1;
      end

      FSM_READ_CMD:
        if (!i_pready)
          penable_d = 1'b1;
        else
          data_d = i_prdata;
      //FSM_READ_DATA:
      //  data_d = i_prdata;

      default: //FSM_READ_SEND:
        if (!i_fifo_full) begin
          o_fifo_write = 1'b1;

          byte_cnt_d = byte_cnt_q + 1;
          data_d = {data_q[23:0], 8'b0};

          if (byte_cnt_q == 2'd3)
            if (burst_cnt_q) begin
              burst_cnt_d = burst_cnt_q - 1;

              penable_d = 1'b1;
              addr_d = addr_q + 4; //1;
            end
        end
    endcase
  end

  // ---------------------------------------------------------------------------
  always_comb begin
    fsm_ns = fsm_cs;

    case (fsm_cs)
      FSM_IDLE:
        if (!i_fifo_empty)
          fsm_ns = FSM_ADDR;

      FSM_ADDR:
        if (!i_fifo_empty)
          if (byte_cnt_q == 2'd3)
            fsm_ns = write_q ? FSM_WRITE : FSM_READ_CMD;

      FSM_WRITE:
        if (!i_fifo_empty)
          if (byte_cnt_q == 2'd3)
            if (burst_cnt_q == 0)
              fsm_ns = FSM_IDLE;

      FSM_READ_CMD:
        if (i_pready)
          fsm_ns = FSM_READ_SEND;
        //fsm_ns = FSM_READ_DATA;

      //FSM_READ_DATA:
      //  if (i_pready)
      //    fsm_ns = FSM_READ_SEND;

      default: //FSM_READ_SEND:
        if (!i_fifo_full)
          if (byte_cnt_q == 2'd3)
            fsm_ns = (burst_cnt_q == 0) ? FSM_IDLE : FSM_READ_CMD;
    endcase
  end

  // Flip flops
  // ---------------------------------------------------------------------------
  `infer_ff_begin
  `infer_ff(0, i_clk, i_rst_n, fsm_cs, fsm_ns, FSM_IDLE)
  `infer_ff_default_all0(byte_cnt_)
  `infer_ff_default_bit0(write_)
  `infer_ff_default_all0(burst_cnt_)
  `infer_ff_default_all0(addr_)
  `infer_ff_default_all0(data_)
  `infer_ff_default_bit0(penable_)
  `infer_ff_default_bit0(pwrite_)
  `infer_ff_default_all0(pwdata_)
  `infer_ff_end

endmodule

`endif // DBG_CMD_V

