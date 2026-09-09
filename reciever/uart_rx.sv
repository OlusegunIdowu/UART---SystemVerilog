module rx (input logic clk,rst_n, tick, rx_signal, output logic [7:0] data_out, output logic data_valid);

    typedef enum logic [1:0] {IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11} state_t;

    state_t state;
    logic [7:0] byte_reg;
    logic [2:0] bit_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            data_out <= 8'b0;
            data_valid <= 1'b0;
            bit_counter <= 3'b0;
            byte_reg <= 8'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    data_valid <= 1'b0;
                    if (rx_signal == 1'b0) begin
                        state <= START;
                    end 
                end 

                START: begin
                    if (tick) begin
                        bit_counter <= 3'b0;
                        state <= DATA;
                    end 
                end 

                DATA: begin
                    if (tick) begin
                        byte_reg <= {rx_signal, byte_reg[7:1]};
                        if (bit_counter == 3'd7) begin
                            state <= STOP;
                        end 
                        else begin
                            bit_counter <= bit_counter + 1;
                        end
                    end 
                end 

                STOP: begin
                    if (tick) begin
                        data_out <= byte_reg;
                        data_valid <= 1'b1;
                        state <= IDLE;
                    end 
                end 
            endcase
        end 
    end 
endmodule