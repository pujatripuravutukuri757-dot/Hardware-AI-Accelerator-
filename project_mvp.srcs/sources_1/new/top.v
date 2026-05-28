module top (
    input  wire        clk100mhz,

    //// 11) LED[0] pulse on rising edge of cnn_done (visible blink) OV7670 camera
    input  wire        cam_pclk,
    input  wire        cam_vsync,
    input  wire        cam_href,
    input  wire [7:0]  cam_d,
    output wire        cam_xclk,
    inout  wire        cam_scl,
    inout  wire        cam_sda,
    output wire        cam_reset,
    output wire        cam_pwdn,

    // VGA
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b,
    output wire        vga_hs,
    output wire        vga_vs,

    // USER LEDs (these appear as LD4..LD7 on silkscreen)
    output wire [3:0]  led
);

    // --------------------------------------------------------
    // 1) 25 MHz pixel clock from 100 MHz
    // --------------------------------------------------------
    reg [1:0] clkdiv = 2'b00;
    always @(posedge clk100mhz) clkdiv <= clkdiv + 2'b01;

    wire pix_clk = clkdiv[1]; // 25 MHz

    assign cam_xclk  = pix_clk;
    assign cam_reset = 1'b1;
    assign cam_pwdn  = 1'b0;

    // --------------------------------------------------------
    // 2) OV7670 init
    // --------------------------------------------------------
    wire scl_drive_low, sda_drive_low;
    wire cam_init_done;

    ov7670_init u_ov7670_init (
        .clk           (clk100mhz),
        .reset_n       (1'b1),
        .scl_drive_low (scl_drive_low),
        .sda_drive_low (sda_drive_low),
        .init_done     (cam_init_done)
    );

    assign cam_scl = scl_drive_low ? 1'b0 : 1'bz;
    assign cam_sda = sda_drive_low ? 1'b0 : 1'bz;

    // --------------------------------------------------------
    // 3) Capture -> 320x240 RGB565 framebuffer
    //    and also provide full-res Y + coords for resize
    // --------------------------------------------------------
    localparam H_RES      = 320;
    localparam V_RES      = 240;
    localparam FRAME_SIZE = H_RES * V_RES; // 76800
    localparam ADDR_W     = 17;

    wire [ADDR_W-1:0] fb_wr_addr;
    wire              fb_wr_en;
    wire [15:0]       fb_wr_data;

    wire [7:0]  y_full_pix;
    wire        y_full_valid;
    wire [9:0]  x_full;
    wire [9:0]  y_full;

    cam_capture_rgb565_320x240 u_cap (
        .pclk         (cam_pclk),
        .vsync        (cam_vsync),
        .href         (cam_href),
        .d            (cam_d),

        .wr_addr      (fb_wr_addr),
        .wr_en        (fb_wr_en),
        .wr_data      (fb_wr_data),

        .y_full_pix   (y_full_pix),
        .y_full_valid (y_full_valid),
        .x_full       (x_full),
        .y_full       (y_full)
    );

    // --------------------------------------------------------
    // 4) Framebuffer BRAM
    // --------------------------------------------------------
    wire [ADDR_W-1:0] fb_rd_addr;
    wire [15:0]       fb_rd_data;

    frame_buffer_rgb565 #(
        .ADDR_WIDTH (ADDR_W),
        .FRAME_SIZE (FRAME_SIZE)
    ) u_fb (
        .wr_clk  (cam_pclk),
        .wr_en   (fb_wr_en),
        .wr_addr (fb_wr_addr),
        .wr_data (fb_wr_data),

        .rd_clk  (pix_clk),
        .rd_addr (fb_rd_addr),
        .rd_data (fb_rd_data)
    );

    // --------------------------------------------------------
    // 5) VGA timing
    // --------------------------------------------------------
    wire       video_active;
    wire [9:0] vga_x;
    wire [9:0] vga_y;

    vga_640x480 u_vga (
        .clk    (pix_clk),
        .hs     (vga_hs),
        .vs     (vga_vs),
        .active (video_active),
        .x      (vga_x),
        .y      (vga_y)
    );

    // Upscale 2x
    wire [8:0] src_x = vga_x[9:1];
    wire [8:0] src_y = vga_y[9:1];

    reg [ADDR_W-1:0] rd_addr_reg = 0;
    always @(posedge pix_clk) begin
        if (video_active)
            rd_addr_reg <= src_y * H_RES + src_x;
        else
            rd_addr_reg <= 0;
    end
    assign fb_rd_addr = rd_addr_reg;

    // --------------------------------------------------------
    // 6) Whole-frame resize 640x480 -> 64x64 grayscale RAM
    // --------------------------------------------------------
    wire        g64_wr_en;
    wire [11:0] g64_wr_addr;
    wire [7:0]  g64_wr_data;

    resize_whole_640x480_to_64x64 u_resize64 (
        .pclk      (cam_pclk),
        .vsync     (cam_vsync),
        .pix_valid (y_full_valid),
        .x_full    (x_full),
        .y_full    (y_full),
        .y_in      (y_full_pix),

        .wr_en     (g64_wr_en),
        .wr_addr   (g64_wr_addr),
        .wr_data   (g64_wr_data)
    );

    wire [7:0]  g64_rd_data;
    reg  [11:0] g64_rd_addr = 0;

    gray64_mem u_gray64 (
        .wr_clk  (cam_pclk),
        .wr_en   (g64_wr_en),
        .wr_addr (g64_wr_addr),
        .wr_data (g64_wr_data),

        .rd_clk  (pix_clk),
        .rd_addr (g64_rd_addr),
        .rd_data (g64_rd_data)
    );

    // --------------------------------------------------------
    // 7) PiP overlay (128x128 showing 64x64)
    // --------------------------------------------------------
    wire pip_on = video_active && (vga_x < 10'd128) && (vga_y < 10'd128);
    wire [5:0] pip_x = vga_x[6:1];
    wire [5:0] pip_y = vga_y[6:1];
    wire [11:0] pip_addr = {pip_y, pip_x};

    // --------------------------------------------------------
    // 8) frame_start = VSYNC falling edge (ONE pulse per frame)
    // --------------------------------------------------------
    reg vs_d = 1'b1;
    always @(posedge pix_clk) vs_d <= vga_vs;
    wire frame_start = (vs_d == 1'b1) && (vga_vs == 1'b0);

    // --------------------------------------------------------
    // 9) Stream 64x64 once per frame
    // --------------------------------------------------------
    wire [11:0] cnn_addr;
    wire [7:0]  cnn_pix;
    wire        cnn_pix_valid;
    wire        cnn_done;

    gray64_stream u_stream (
        .clk       (pix_clk),
        .start     (frame_start),
        .rd_addr   (cnn_addr),
        .rd_data   (g64_rd_data),
        .pix_out   (cnn_pix),
        .pix_valid (cnn_pix_valid),
        .done      (cnn_done)
    );
    // ================= CNN =================
      wire cnn_fan;
    
    cnn_production u_cnn(
        .clk(pix_clk),
        .start(frame_start),
        .pixel_in(cnn_pix),
        .pixel_valid(cnn_pix_valid),
        .done(cnn_done),
        .fan(cnn_fan)
    );
    


    // Read addr mux: PiP first, else stream
    always @(posedge pix_clk) begin
        if (pip_on)
            g64_rd_addr <= pip_addr;
        else
            g64_rd_addr <= cnn_addr;
    end
        // =======================================================
    // INDUSTRY STYLE CENTER BOUNDING BOX
    // =======================================================
    localparam BOX_W = 220;
    localparam BOX_H = 220;
    
    localparam CX = 640/2;
    localparam CY = 480/2;
    
    localparam X1 = CX - BOX_W/2;
    localparam X2 = CX + BOX_W/2;
    localparam Y1 = CY - BOX_H/2;
    localparam Y2 = CY + BOX_H/2;
    
    // 3-pixel thick border
    wire box_border =
        cnn_fan && video_active &&
        (
          ((vga_x>=X1)&&(vga_x<=X2)&&((vga_y>=Y1&&vga_y<Y1+3)||(vga_y<=Y2&&vga_y>Y2-3)))
          ||
          ((vga_y>=Y1)&&(vga_y<=Y2)&&((vga_x>=X1&&vga_x<X1+3)||(vga_x<=X2&&vga_x>X2-3)))
        );
            // =======================================================
    // INDUSTRY STYLE TEXT "FAN"
    // positioned slightly above box center
    // =======================================================
    wire text_enable = cnn_fan && video_active;
    
    // text start location
    localparam TXT_X = CX - 36;
    localparam TXT_Y = Y1 - 28;
    
    wire inside_text =
    cnn_fan &&
    video_active &&
    (vga_x >= TXT_X) && (vga_x < TXT_X+72) &&
    (vga_y >= TXT_Y) && (vga_y < TXT_Y+16);

    wire [6:0] tx = inside_text ? (vga_x - TXT_X) : 0;
    wire [4:0] ty = inside_text ? (vga_y - TXT_Y) : 0;
        
    reg fan_pixel;
    
    always @(*) begin
        fan_pixel = 0;
    
        if(inside_text) begin
    
            // ------------ F -------------
            if(tx<16) begin
                if(tx<3) fan_pixel=1;
                if(ty<3) fan_pixel=1;
                if(ty>6 && ty<9 && tx<12) fan_pixel=1;
            end
    
            // ------------ A -------------
            if(tx>=24 && tx<40) begin
                if(tx==24 || tx==39) fan_pixel=1;
                if(ty==0 || ty==8) fan_pixel=1;
            end
    
            // ------------ N -------------
            if(tx>=48 && tx<64) begin
                if(tx==48 || tx==63) fan_pixel=1;
                if((tx-48)==ty/1) fan_pixel=1;
            end
    
        end
    end

    // --------------------------------------------------------
    // 10) VGA output with PiP overlay
    // --------------------------------------------------------
    reg [15:0] rgb_reg;
    always @(posedge pix_clk) rgb_reg <= fb_rd_data;

    wire [4:0] r5 = rgb_reg[15:11];
    wire [5:0] g6 = rgb_reg[10:5];
    wire [4:0] b5 = rgb_reg[4:0];

    wire [3:0] base_r = r5[4:1];
    wire [3:0] base_g = g6[5:2];
    wire [3:0] base_b = b5[4:1];

    wire [3:0] pip_v = g64_rd_data[7:4];

    wire overlay_red = cnn_fan && (box_border | fan_pixel);

    assign vga_r =
        video_active ?
            (overlay_red ? 4'hF : (pip_on ? pip_v : base_r))
        : 0;
    
    assign vga_g =
        video_active ?
            (overlay_red ? 4'h0 : (pip_on ? pip_v : base_g))
        : 0;
    
    assign vga_b =
        video_active ?
            (overlay_red ? 4'h0 : (pip_on ? pip_v : base_b))
        : 0;

    // --------------------------------------------------------
    // 11) LED[0] pulse on rising edge of cnn_done (visible blink)
    // --------------------------------------------------------
// --------------------------------------------------------
// 11) Robust LED blink (LD4) using cnn_done events
//     LD6 and LD7 are expected to be ON continuously.
// --------------------------------------------------------
reg cnn_done_d = 1'b0;
always @(posedge pix_clk) cnn_done_d <= cnn_done;

// detect rising edge (one pulse when done goes 0->1)
wire cnn_done_rise = (~cnn_done_d) & cnn_done;

// count done-events (frames) and toggle LED every N frames
localparam integer TOGGLE_N = 15;   // ~15 frames ? 0.5s at 30fps
reg [7:0] frame_cnt = 0;
reg       led4_state = 1'b0;

always @(posedge pix_clk) begin
    if (cnn_done_rise) begin
        if (frame_cnt == TOGGLE_N-1) begin
            frame_cnt  <= 0;
            led4_state <= ~led4_state;  // toggle LD4
        end else begin
            frame_cnt <= frame_cnt + 1'b1;
        end
    end
end

// --------------------------------------------------------
// LED mapping (Arty A7: led[0..3] show as LD4..LD7)
// --------------------------------------------------------
assign led[0] = cnn_fan;      // FAN detected
assign led[1] = cnn_pix_valid;
assign led[2] = cam_init_done;
assign led[3] = video_active;


endmodule
