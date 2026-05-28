// ============================================================
// OV7670 UYVY stream -> 320x240 RGB565 (2x2 downsample)
// Also exports full-res Y0 pixels + full coordinates for resize/CNN
// ============================================================

module cam_capture_rgb565_320x240(
    input  wire        pclk,
    input  wire        vsync,
    input  wire        href,
    input  wire [7:0]  d,

    output reg  [16:0] wr_addr = 0,
    output reg         wr_en   = 0,
    output reg  [15:0] wr_data = 0,

    output reg  [7:0]  y_full_pix   = 0,
    output reg         y_full_valid = 0,
    output reg  [9:0]  x_full       = 0,
    output reg  [9:0]  y_full       = 0
);

    reg [9:0] x = 0;
    reg [9:0] y = 0;

    reg [1:0] phase = 0; // 0=U,1=Y0,2=V,3=Y1
    reg [7:0] u_reg = 0;
    reg [7:0] v_reg = 0;

    reg href_d = 0;
    wire href_rise = href & ~href_d;
    wire href_fall = ~href & href_d;

    // YUV->RGB (BT.601-ish integer)
    reg signed [8:0]  u_diff, v_diff;
    reg signed [17:0] r_acc, g_acc, b_acc;
    reg signed [10:0] r_tmp, g_tmp, b_tmp;
    reg [7:0] r8, g8, b8;

    always @(posedge pclk) begin
        href_d <= href;
        wr_en <= 1'b0;
        y_full_valid <= 1'b0;

        if (vsync) begin
            x <= 0; y <= 0; phase <= 0;
            wr_addr <= 0;
        end else begin
            if (href_rise) x <= 0;
            if (href_fall) y <= y + 1'b1;

            if (href) begin
                case (phase)
                    2'd0: begin
                        u_reg <= d;
                        phase <= 2'd1;
                    end

                    2'd1: begin
                        // Y0 at (x,y): export full-res Y + coords
                        y_full_pix   <= d;
                        y_full_valid <= 1'b1;
                        x_full       <= x;
                        y_full       <= y;

                        // framebuffer write only for even x and even y
                        if ((x[0]==1'b0) && (y[0]==1'b0)) begin
                            u_diff = $signed({1'b0,u_reg}) - 9'sd128;
                            v_diff = $signed({1'b0,v_reg}) - 9'sd128;

                            r_acc = ($signed({1'b0,d}) <<< 7) + v_diff * 18'sd179;
                            g_acc = ($signed({1'b0,d}) <<< 7) - u_diff * 18'sd44 - v_diff * 18'sd91;
                            b_acc = ($signed({1'b0,d}) <<< 7) + u_diff * 18'sd227;

                            r_tmp = r_acc >>> 7;
                            g_tmp = g_acc >>> 7;
                            b_tmp = b_acc >>> 7;

                            if (r_tmp < 0) r8 = 0; else if (r_tmp > 255) r8 = 255; else r8 = r_tmp[7:0];
                            if (g_tmp < 0) g8 = 0; else if (g_tmp > 255) g8 = 255; else g8 = g_tmp[7:0];
                            if (b_tmp < 0) b8 = 0; else if (b_tmp > 255) b8 = 255; else b8 = b_tmp[7:0];

                            wr_data <= {r8[7:3], g8[7:2], b8[7:3]};
                            wr_en   <= 1'b1;

                            // (y/2)*320 + (x/2)
                            wr_addr <= (y[9:1] * 17'd320) + x[9:1];
                        end

                        phase <= 2'd2;
                    end

                    2'd2: begin
                        v_reg <= d;
                        phase <= 2'd3;
                    end

                    2'd3: begin
                        // Y1 ignored
                        x <= x + 2;
                        phase <= 2'd0;
                    end
                endcase
            end else begin
                phase <= 2'd0;
            end
        end
    end
endmodule
