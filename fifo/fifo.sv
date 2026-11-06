module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16            
)(
    input  logic             clk,
    input  logic             rst_n,
    input  logic             wr_en,
    input  logic [WIDTH-1:0] wr_data,
    input  logic             rd_en,
    output logic [WIDTH-1:0] rd_data,
    output logic             full,
    output logic             empty
);
    localparam AW = $clog2(DEPTH);

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [AW:0]      wr_ptr, rd_ptr;     
    logic do_write, do_read;

    assign empty    = (wr_ptr == rd_ptr);
    assign full     = (wr_ptr[AW] != rd_ptr[AW]) && (wr_ptr[AW-1:0] == rd_ptr[AW-1:0]);
    assign do_write = wr_en && !full;     
    assign do_read  = rd_en && !empty;    

    assign rd_data  = mem[rd_ptr[AW-1:0]];

    always_ff @(posedge clk) begin
        if (do_write)
            mem[wr_ptr[AW-1:0]] <= wr_data;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
        end else begin
            if (do_write) wr_ptr <= wr_ptr + 1'b1;
            if (do_read)  rd_ptr <= rd_ptr + 1'b1;
        end
    end
endmodule