`timescale 1ns/1ps

module tb_sync_fifo_comb_read;

    parameter int DATA_WIDTH = 8;
    parameter int DEPTH      = 16;

    logic clk;
    logic rst;
    logic wr_en;
    logic rd_en;
    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH-1:0] rdata;
    logic full;
    logic empty;

    logic [DATA_WIDTH-1:0] expected_q[$];
    logic [DATA_WIDTH-1:0] exp_rdata;

    sync_fifo_comb_read #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk   (clk),
        .rst   (rst),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .wdata (wdata),
        .rdata (rdata),
        .full  (full),
        .empty (empty)
    );

    // Clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Reference model / scoreboard
    always_ff @(posedge clk) begin
        if (rst) begin
            expected_q.delete();
            exp_rdata <= '0;
        end
        else begin
            if (rd_en && !empty) begin
                exp_rdata <= expected_q[0];
            end

            case ({(wr_en && !full), (rd_en && !empty)})

                2'b10: begin
                    expected_q.push_back(wdata);
                end

                2'b01: begin
                    void'(expected_q.pop_front());
                end

                2'b11: begin
                    expected_q.push_back(wdata);
                    void'(expected_q.pop_front());
                end

                default: begin
                    // no operation
                end

            endcase
        end
    end

    // Output data check
    // For combinational read, check the front element whenever FIFO is not empty.
    always @(posedge clk) begin
        if (!rst && !empty) begin
            #1;
            if (rdata !== expected_q[0]) begin
                $error("DATA MISMATCH: expected front = 0x%0h, got = 0x%0h at time %0t",
                       expected_q[0], rdata, $time);
            end
            else begin
                $display("DATA MATCH: expected front = 0x%0h, got = 0x%0h at time %0t",
                         expected_q[0], rdata, $time);
            end
        end
    end

    // Tasks
    task automatic apply_reset();
        begin
            rst   = 1'b1;
            wr_en = 1'b0;
            rd_en = 1'b0;
            wdata = '0;
            repeat (3) @(posedge clk);
            rst = 1'b0;
            @(posedge clk);
        end
    endtask

    task automatic fifo_write(input logic [DATA_WIDTH-1:0] data);
        begin
            @(negedge clk);
            wr_en <= 1'b1;
            rd_en <= 1'b0;
            wdata <= data;

            @(negedge clk);
            wr_en <= 1'b0;
            rd_en <= 1'b0;
        end
    endtask

    task automatic fifo_read();
        begin
            @(negedge clk);
            wr_en <= 1'b0;
            rd_en <= 1'b1;

            @(negedge clk);
            wr_en <= 1'b0;
            rd_en <= 1'b0;
        end
    endtask

    task automatic fifo_simul_rw(input logic [DATA_WIDTH-1:0] data);
        begin
            @(negedge clk);
            wr_en <= 1'b1;
            rd_en <= 1'b1;
            wdata <= data;

            @(negedge clk);
            wr_en <= 1'b0;
            rd_en <= 1'b0;
        end
    endtask

    // Assertions

    property p_reset_empty;
        @(posedge clk) rst |=> (empty && !full && dut.count == 0);
    endproperty
    assert property (p_reset_empty)
        else $error("ASSERTION FAILED: reset state incorrect");

    property p_count_range;
        @(posedge clk) disable iff (rst)
        (dut.count <= DEPTH);
    endproperty
    assert property (p_count_range)
        else $error("ASSERTION FAILED: count out of range");

    property p_empty_flag;
        @(posedge clk) disable iff (rst)
        (dut.count == 0) |-> empty;
    endproperty
    assert property (p_empty_flag)
        else $error("ASSERTION FAILED: empty flag incorrect");

    property p_full_flag;
        @(posedge clk) disable iff (rst)
        (dut.count == DEPTH) |-> full;
    endproperty
    assert property (p_full_flag)
        else $error("ASSERTION FAILED: full flag incorrect");

    property p_write_incr;
        @(posedge clk) disable iff (rst)
        (wr_en && !full && !(rd_en && !empty)) |=> (dut.count == $past(dut.count) + 1);
    endproperty
    assert property (p_write_incr)
        else $error("ASSERTION FAILED: write did not increment count");

    property p_read_decr;
        @(posedge clk) disable iff (rst)
        (rd_en && !empty && !(wr_en && !full)) |=> (dut.count == $past(dut.count) - 1);
    endproperty
    assert property (p_read_decr)
        else $error("ASSERTION FAILED: read did not decrement count");

    property p_simul_rw_same_count;
        @(posedge clk) disable iff (rst)
        (wr_en && !full && rd_en && !empty) |=> (dut.count == $past(dut.count));
    endproperty
    assert property (p_simul_rw_same_count)
        else $error("ASSERTION FAILED: simultaneous read/write changed count");

    property p_no_overflow;
        @(posedge clk) disable iff (rst)
        (wr_en && full && !rd_en) |=> (dut.count == $past(dut.count));
    endproperty
    assert property (p_no_overflow)
        else $error("ASSERTION FAILED: overflow protection failed");

    property p_no_underflow;
        @(posedge clk) disable iff (rst)
        (rd_en && empty && !wr_en) |=> (dut.count == $past(dut.count));
    endproperty
    assert property (p_no_underflow)
        else $error("ASSERTION FAILED: underflow protection failed");

    // Coverage
    cover property (@(posedge clk) disable iff (rst) wr_en && !full);
    cover property (@(posedge clk) disable iff (rst) rd_en && !empty);
    cover property (@(posedge clk) disable iff (rst) wr_en && !full && rd_en && !empty);
    cover property (@(posedge clk) disable iff (rst) full);
    cover property (@(posedge clk) disable iff (rst) empty);

    // Test sequence
    initial begin
        apply_reset();

        $display("---- BASIC WRITE ----");
        fifo_write(8'h11);
        fifo_write(8'h22);
        fifo_write(8'h33);

        $display("---- BASIC READ ----");
        fifo_read();
        fifo_read();

        $display("---- SIMULTANEOUS READ/WRITE ----");
        fifo_simul_rw(8'h44);
        fifo_simul_rw(8'h55);
        fifo_simul_rw(8'h66);

        $display("---- FILL FIFO ----");
        while (!full) begin
            fifo_write($urandom_range(0,255));
        end

        $display("---- OVERFLOW ATTEMPT ----");
        @(negedge clk);
        wr_en <= 1'b1;
        rd_en <= 1'b0;
        wdata <= 8'hAA;
        @(negedge clk);
        wr_en <= 1'b0;
        rd_en <= 1'b0;

        $display("---- EMPTY FIFO ----");
        while (!empty) begin
            fifo_read();
        end

        $display("---- UNDERFLOW ATTEMPT ----");
        @(negedge clk);
        wr_en <= 1'b0;
        rd_en <= 1'b1;
        @(negedge clk);
        rd_en <= 1'b0;

        $display("---- PATTERNED RANDOM DATA TRAFFIC ----");
        fifo_write(8'hA1);
        fifo_write(8'hB2);

        repeat (10) begin
            if (!full)
                fifo_write($urandom_range(0,255));

            if (!empty && !full)
                fifo_simul_rw($urandom_range(0,255));

            if (!empty)
                fifo_read();

            if (!empty && !full)
                fifo_simul_rw($urandom_range(0,255));
        end

        @(negedge clk);
        wr_en <= 1'b0;
        rd_en <= 1'b0;
        wdata <= '0;

        repeat (5) @(posedge clk);
        $display("TEST PASSED / COMPLETED");
        $finish;
    end

endmodule