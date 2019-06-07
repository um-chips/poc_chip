//-----------------------------------------------------------------
//                           AltOR32 
//                Alternative Lightweight OpenRisc 
//                            V2.1
//                     Ultra-Embedded.com
//                   Copyright 2011 - 2014
//
//               Email: admin@ultra-embedded.com
//
//                       License: LGPL
//-----------------------------------------------------------------
//
// Copyright (C) 2011 - 2014 Ultra-Embedded.com
//
// This source file may be used and distributed without         
// restriction provided that this copyright statement is not    
// removed from the file and that any derivative work contains  
// the original copyright notice and the associated disclaimer. 
//
// This source file is free software; you can redistribute it   
// and/or modify it under the terms of the GNU Lesser General   
// Public License as published by the Free Software Foundation; 
// either version 2.1 of the License, or (at your option) any   
// later version.
//
// This source is distributed in the hope that it will be       
// useful, but WITHOUT ANY WARRANTY; without even the implied   
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
// PURPOSE.  See the GNU Lesser General Public License for more 
// details.
//
// You should have received a copy of the GNU Lesser General    
// Public License along with this source; if not, write to the 
// Free Software Foundation, Inc., 59 Temple Place, Suite 330, 
// Boston, MA  02111-1307  USA
//-----------------------------------------------------------------

//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "altor32_defs.v"

//-----------------------------------------------------------------
// Module - Instruction Cache
//-----------------------------------------------------------------
module altor32_icache
( 
    input                       clk_i /*verilator public*/,
    input                       rst_i /*verilator public*/,

    input                       cfg_icache_en,
    input                       cfg_colli_dis,
    input [31:0]                cfg_boot_vector,

    // Processor interface
    input                       rd_i /*verilator public*/,
    input [31:0]                pc_i /*verilator public*/,
    output [31:0]               instruction_o /*verilator public*/,
    output                      valid_o /*verilator public*/,
    input                       invalidate_i /*verilator public*/,

    // Memory interface
    output [31:0]               wbm_addr_o /*verilator public*/,
    input [31:0]                wbm_dat_i /*verilator public*/,
    output [2:0]                wbm_cti_o /*verilator public*/,
    output                      wbm_cyc_o /*verilator public*/,
    output                      wbm_stb_o /*verilator public*/,
    input                       wbm_stall_i/*verilator public*/,
    input                       wbm_ack_i/*verilator public*/
);

//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
// Option: Number of ways (supports 1 or 2)
parameter CACHE_NUM_WAYS            = 2;

// Option: Number of cache lines (2^param) * line_size_bytes = cache size
parameter CACHE_LINE_ADDR_WIDTH     = 8 - (CACHE_NUM_WAYS-1); /* 256 lines total across all ways */

parameter CACHE_LINE_SIZE_WIDTH     = 5; /* 5-bits -> 32 entries */
parameter CACHE_LINE_SIZE_BYTES     = 2 ** CACHE_LINE_SIZE_WIDTH; /* 32 bytes / 8 words per line */

parameter CACHE_TAG_ENTRIES         = 2 ** CACHE_LINE_ADDR_WIDTH ; /* 128 tag entries */
parameter CACHE_DSIZE               = CACHE_NUM_WAYS * (2 ** CACHE_LINE_ADDR_WIDTH) * CACHE_LINE_SIZE_BYTES; /* 8KB data */
parameter CACHE_DWIDTH              = CACHE_LINE_ADDR_WIDTH + CACHE_LINE_SIZE_WIDTH - 2; /* 10-bits */

parameter CACHE_TAG_WIDTH           = 16; /* 16-bit tag entry size */
parameter CACHE_TAG_STAT_BITS       = 1 + (CACHE_NUM_WAYS-1);

parameter CACHE_TAG_LINE_ADDR_WIDTH = CACHE_TAG_WIDTH - CACHE_TAG_STAT_BITS; /* 15 bits of data (tag entry size minus valid / LRU bit) */

parameter CACHE_TAG_ADDR_LOW        = CACHE_LINE_SIZE_WIDTH + CACHE_LINE_ADDR_WIDTH;
parameter CACHE_TAG_ADDR_HIGH       = CACHE_TAG_LINE_ADDR_WIDTH + CACHE_LINE_SIZE_WIDTH + CACHE_LINE_ADDR_WIDTH - 1;

// Tag fields
parameter CACHE_TAG_VALID_BIT       = 15;
parameter CACHE_TAG_LRU_BIT         = 14;   // If CACHE_NUM_WAYS > 1
parameter CACHE_TAG_ADDR_BITS       = CACHE_TAG_WIDTH - CACHE_TAG_STAT_BITS;

//  31          16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
// |--------------|  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
//     +-----------------+  +-------------------+   +-----------+      
//     Tag entry                    Line address         Address 
//       (14/15-bits)               (7/8-bits)           within line 
//                                                       (5-bits)

//-----------------------------------------------------------------
// Registers / Wires
//-----------------------------------------------------------------

// Tag read / write data
reg                             tag_wr_r;
wire [CACHE_TAG_WIDTH-1:0]      tag_out0_w;
reg  [CACHE_TAG_WIDTH-1:0]      tag_in0_r;
wire [CACHE_TAG_WIDTH-1:0]      tag_out1_w;
reg  [CACHE_TAG_WIDTH-1:0]      tag_in1_r;

// Tag address
wire [CACHE_LINE_ADDR_WIDTH-1:0] tag_address_w;

// Data memory read / write
wire [CACHE_DWIDTH-1:0]         address_rd_w;
wire [CACHE_DWIDTH-1:0]         address_wr_w;

wire                            cache_wr0_w;
wire                            cache_wr1_w;

reg                             way_update_q;

// Current / Miss PC
reg [31:0]                      last_pc_q;
reg [31:0]                      miss_pc_q;

// Flush state
reg                             flush_q;
reg [CACHE_LINE_ADDR_WIDTH-1:0] flush_addr_q;
reg                             flush_wr_q;

// Other state
reg                             read_while_busy_q;

// Current state
parameter STATE_CHECK       = 0;
parameter STATE_FETCH       = 1;
parameter STATE_WAIT        = 2;
parameter STATE_FLUSH       = 3;
reg [1:0]                   state_q;

// Tag address from input PC or flopped version of it
assign tag_address_w      = (state_q != STATE_CHECK) ? 
                          miss_pc_q[CACHE_LINE_ADDR_WIDTH + CACHE_LINE_SIZE_WIDTH - 1:CACHE_LINE_SIZE_WIDTH] : 
                          pc_i[CACHE_LINE_ADDR_WIDTH + CACHE_LINE_SIZE_WIDTH - 1:CACHE_LINE_SIZE_WIDTH];

// Cache read address
assign address_rd_w   = pc_i[CACHE_LINE_ADDR_WIDTH + CACHE_LINE_SIZE_WIDTH - 1:2];

// Cache miss output if requested PC is not in the tag memory
wire miss0_w               = ~tag_out0_w[CACHE_TAG_VALID_BIT] | 
                            (last_pc_q[CACHE_TAG_ADDR_HIGH:CACHE_TAG_ADDR_LOW] != tag_out0_w[CACHE_TAG_ADDR_BITS-1:0]);

wire miss1_w               = ~tag_out1_w[CACHE_TAG_VALID_BIT] | 
                            (last_pc_q[CACHE_TAG_ADDR_HIGH:CACHE_TAG_ADDR_LOW] != tag_out1_w[CACHE_TAG_ADDR_BITS-1:0]);

// Stall the CPU if cache state machine is not idle!
wire busy_w               = (state_q != STATE_CHECK) | read_while_busy_q;

// Cache output valid
assign valid_o            = busy_w ? 1'b0 : ~(miss0_w & miss1_w);

// Flushing: Last line to flush
wire flush_last_w         = (flush_addr_q == {CACHE_LINE_ADDR_WIDTH{1'b0}});

// Is this a cache miss?
wire cache_miss_w         = miss0_w & miss1_w &     // Tag lookup failed
                            !rd_i &                 // NOT new read request cycle
                            !read_while_busy_q &    // NOT pending read whilst busy
                            !flush_q &              // NOT flush request
                            !invalidate_i;

wire        mem_fetch_w = (state_q == STATE_CHECK) & cache_miss_w;
wire [31:0] mem_data_w;
wire [31:0] mem_resp_addr_w;
wire        mem_valid_w; 
wire        mem_final_w;

//-----------------------------------------------------------------
// Next State Logic
//-----------------------------------------------------------------
reg [1:0] next_state_r;
always @ *
begin
    next_state_r = state_q;

    case (state_q)

    //-----------------------------------------
    // CHECK - check cache for hit or miss
    //-----------------------------------------
    STATE_CHECK :
    begin
        // Cache flush request pending?
        if (flush_q || invalidate_i)
            next_state_r    = STATE_FLUSH;               
        // Cache miss (& new read request not pending)
        else if (cache_miss_w)
            next_state_r    = STATE_FETCH;
        // Cache hit (or new read request)
        else
            next_state_r    = STATE_CHECK;
    end
    //-----------------------------------------
    // FETCH - Fetch row from memory
    //-----------------------------------------
    STATE_FETCH :
    begin
        // Line fetch complete?
        if (mem_final_w)
           next_state_r = STATE_WAIT;
    end
    //-----------------------------------------
    // FLUSH - Invalidate tag memory
    //-----------------------------------------
    STATE_FLUSH :
    begin
        if (flush_last_w)
            next_state_r = STATE_CHECK;
        else
            next_state_r = STATE_FLUSH;
    end
    //-----------------------------------------
    // WAIT - Wait cycle
    //-----------------------------------------
    STATE_WAIT :
        next_state_r = STATE_CHECK;
    default:
        ;
   endcase
end

// Update state
always @ (posedge rst_i or posedge clk_i )
begin
   if (rst_i == 1'b1)
        state_q   <= STATE_FLUSH;
   else
        state_q   <= next_state_r;
end

//-----------------------------------------------------------------
// Select way to be replaced
//-----------------------------------------------------------------
reg lru_way_r;

// 2-Way
generate
if (CACHE_NUM_WAYS >= 2)
begin: LRU_SELECT
    always @ *
    begin
        if (tag_out0_w[CACHE_TAG_LRU_BIT])
            lru_way_r = 1'b0;
        else
            lru_way_r = 1'b1;
    end
end
// 1-Way
else
begin: LRU_FIXED
    wire lru_way_w = 1'b0;
    always @ *
        lru_way_r = lru_way_w;
end
endgenerate

//-----------------------------------------------------------------
// Flop request details
//-----------------------------------------------------------------
reg [CACHE_LINE_ADDR_WIDTH-1:0] tag_address_q;

always @ (posedge rst_i or posedge clk_i )
begin
   if (rst_i == 1'b1)
   begin
        miss_pc_q       <= cfg_boot_vector + `VECTOR_RESET;
        last_pc_q       <= 32'h00000000;

        tag_address_q   <= {CACHE_LINE_ADDR_WIDTH{1'b0}};
        way_update_q    <= 1'b0;
   end
   else
   begin
        last_pc_q       <= pc_i;
        tag_address_q   <= tag_address_w;
        
        case (state_q)

        //-----------------------------------------
        // CHECK - check cache for hit or miss
        //-----------------------------------------
        STATE_CHECK :
        begin
            // Cache hit (or new read request), store fetch PC
            if (!cache_miss_w)
            begin
                miss_pc_q   <= pc_i;
            end
            // Cache miss
            else
            begin
                // Select line way to replace
                way_update_q <= lru_way_r;
            end
        end
        default:
            ;
       endcase
   end
end

//-----------------------------------------------------------------
// Detect new read request whilst busy
//-----------------------------------------------------------------
always @ (posedge rst_i or posedge clk_i )
begin
   if (rst_i == 1'b1)
   begin
        read_while_busy_q <= 1'b0;
   end
   else
   begin
        case (state_q)
        //-----------------------------------------
        // CHECK - Check cache for hit or miss
        //-----------------------------------------
        STATE_CHECK :
        begin
            read_while_busy_q <= 1'b0;
        end      
        //-----------------------------------------
        // OTHER - Fetching, flushing, waiting
        //-----------------------------------------
        default:
        begin
            // New request whilst cache busy?
            if (rd_i)
                read_while_busy_q <= 1'b1;        
        end
        endcase
   end
end

//-----------------------------------------------------------------
// Cache Tag Write
//-----------------------------------------------------------------
always @ *
begin
    tag_in0_r    = tag_out0_w;
    tag_in1_r    = tag_out1_w;
    tag_wr_r     = 1'b0;

    case (state_q)

    //-----------------------------------------
    // CHECK - check cache for hit or miss
    //-----------------------------------------
    STATE_CHECK :
    begin
        // Cache miss (& new read request not pending)
        if (cache_miss_w)
        begin
            // Update tag memory with this line's details
            if (lru_way_r)
            begin
                tag_in1_r[CACHE_TAG_ADDR_BITS-1:0] = miss_pc_q[CACHE_TAG_ADDR_HIGH:CACHE_TAG_ADDR_LOW];
                tag_in1_r[CACHE_TAG_VALID_BIT]     = 1'b1;

                if (CACHE_NUM_WAYS >= 2)
                begin
                    tag_in1_r[CACHE_TAG_LRU_BIT]   = 1'b0;
                    tag_in0_r[CACHE_TAG_LRU_BIT]   = 1'b1;
                end
            end
            else
            begin
                tag_in0_r[CACHE_TAG_ADDR_BITS-1:0] = miss_pc_q[CACHE_TAG_ADDR_HIGH:CACHE_TAG_ADDR_LOW];
                tag_in0_r[CACHE_TAG_VALID_BIT]     = 1'b1;

                if (CACHE_NUM_WAYS >= 2)
                begin
                    tag_in0_r[CACHE_TAG_LRU_BIT]   = 1'b0;
                    tag_in1_r[CACHE_TAG_LRU_BIT]   = 1'b1;
                end
            end

            tag_wr_r    = 1'b1;
        end
        // Update LRU (if possible)
        else if ((tag_address_q == tag_address_w) && (CACHE_NUM_WAYS >= 2))
        begin
            // Hit Way 0
            if (!miss0_w)
            begin
                // Least recently used way is 1
                tag_in1_r[CACHE_TAG_LRU_BIT] = 1'b1;
                tag_in0_r[CACHE_TAG_LRU_BIT] = 1'b0;
            end
            // Hit Way 1
            else
            begin
                // Least recently used way is 0
                tag_in0_r[CACHE_TAG_LRU_BIT] = 1'b1;
                tag_in1_r[CACHE_TAG_LRU_BIT] = 1'b0;
            end

            tag_wr_r    = 1'b1;
        end
    end       
    default:
        ;
   endcase
end

//-----------------------------------------------------------------
// Flush Logic
//-----------------------------------------------------------------
reg                             flush_r;
reg [CACHE_LINE_ADDR_WIDTH-1:0] flush_addr_r;
reg                             flush_wr_r;

always @ *
begin
    flush_wr_r   = 1'b0;
    flush_addr_r = flush_addr_q;
    flush_r      = flush_q;
    
    case (state_q)

    //-----------------------------------------
    // CHECK - Check cache for hit or miss
    //-----------------------------------------
    STATE_CHECK :
    begin
        // Cache flush request pending?
        if (flush_q || invalidate_i)
        begin
            flush_r         = 1'b0;
            flush_addr_r    = {CACHE_LINE_ADDR_WIDTH{1'b1}};
            flush_wr_r      = 1'b1;
        end
    end
    //-----------------------------------------
    // FLUSH - Invalidate tag memory
    //-----------------------------------------
    STATE_FLUSH :
    begin
        flush_addr_r  = flush_addr_q - 1;
        flush_wr_r    = 1'b1;
    end
    //-----------------------------------------
    // OTHER - Fetching / wait cycles
    //-----------------------------------------
    default:
    begin
        // Latch invalidate request even if can't be actioned now...
        if (invalidate_i)
            flush_r     = 1'b1;
    end
    endcase
end

always @ (posedge rst_i or posedge clk_i )
begin
   if (rst_i == 1'b1)
   begin      
        flush_addr_q    <= {CACHE_LINE_ADDR_WIDTH{1'b1}};
        flush_wr_q      <= 1'b0;
        flush_q         <= 1'b0;
   end
   else
   begin
        flush_addr_q    <= flush_addr_r;
        flush_wr_q      <= flush_wr_r;
        flush_q         <= flush_r;
   end
end

//-----------------------------------------------------------------
// External Mem Access
//-----------------------------------------------------------------
altor32_wb_fetch
u_wb
( 
    .clk_i(clk_i),
    .rst_i(rst_i),

    // Request
    .fetch_i(mem_fetch_w),
    .burst_i(1'b1),
    .address_i(miss_pc_q),

    // Response
    .resp_addr_o(mem_resp_addr_w),
    .data_o(mem_data_w),
    .valid_o(mem_valid_w),
    .final_o(mem_final_w),

    // Wishbone interface
    .wbm_addr_o(wbm_addr_o),
    .wbm_dat_i(wbm_dat_i),
    .wbm_cti_o(wbm_cti_o),
    .wbm_cyc_o(wbm_cyc_o),
    .wbm_stb_o(wbm_stb_o),
    .wbm_stall_i(wbm_stall_i),
    .wbm_ack_i(wbm_ack_i)
);

//-----------------------------------------------------------------
// Tag memory
//-----------------------------------------------------------------
wire [(CACHE_NUM_WAYS*CACHE_TAG_WIDTH)-1:0] tag_in;
wire [(CACHE_NUM_WAYS*CACHE_TAG_WIDTH)-1:0] tag_out;

//altor32_ram_dp
//#(
//    .WIDTH(CACHE_TAG_WIDTH * CACHE_NUM_WAYS),
//    .SIZE(CACHE_LINE_ADDR_WIDTH)
//) 
//u_tag_mem
//(
//    // Tag read/write port
//    .aclk_i(clk_i), 
//    .adat_o(tag_out), 
//    .adat_i(tag_in), 
//    .aadr_i(tag_address_w), 
//    .awr_i(tag_wr_r),
//    
//    // Tag invalidate port
//    .bclk_i(clk_i), 
//    .badr_i(flush_addr_q), 
//    .bdat_o(/*open*/), 
//    .bdat_i({(CACHE_NUM_WAYS*CACHE_TAG_WIDTH){1'b0}}),
//    .bwr_i(flush_wr_q)
//);
ic_tag_mem u_tag_mem (
  .CLKA     (clk_i),
  .CENA     (~cfg_icache_en),
  .GWENA    (~tag_wr_r),
  .AA       (tag_address_w),
  .DA       (tag_in),
  .QA       (tag_out),

  .CLKB     (clk_i),
  .CENB     (~cfg_icache_en),
  .GWENB    (~flush_wr_q),
  .AB       (flush_addr_q),
  .DB       (32'b0),
  .QB       (),

  .COLLDISN (~cfg_colli_dis),

  .STOV     (1'b0),
  .EMAA     (3'd3),
  .EMAB     (3'd3),
  .EMAWA    (2'd1),
  .EMAWB    (2'd1),
  .EMASA    (1'd0),
  .EMASB    (1'd0),
  .RET1N    (1'b1)
);

// 2-Way
generate
if (CACHE_NUM_WAYS >= 2)
begin: TAG_2WAY
    assign tag_in                   = {tag_in1_r, tag_in0_r};
    assign {tag_out1_w, tag_out0_w} = tag_out;
end
// 1-Way
else
begin: TAG_1WAY
    assign tag_in       = tag_in0_r;
    assign tag_out0_w   = tag_out;
    assign tag_out1_w   = {(CACHE_TAG_WIDTH){1'b0}};
end
endgenerate

//-----------------------------------------------------------------
// Data memory
//-----------------------------------------------------------------
wire [31:0] way0_instruction_w /*verilator public*/;
wire [31:0] way1_instruction_w /*verilator public*/;

// Way 0 Instruction Memory
//altor32_ram_dp
//#(
//    .WIDTH(32),
//    .SIZE(CACHE_DWIDTH)
//) 
//u2_data_way0
//(
//    // Data read port
//    .aclk_i(clk_i),
//    .aadr_i(address_rd_w), 
//    .adat_o(way0_instruction_w), 
//    .adat_i(32'h00),
//    .awr_i(1'b0),
//    
//    // Data write port
//    .bclk_i(clk_i),
//    .badr_i(address_wr_w), 
//    .bdat_o(/*open*/), 
//    .bdat_i(mem_data_w),
//    .bwr_i(cache_wr0_w)
//);
ic_data_mem u2_data_way0 (
  .CLK    (clk_i),
  .CENA   (1'b0), // TODO
  .AA     (address_rd_w),
  .QA     (way0_instruction_w),
  .CENB   (~cache_wr0_w), // TODO
  .AB     (address_wr_w),
  .DB     (mem_data_w),

  .STOV   (1'b0),
  .STOVAB (1'b0),
  .EMA    (3'd2),
  .EMAW   (2'd1),
  .EMAS   (1'b0),
  .EMAP   (1'b0),
  .RET1N  (1'b1)
);

// Way 1 Instruction Memory
//altor32_ram_dp
//#(
//    .WIDTH(32),
//    .SIZE(CACHE_DWIDTH)
//) 
//u2_data_way1
//(
//    // Data read port
//    .aclk_i(clk_i), 
//    .aadr_i(address_rd_w), 
//    .adat_o(way1_instruction_w), 
//    .adat_i(32'h00),
//    .awr_i(1'b0),
//    
//    // Data write port
//    .bclk_i(clk_i), 
//    .badr_i(address_wr_w), 
//    .bdat_o(/*open*/), 
//    .bdat_i(mem_data_w),
//    .bwr_i(cache_wr1_w)
//);
ic_data_mem u2_data_way1 (
  .CLK    (clk_i),
  .CENA   (1'b0), // TODO
  .AA     (address_rd_w),
  .QA     (way1_instruction_w),
  .CENB   (~cache_wr1_w), // TODO
  .AB     (address_wr_w),
  .DB     (mem_data_w),

  .STOV   (1'b0),
  .STOVAB (1'b0),
  .EMA    (3'd2),
  .EMAW   (2'd1),
  .EMAS   (1'b0),
  .EMAP   (1'b0),
  .RET1N  (1'b1)
);

// Select between ways for result
assign instruction_o = (miss0_w == 1'b0) ? way0_instruction_w : way1_instruction_w;

// Write to cache on wishbone response
assign address_wr_w = {miss_pc_q[CACHE_LINE_ADDR_WIDTH + CACHE_LINE_SIZE_WIDTH - 1:CACHE_LINE_SIZE_WIDTH], mem_resp_addr_w[CACHE_LINE_SIZE_WIDTH-1:2]};

assign cache_wr0_w = (state_q == STATE_FETCH) & mem_valid_w & ~way_update_q;
assign cache_wr1_w = (state_q == STATE_FETCH) & mem_valid_w & way_update_q;

endmodule
