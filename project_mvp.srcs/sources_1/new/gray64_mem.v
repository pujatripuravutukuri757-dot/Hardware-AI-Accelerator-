module gray64_mem (
    input  wire        wr_clk,
    input  wire        wr_en,
    input  wire [11:0] wr_addr,
    input  wire [7:0]  wr_data,

    input  wire        rd_clk,
    input  wire [11:0] rd_addr,
    output reg  [7:0]  rd_data
);
    (* ram_style = "block" *)
    reg [7:0] mem [0:4095];

    always @(posedge wr_clk) begin
        if (wr_en) mem[wr_addr] <= wr_data;
    end

    always @(posedge rd_clk) begin
        rd_data <= mem[rd_addr];
    end
endmodule
