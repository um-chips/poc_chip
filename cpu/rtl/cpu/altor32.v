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
// Module - AltOR32 CPU (Pipelined Wishbone Interfaces)
//-----------------------------------------------------------------
module altor32
(
    // General
    input  logic              clk_i /*verilator public*/,
    input  logic              rst_i /*verilator public*/,

    input  logic              cfg_icache_en,
    input  logic              cfg_colli_dis,
    input  logic[31:0]        cfg_boot_vector,
    input  logic[31:0]        cfg_isr_vector,

    input  logic              intr_i /*verilator public*/,
    input  logic              nmi_i /*verilator public*/,
    output logic              fault_o /*verilator public*/,
    output logic              break_o /*verilator public*/,

    // Instruction memory
    output logic [31:0]       imem_addr_o /*verilator public*/,
    input  logic[31:0]        imem_dat_i /*verilator public*/,
    output logic [2:0]        imem_cti_o /*verilator public*/,
    output logic              imem_cyc_o /*verilator public*/,
    output logic              imem_stb_o /*verilator public*/,
    input  logic              imem_stall_i/*verilator public*/,
    input  logic              imem_ack_i/*verilator public*/,  

    // Data memory
    output logic [31:0]       dmem_addr_o /*verilator public*/,
    output logic [31:0]       dmem_dat_o /*verilator public*/,
    input  logic[31:0]        dmem_dat_i /*verilator public*/,
    output logic [3:0]        dmem_sel_o /*verilator public*/,
    output logic [2:0]        dmem_cti_o /*verilator public*/,
    output logic              dmem_cyc_o /*verilator public*/,
    output logic              dmem_we_o /*verilator public*/,
    output logic              dmem_stb_o /*verilator public*/,
    input  logic              dmem_stall_i/*verilator public*/,
    input  logic              dmem_ack_i/*verilator public*/
);

//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
parameter           REGISTER_FILE_TYPE  = "SIMULATION";
parameter           ENABLE_ICACHE       = "DISABLED";
parameter           ENABLE_DCACHE       = "DISABLED";
parameter           SUPPORT_32REGS      = "ENABLED";
parameter           PIPELINED_FETCH     = "ENABLED";

//-----------------------------------------------------------------
// Registers / Wires
//-----------------------------------------------------------------

// Instruction fetch
wire        fetch_rd_w;
wire [31:0] fetch_pc_w;
logic [31:0] fetch_opcode_w;
logic        fetch_valid_w;

// Decode opcode / PC / state
wire [31:0] dec_opcode_w;
wire [31:0] dec_opcode_pc_w;
wire        dec_opcode_valid_w;

// Register number (rA)
wire [4:0]  dec_ra_w;

// Register number (rB)
wire [4:0]  dec_rb_w;

// Destination register number (pre execute stage)
wire [4:0]  dec_rd_w;

// Register value (rA)
wire [31:0] dec_ra_val_w;

// Register value (rB)
wire [31:0] dec_rb_val_w;

// Destination register number (post execute stage)
wire [4:0]  ex_rd_w;

// Current executing instruction
wire [31:0] ex_opcode_w;

// Result from execute
wire [31:0] ex_result_w;
wire [63:0] ex_mult_res_w;

// Branch request
wire        ex_branch_w;
wire [31:0] ex_branch_pc_w;
wire        ex_stall_w;

// Register writeback value
wire [4:0]  wb_rd_w;
wire [31:0] wb_rd_val_w;

// Register writeback enable
wire        wb_rd_write_w;

wire [31:0] dcache_addr_w;
wire [31:0] dcache_data_out_w;
wire [31:0] dcache_data_in_w;
wire [3:0]  dcache_sel_w;
wire        dcache_we_w;
wire        dcache_stb_w;
wire        dcache_cyc_w;
wire        dcache_ack_w;
wire        dcache_stall_w;

wire        icache_flush_w;
wire        dcache_flush_w;

//-----------------------------------------------------------------
// Instruction Cache
//-----------------------------------------------------------------
generate
if (ENABLE_ICACHE == "ENABLED")
begin : ICACHE
    logic [31:0] fetch_opcode_ic;
    logic        fetch_valid_ic;

    logic [31:0] imem_addr_ic;
    logic [2:0]  imem_cti_ic;
    logic        imem_cyc_ic;
    logic        imem_stb_ic;

    logic [31:0] fetch_opcode_noic;
    logic        fetch_valid_noic;

    logic [31:0] imem_addr_noic;
    logic [2:0]  imem_cti_noic;
    logic        imem_cyc_noic;
    logic        imem_stb_noic;

    always_comb
      if (cfg_icache_en) begin
        fetch_opcode_w = fetch_opcode_ic;
        fetch_valid_w  = fetch_valid_ic;

        imem_addr_o = imem_addr_ic;
        imem_cti_o  = imem_cti_ic;
        imem_cyc_o  = imem_cyc_ic;
        imem_stb_o  = imem_stb_ic;
      end
      else begin
        fetch_opcode_w = fetch_opcode_noic;
        fetch_valid_w  = fetch_valid_noic;

        imem_addr_o = imem_addr_noic;
        imem_cti_o  = imem_cti_noic;
        imem_cyc_o  = imem_cyc_noic;
        imem_stb_o  = imem_stb_noic;
      end

    // Instruction cache
    altor32_icache 
    u_icache
    ( 
        .clk_i          (clk_i),
        .rst_i          (rst_i),

        .cfg_icache_en  (cfg_icache_en),
        .cfg_colli_dis  (cfg_colli_dis),
        .cfg_boot_vector(cfg_boot_vector),
        
        // Processor interface
        .rd_i           (cfg_icache_en ? fetch_rd_w : 1'd0),
        .pc_i           (cfg_icache_en ? fetch_pc_w : 32'd0), 
        .invalidate_i   (cfg_icache_en ? icache_flush_w : 1'd0),
        .instruction_o  (fetch_opcode_ic),
        .valid_o        (fetch_valid_ic),
        
        // Instruction memory
        .wbm_addr_o     (imem_addr_ic),
        .wbm_cti_o      (imem_cti_ic),
        .wbm_cyc_o      (imem_cyc_ic),
        .wbm_stb_o      (imem_stb_ic),
        .wbm_stall_i    (cfg_icache_en ? imem_stall_i : 1'd0),
        .wbm_ack_i      (cfg_icache_en ? imem_ack_i : 1'd0),
        .wbm_dat_i      (cfg_icache_en ? imem_dat_i : 32'd0)
    );

    altor32_noicache 
    u_noicache
    ( 
        .clk_i          (clk_i),
        .rst_i          (rst_i),
        
        // Processor interface
        .rd_i           (cfg_icache_en ? 1'd0  : fetch_rd_w),
        .pc_i           (cfg_icache_en ? 32'd0 : fetch_pc_w), 
        .invalidate_i   (cfg_icache_en ? 1'd0  : icache_flush_w),
        .instruction_o  (fetch_opcode_noic),
        .valid_o        (fetch_valid_noic),
        
        // Instruction memory
        .wbm_addr_o     (imem_addr_noic),
        .wbm_cti_o      (imem_cti_noic),
        .wbm_cyc_o      (imem_cyc_noic),
        .wbm_stb_o      (imem_stb_noic),
        .wbm_stall_i    (cfg_icache_en ? 1'd0  : imem_stall_i),
        .wbm_ack_i      (cfg_icache_en ? 1'd0  : imem_ack_i),
        .wbm_dat_i      (cfg_icache_en ? 32'd0 : imem_dat_i)
    );
end
//-----------------------------------------------------------------
// No instruction cache
//-----------------------------------------------------------------
else
begin : NO_ICACHE
    altor32_noicache 
    u_icache
    ( 
        .clk_i(clk_i),
        .rst_i(rst_i),
        
        // Processor interface
        .rd_i(fetch_rd_w),
        .pc_i(fetch_pc_w), 
        .instruction_o(fetch_opcode_w),
        .valid_o(fetch_valid_w),
        .invalidate_i(icache_flush_w),
        
        // Instruction memory
        .wbm_addr_o(imem_addr_o),
        .wbm_dat_i(imem_dat_i),
        .wbm_cti_o(imem_cti_o),
        .wbm_cyc_o(imem_cyc_o),
        .wbm_stb_o(imem_stb_o),
        .wbm_stall_i(imem_stall_i),
        .wbm_ack_i(imem_ack_i)
    );
end
endgenerate   

//-----------------------------------------------------------------
// Instruction Fetch
//-----------------------------------------------------------------
altor32_fetch 
#(
    .PIPELINED_FETCH(PIPELINED_FETCH)
)
u_fetch
(
    // General
    .clk_i(clk_i),
    .rst_i(rst_i),

    .cfg_boot_vector(cfg_boot_vector),
    
    // Instruction memory
    .pc_o(fetch_pc_w),
    .data_i(fetch_opcode_w),
    .fetch_o(fetch_rd_w),
    .data_valid_i(fetch_valid_w),
    
    // Fetched opcode
    .opcode_o(dec_opcode_w),
    .opcode_pc_o(dec_opcode_pc_w),
    .opcode_valid_o(dec_opcode_valid_w),
    
    // Branch target
    .branch_i(ex_branch_w),
    .branch_pc_i(ex_branch_pc_w),    
    .stall_i(ex_stall_w),

    // Decoded register details
    .ra_o(dec_ra_w),
    .rb_o(dec_rb_w),
    .rd_o(dec_rd_w)
);

//-----------------------------------------------------------------
// [Xilinx] Register file
//-----------------------------------------------------------------
generate
if (REGISTER_FILE_TYPE == "XILINX")
begin : REGFILE_XIL
    altor32_regfile_xil
    #(
        .SUPPORT_32REGS(SUPPORT_32REGS)
    )
    u_regfile
    (
        // Clocking
        .clk_i(clk_i),
        .rst_i(rst_i),
        .wr_i(wb_rd_write_w),

        // Tri-port
        .ra_i(dec_ra_w),
        .rb_i(dec_rb_w),
        .rd_i(wb_rd_w),
        .reg_ra_o(dec_ra_val_w),
        .reg_rb_o(dec_rb_val_w),
        .reg_rd_i(wb_rd_val_w)
    );
end
//-----------------------------------------------------------------
// [Altera] Register file
//-----------------------------------------------------------------
else if (REGISTER_FILE_TYPE == "ALTERA")
begin : REGFILE_ALT
    altor32_regfile_alt
    #(
        .SUPPORT_32REGS(SUPPORT_32REGS)
    )    
    u_regfile
    (
        // Clocking
        .clk_i(clk_i),
        .rst_i(rst_i),
        .wr_i(wb_rd_write_w),

        // Tri-port
        .ra_i(dec_ra_w),
        .rb_i(dec_rb_w),
        .rd_i(wb_rd_w),
        .reg_ra_o(dec_ra_val_w),
        .reg_rb_o(dec_rb_val_w),
        .reg_rd_i(wb_rd_val_w)
    );
end
//-----------------------------------------------------------------
// [Simulation] Register file
//-----------------------------------------------------------------
else
begin : REGFILE_SIM
    altor32_regfile_sim
    #(
        .SUPPORT_32REGS(SUPPORT_32REGS)
    )
    u_regfile
    (
        // Clocking
        .clk_i(clk_i),
        .rst_i(rst_i),
        .wr_i(wb_rd_write_w),

        // Tri-port
        .ra_i(dec_ra_w),
        .rb_i(dec_rb_w),
        .rd_i(wb_rd_w),
        .reg_ra_o(dec_ra_val_w),
        .reg_rb_o(dec_rb_val_w),
        .reg_rd_i(wb_rd_val_w)
    );
end
endgenerate

//-----------------------------------------------------------------
// Data cache
//-----------------------------------------------------------------
generate
if (ENABLE_DCACHE == "ENABLED")
begin : DCACHE
    altor32_dcache 
    u_dcache
    ( 
        .clk_i(clk_i),
        .rst_i(rst_i),

        .flush_i(dcache_flush_w),
        
        // Processor interface
        .address_i({dcache_addr_w[31:2], 2'b00}),
        .data_o(dcache_data_in_w), 
        .data_i(dcache_data_out_w),
        .we_i(dcache_we_w),
        .stb_i(dcache_stb_w),
        .sel_i(dcache_sel_w),
        .stall_o(dcache_stall_w),
        .ack_o(dcache_ack_w),
        
        // Memory interface (slave)
        .mem_addr_o(dmem_addr_o),
        .mem_data_i(dmem_dat_i),
        .mem_data_o(dmem_dat_o),
        .mem_sel_o(dmem_sel_o),
        .mem_we_o(dmem_we_o),
        .mem_stb_o(dmem_stb_o),
        .mem_cyc_o(dmem_cyc_o),
        .mem_cti_o(dmem_cti_o),
        .mem_stall_i(dmem_stall_i),
        .mem_ack_i(dmem_ack_i)
    );
end
//-----------------------------------------------------------------
// No data cache
//-----------------------------------------------------------------
else
begin: NO_DCACHE
    assign dmem_addr_o      = {dcache_addr_w[31:2], 2'b00};
    assign dmem_dat_o       = dcache_data_out_w;
    assign dcache_data_in_w = dmem_dat_i;
    assign dmem_sel_o       = dcache_sel_w;
    assign dmem_cyc_o       = dcache_cyc_w;
    assign dmem_we_o        = dcache_we_w;
    assign dmem_stb_o       = dcache_stb_w;
    assign dmem_cti_o       = 3'b111;
    assign dcache_ack_w     = dmem_ack_i;
    assign dcache_stall_w   = dmem_stall_i;
end
endgenerate

//-----------------------------------------------------------------
// Execution unit
//-----------------------------------------------------------------
altor32_exec
u_exec
(
    // General
    .clk_i(clk_i),
    .rst_i(rst_i),

    .cfg_isr_vector(cfg_isr_vector),

    .intr_i(intr_i),
    .break_i(nmi_i),
    
    // Status
    .fault_o(fault_o),
    .break_o(break_o),
    
    // Cache control
    .icache_flush_o(icache_flush_w),
    .dcache_flush_o(dcache_flush_w),
    
    // Branch target
    .branch_o(ex_branch_w),
    .branch_pc_o(ex_branch_pc_w),
    .stall_o(ex_stall_w),

    // Opcode & arguments
    .opcode_i(dec_opcode_w),
    .opcode_pc_i(dec_opcode_pc_w),
    .opcode_valid_i(dec_opcode_valid_w),

    // Operands
    .reg_ra_i(dec_ra_w),
    .reg_ra_value_i(dec_ra_val_w),
    .reg_rb_i(dec_rb_w),
    .reg_rb_value_i(dec_rb_val_w),    
    .reg_rd_i(dec_rd_w),

    // Output
    .opcode_o(ex_opcode_w),
    .opcode_pc_o(/* not used */),
    .reg_rd_o(ex_rd_w),
    .reg_rd_value_o(ex_result_w),
    .mult_res_o(ex_mult_res_w),

    // Register write back bypass
    .wb_rd_i(wb_rd_w),
    .wb_rd_value_i(wb_rd_val_w),

    // Memory Interface
    .dmem_addr_o(dcache_addr_w),
    .dmem_data_out_o(dcache_data_out_w),
    .dmem_data_in_i(dcache_data_in_w),
    .dmem_sel_o(dcache_sel_w),
    .dmem_we_o(dcache_we_w),
    .dmem_stb_o(dcache_stb_w),
    .dmem_cyc_o(dcache_cyc_w),
    .dmem_stall_i(dcache_stall_w),
    .dmem_ack_i(dcache_ack_w)
);

//-----------------------------------------------------------------
// Register file writeback
//-----------------------------------------------------------------
altor32_writeback 
u_wb
(
    // General
    .clk_i(clk_i),
    .rst_i(rst_i),

    // Opcode
    .opcode_i(ex_opcode_w),

    // Register target
    .rd_i(ex_rd_w),
    
    // ALU result
    .alu_result_i(ex_result_w),

    // Memory load result
    .mem_result_i(dcache_data_in_w),
    .mem_offset_i(dcache_addr_w[1:0]),
    .mem_ready_i(dcache_ack_w),

    // Multiplier result
    .mult_result_i(ex_mult_res_w),

    // Outputs
    .write_enable_o(wb_rd_write_w),
    .write_addr_o(wb_rd_w),
    .write_data_o(wb_rd_val_w)
);

//-------------------------------------------------------------------
// Hooks for debug
//-------------------------------------------------------------------
`ifdef verilator
   function [31:0] get_pc;
      // verilator public
      get_pc = dec_opcode_pc_w;
   endfunction
   function get_fault;
      // verilator public
      get_fault = fault_o;
   endfunction  
   function get_break;
      // verilator public
      get_break = break_o;
   endfunction   
`endif

endmodule
