module roi_gray64_writer_xy (
    input  wire        pclk,
    input  wire        vsync,
    input  wire        pix_valid,
    input  wire [9:0]  x_full,
    input  wire [9:0]  y_full,
    input  wire [7:0]  y_in,

    output reg         wr_en,
    output reg  [11:0] wr_addr,
    output reg  [7:0]  wr_data
);

    reg [5:0] x = 0;
    reg [5:0] y = 0;

    always @(posedge pclk) begin
        wr_en <= 1'b0;

        if (vsync) begin
            x <= 0;
            y <= 0;
        end else if (pix_valid) begin

            // Just fill 64x64 sequentially (no ROI yet)
            wr_addr <= {y,x};
            wr_data <= y_in;
            wr_en   <= 1'b1;

            if (x == 63) begin
                x <= 0;
                if (y != 63) y <= y + 1'b1;
            end else begin
                x <= x + 1'b1;
            end
        end
    end
endmodule
