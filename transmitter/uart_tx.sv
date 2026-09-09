module tx (input logic clk, rst_n, tick, send, input logic [7:0] data, output logic tx_signal, busy);
    
    typedef enum logic [1:0]{IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11} state_t;

    state_t state;
    logic [7:0] byte_reg;
    logic [2:0] bit_counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            tx_signal <= 1'b1;
            busy <= 1'b0;
            bit_counter <= 3'b0;
            byte_reg <= '0;
        end
        else begin
            case (state)
                IDLE: begin
                    tx_signal <= 1'b1;
                    busy <= 1'b0;
                    if (send) begin
                        byte_reg <= data;
                        busy <= 1'b1;
                        state <= START;
                    end
                end

                START: begin
                    tx_signal <= 1'b0;
                    if (tick) begin
                        bit_counter <= 3'b0;
                        state <= DATA;
                    end
                end 

                DATA: begin
                    tx_signal <= byte_reg[0];
                    if (tick) begin
                        byte_reg <= byte_reg >> 1;
                        if (bit_counter == 3'd7) begin
                            state <= STOP;
                        end 
                        else begin
                            bit_counter <= bit_counter + 1;
                        end 
                    end 
                end 

                STOP: begin
                    tx_signal <= 1'b1;
                    if (tick) begin
                        state <= IDLE;
                        busy <= 1'b0;
                    end 
                end 
            endcase 
        end 
    end
endmodule