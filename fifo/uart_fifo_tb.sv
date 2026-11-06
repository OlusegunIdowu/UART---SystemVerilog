module uart_fifo_tb;
    localparam NUM_BYTES = 8;

    logic clk   = 1'b0;
    logic rst_n = 1'b0;
    logic tick;

    logic       push;
    logic [7:0] push_data;
    logic       fifo_full, fifo_empty;

    logic       line;
    logic [7:0] data_out;
    logic       data_valid;
    logic       valid_d = 1'b0;

    logic [7:0] expected [0:NUM_BYTES-1];
    int rx_count   = 0;
    int pass_count = 0;
    int fail_count = 0;

    baud_gen #(.clk_frq(50000000), .baud_rate(115200)) baud_uut (
        .clk(clk), .rst_n(rst_n), .tick(tick)
    );

    uart_tx_fifo #(.DEPTH(16)) dut (
        .clk(clk), .rst_n(rst_n), .tick(tick),
        .push(push), .push_data(push_data),
        .fifo_full(fifo_full), .fifo_empty(fifo_empty),
        .tx_signal(line)
    );

    rx rx_uut (
        .clk(clk), .rst_n(rst_n), .tick(tick),
        .rx_signal(line), .data_out(data_out), .data_valid(data_valid)
    );

    always #10 clk = ~clk;

    always @(posedge clk) begin
        valid_d <= data_valid;
        if (valid_d) begin
            if (data_out === expected[rx_count]) begin
                $display("PASS: byte %0d sent %h, received %h", rx_count, expected[rx_count], data_out);
                pass_count++;
            end else begin
                $display("FAIL: byte %0d expected %h, received %h", rx_count, expected[rx_count], data_out);
                fail_count++;
            end
            rx_count++;
        end
    end

    initial begin
        $dumpfile("uart_fifo.vcd");
        $dumpvars(0, uart_fifo_tb);
    end

    initial begin
        expected[0] = 8'hA5; expected[1] = 8'h3C; expected[2] = 8'hFF; expected[3] = 8'h00;
        expected[4] = 8'h81; expected[5] = 8'h7E; expected[6] = 8'h55; expected[7] = 8'hAA;

        push = 1'b0;
        push_data = 8'h00;
        #25 rst_n = 1'b1;
        #100;

        
        for (int i = 0; i < NUM_BYTES; i++) begin
            @(negedge clk);
            push = 1'b1;
            push_data = expected[i];
        end
        @(negedge clk);
        push = 1'b0;

        wait (rx_count == NUM_BYTES);
        repeat (10) @(posedge clk);

        $display("");
        $display("=== Results: %0d passed, %0d failed ===", pass_count, fail_count);
        if (fail_count == 0 && pass_count == NUM_BYTES)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED - check output above");
        $finish;
    end

    initial begin
        #5_000_000;
        $display("TIMEOUT: only %0d of %0d bytes received", rx_count, NUM_BYTES);
        $display("SOME TESTS FAILED");
        $finish;
    end
endmodule