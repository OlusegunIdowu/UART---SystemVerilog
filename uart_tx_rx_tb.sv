module uart_loopback_tb;

    logic clk   = 1'b0;
    logic rst_n = 1'b0;
    logic tick;

    // TX
    logic [7:0] data;
    logic send;
    logic tx_signal;
    logic busy;

    // RX 
    logic [7:0] data_out;
    logic data_valid;

    baud_gen #(.clk_frq (50000000), .baud_rate(9600)) baud_uut (.clk (clk), .rst_n (rst_n), .tick (tick));

    // TX
    tx tx_uut (.clk (clk), .rst_n (rst_n), .tick (tick), .send (send), .data (data), .tx_signal (tx_signal), .busy (busy));

    // RX
    rx rx_uut (.clk (clk), .rst_n (rst_n), .tick (tick), .rx_signal (tx_signal), .data_out (data_out), .data_valid (data_valid));

    always #10 clk = ~clk;

    task send_byte(input logic [7:0] byte_to_send);
        begin
            data = byte_to_send;
            send = 1'b1;
            #20 send = 1'b0;

            wait (busy == 1'b0);
            wait (data_valid == 1'b1);
            @(posedge clk);

            if (data_out === byte_to_send)
                $display("PASS: sent %b, received %b", byte_to_send, data_out);
            else
                $display("FAIL: sent %b, received %b", byte_to_send, data_out);
        end
    endtask

    initial begin
        rst_n = 1'b0;
        send  = 1'b0;
        data  = 8'b0;
        #25 rst_n = 1'b1;

        #100;
        send_byte(8'b1010_1100);

        #100;
        send_byte(8'b0110_0101);

        #100;
        send_byte(8'b1111_0000);

        #200;
        $finish;
    end

    initial begin
        $dumpfile("uart_loopback.vcd");
        $dumpvars(0, uart_loopback_tb);
    end

endmodule