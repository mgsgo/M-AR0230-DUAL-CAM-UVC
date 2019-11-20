----------------------------------------------------------------------------------
-- Company:        MGSG
-- Engineer:       jhyoo, mgsg.opensource@gmail.com
-- 
-- Create Date:    2019
-- Design Name:    FPGA_USB3_UVC
-- Module Name:    FPGA - Behavioral 
-- Project Name:   M-AR0230-DUAL-CAM-UVC
-- Target Devices: XC6SLX16-2FTG256
-- Tool versions:  ISE14.7
-- Description:    Example of UVC(Universal Video Class) camera FPGA generated video
-- License:        BSD 2-Clause
--
-- Dependencies:   
--
-- Revision:       
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_ARITH.ALL;
use IEEE.std_logic_UNSIGNED.ALL;

entity FPGA_USB3_UVC is
port(
i_clk_100mhz            : in     std_logic;      --100mhz
io_led0                 : inout  std_logic;      --LED, D11 low ON, blue LED
io_uart_txd             : inout  std_logic;
io_uart_rxd             : inout  std_logic;

--FX3
io_fx3_PCLK             : inout  std_logic;
io_fx3_resetn           : inout  std_logic;
io_fx3_DQ               : inout  std_logic_vector(32-1 downto 0); --DATA
io_fx3_CTL11_GP28_A1_LV : inout  std_logic;                       --LV, A1/GP28
io_fx3_CTL12_GP29_A0_FV : inout  std_logic;                       --FV, A0/GP29
io_fx3_spi_miso_uart_tx : inout  std_logic;                       --UART_TX
io_fx3_spi_mosi_uart_rx : inout  std_logic                        --UART_RX
);
end FPGA_USB3_UVC;

architecture Behavioral of FPGA_USB3_UVC is

--components-------------------------------------------------------------------
component clock_wizard_100mhz_input
port
(-- Clock in ports
CLK_IN1                 : in     std_logic;  -- Clock out ports
CLK_OUT1                : out    std_logic;  -- Status and control signals
CLK_OUT2                : out    std_logic;  -- Status and control signals
--CLK_OUT3                : out    std_logic;  -- Status and control signals
--CLK_OUT4                : out    std_logic;  -- Status and control signals
--CLK_OUT5                : out    std_logic;  -- Status and control signals
--CLK_OUT6                : out    std_logic;  -- Status and control signals
--CLK_OUT7                : out    std_logic;  -- Status and control signals
--CLK_OUT8                : out    std_logic;  -- Status and control signals
RESET                   : in     std_logic;
LOCKED                  : out    std_logic
);
end component;

component ODDR2
generic(
DDR_ALIGNMENT  : string := "NONE";
INIT           : bit    := '0';
SRTYPE         : string := "SYNC"
);
port(
Q              : out std_ulogic;
C0             : in  std_ulogic;
C1             : in  std_ulogic;
CE             : in  std_ulogic := 'H';
D0             : in  std_ulogic;
D1             : in  std_ulogic;
R              : in  std_ulogic := 'L';
S              : in  std_ulogic := 'L'
);
end component;

component video_pattern_gen is
Port(
i_rst_n           : in     STD_LOGIC;
i_clk             : in     STD_LOGIC;

o_href            : out    STD_LOGIC;
o_de              : out    STD_LOGIC;
o_vref            : out    STD_LOGIC;
o_vref_dtmg       : out    STD_LOGIC;
o_data            : out    STD_LOGIC_vector(16-1 downto 0)
);
end component;

--signals----------------------------------------------------------------------
signal s_clk_100mhz        : std_logic;
signal s_rst               : std_logic;
signal s_rst_n             : std_logic;
signal s_cnt_32bit         : std_logic_vector(32-1 downto 0);

signal s_clk_75mhz         : std_logic;
signal s_clk_75mhz_n       : std_logic;

--video pattern gen
signal s_vid_pattern_LV    : std_logic;
signal s_vid_pattern_FV    : std_logic;
signal s_vid_pattern_DATA  : std_logic_vector(16-1 downto 0);

--FX3
signal s_FX3_PCLK          : std_logic;
signal s_FX3_PCLK_n        : std_logic;



begin


--clock------------------------------------------------------------------------
--clock wizard, internal reset
clock_wizard_100mhz_input_u0 : clock_wizard_100mhz_input
port map(
CLK_IN1              => i_clk_100mhz,
CLK_OUT1             => s_clk_100mhz,
CLK_OUT2             => s_clk_75mhz,      --24MHz clock generate
RESET                => '0',
LOCKED               => s_rst_n
);
s_rst                <= not s_rst_n;
s_clk_75mhz_n        <= not s_clk_75mhz;
--end clock--------------------------------------------------------------------


--test counter-----------------------------------------------------------------
process(s_rst_n, s_clk_100mhz)
begin
	if s_rst_n = '0' then
		s_cnt_32bit       <= (others=>'0');
	elsif rising_edge(s_clk_100mhz) then
		s_cnt_32bit       <= s_cnt_32bit +1;
	end if;
end process;
--end test counter-------------------------------------------------------------


--led--------------------------------------------------------------------------
io_led0              <= not s_cnt_32bit(24);          --LED, D11 low ON, blue LED
--end led----------------------------------------------------------------------


--pattern generation-----------------------------------------------------------
video_pattern_gen_u1 : video_pattern_gen
Port map(
i_rst_n           => s_rst_n,
i_clk             => s_clk_75mhz,
o_href            => open,
o_de              => s_vid_pattern_LV,
o_vref            => open,
o_vref_dtmg       => s_vid_pattern_FV,
o_data            => s_vid_pattern_DATA
);
--end pattern generation-------------------------------------------------------


--FX3 AN75779 16bit mappings---------------------------------------------------
io_fx3_resetn        <= '1';                          --FX3 reset after FPGA boot

s_FX3_PCLK           <= s_clk_75mhz;
s_FX3_PCLK_n         <= not s_FX3_PCLK;

--FX3 PCLK out use ODDR2(SPARTAN6)
ODDR2_FX3_PCLK : ODDR2
generic map(DDR_ALIGNMENT => "NONE",   INIT          => '0',   SRTYPE        => "SYNC")
port map(
Q           => io_fx3_PCLK,    --port
C0          => s_FX3_PCLK_n,   --output
C1          => s_FX3_PCLK,     --not output
CE          => '1', D0 => '1', D1 => '0', R => '0', S => '0');

io_fx3_CTL11_GP28_A1_LV    <= s_vid_pattern_LV;
io_fx3_CTL12_GP29_A0_FV    <= s_vid_pattern_FV;
io_fx3_DQ(16-1 downto 0)   <= s_vid_pattern_DATA;
--end FX3 AN75779 16bit mappings-----------------------------------------------

--UART mappins-----------------------------------------------------------------
io_uart_txd                <= io_fx3_spi_miso_uart_tx;
io_fx3_spi_mosi_uart_rx    <= io_uart_rxd;
--end UART mappins-------------------------------------------------------------


end Behavioral;

