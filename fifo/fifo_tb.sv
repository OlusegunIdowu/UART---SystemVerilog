module fifo_tb;
    localparam WIDTH = 8;
    localparam DEPTH = 4;

    logic             clk     = 1'b0;
    logic             rst_n   = 1'b0;
    logic             wr_en   = 1'b0;
    logic [WIDTH-1:0] wr_data = '0;
    logic             rd_en   = 1'b0;
    logic [WIDTH-1:0] rd_data;
    logic             full, empty;

    int pass_count = 0;
    int fail_count = 0;

    fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (
        .clk(clk), .rst_n(rst_n),
        .wr_en(wr_en), .wr_data(wr_data),
        .rd_en(rd_en), .rd_data(rd_data),
        .full(full), .empty(empty)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("fifo_signals.vcd");
        $dumpvars(0, fifo_tb);
    end

    task check(input string test_name, input logic condition);
        begin
            if (condition) begin
                $display("PASSED TEST: %s", test_name);
                pass_count++;
            end else begin
                $display("FAILED TEST: %s", test_name);
                fail_count++;
            end
        end
    endtask

    task push(input logic [WIDTH-1:0] d);
        begin
            @(negedge clk);
            wr_en = 1'b1; wr_data = d;
            @(negedge clk);
            wr_en = 1'b0;
        end
    endtask

    task pop_and_check(input logic [WIDTH-1:0] expected, input string test_name);
        begin
            check(test_name, rd_data === expected);   
            @(negedge clk);
            rd_en = 1'b1;
            @(negedge clk);
            rd_en = 1'b0;
        end
    endtask

    initial begin
        $display("=== FIFO Testbench ===");
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);

        check("empty after reset", empty === 1'b1 && full === 1'b0);

        push(8'hA1); push(8'hB2); push(8'hC3);
        check("not full at DEPTH-1", full === 1'b0 && empty === 1'b0);
        push(8'hD4);
        check("full at DEPTH", full === 1'b1 && empty === 1'b0);

        push(8'hFF);
        check("full flag held after overflow write", full === 1'b1);

        pop_and_check(8'hA1, "pop 1 is the oldest byte");
        check("not full after one pop", full === 1'b0);
        pop_and_check(8'hB2, "pop 2 in order");
        pop_and_check(8'hC3, "pop 3 in order");
        pop_and_check(8'hD4, "pop 4 in order (0xFF was dropped)");
        check("empty after draining", empty === 1'b1);

        @(negedge clk); rd_en = 1'b1;
        @(negedge clk); rd_en = 1'b0;
        check("empty held after underflow read", empty === 1'b1);

        for (int i = 0; i < 10; i++) begin
            push(i[7:0]);
            pop_and_check(i[7:0], "wrap-around");
        end
        check("empty at end", empty === 1'b1);

        $display("");
        $display("=== Results: %0d passed, %0d failed ===", pass_count, fail_count);
        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED - check output above");
        $finish;
    end
endmodule