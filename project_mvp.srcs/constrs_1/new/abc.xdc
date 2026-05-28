## Clock 100 MHz
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk100mhz }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk100mhz }];

## Pmod VGA on JA (R and B)
set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33 } [get_ports { vga_r[0] }];
set_property -dict { PACKAGE_PIN B11   IOSTANDARD LVCMOS33 } [get_ports { vga_r[1] }];
set_property -dict { PACKAGE_PIN A11   IOSTANDARD LVCMOS33 } [get_ports { vga_r[2] }];
set_property -dict { PACKAGE_PIN D12   IOSTANDARD LVCMOS33 } [get_ports { vga_r[3] }];

set_property -dict { PACKAGE_PIN D13   IOSTANDARD LVCMOS33 } [get_ports { vga_b[0] }];
set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports { vga_b[1] }];
set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33 } [get_ports { vga_b[2] }];
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { vga_b[3] }];

## Pmod VGA on JB (G and sync)
set_property -dict { PACKAGE_PIN E15   IOSTANDARD LVCMOS33 } [get_ports { vga_g[0] }];
set_property -dict { PACKAGE_PIN E16   IOSTANDARD LVCMOS33 } [get_ports { vga_g[1] }];
set_property -dict { PACKAGE_PIN D15   IOSTANDARD LVCMOS33 } [get_ports { vga_g[2] }];
set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33 } [get_ports { vga_g[3] }];

set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports { vga_hs }];
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports { vga_vs }];

## Camera OV7670 data bus on JC
set_property -dict { PACKAGE_PIN U12 IOSTANDARD LVCMOS33 } [get_ports { cam_d[0] }];
set_property -dict { PACKAGE_PIN V12 IOSTANDARD LVCMOS33 } [get_ports { cam_d[1] }];
set_property -dict { PACKAGE_PIN V10 IOSTANDARD LVCMOS33 } [get_ports { cam_d[2] }];
set_property -dict { PACKAGE_PIN V11 IOSTANDARD LVCMOS33 } [get_ports { cam_d[3] }];
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports { cam_d[4] }];
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports { cam_d[5] }];
set_property -dict { PACKAGE_PIN T13 IOSTANDARD LVCMOS33 } [get_ports { cam_d[6] }];
set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports { cam_d[7] }];

## PCLK / VS / HS / XCLK / RESET / PWDN on JD
set_property -dict { PACKAGE_PIN D4  IOSTANDARD LVCMOS33 } [get_ports { cam_pclk }];
set_property -dict { PACKAGE_PIN D3  IOSTANDARD LVCMOS33 } [get_ports { cam_vsync }];
set_property -dict { PACKAGE_PIN F4  IOSTANDARD LVCMOS33 } [get_ports { cam_href }];
set_property -dict { PACKAGE_PIN F3  IOSTANDARD LVCMOS33 } [get_ports { cam_xclk }];
set_property -dict { PACKAGE_PIN E2  IOSTANDARD LVCMOS33 } [get_ports { cam_reset }];
set_property -dict { PACKAGE_PIN D2  IOSTANDARD LVCMOS33 } [get_ports { cam_pwdn }];

## SCCB / I2C using ChipKit I2C header
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports { cam_scl }];
set_property -dict { PACKAGE_PIN M18 IOSTANDARD LVCMOS33 } [get_ports { cam_sda }];

## Simple status LED
set_property -dict { PACKAGE_PIN H5  IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN J5  IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports { led[2] }];
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports { led[3] }];

## Allow camera PCLK to use a non-dedicated clock route
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {cam_pclk_IBUF}]
