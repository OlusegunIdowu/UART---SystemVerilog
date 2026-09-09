module tx_tb;
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic tick, send, tx_signal, busy;
    logic [7:0] data;

    baud_gen #(.clk_frq(50000000), .baud_rate(9600)) baud_uut (.clk(clk), .rst_n(rst_n), .tick(tick));

    tx uut(.clk(clk), .rst_n(rst_n), .tick(tick), .data(data), .send(send), .tx_signal(tx_signal), .busy(busy));

    always #10 clk = ~clk;

    initial begin
        rst_n = 1'b0;
        send = 1'b0;
        data = 8'b0;
        #25 rst_n = 1'b1;

        #100;
        data = 8'b1010_1100;
        send = 1'b1;
        #20 send = 1'b0;

        wait (busy == 1'b0);
        #100;

        data = 8'b0110_0101;
        send = 1'b1;
        #20 send = 1'b0;

        wait (busy == 1'b0);
        #200;

        $finish;
    end

    initial begin
        $dumpfile("uart_tx.vcd");
        $dumpvars(0, tx_tb);
    end

endmodule

