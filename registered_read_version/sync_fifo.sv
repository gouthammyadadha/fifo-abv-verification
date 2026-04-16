`timescale 1ns/1ps

module sync_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  wr_en,
    input  logic                  rd_en,
    input  logic [DATA_WIDTH-1:0] wdata,

    output logic [DATA_WIDTH-1:0] rdata,
    output logic                  full,
    output logic                  empty
);

    localparam int ADDR_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    logic [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;
    logic [ADDR_WIDTH:0]   count;

    function automatic logic [ADDR_WIDTH-1:0] ptr_next(
        input logic [ADDR_WIDTH-1:0] ptr
    );
        if (ptr == DEPTH-1)
            ptr_next = '0;
        else
            ptr_next = ptr + 1'b1;
    endfunction

    always_ff @(posedge clk) begin
        if (rst) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            count  <= '0;
            rdata  <= '0;
        end
        else begin
            unique case ({(wr_en && !full), (rd_en && !empty)})

                2'b10: begin
                    mem[wr_ptr] <= wdata;
                    wr_ptr      <= ptr_next(wr_ptr);
                    count       <= count + 1'b1;
                end

                2'b01: begin
                    rdata  <= mem[rd_ptr];
                    rd_ptr <= ptr_next(rd_ptr);
                    count  <= count - 1'b1;
                end

                2'b11: begin
                    mem[wr_ptr] <= wdata;
                    rdata       <= mem[rd_ptr];
                    wr_ptr      <= ptr_next(wr_ptr);
                    rd_ptr      <= ptr_next(rd_ptr);
                    // count unchanged
                end

                default: begin
                    // no operation
                end

            endcase
        end
    end

    always_comb begin
        empty = (count == 0);
        full  = (count == DEPTH);
    end

endmodule