module cnn_production(

    input wire clk,
    input wire start,

    input wire [7:0] pixel_in,
    input wire pixel_valid,

    output reg done = 0,
    output reg fan  = 0
);

// 64x64 image storage
reg signed [7:0] img[0:4095];

// weights
reg signed [15:0] W[0:4095];
initial $readmemh("weights.hex", W);

// pointers
reg [11:0] ptr = 0;
reg [12:0] mac_index = 0;

reg running = 0;

reg signed [31:0] acc = 0;

always @(posedge clk)
begin

    done <= 0;

    // collect pixels first
    if(pixel_valid && !running)
    begin
        img[ptr] <= pixel_in;
        ptr <= ptr + 1;

        if(ptr == 4095)
        begin
            running <= 1;
            mac_index <= 0;
            acc <= 0;
        end
    end

    // sequential MAC (safe slow CNN)
    if(running)
    begin
        acc <= acc + img[mac_index] * W[mac_index];
        mac_index <= mac_index + 1;

        if(mac_index == 4095)
        begin
            fan  <= (acc > 0);
            done <= 1;

            running <= 0;
            ptr <= 0;
        end
    end

end

endmodule
