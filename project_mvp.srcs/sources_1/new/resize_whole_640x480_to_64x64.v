module resize_whole_640x480_to_64x64 (
    input  wire        pclk,
    input  wire        vsync,
    input  wire        pix_valid,     // valid on Y0 pixels
    input  wire [9:0]  x_full,        // 0..639 (even positions for Y0)
    input  wire [9:0]  y_full,        // 0..479
    input  wire [7:0]  y_in,          // grayscale from Y

    output reg         wr_en,
    output reg  [11:0] wr_addr,
    output reg  [7:0]  wr_data
);

    // output coordinates (0..63)
    reg [5:0] ox = 0;
    reg [5:0] oy = 0;

    // current target input coordinates
    reg [9:0] x_tgt = 0;
    reg [9:0] y_tgt = 0;

    // compute y target = floor(oy * 480 / 64) = floor(oy * 480 / 64)
    // 480/64 = 7.5, so targets: 0,7,15,22,... (good spread)
    function [9:0] y_target;
        input [5:0] y;
        reg [15:0] mult;
        begin
            mult = y * 16'd480;   // up to 63*480 = 30240 fits 16 bits
            y_target = mult >> 6; // divide by 64
        end
    endfunction

    always @(posedge pclk) begin
        wr_en <= 1'b0;

        if (vsync) begin
            ox    <= 0;
            oy    <= 0;
            x_tgt <= 0;
            y_tgt <= 0;
        end
        else if (pix_valid) begin
            // Write only when stream hits our target coordinate
            // x_tgt is always multiple of 10 (even), so it will appear on Y0 samples.
            if ((x_full == x_tgt) && (y_full == y_tgt)) begin
                wr_addr <= {oy, ox};   // 12-bit: [11:6]=oy, [5:0]=ox
                wr_data <= y_in;
                wr_en   <= 1'b1;

                // advance to next output pixel
                if (ox == 6'd63) begin
                    ox <= 0;
                    if (oy == 6'd63) begin
                        oy <= 0;
                        x_tgt <= 0;
                        y_tgt <= 0;
                    end else begin
                        oy <= oy + 1'b1;
                        x_tgt <= 0;
                        y_tgt <= y_target(oy + 1'b1);
                    end
                end else begin
                    ox <= ox + 1'b1;
                    x_tgt <= (ox + 1'b1) * 10;  // exact 640->64 mapping
                end
            end
        end
    end

endmodule
