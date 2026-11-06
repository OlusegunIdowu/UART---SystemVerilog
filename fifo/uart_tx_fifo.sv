module uart_tx_fifo #(
    parameter DEPTH = 16
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       tick,
    input  logic       push,          
    input  logic [7:0] push_data,
    output logic       fifo_full,
    output logic       fifo_empty,
    output logic       tx_signal
);
    logic [7:0] fifo_data;
    logic       send, pop, busy;
    logic       waiting;              

    fifo #(.WIDTH(8), .DEPTH(DEPTH)) tx_fifo (
        .clk(clk), .rst_n(rst_n),
        .wr_en(push), .wr_data(push_data),
        .rd_en(pop),  .rd_data(fifo_data),
        .full(fifo_full), .empty(fifo_empty)
    );

    tx tx_inst (
        .clk(clk), .rst_n(rst_n), .tick(tick),
        .send(send), .data(fifo_data),
        .tx_signal(tx_signal), .busy(busy)
    );

    
    assign send = !waiting && !fifo_empty && !busy;
    assign pop  = send;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)       waiting <= 1'b0;
        else if (send)    waiting <= 1'b1;   
        else if (busy)    waiting <= 1'b0;   
    end
endmodule