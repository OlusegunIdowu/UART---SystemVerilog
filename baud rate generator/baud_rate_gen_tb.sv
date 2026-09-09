module baud_gen_tb;
    
    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic tick;

    baud_gen #(.clk_frq(50000000), .baud_rate(9600)) uut (.clk(clk), .rst_n(rst_n), .tick(tick));

    always #10 clk = ~clk;

    initial begin
        rst_n = 1'b0;
        #25 rst_n = 1'b1;
        #1000000 $finish;
    end

    initial begin
        $dumpfile("baud_gen.vcd");
        $dumpvars(0, baud_gen_tb);
    end
endmodule