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
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity video_pattern_gen is
Port(
i_rst_n           : in     STD_LOGIC;
i_clk             : in     STD_LOGIC;

o_href            : out    STD_LOGIC;                       --include Hporch
o_de              : out    STD_LOGIC;                       --no include Hporch
o_vref            : out    STD_LOGIC;                       --include Vporch
o_vref_dtmg       : out    STD_LOGIC;                       --no include Vporch
o_data            : out    STD_LOGIC_vector(16-1 downto 0)
);
end video_pattern_gen;

architecture Behavioral of video_pattern_gen is

--components

--75MHz 16bit BUS, 1920x1080, 30fps, VESA code 34
constant DATA_WIDTH        : integer := 16;
constant WIN_WIDTH         : integer := 1920;
constant H_SYNC            : integer := 280-2;
constant H_BPORCH          : integer := 1;
constant H_FPORCH          : integer := 1;
constant WIN_HEIGHT        : integer := 1080;
constant V_SYNC            : integer := 45-2;
constant V_BPORCH          : integer := 1;
constant V_FPORCH          : integer := 1;


signal s_cnt_h             : std_logic_vector(13-1 downto 0);
signal s_cnt_v             : std_logic_vector(11-1 downto 0);
signal s_de                : std_logic;                 
signal s_de_1t             : std_logic;                 
signal s_de_2t             : std_logic;                 
signal s_de_3t             : std_logic;                 
signal s_href_blank_n      : std_logic;                 
signal s_hsync             : std_logic;                 
signal s_hsync_f_pulse     : std_logic;                 
signal s_hsync_1t          : std_logic;                 
signal s_hsync_2t          : std_logic;                 
signal s_hsync_3t          : std_logic;                 
signal s_vsync             : std_logic;                 
signal s_vsync_1t          : std_logic;                 
signal s_vsync_2t          : std_logic;                 
signal s_vsync_3t          : std_logic;                 
signal s_data              : std_logic_vector(16-1 downto 0);
signal s_vsync_dtmg        : std_logic;                 
signal s_vsync_dtmg_1t     : std_logic;                 
signal s_vsync_dtmg_2t     : std_logic;                 
signal s_vsync_dtmg_3t     : std_logic;                 
signal s_data_1dff         : std_logic_vector(16-1 downto 0);
signal s_cnt_frame         : std_logic_vector(8-1 downto 0);

begin

--Generate s_hsync
process(i_rst_n, i_clk)
begin
   if i_rst_n = '0' then
      s_cnt_h        <= (others => '0');
      s_hsync        <= '0';
      s_href_blank_n <= '0';
      s_de           <= '0';
   elsif rising_edge(i_clk) then
      s_cnt_h        <= s_cnt_h + 1 ;
      if    s_cnt_h = (H_SYNC-1) then
         s_hsync           <= '1';
         s_href_blank_n    <= '0';
         s_de              <= '0';
      elsif s_cnt_h = (H_SYNC +H_BPORCH -1 -2) then
         s_hsync           <= '1';
         s_href_blank_n    <= '1';
         s_de              <= '0';
      elsif s_cnt_h = (H_SYNC +H_BPORCH -1) then
         s_hsync           <= '1';
         s_href_blank_n    <= '1';
         s_de              <= '1';

      elsif s_cnt_h = (H_SYNC +H_BPORCH +WIN_WIDTH -2) then
         s_hsync           <= '1';
         s_href_blank_n    <= '0';
         s_de              <= '1';
      elsif s_cnt_h = (H_SYNC +H_BPORCH +WIN_WIDTH -1) then
         s_hsync           <= '1';
         s_href_blank_n    <= '0';
         s_de              <= '0';
      elsif s_cnt_h = (H_SYNC +H_BPORCH +WIN_WIDTH +H_FPORCH -1) then
         s_cnt_h           <= (others => '0');
         s_hsync           <= '0';
         s_href_blank_n    <= '0';
         s_de              <= '0';
      end if;
   end if;
end process;

--data
process(i_rst_n, i_clk)
begin
   if i_rst_n = '0' then
      s_data            <= (others=>'0');
   elsif rising_edge(i_clk) then
		if s_de = '0' then
			s_data         <= (others => '0');
		else
			s_data         <= s_data +1;
		end if;
   end if;                
end process;

--syncs dffs
process(i_rst_n, i_clk)
begin
   if i_rst_n = '0' then
      s_hsync_1t      <= '0';
      s_de_1t         <= '0';
   elsif rising_edge(i_clk) then
      s_hsync_1t      <= s_hsync;
      s_de_1t         <= s_de;
   end if;                
end process;

s_hsync_f_pulse   <= (not s_hsync) and s_hsync_1t;   --falling signal, positive pulse

--Generate s_vsync
process(i_rst_n, i_clk)--s_hsync)
begin
   if i_rst_n = '0' then
      s_cnt_v         <= (others => '0') ;--conv_std_logic_vector((V_SYNC +V_BPORCH +WIN_HEIGHT +V_FPORCH -1), 11);
      s_vsync_1t         <= '0';
      s_vsync_dtmg_1t   <= '0';
   elsif rising_edge(i_clk) then--s_hsync = '0' and s_hsync'event then
      if s_hsync_f_pulse = '1' then
        s_cnt_v   <= s_cnt_v + 1 ;
        if    s_cnt_v = (V_SYNC -1) then
          s_vsync_1t        <= '1';
          s_vsync_dtmg_1t   <= '0';
        elsif s_cnt_v = (V_SYNC +V_BPORCH -1) then
          s_vsync_1t        <= '1';
          s_vsync_dtmg_1t   <= '1';
        elsif s_cnt_v = (V_SYNC +V_BPORCH +WIN_HEIGHT -1) then
          s_vsync_1t        <= '1';
          s_vsync_dtmg_1t   <= '0';
        elsif s_cnt_v = (V_SYNC +V_BPORCH +WIN_HEIGHT +V_FPORCH -1) then
          s_cnt_v        <= (others => '0');
          s_vsync_1t        <= '0';
          s_vsync_dtmg_1t   <= '0';
        end if;
      end if;
   end if;
end process;

----count frame
--process(i_rst_n, s_vsync)
--begin
--   if i_rst_n = '0' then
--      s_cnt_frame          <= (others => '0');
--   elsif s_vsync = '0' and s_vsync'event then      --falling, start of SYNC
--      s_cnt_frame          <= s_cnt_frame + 1 ;
--      if    s_cnt_frame = i_vga_out_count_num then
--         s_cnt_frame      <= (others => '0');
--      end if;
--   end if;
--end process;
-----------------------------------------------------------------------------------------

----inputs
--s_hsync_1t
--s_de_1t
--s_vsync_1t
--s_vsync_dtmg_1t

--syncs dffs
process(i_rst_n, i_clk)
begin
   if i_rst_n = '0' then
--      s_hsync_1t      <= '0';
      s_hsync_2t         <= '0';
      s_hsync_3t         <= '0';
--      s_de_1t         <= '0';
      s_de_2t         <= '0';
      s_de_3t         <= '0';
      s_vsync_2t         <= '0';
      s_vsync_3t         <= '0';
      s_vsync_dtmg_2t    <= '0';
      s_vsync_dtmg_3t    <= '0';
   elsif rising_edge(i_clk) then
--      s_hsync_1t      <= s_hsync;
      s_hsync_2t      <= s_hsync_1t;
      s_hsync_3t      <= s_hsync_2t;
--      s_de_1t         <= s_de;
      s_de_2t         <= s_de_1t;
      s_de_3t         <= s_de_2t;
      s_vsync_2t      <= s_vsync_1t;
      s_vsync_3t      <= s_vsync_2t;
      s_vsync_dtmg_2t   <= s_vsync_dtmg_1t;
      s_vsync_dtmg_3t   <= s_vsync_dtmg_2t;
   end if;                
end process;
o_href                  <= s_hsync_1t;
o_de                    <= s_de_1t;
o_vref                  <= s_vsync_1t;
o_vref_dtmg             <= s_vsync_dtmg_1t;
o_data(16-1 downto  8)  <= x"80";							--CbCr video of YUY2(YCbCr 16bit per pixel)
o_data( 8-1 downto  0)  <= s_data( 8+3-1 downto  0+3);		--Y video of YUY2(YCbCr 16bit per pixel)

end Behavioral;
