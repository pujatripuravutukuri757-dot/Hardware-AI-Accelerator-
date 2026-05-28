module frame_buffer_rgb565 #(
    parameter ADDR_WIDTH = 17,
    parameter FRAME_SIZE = 76800
)(
    input  wire                  wr_clk,
    input  wire                  wr_en,
    input  wire [ADDR_WIDTH-1:0] wr_addr,
    input  wire [15:0]           wr_data,

    input  wire                  rd_clk,
    input  wire [ADDR_WIDTH-1:0] rd_addr,
    output reg  [15:0]           rd_data
);
    (* ram_style = "block" *)
    reg [15:0] mem [0:FRAME_SIZE-1];

    always @(posedge wr_clk) begin
        if (wr_en) mem[wr_addr] <= wr_data;
    end

    always @(posedge rd_clk) begin
        rd_data <= mem[rd_addr];
    end
endmodule
