module baud_gen #(parameter int clk_frq = 50000000, parameter baud_rate = 9600)
                (input logic clk, rst_n, output logic tick);
    
    localparam baud_cycle = clk_frq/baud_rate;

    logic [$clog2(baud_cycle)-1:0] counter;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            counter <= '0;
            tick <= 1'b0;
        end
        else if (counter == baud_cycle - 1) begin
            counter <= '0;
            tick <= 1'b1;
        end
        else begin
            counter <= counter + 1'b1;
            tick <= 1'b0;
        end
    end
endmodule

