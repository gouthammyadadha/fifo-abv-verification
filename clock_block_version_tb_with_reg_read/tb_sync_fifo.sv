`timescale 1ns/1ps
//myadadha Goutham Reddy
module tb_sync_fifo;

    parameter int DATA_WIDTH = 8;
    parameter int DEPTH      = 16;

    logic clk;
    logic rst_n;

    logic                  wr_en;
    logic                  rd_en;
    logic [DATA_WIDTH-1:0] wdata;
    logic [DATA_WIDTH-1:0] rdata;
    logic                  full;
    logic                  empty;

    logic [DATA_WIDTH-1:0] exp_q[$];
    logic [DATA_WIDTH-1:0] exp_rdata;

    // -----------------------------
    // DUT
    // -----------------------------
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH     (DEPTH)
    ) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .wdata (wdata),
        .rdata (rdata),
        .full  (full),
        .empty (empty)
    );

    // -----------------------------
    // Clock generation
    // -----------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -----------------------------
    // Clocking block
    // -----------------------------
    clocking cb @(posedge clk);
        default input #1step output #1step;
        output wr_en, rd_en, wdata;
        input  rdata, full, empty;
    endclocking

    // -----------------------------
    // Helper handshake signals
    // -----------------------------
    logic wr_fire, rd_fire, simul_fire;

    always_comb begin
        wr_fire    = wr_en && !full;
        rd_fire    = rd_en && !empty;
        simul_fire = wr_en && !full && rd_en && !empty;
    end

    // -----------------------------
    // Tasks
    // -----------------------------
    task automatic apply_reset();
        begin
            rst_n = 1'b0;
            cb.wr_en <= 1'b0;
            cb.rd_en <= 1'b0;
            cb.wdata <= '0;
            repeat (3) @(posedge clk);
            rst_n = 1'b1;
            @(posedge clk);
        end
    endtask

    task automatic fifo_idle(input int cycles = 1);
        begin
            repeat (cycles) begin
                cb.wr_en <= 1'b0;
                cb.rd_en <= 1'b0;
                cb.wdata <= '0;
                @(cb);
            end
        end
    endtask

    task automatic fifo_write(input logic [DATA_WIDTH-1:0] data);
        begin
            cb.wr_en <= 1'b1;
            cb.rd_en <= 1'b0;
            cb.wdata <= data;
            @(cb);

            cb.wr_en <= 1'b0;
            cb.rd_en <= 1'b0;
            cb.wdata <= '0;
            @(cb);
        end
    endtask

    task automatic fifo_read();
        begin
            cb.wr_en <= 1'b0;
            cb.rd_en <= 1'b1;
            cb.wdata <= '0;
            @(cb);

            cb.wr_en <= 1'b0;
            cb.rd_en <= 1'b0;
            cb.wdata <= '0;
            @(cb);
        end
    endtask

    task automatic fifo_simul_rw(input logic [DATA_WIDTH-1:0] data);
        begin
            cb.wr_en <= 1'b1;
            cb.rd_en <= 1'b1;
            cb.wdata <= data;
            @(cb);

            cb.wr_en <= 1'b0;
            cb.rd_en <= 1'b0;
            cb.wdata <= '0;
            @(cb);
        end
    endtask

    // -----------------------------
    // Scoreboard / reference model
    // -----------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            expected_q_reset();
            exp_rdata <= '0;
        end
        else begin
            if (rd_fire) begin
                exp_rdata <= exp_q[0];
            end

            case ({wr_fire, rd_fire})
                2'b10: begin
                    exp_q.push_back(wdata);
                end

                2'b01: begin
                    void'(exp_q.pop_front());
                end

                2'b11: begin
                    exp_q.push_back(wdata);
                    void'(exp_q.pop_front());
                end

                default: begin
                    // no operation
                end
            endcase
        end
    end

    task automatic expected_q_reset();
        begin
            exp_q.delete();
        end
    endtask

    // -----------------------------
    // Data checker
    // -----------------------------
    always @(posedge clk) begin
        if (rst_n && rd_fire) begin
            #1;
            if (rdata !== exp_rdata) begin
                $error("DATA MISMATCH: expected=0x%0h got=0x%0h time=%0t",
                       exp_rdata, rdata, $time);
            end
            else begin
                $display("DATA MATCH: expected=0x%0h got=0x%0h time=%0t",
                         exp_rdata, rdata, $time);
            end
        end
    end

    // -----------------------------
    // Transaction logging
    // -----------------------------
    always @(posedge clk) begin
        if (rst_n) begin
            if (wr_fire && !rd_fire)
                $display("WRITE : wdata=0x%0h count=%0d time=%0t",
                         wdata, dut.count, $time);

            if (rd_fire && !wr_fire)
                $display("READ  : rdata=0x%0h count=%0d time=%0t",
                         rdata, dut.count, $time);

            if (simul_fire)
                $display("SIMUL : wdata=0x%0h rdata=0x%0h count=%0d time=%0t",
                         wdata, rdata, dut.count, $time);
        end
    end

    // -----------------------------
    // Assertions
    // -----------------------------
    property p_reset_state;
        @(posedge clk) !rst_n |=> (empty && !full && dut.count == 0);
    endproperty
    assert property (p_reset_state)
        else $error("ASSERTION FAILED: reset state incorrect");

    property p_count_range;
        @(posedge clk) disable iff (!rst_n)
        (dut.count <= DEPTH);
    endproperty
    assert property (p_count_range)
        else $error("ASSERTION FAILED: count out of range");

    property p_empty_flag;
        @(posedge clk) disable iff (!rst_n)
        (dut.count == 0) |-> empty;
    endproperty
    assert property (p_empty_flag)
        else $error("ASSERTION FAILED: empty flag incorrect");

    property p_full_flag;
        @(posedge clk) disable iff (!rst_n)
        (dut.count == DEPTH) |-> full;
    endproperty
    assert property (p_full_flag)
        else $error("ASSERTION FAILED: full flag incorrect");

    property p_write_incr;
        @(posedge clk) disable iff (!rst_n)
        (wr_en && !full && !(rd_en && !empty)) |=> (dut.count == $past(dut.count) + 1);
    endproperty
    assert property (p_write_incr)
        else $error("ASSERTION FAILED: write did not increment count");

    property p_read_decr;
        @(posedge clk) disable iff (!rst_n)
        (rd_en && !empty && !(wr_en && !full)) |=> (dut.count == $past(dut.count) - 1);
    endproperty
    assert property (p_read_decr)
        else $error("ASSERTION FAILED: read did not decrement count");

    property p_simul_same_count;
        @(posedge clk) disable iff (!rst_n)
        (wr_en && !full && rd_en && !empty) |=> (dut.count == $past(dut.count));
    endproperty
    assert property (p_simul_same_count)
        else $error("ASSERTION FAILED: simultaneous rw changed count");

    property p_no_overflow;
        @(posedge clk) disable iff (!rst_n)
        (wr_en && full && !rd_en) |=> (dut.count == $past(dut.count));
    endproperty
    assert property (p_no_overflow)
        else $error("ASSERTION FAILED: overflow protection failed");

    property p_no_underflow;
        @(posedge clk) disable iff (!rst_n)
        (rd_en && empty && !wr_en) |=> (dut.count == $past(dut.count));
    endproperty
    assert property (p_no_underflow)
        else $error("ASSERTION FAILED: underflow protection failed");

    property p_wr_ptr_stable_when_full;
        @(posedge clk) disable iff (!rst_n)
        (wr_en && full && !rd_en) |=> (dut.wr_ptr == $past(dut.wr_ptr));
    endproperty
    assert property (p_wr_ptr_stable_when_full)
        else $error("ASSERTION FAILED: wr_ptr changed on blocked write");

    property p_rd_ptr_stable_when_empty;
        @(posedge clk) disable iff (!rst_n)
        (rd_en && empty && !wr_en) |=> (dut.rd_ptr == $past(dut.rd_ptr));
    endproperty
    assert property (p_rd_ptr_stable_when_empty)
        else $error("ASSERTION FAILED: rd_ptr changed on blocked read");

    // -----------------------------
    // Coverage
    // -----------------------------
    cover property (@(posedge clk) disable iff (!rst_n) wr_en && !full);
    cover property (@(posedge clk) disable iff (!rst_n) rd_en && !empty);
    cover property (@(posedge clk) disable iff (!rst_n) wr_en && !full && rd_en && !empty);
    cover property (@(posedge clk) disable iff (!rst_n) full);
    cover property (@(posedge clk) disable iff (!rst_n) empty);

    // -----------------------------
    // Test sequence
    // -----------------------------
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
        cb.wr_en <= 1'b1;
        cb.rd_en <= 1'b0;
        cb.wdata <= 8'hAA;
        @(cb);
        cb.wr_en <= 1'b0;
        cb.rd_en <= 1'b0;
        cb.wdata <= '0;
        @(cb);

        $display("---- EMPTY FIFO ----");
        while (!empty) begin
            fifo_read();
        end

        $display("---- UNDERFLOW ATTEMPT ----");
        cb.wr_en <= 1'b0;
        cb.rd_en <= 1'b1;
        cb.wdata <= '0;
        @(cb);
        cb.rd_en <= 1'b0;
        cb.wdata <= '0;
        @(cb);

        $display("---- PATTERNED RANDOM DATA TRAFFIC ----");
        fifo_write(8'hA1);
        fifo_write(8'hB2);

        repeat (12) begin
            if (!full)
                fifo_write($urandom_range(0,255));

            if (!empty && !full)
                fifo_simul_rw($urandom_range(0,255));

            if (!empty)
                fifo_read();

            if (!empty && !full)
                fifo_simul_rw($urandom_range(0,255));
        end

        fifo_idle(3);

        $display("TEST PASSED / COMPLETED");
        $finish;
    end

endmodule