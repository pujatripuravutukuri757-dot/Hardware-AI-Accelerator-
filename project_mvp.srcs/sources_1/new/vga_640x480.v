module vga_640x480 (
    input  wire clk,
    output reg  hs,
    output reg  vs,
    output wire active,
    output reg [9:0] x,
    output reg [9:0] y
);
    localparam H_ACTIVE = 640;
    localparam H_FRONT  = 16;
    localparam H_SYNC   = 96;
    localparam H_BACK   = 48;
    localparam H_TOTAL  = H_ACTIVE + H_FRONT + H_SYNC + H_BACK; // 800

    localparam V_ACTIVE = 480;
    localparam V_FRONT  = 10;
    localparam V_SYNC   = 2;
    localparam V_BACK   = 33;
    localparam V_TOTAL  = V_ACTIVE + V_FRONT + V_SYNC + V_BACK; // 525

    reg [9:0] h_cnt = 0;
    reg [9:0] v_cnt = 0;

    assign active = (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);

    always @(posedge clk) begin
        if (h_cnt == H_TOTAL-1) begin
            h_cnt <= 0;
            if (v_cnt == V_TOTAL-1) v_cnt <= 0;
            else v_cnt <= v_cnt + 1'b1;
        end else begin
            h_cnt <= h_cnt + 1'b1;
        end

        // active-low syncs
        hs <= ~((h_cnt >= H_ACTIVE + H_FRONT) && (h_cnt < H_ACTIVE + H_FRONT + H_SYNC));
        vs <= ~((v_cnt >= V_ACTIVE + V_FRONT) && (v_cnt < V_ACTIVE + V_FRONT + V_SYNC));

        if (active) begin
            x <= h_cnt;
            y <= v_cnt;
        end else begin
            x <= 0;
            y <= 0;
        end
    end
endmodule
