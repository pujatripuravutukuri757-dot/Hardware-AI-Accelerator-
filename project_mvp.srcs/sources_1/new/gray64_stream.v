module gray64_stream (
    input  wire        clk,
    input  wire        start,      // 1-clock pulse to start a 64x64 scan

    output reg  [11:0] rd_addr,
    input  wire [7:0]  rd_data,

    output reg  [7:0]  pix_out,
    output reg         pix_valid,
    output reg         done         // 1-clock pulse after last pixel is output
);

    reg [5:0] x = 0;
    reg [5:0] y = 0;
    reg running = 0;

    reg primed = 0;          // becomes 1 after first rd_data is valid
    reg last_addr_issued = 0;

    always @(posedge clk) begin
        pix_valid <= 1'b0;
        done      <= 1'b0;

        // start scan
        if (start && !running) begin
            running <= 1'b1;
            x <= 6'd0;
            y <= 6'd0;
            primed <= 1'b0;
            last_addr_issued <= 1'b0;

            rd_addr <= 12'd0;  // first address issued
        end

        if (running) begin
            // Output pixel from previous cycle address (after primed)
            if (primed) begin
                pix_out   <= rd_data;
                pix_valid <= 1'b1;

                if (last_addr_issued) begin
                    // last pixel data just came out
                    done    <= 1'b1;
                    running <= 1'b0;
                end
            end else begin
                // after first cycle, rd_data becomes valid next
                primed <= 1'b1;
            end

            // Issue next address (unless we already issued the last one)
            if (!last_addr_issued) begin
                rd_addr <= {y, x};

                // Detect if current address is the last one (63,63)
                if (x == 6'd63 && y == 6'd63) begin
                    last_addr_issued <= 1'b1;
                end else begin
                    // advance x,y
                    if (x == 6'd63) begin
                        x <= 6'd0;
                        y <= y + 1'b1;
                    end else begin
                        x <= x + 1'b1;
                    end
                end
            end
        end
    end

endmodule
