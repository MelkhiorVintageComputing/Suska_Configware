------------------------------------------------------------------------
----                                                                ----
---- Atari STE compatible IP Core for the Suska-III-B board.        ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- This model provides the top level file of an STE compatible    ----
---- machine including CPU, Blitter, MCU, DMA, Shifter, GLUE,       ----
---- MFP, SOUND, ACIA and RTC.                                      ----
----                                                                ----
---- Important Notice concerning the clock system:                  ----
---- The systems of the original ST or STE machines used several    ----
---- clocks which must stand in a fixed relation to each other.     ----
---- This core uses one central system clock of 16MHz. From this    ----
---- clock all required clocks are derived. These are CLK_1,        ----
---- CLK_2 and CLK_CPU. These are the clocks used for clocking      ----
---- D type flip-flops of the system and are provided by a first    ----
---- phase locked loop circuit.                                     ----
---- The clocks should used as follows:                             ----
---- CLK_1 for the BLITTER, GLUE, DMA, MFP, 1772, SOUND and UARTs.  ----
---- CLK_2 for the MCU, , SHIFTER, the video RAM component and      ----
---- the external SD-RAMs and the memory data buffer.               ----
---- CLK_CPU for the processor unit.                                ----
---- Beside these 'real' clocks, there are several auxiliary        ----
---- clocks which are processed by one of the above mentioned       ----
---- clocks (CLK_1, CLK_2). There are two clocks SCLK_6M4 and       ----
---- CLK_24576 which are provided by a second phase locked loop and ----
---- a counter process. The SCLK_6M4 controls the DMA sound module  ----
---- whereas the CLK_24576 is responsible for a correct timing of   ----
---- the MFP. The clocks are outputs of the counter process for     ----
---- their frequency is too low to provide it directly by a phase   ----
---- locked loop.                                                   ----
---- Last but not least there are two clocks CLK_2M0 and CLK_0M5    ----
---- which control the UARTs and the sound chip. These two clocks   ----
---- are provided by a counter out of the CLK_PLL_16000 due to      ----
---- their low frequency.                                           ----
---- To meet the correct timing requirements for the following      ----
---- units, there must be the correct generic settings in the       ----
---- respective top level _soc files.                               ----
---- The timing critical units are:                                 ----
----   - the video timing in the GLUE.                              ----
----   - the paddle counter in the GLUE.                            ----
----   - the video phase control in the MCU.                        ----
----   - the dma sound control in the MCU.                          ----
----                                                                ----
---- The phase locked loops are customer / hardware specific        ----
---- components and therefore declared in this top level file.      ----
---- This kind of modelling has the advantage, that the migration   ----
---- to other hardware is simple by modifying only the top level    ----
---- file of the SUSKA core.                                        ----
----                                                                ----
---- CPU: this core features a light weight 68K30L CPU. Due to      ----
----   resource limitations the generic swicht for the CPU is set   ----
----   to true resulting in removing the bit field operations. So   ----
----   BFCHG, BFCLR, BFEXTS, BFEXTU, BFFFO, BFINS, BFSET and BFTST  ----
----   will not work. For more information refer to the top level   ----
----   file of the 68K30L.                                          ---- 
----                                                                ----
---- SD-RAM section: This core provides a memory of 16MByte ST RAM  ----
----   and aditionally 16MB ALTRAM. The ALTRAM is switched by the   ----
----   OS selector configuration switch. See the info concerning    ----
----   the configuration switch in this file header. ALTRAM is      ----
----   disabled if the generic EN_RAM_14MB is switched to 4MB.      ----
----                                                                ----
---- Recommendations for the signal termination:                    ----
----   The following signals should be terminated with a weak       ----
----   pull up resistor (~22K). Use either weak pull up resistors   ----
----   of the FPGAs or external ones:                               ----
----     DATA, CONFIG, DSC_CDn, SDC_WPn.                            ----
----                                                                ----
---- The half moon switches have the following functionality:       ----
---- The bits are low active.                                       ----
----   HALFMOON_STE(8)   : '0' = DMA sound off.                     ----
----   HALFMOON_STE(7)   : '0' = HD type Floppy.                    ----
----   HALFMOON_STE(6)   : '0' = Bypass self test.                  ----
----   HALFMOON_STE(5)   : reserved.                                ----
----   HALFMOON_STE(4)   : reserved.                                ----
----   HALFMOON_STE(3)   : reserved.                                ----
----   HALFMOON_STE(2)   : reserved.                                ----
----   HALFMOON_STE(1)   : reserved.                                ----
----                                                                ----
---- The audio output is multiplexed. If the DMA sound is enabled,  ----
---- the DMA audio stream is enabled and the YM2149 audio data is   ----
---- disabled. When DMA sound is disabled, the YM2149 audio data is ----
---- enabled.                                                       ----
----                                                                ----
---- The SLOW_CPU feature is enabled for the old operating system   ----
---- versions which reside in the RAM space above x"FC0000".        ----
----                                                                ----
---- The configuration swich is as follows:                         ----
---- Config Switch 1 and 2 (1 is leftmost on the B board) are       ----
---- intended to select the video mode in sense of resolution and   ----
---- colour as follows:                                             ----
----   "11" : We use an RGB colour monitor. (15kHz@50Hz)            ----
----   "10" : We use a VGA monitor with colour modi. (31kHz@50Hz)   ----
----   "01" : 72Hz compatible modi. (35kHz@72Hz)                    ----
----   "00" : We use a monochrome monitor or VGA monochrome mode.   ----
---- Config Switch 3 to 6 switches 1 from 16 operating system flash ----
---- spaces. x"0" is the lowest address block and x"F" the highest. ----
---- The size of each address block is 256k x 16 bit. The address   ----
---- x"0", x"1" and x"2" switch to the xFC0000" RAM address space,  ----
---- so these three are reserved for the old TOS versions 1.00,     ----
---- 1.02 and 1.04.                                                 ----
---- For ALTRAM supporting operating systems, the selector enables  ----
---- additional 16MB of ALTRAM at selector settings > "1000". So    ----
---- be aware to place those operating systems in the correct (hi)  ----
---- address space in Flash memory.                                 ----
---- The selector switches are arranged in binary order. Switch 3   ----
---- is MSB and switch 6 is LSB.                                    ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2021... Wolfgang Foerster - Inventronik GmbH.      ----
---- Copyright © 2023... Udo Matthe.                                ----
----                                                                ----
---- This source file may be used and distributed without           ----
---- restriction provided that this copyright statement is not      ----
---- removed from the file and that any derivative work contains    ----
---- the original copyright notice and the associated disclaimer.   ----
----                                                                ----
---- This source file is free software; you can redistribute it     ----
---- and/or modify it under the terms of the GNU Lesser General     ----
---- Public License as published by the Free Software Foundation;   ----
---- either version 2.1 of the License, or (at your option) any     ----
---- later version.                                                 ----
----                                                                ----
---- This source is distributed in the hope that it will be         ----
---- useful, but WITHOUT ANY WARRANTY; without even the implied     ----
---- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR        ----
---- PURPOSE. See the GNU Lesser General Public License for more    ----
---- details.                                                       ----
----                                                                ----
---- You should have received a copy of the GNU Lesser General      ----
---- Public License along with this source; if not, download it     ----
---- from http://www.gnu.org/licenses/lgpl.html                     ----
----                                                                ----
------------------------------------------------------------------------
--
-- Revision History
--
-- Revision 2K21A 20211224 WF
--   Initial Release.
-- Revision 2K23A 20230620 UMA
--   Implemented Udo Matthe Shadow TOS.
--   CLK_SD is now 64MHz.
-- Revision 2K23B 20231224
--   ROMSEL_FC_E0n is now switched via address space (UMA).
--   Removed CLK_SDCARD.
--   New unitized video timing settings (UMA).
-- Revision 2K24A 20240620
--   Changes due to GLUE SCC enhancements.
--
--   !!! See the header for actual configuration switch settings!!!


library work;
use work.SUSKA_CORE_B_STE_PKG.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity SUSKA_III_B_STE_68K30L_TOP is
    generic(CORETYPE                : std_logic_vector(15 downto 0) := x"0120"; -- Core Type is 'B Suska-STE-68K30L'.
            VERSION                 : std_logic_vector(31 downto 0) := x"20250620"; -- Core version.
            HALFMOONS_STE           : std_logic_vector(8 downto 1) := x"BF"; -- This is the STE configuration switch.
            NO_FLOPPY               : boolean := true; -- Set true to disable floppy on SD card otherwise false.
            EN_RAM_14MB             : std_logic := '1'; -- '1' to enable the 14MB memory, '0' is 4MB.
            NO_BFOPS                : boolean := true; -- No bitfield operations if true. This saves 30% of the CPU resources.
            MFP_UART_FIXED_SPEED    : boolean := false); -- Set true to use fixed Speed 38400bd
            
    port(
        -- System controls:
        RESET_COREn             : in std_logic; -- FPGA reset.
        RESETn                  : inout std_logic; -- System and CPU reset.
        CLK_PLL1                : in std_logic; -- 16 MHz system clock.
        CLK_PLL2                : in std_logic; -- 16 MHz system clock.

        -- Data and address busses:
        DATA                    : inout std_logic_vector(15 downto 0); -- This is the ROM data port.
        ADR                     : out std_logic_vector(22 downto 1);

        -- The SDRAM and ROM interface:
        RAM_CLK                 : out std_logic;
        RAM_CKE                 : out std_logic;

        RAM_RASn                : out std_logic;
        RAM_CASn                : out std_logic;
        RAM_DQMH                : out std_logic;
        RAM_DQML                : out std_logic;
        RAM_WEn                 : out std_logic;
        RAM_ADR                 : out std_logic_vector(12 downto 0);
        RAM_BA                  : out std_logic_vector(1 downto 0);
        RAM_DATA                : inout std_logic_vector(15 downto 0);

        -- Video interface:
        VDAC_CLK                : out std_logic;
        CRT_R                   : out std_logic_vector(7 downto 4);
        CRT_G                   : out std_logic_vector(7 downto 4);
        CRT_B                   : out std_logic_vector(7 downto 4);

        HSYNC                  : inout std_logic;
        VSYNC                  : inout std_logic;

        -- Keyboard:
        KEYB_RxD                : in std_logic;
        KEYB_TxD                : out std_logic;

        -- DS1392 RTC:
        DS1392_D                : inout std_logic;
        DS1392_SCL              : out std_logic;
        DS1392_CE               : out std_logic;

        -- Flash controls:
        FLASH_RDY               : in std_logic;
        FLASH_WEn               : out std_logic;
        FLASH_OEn               : out std_logic;
        FLASH_CEn               : out std_logic;

        -- Audio DAC AD5302:
        DAC_SCLK                : out std_logic;
        DAC_SYNCn               : out std_logic;
        DAC_SDATA               : out std_logic;
        DAC_LDACn               : out std_logic;

        -- Other system signals:
        LED3                    : out std_logic; -- Indicates unlocked PLLs.
        LED2                    : out std_logic; -- SD card and Boot loader active...
        LED1                    : out std_logic; -- SD card LED.
        JOY_DIS                 : out std_logic; -- Disables the output buffer of the joystick.
        CONFIG                  : in std_logic_vector(1 to 6); -- Configuration switches, use weak pull up.
        JOY_A5                  : in std_logic; -- Joystick pin.
        JOY_A2                  : in std_logic; -- Joystick pin.

        -- SD card and SPI interface:
        SDC_SPI_CLK             : inout std_logic;
        MOSI                    : inout std_logic; -- SD-Drive is master, bootloader is slave.
        MISO                    : inout std_logic; -- SD-Drive is master, bootloader is slave.
        SDC_D                   : inout std_logic_vector(3 downto 1); -- SD card interconnect.
        SDC_CDn                 : in std_logic; -- Card detect..
        SDC_WP                  : in std_logic; -- Write protect.
        SDC_PWRn                : out std_logic; -- Power switch.

        -- Microcontroller interface:
        DRIVES_BSYn             : buffer std_logic;
        BOOT_ACK                : in std_logic;
        BOOT_REQ                : out std_logic
    );
end entity SUSKA_III_B_STE_68K30L_TOP;

architecture STRUCTURE of SUSKA_III_B_STE_68K30L_TOP is

-- Hardware specific components. Use these for a Cyclone device:
component cyclone_pll_1
    PORT
    (
        areset        : IN STD_LOGIC  := '0';
        inclk0        : IN STD_LOGIC  := '0';
        c0            : OUT STD_LOGIC ;
        c1            : OUT STD_LOGIC ;
        c2            : OUT STD_LOGIC ;
        locked        : OUT STD_LOGIC
    );
end component;

component cyclone_pll_2
    PORT
    (
        areset        : IN STD_LOGIC  := '0';
        inclk0        : IN STD_LOGIC  := '0';
        c0            : OUT STD_LOGIC ;
        c1            : OUT STD_LOGIC ;
        c2            : OUT STD_LOGIC ;
        locked        : OUT STD_LOGIC
    );
end component;
-- End of ardware specific components for a Cyclone III.

alias SPI_SS2n                      : std_logic is SDC_D(2);
alias SPI_SS1n                      : std_logic is SDC_D(1);
alias SPI_SS0n                      : std_logic is JOY_A2;

signal ACIA_CS                      : std_logic;
signal ADR_EN_BLT                   : std_logic;
signal ADR_EN_BOOT                  : std_logic;
signal ADR_I                        : std_logic_vector(31 downto 1);
signal ADR_OUT_68K30L               : std_logic_vector(31 downto 0);
signal ADR_OUT_BLT                  : std_logic_vector(31 downto 1);
signal ADR_OUT_BOOT                 : std_logic_vector(24 downto 1);
signal ASn                          : std_logic;
signal AS_OUT_68K30Ln               : std_logic;
signal AS_OUT_BLTn                  : std_logic;
signal AS_OUT_GLUEn                 : std_logic;
signal AVECn                        : std_logic;
signal BERRn                        : std_logic;
signal BG_68K30Ln                   : std_logic;
signal BG_BLTn                      : std_logic;
signal BGACK_BLTn                   : std_logic;
signal BGACK_GLUEn                  : std_logic;
signal BLANKn                       : std_logic;
signal BOOT_LED                     : std_logic;
signal BRn                          : std_logic;
signal BR_BLTn                      : std_logic;
signal BR_GLUEn                     : std_logic;
signal BUS_EN_68K30L                : std_logic;
signal BUSCTRL_EN_BLT               : std_logic;
signal BUSCTRL_EN_GLUE              : std_logic;
signal BUTTONn                      : std_logic;
signal CA1                          : std_logic;
signal CA2                          : std_logic;
signal CD_IN_DMA                    : std_logic_vector(7 downto 0);
signal CD_EN_DRIVES                 : std_logic;
signal CD_EN_FDC                    : std_logic;
signal CD_OUT_DMA                   : std_logic_vector(7 downto 0);
signal CD_OUT_DRIVES                : std_logic_vector(7 downto 0);
signal CD_OUT_FDC                   : std_logic_vector(7 downto 0);
signal CLK_0M5                      : std_logic;
signal CLK_1                        : std_logic;
signal CLK_2                        : std_logic;
signal CLK_24576                    : std_logic;
signal CLK_2M0                      : std_logic;
signal CLK_38400x16                 : std_logic;
signal CLK_CPU                      : std_logic;
signal CLK_MFP_UART                 : std_logic;
signal CLK_PLL_16000                : std_logic;
signal CLK_PLL_256                  : std_logic;
signal CLK_PLL_394                  : std_logic;
signal CMPCSn                       : std_logic;
signal CR_Wn                        : std_logic;
signal DATA_EN_68K30L               : std_logic;
signal DATA_EN_ACIA_I               : std_logic;
signal DATA_EN_ACIA_II              : std_logic;
signal DATA_EN_BLT                  : std_logic;
signal DATA_EN_BOOT                 : std_logic;
signal DATA_EN_DMA                  : std_logic;
signal DATA_EN_GLUE                 : std_logic;
signal DATA_EN_HI_SHFT              : std_logic;
signal DATA_EN_LO_SHFT              : std_logic;
signal DATA_EN_MCU                  : std_logic;
signal DATA_EN_MFP                  : std_logic;
signal DATA_EN_RP5C15               : std_logic;
signal DATA_EN_SOUND                : std_logic;
signal DATA_I                       : std_logic_vector(15 downto 0);
signal DATA_OUT_68K30L              : std_logic_vector(15 downto 0);
signal DATA_OUT_ACIA_I              : std_logic_vector(7 downto 0);
signal DATA_OUT_ACIA_II             : std_logic_vector(7 downto 0);
signal DATA_OUT_BLT                 : std_logic_vector(15 downto 0);
signal DATA_OUT_BOOT                : std_logic_vector(15 downto 0);
signal DATA_OUT_DMA                 : std_logic_vector(15 downto 0);
signal DATA_OUT_GLUE                : std_logic_vector(15 downto 0);
signal DATA_OUT_MCU                 : std_logic_vector(7 downto 0);
signal DATA_OUT_MFP                 : std_logic_vector(7 downto 0);
signal DATA_OUT_RP5C15              : std_logic_vector(3 downto 0);
signal DATA_OUT_SOUND               : std_logic_vector(7 downto 0);
signal DATA_SHFT                    : std_logic_vector(15 downto 0);
signal DCYCn                        : std_logic;
signal DE_I                         : std_logic;
signal DE_MSYNC                     : std_logic;
signal DEVn                         : std_logic;
signal DINTn                        : std_logic;
signal DMA_SOUND_EN                 : std_logic;
signal DMAn                         : std_logic;
signal DSn                          : std_logic;
signal DS1392_OUT                   : std_logic;
signal DS1392_OUT_EN                : std_logic;
signal DSACKn                       : std_logic_vector(1 downto 0);
signal DTACK_INn                    : std_logic;
signal DTACK_OUT_BLTn               : std_logic;
signal DTACK_OUT_GLUEn              : std_logic;
signal DTACK_OUT_MCUn               : std_logic;
signal DTACK_OUT_MFPn               : std_logic;
signal DTACKn                       : std_logic;
signal E_I                          : std_logic;
signal EN_ALTRAM                    : std_logic;
signal EXT_RAMn                     : std_logic;
signal FC                           : std_logic_vector(2 downto 0);
signal FC_OUT_68K30L                : std_logic_vector(2 downto 0);
signal FC_OUT_BLT                   : std_logic_vector(2 downto 0);
signal FC_OUT_GLUE                  : std_logic_vector(2 downto 0);
signal FCLK                         : std_logic;
signal FCSn                         : std_logic;
signal FDCSn                        : std_logic;
signal FDD_D0SELn                   : std_logic;
signal FDD_D1SELn                   : std_logic;
signal FDD_DIRC                     : std_logic;
signal FDD_IPn                      : std_logic;
signal FDD_MO                       : std_logic;
signal FDD_MO_WDC                   : std_logic;
signal FDD_RDn                      : std_logic;
signal FDD_SDSEL                    : std_logic;
signal FDD_STEP                     : std_logic;
signal FDD_TR00n                    : std_logic;
signal FDD_WD                       : std_logic;
signal FDD_WG                       : std_logic;
signal FDD_WPn                      : std_logic;
signal FDINT                        : std_logic;
signal FDINT_1772                   : std_logic;
signal FDRQ                         : std_logic;
signal FLASH_RESETn                 : std_logic;
signal FLASH_WAITSTATEn             : std_logic;
signal HALT_INn                     : std_logic;
signal HDACKn                       : std_logic;
signal HDCSn                        : std_logic;
signal HDINTn                       : std_logic;
signal HDRQ                         : std_logic;
signal HSYNCn                       : std_logic;
signal INT_BLTn                     : std_logic;
signal IPLn                         : std_logic_vector(2 downto 0);
signal IRQ_ACIAn                    : std_logic;
signal IRQ_KEYBDn                   : std_logic;
signal IRQ_MIDIn                    : std_logic;
signal JOY_RHn                      : std_logic;
signal JOY_RLn                      : std_logic;
signal JOY_WEn                      : std_logic;
signal KEYB_TxD_I                   : std_logic;
signal LATCHn                       : std_logic;
signal LED1_I                       : std_logic;
signal LED2_I                       : std_logic;
signal LDS_68K30Ln                  : std_logic;
signal LDS_OUT_BLTn                 : std_logic;
signal LDS_OUT_GLUEn                : std_logic;
signal LDSn                         : std_logic;
signal MCU_ADR                      : std_logic_vector(25 downto 1);
signal MDAT_BUFFER                  : std_logic_vector(15 downto 0);
signal MFP_CS_In                    : std_logic;
signal MFP_IACKn                    : std_logic;
signal MFPINTn                      : std_logic;
signal MONOCHROME                   : std_logic;
signal MULTISYNC_I                  : std_logic_vector(1 downto 0);
signal PLL_ARESET                   : std_logic;
signal PLL_FAULT                    : std_logic;
signal PLL_LOCKS                    : std_logic;
signal PLL1_LOCKED                  : std_logic;
signal PLL2_LOCKED                  : std_logic;
signal RAMn                         : std_logic;
signal RDATn                        : std_logic;
signal RDY_DMAn                     : std_logic;
signal RDY_GLUEn                    : std_logic;
signal RESET_CORE_Sn                : std_logic;
signal RESET_BOOTn                  : std_logic;
signal RESET_EN_68K30L              : std_logic;
signal RESET_INn                    : std_logic;
signal RESET_MCUn                   : std_logic;
signal RESET_Sn                     : std_logic;
signal ROM_CEn                      : std_logic;
signal ROM2n                        : std_logic;
signal ROM3n                        : std_logic;
signal ROM4n                        : std_logic;
signal ROM5n                        : std_logic;
signal ROM6n                        : std_logic;
signal ROMSEL_FC_E0n                : std_logic;
signal RP5C15_CSn                   : std_logic;
signal RP5C15_RDn                   : std_logic;
signal RP5C15_WRn                   : std_logic;
signal RWn_OUT_68K30L               : std_logic;
signal RWn_OUT_BLT                  : std_logic;
signal RWn_OUT_GLUE                 : std_logic;
signal RWn                          : std_logic;
signal SCLK_6M4                     : std_logic;
signal SDATA_L                      : std_logic_vector(7 downto 0);
signal SDATA_L_DMA                  : std_logic_vector(7 downto 0);
signal SDATA_R                      : std_logic_vector(7 downto 0);
signal SDATA_R_DMA                  : std_logic_vector(7 downto 0);
signal SDATA_YM                     : std_logic_vector(7 downto 0);
signal SDC_CSn                      : std_logic;
signal SDC_CLK                      : std_logic;
signal SDC_MOSI                     : std_logic;
signal SDC_PWR_In                   : std_logic;
signal SINT_IO7                     : std_logic;
signal SINT_TAI                     : std_logic;
signal SIZE                         : std_logic_vector(1 downto 0);
signal SLOADn                       : std_logic;
signal SNDCS_I                      : std_logic;
signal SNDIR_I                      : std_logic;
signal SPI_MISO                     : std_logic;
signal SREQ                         : std_logic;
signal SYNC_EN                      : std_logic;
signal SYNCn                        : std_logic;
signal TDO                          : std_logic;
signal UDS_68K30Ln                  : std_logic;
signal UDS_OUT_BLTn                 : std_logic;
signal UDS_OUT_GLUEn                : std_logic;
signal UDSn                         : std_logic;
signal VIDEO_HIMODE_I               : std_logic;
signal VPAn                         : std_logic;
signal VMA_68K30Ln                  : std_logic;
signal VSYNCn                       : std_logic;
signal WDATn                        : std_logic;
signal XFF827D                      : std_logic_vector(7 downto 0);
signal YM_OUT_A                     : std_logic;
signal YM_OUT_B                     : std_logic;
signal YM_OUT_C                     : std_logic;
begin
    -- Clock system:
    RAM_CLK <= CLK_2; -- Use the MCU clock.
    RAM_CKE <= RESET_COREn;
    VDAC_CLK <= CLK_2;

    PLL_RESET: process
    -- This process is responsible for resetting the PLLs
    -- during system startp.
    variable LOCK : boolean;
    begin
        wait until CLK_PLL1 = '1' and CLK_PLL1' event;
        if RESET_COREn = '0' and LOCK = false then
            LOCK := true;
            PLL_ARESET <= '1';
        elsif RESET_COREn = '1' then
            LOCK := false;
            PLL_ARESET <= '0';
        else
            PLL_ARESET <= '0';
        end if;
    end process PLL_RESET;

    PLL_LOCK_FLT: process
    -- This process provides a filter for the PLL status
    -- information.
    variable TMP : integer range 0 to 31;
    begin
        wait until CLK_PLL1 = '1' and CLK_PLL1' event;
        if (PLL1_LOCKED = '0' or PLL2_LOCKED = '0') and TMP = 0 then
            PLL_LOCKS <= '0';
            PLL_FAULT <= '1';
        elsif PLL1_LOCKED = '0' or PLL2_LOCKED = '0' then
            TMP := TMP -1;
            PLL_LOCKS <= '1';
            PLL_FAULT <= '0';
        else
            TMP := 31;
            PLL_LOCKS <= '1';
            PLL_FAULT <= '0';
        end if;
    end process PLL_LOCK_FLT;

    -------------------- Hardware specific components --------------------
    ----                  This is for a Cyclone device                ----
    ---- The following components instantiate the clock phase locked  ----
    ---- loops and the video ram. These are cyclone specific and thus ----
    ---- an object of change, if other devices are used for this core.----
    ----                                                              ----
    I_SYSCLOCKS: cyclone_pll_1
        port map(
            areset                => PLL_ARESET,
            inclk0                => CLK_PLL1, -- 16MHz.
            c0                    => CLK_1, -- 16MHz.
            c1                    => CLK_2, -- 32MHz.
            c2                    => CLK_CPU, -- 16MHz.
            locked                => PLL1_LOCKED
        );

    I_AUXCLOCKS: cyclone_pll_2
        port map(
            areset                => PLL_ARESET,
            inclk0                => CLK_PLL2, -- 16MHz.
            c0                    => CLK_PLL_256, -- 25.6MHz.
            c1                    => CLK_PLL_394, -- 39.4MHz.
            c2                    => CLK_PLL_16000, -- 16.0MHz.
            locked                => PLL2_LOCKED
        );
    ----                                                              ----
    ------------------ End hardware specific components ------------------

    -------------------- Hardware specific components --------------------
    ----                     This is for a ECP5U                      ----
    ---- The following components instantiate the clock phase locked  ----
    ---- loops and the video ram. These are cyclone specific and thus ----
    ---- an object of change, if other devices are used for this core.----
    ----                                                              ----
    --I_SYSCLOCKS: ECP5U_PLL_1
    --    port map(
    --        CLKI                => CLK_PLL1, -- 16MHz.
    --        RST                 => PLL_ARESET,
    --        CLKOP               => CLK_1, -- 16MHz.
    --        CLKOS               => CLK_2, -- 32MHz.
    --        CLKOS2              => CLK_CPU, -- 16MHz.
    --        LOCK                => PLL1_LOCKED
    --    );
    --
    --I_AUXCLOCKS: ECP5U_PLL_2
    --    port map(
    --        CLKI                => CLK_PLL2, -- 16MHz.
    --        RST                 => PLL_ARESET,
    --        CLKOP               => CLK_PLL_256, -- 25.6MHz.
    --        CLKOS               => CLK_PLL_394, -- 39.4MHz.
    --        CLKOS2              => CLK_PLL_16000, -- 16.0MHz.
    --        LOCK                => PLL2_LOCKED
    --    );
    ----                                                              ----
    ------------------ End hardware specific components ------------------

    P_AUX_CLOCKS: process
    -- The sound wave clock CLK_2M0 and the UART receiver,
    -- UART transmitter and sound clock CLK_0M5 are slow
    -- and therefore not possible to be provided by a PLL.
    -- Therefore this clock divider is adjusted to produce
    -- the required frequencies of 2MHz for the CLK_2M0 and
    -- 500kHz for the CLK_0M5. The Clocks are not used as
    -- clocks for d type flip-flops and therefore allowed
    -- as gated clocks.
    variable TMP: std_logic_vector(3 downto 0);
    begin
        wait until CLK_PLL_16000 = '1' and CLK_PLL_16000' event; -- 16MHz.
        TMP := TMP + '1';
        case TMP is
            when "0000" =>
                CLK_0M5 <= not CLK_0M5;
                CLK_2M0 <= not CLK_2M0;
            when "0100" | "1000" | "1100" =>
                CLK_2M0 <= not CLK_2M0;
            when others => null;
        end case;
    end process P_AUX_CLOCKS;

    P_2M4576: process
    -- This process provides the 2.4576MHz clock for the MFP
    -- timer. It is derived from a 39.4MHz PLL clock divided
    -- by 16 which results in a 2.4600 MHz clock.
    variable TMP_2M54: std_logic_vector(5 downto 0); --UMA
    begin
        wait until CLK_PLL_394 = '1' and CLK_PLL_394' event;
        TMP_2M54 := TMP_2M54 + '1';
        CLK_24576 <= TMP_2M54(3);
		  --UMA
        CLK_38400x16 <= TMP_2M54(5);
		  --UMA
    end process P_2M4576;

    CLK_MFP_UART <= TDO when MFP_UART_FIXED_SPEED = false else CLK_38400x16;

    P_6M4: process
    -- This process provides the 6.4000MHz clock for the DMA
    -- sound module. It is derived from a 25.6MHz PLL clock
    -- divided by 4 which results in a 6.4000 MHz clock.
    variable TMP_6M4: std_logic_vector(1 downto 0);
    begin
        wait until CLK_PLL_256 = '1' and CLK_PLL_256' event;
        TMP_6M4 := TMP_6M4 + '1';
        SCLK_6M4 <= TMP_6M4(1);
    end process P_6M4;

    KEYB_TxD <= 'Z' when RESET_CORE_Sn = '0' else
                'Z' when RESETn = '0' else
                'Z' when RESET_BOOTn = '0' else KEYB_TxD_I; -- The boot loader has priority.

    KEY_SCAN: process
    -- Sample the RESETn and the RESET_COREn buttons
    -- about every 5ms. This provides stability against
    -- push button jitter.
    variable SCAN_TIMER    : std_logic_vector(19 downto 0);
    begin
        wait until CLK_1 = '1' and CLK_1' event;
        if SCAN_TIMER <= x"4E200" then -- 20ms@16MHz.
            SCAN_TIMER := SCAN_TIMER + '1';
        else
            SCAN_TIMER := (others => '0');
            RESET_Sn <= RESETn;
            RESET_CORE_Sn <= RESET_COREn;
        end if;
    end process KEY_SCAN;

    -- The RESETs are as follows:
    -- RESET_Sn is the user's reset button.
    -- The RESET_CORE_Sn is the system's reset button.
    -- The RESET_BOOTn is the bootloader's reset during flash load operation.
    -- The RESET_MCUn is the memory controller's reset during RAM initialisation.
    -- PLL_LOCKS reset the system when the PLLs do not lock.
    -- RESET_EN_68K30L is the CPU reset output.
    RESET_INn <= RESET_Sn and RESET_BOOTn and RESET_MCUn and PLL_LOCKS;
    RESETn <= '0' when RESET_EN_68K30L = '1' or FLASH_RESETn = '0' or RESET_MCUn = '0' or PLL_LOCKS = '0' else 'Z';
    HALT_INn <= '0' when RESET_INn = '0' and RESET_EN_68K30L = '0' else '1';

    MEM_DATA_BUFFER: process(RESET_INn, CLK_2)
    -- This process is the synchronous pendant of the
    -- memory to data bus bridge buffer of the original ST
    -- machine. To work properly, the buffer is driven by
    -- a fast clock.
    begin
        if RESET_INn = '0' then
            MDAT_BUFFER <= (others => '0');
        elsif CLK_2 = '1' and CLK_2' event then
            if LATCHn = '1' then
                MDAT_BUFFER <= RAM_DATA;
            end if;
        end if;
    end process MEM_DATA_BUFFER;

    DATA <= DATA_OUT_BOOT when DATA_EN_BOOT = '1' else (others => 'Z'); -- ROM data.

    DATA_I <= DATA when RESET_BOOTn = '0' else -- This is the Flash to bootloader path.
              DATA_OUT_68K30L when DATA_EN_68K30L = '1' else
              DATA_OUT_BLT when DATA_EN_BLT = '1' else
              DATA_OUT_GLUE when DATA_EN_GLUE = '1' else
              x"FF" & DATA_OUT_MCU when DATA_EN_MCU = '1' else -- x"FF" due to pull up resistors in original hardware.
              DATA_OUT_DMA when DATA_EN_DMA = '1' else
              x"FF" & DATA_OUT_MFP when DATA_EN_MFP = '1' else
              DATA_OUT_SOUND & x"FF" when DATA_EN_SOUND = '1' else
              DATA_OUT_ACIA_I & x"FF" when DATA_EN_ACIA_I = '1' else
              DATA_OUT_ACIA_II & x"FF" when DATA_EN_ACIA_II = '1' else
              x"F" & DATA_OUT_RP5C15 & x"FF" when DATA_EN_RP5C15 = '1' else
              x"FFFF" when (JOY_RHn = '0' or JOY_RLn = '0') and JOY_WEn = '1' else -- Joyport enhancements (dummy).
              HALFMOONS_STE & x"FF" when BUTTONn = '0' else
              DATA when ROM_CEn = '0' else -- This is the Flash data.
              --
              -- The following is the read access from RAM. The data is switched directly to the data bus,
              -- when the LATCH is transparent. The reason is the critical bus timing. Switching the data
              -- directly saves one CLK_2 period.
              RAM_DATA when LATCHn = '1' and RDATn = '0' else MDAT_BUFFER;

    -- The SHIFTER registers are read via the RAM_DATA bus. See respective ST schematics.
    RAM_DATA <= DATA_I when WDATn = '0' else
                DATA_SHFT when DATA_EN_HI_SHFT = '1' and DATA_EN_LO_SHFT = '1' else
                DATA_SHFT(15 downto 8) & x"FF" when DATA_EN_HI_SHFT = '1' else
                x"FF" & DATA_SHFT(7 downto 0) when DATA_EN_LO_SHFT = '1' else (others => 'Z');

    ADR_I <= x"FF" & ADR_OUT_68K30L(23 downto 1) when BUS_EN_68K30L = '1' and ADR_OUT_68K30L(23 downto 16) = x"FF" and CONFIG(3 to 6) < "0110" else -- Memory map for operating systems non ALTRAM cabaple.
             x"FF" & ADR_OUT_68K30L(23 downto 1) when BUS_EN_68K30L = '1' and ADR_OUT_68K30L(23 downto 16) = x"FF" and ADR_OUT_68K30L(31 downto 20) < x"010" and CONFIG(3 to 6) > "0101" else -- Memory map for OS with ALTRAM.
             x"FF" & ADR_OUT_68K30L(23 downto 1) when BUS_EN_68K30L = '1' and ADR_OUT_68K30L(31 downto 20) >= x"040" and CONFIG(3 to 6) > "0101" else -- Memory map by sign extension for OS with ALTRAM.
             x"00" & ADR_OUT_68K30L(23 downto 1) when BUS_EN_68K30L = '1' and CONFIG(3 to 6) < "0110" else -- Non ALTRAM support.
             ADR_OUT_68K30L(31 downto 1) when BUS_EN_68K30L = '1' else -- ALTRAM capable.
             x"FF" & ADR_OUT_BLT(23 downto 1) when ADR_EN_BLT = '1' and ADR_OUT_BLT(23 downto 16) = x"FF" else -- Memory map.
             ADR_OUT_BLT when ADR_EN_BLT = '1' else (others => '1');

    ADR <= ADR_OUT_BOOT(22 downto 1) when ADR_EN_BOOT = '1' else
           CONFIG(3 to 6) & "10" & ADR_I(16 downto 1) when ROM6n = '0' else -- Cartridge space x"FB0000 to FBFFFF" is mapped to Flash space x"4/C_0000 to x5/D_FFFF" (STE).
           CONFIG(3 to 6) & "11" & ADR_I(16 downto 1) when ROM5n = '0' else -- Cartridge space x"FB0000 to FBFFFF" is mapped to Flash space x"6/E_0000 to x7/F_FFFF" (STE).
           CONFIG(3 to 6) & "100" & ADR_I(15 downto 1) when ROM4n = '0' else -- Cartridge space x"FA0000 to FAFFFF" is mapped to Flash space x"4/C_0000 to x4/C_FFFF".
           CONFIG(3 to 6) & "101" & ADR_I(15 downto 1) when ROM3n = '0' else -- Cartridge space x"FB0000 to FBFFFF" is mapped to Flash space x"5/D_0000 to x5/D_FFFF".
           CONFIG(3 to 6) & '0' & ADR_I(17 downto 1) when ROMSEL_FC_E0n = '1' else -- Required to get the old TOS' running.
           CONFIG(3 to 6) & ADR_I(18 downto 1); -- Cartridges or ROM space x"E00000" to x"E3FFFF".

    EN_ALTRAM <= '1' when ADR_I(25) = '0' and CONFIG(3 to 6) > "0101" else '0'; -- GLUE decoding is for 48MB ALTRAM in total, so we need to limit to 16MB.

    MCU_ADR <= ADR_I(25 downto 1) when EXT_RAMn = '0' else
               "00" & ADR_I(23 downto 1) when EN_RAM_14MB = '1' else
               x"0" & ADR_I(21 downto 1); -- For ST machines compatibility mode (running old TOS).



    -- Operating system ROM:
    ROMSEL_FC_E0n <= '1' when  ADR_I(31 downto 18) = "00000000111111" else '0';

    ROM_CEn <= ROM2n and ROM3n and ROM4n and ROM5n and ROM6n; -- The flash contains also ROM cartridge information.

    LED3 <= PLL_FAULT or BOOT_LED;
    LED2 <= '1' when XFF827D = x"55" else LED2_I;
    LED1 <= '1' when ADR_OUT_BOOT(24 downto 23) /= "00" else LED1_I;

    -- Video configuration:
    MONOCHROME <= '1' when CONFIG(1 to 2) = "00" else '0';
    MULTISYNC_I <= CONFIG(1 to 2);

    -- Video section:
    HSYNC <=     HSYNCn when SYNC_EN = '1'and MULTISYNC_I = "10" else
             not HSYNCn when SynC_EN = '1' else 'Z';
    VSYNC <= not VSYNCn when SYNC_EN = '1' else 'Z';

    P_DE_COUNT: process
    -- This flip flop provides a bisection of the DE frequency to
    -- meet a correct line counter value of the multifunction port
    -- timer B in case of the hi video modi with line doubling.
    variable LOCK    : boolean;
    begin
        wait until CLK_1 = '1' and CLK_1' event;
        if VIDEO_HIMODE_I = '0' then
            DE_MSYNC <= DE_I;
        elsif VIDEO_HIMODE_I = '1' and DE_I = '1' and LOCK = false then
            DE_MSYNC <= not DE_MSYNC;
            LOCK := true;
        elsif VIDEO_HIMODE_I = '1' and DE_I = '0' then
            LOCK := false;
        end if;
    end process P_DE_COUNT;

    -- Bus controls:
    UDSn <=  UDS_68K30Ln when BUS_EN_68K30L = '1' else
             UDS_OUT_BLTn when BUSCTRL_EN_BLT = '1' else
             UDS_OUT_GLUEn when BUSCTRL_EN_GLUE = '1' else '1';

    LDSn <=  LDS_68K30Ln when BUS_EN_68K30L = '1' else
             LDS_OUT_BLTn when BUSCTRL_EN_BLT = '1' else
             LDS_OUT_GLUEn when BUSCTRL_EN_GLUE = '1' else '1';

     -- The first condition of ASn is important for system
     -- startup. See process FLASH_WS.
    ASn <= '1' when FLASH_WAITSTATEn = '0' else
           AS_OUT_68K30Ln when BUS_EN_68K30L = '1' else
           AS_OUT_BLTn when BUSCTRL_EN_BLT = '1' else
           AS_OUT_GLUEn when BUSCTRL_EN_GLUE = '1' else '1';

    RWn <= RWn_OUT_68K30L when BUS_EN_68K30L = '1' else
           RWn_OUT_BLT when BUSCTRL_EN_BLT = '1' else
           RWn_OUT_GLUE when BUSCTRL_EN_GLUE = '1' else '1';

    FC <= FC_OUT_68K30L when BUS_EN_68K30L = '1' else
          FC_OUT_BLT when BUSCTRL_EN_BLT = '1' else
          FC_OUT_GLUE when BUSCTRL_EN_GLUE = '1' else "111";

    FLASH_WS: process (RESETn, CLK_1)
    -- This process provides a delay of seven clock cycles after the
    -- release of the RESETn due to the flash memory which is also 
    -- resetted by the RESETn and requires a minimum of 200ns.
    -- Without this logic, the CPU reads too fast from the flash memory
    -- when it releases a RESET_MCUn by itself.
    variable TMP: std_logic_vector(2 downto 0);
    begin
        if RESETn = '0' then
            TMP := "000";
            FLASH_WAITSTATEn <= '0';
        elsif CLK_1 = '1' and CLK_1' event then
            if TMP < "111" then
                TMP := TMP + '1';
                FLASH_WAITSTATEn <= '0';
            else
                FLASH_WAITSTATEn <= '1';
            end if;
        end if;
    end process FLASH_WS;

    SLOW_CPU: process(CLK_1, DTACKn, ROMSEL_FC_E0n, ROM2n)
    -- For software compatibility, it is sometimes necessary to
    -- slow down the CPU. This is done by a delay of the DTACK_INn
    -- signal for operating system access. Be aware, that the DTACKn
    -- signal of the MCU may not be affected due to strong timing
    -- constraints. This feature helps to fix issues with NOP delays.
    -- The delay of the DTACK_INn causes the CPU to insert waitstates.
    variable TMP : std_logic_vector(2 downto 0);
    begin
        if CLK_1 = '1' and CLK_1' event then
            if DTACKn = '1' then
                TMP := "000";
            elsif TMP /= "110" then
                TMP := TMP + '1';
            end if;
        end if;
        --
        case ROMSEL_FC_E0n is
            when '0' => DTACK_INn <= DTACKn; -- Not delayed.
            when others =>
                if ROM2n = '0' and TMP = "110" then -- Slow down flash memory access.
                    DTACK_INn <= '0';
                elsif ROM2n = '0' then
                    DTACK_INn <= '1';
                else
                    DTACK_INn <= DTACKn;
                end if;
        end case;
    end process SLOW_CPU;

    DTACKn <= '0' when DTACK_OUT_BLTn = '0' or DTACK_OUT_GLUEn = '0' else
              '0' when DTACK_OUT_MCUn = '0' or DTACK_OUT_MFPn = '0' else '1';

    -- Bus arbitration request:
    BRn <= BR_BLTn and BR_GLUEn;

    -- ACSI section:
    CD_IN_DMA <= CD_OUT_FDC when CD_EN_FDC = '1' else
    CD_OUT_DRIVES when CD_EN_DRIVES = '1' else (others => '0');

    -- DS1392 RTC interface:
    DS1392_D <= DS1392_OUT when DS1392_OUT_EN = '1' else 'Z';

    -- SD card bus:
    SDC_PWRn <= SDC_PWR_In;
    SDC_SPI_CLK <= 'Z' when SDC_PWR_In = '1' or RESET_BOOTn = '0' else SDC_CLK;
    SDC_D(3) <= 'Z' when SDC_PWR_In = '1' or RESET_BOOTn = '0' else SDC_CSn;
    SDC_D(2 downto 1) <= "ZZ";
    MOSI <= 'Z' when SDC_PWR_In = '1' or RESET_BOOTn = '0' else SDC_MOSI; -- SD-Card.
    MISO <= SPI_MISO when SDC_PWR_In = '1' or RESET_BOOTn = '0' else 'Z'; -- Boot loader.

    DMA_SOUND: process
    -- This Flip Flop is a shadow of the DMA_SOUND_REG(0)
    -- in the WF25912IP_DMA_SOUND_SD module.
    begin
        wait until CLK_2 = '1' and CLK_2' event;
        if RESET_INn = '0' then
            DMA_SOUND_EN <= '0';
        elsif ASn = '0' and (ADR_I(15 downto 1) & '0') = x"FF8900" and LDSn = '0' and RWn = '0' then  -- x"FF8901".
            DMA_SOUND_EN <= DATA_I(0);
        end if;
    end process DMA_SOUND;

    -- Sound Multiplexer:
    SDATA_L <= SDATA_L_DMA when DMA_SOUND_EN = '1' else SDATA_YM;
    SDATA_R <= SDATA_R_DMA when DMA_SOUND_EN = '1' else SDATA_YM;

    IRQ_ACIAn <= IRQ_KEYBDn and IRQ_MIDIn;
    FDINT <= FDINT_1772 when DRIVES_BSYn = '1' else '0'; -- This delay is important during floppy access to the SD card (writeback mode).

    -- This is the floppy drive select feature:
    FDD_MO <= FDD_MO_WDC when NO_FLOPPY = false else '0';

    -- Data strobes:
    UDS_68K30Ln <= '1' when SIZE = "01" and ADR_OUT_68K30L(0) = '1' else DSn;
    LDS_68K30Ln <= '1' when SIZE = "01" and ADR_OUT_68K30L(0) = '0' else DSn;

    -- Synchronous bus timing:
    DSACKn <= "01" when  DTACKn = '0' else -- Any access is 16 bit wide.
              "10" when SYNCn = '0' else "11"; -- SYNCn is used for interrupt vectoring.

    E_TIMER: process
    -- The E clock is a free running clock with a period of 10 times
    -- the CLK period. The pulse ratio is 4 CLK high and 6 CLK low.
    -- Use a synchronous reset due to FPGA constraints.
    variable TMP : std_logic_vector(3 downto 0);
    begin
        wait until CLK_1 = '1' and CLK_1' event;
        if RESET_INn = '0' then
            TMP := x"0";
            VMA_68K30Ln <= '1';
            E_I <= '1';
        elsif TMP < x"9" then
            TMP := TMP + '1';
        else
            TMP := x"0";
        end if;

        -- E logic:
        if TMP = x"0" then
            E_I <= '1';
        elsif TMP = x"4" then
            E_I <= '0';
        end if;

        -- VMA logic:
        if VPAn = '0' and TMP >= x"4" then -- Switch, when E is low.
            VMA_68K30Ln <= '0';
        elsif VPAn = '1' then
            VMA_68K30Ln <= '1';
        end if;
		  
        -- SYNCn logic (wait states controlling for the 68K30).
        -- Used for the legacy synchronous bus termination (ACIAs and RTC).
        if VPAn = '0' and VMA_68K30Ln = '0' and TMP = x"2" then -- Adjust E to S6..
            SYNCn <= '0';
        elsif VPAn = '1' then
            SYNCn <= '1';
        end if;

    end process E_TIMER;

    I_CPU: WF68K30L_TOP
    generic map(NO_BFOPS            => NO_BFOPS)
    port map(
        CLK                         => CLK_CPU,

        -- Address and data:
        --ADR_OUT(31 downto 24)     =>, -- Not used.
        ADR_OUT                     => ADR_OUT_68K30L,
        DATA_IN(31 downto 16)       => DATA_I,
        DATA_IN(15 downto 0)        => x"0000", -- Not used.
        DATA_OUT(31 downto 16)      => DATA_OUT_68K30L,
        --DATA_OUT(15 downto 0)     => DATA_OUT_68K30L, -- Not used.
        DATA_EN                     => DATA_EN_68K30L,

        -- System control:
        BERRn                       => BERRn,
        RESET_INn                   => RESET_INn,
        RESET_OUT                   => RESET_EN_68K30L,
        HALT_INn                    => HALT_INn,
        --HALT_OUTn                 => Not used.

        -- Processor status:
        FC_OUT                      => FC_OUT_68K30L,

        -- Interrupt control:
        AVECn                       => AVECn,
        IPLn                        => IPLn,
        --IPENDn                    =>, -- Not used.

        -- Aynchronous bus control:
        DSACKn                      => DSACKn,
        SIZE                        => SIZE,
        ASn                         => AS_OUT_68K30Ln,
        RWn                         => RWn_OUT_68K30L,
        --RMCn                      =>, -- Not used.
        DSn                         => DSn,
        --ECSn                      =>, -- Not used.
        --OCSn                      =>, -- Not used.
        --DBENn                     =>, -- Not used.
        BUS_EN                      => BUS_EN_68K30L,

        -- Synchronous bus control:
        STERMn                      => '1', -- Not used.

        -- Status controls:
        --STATUSn                   =>, Not used.
        --REFILLn                   =>, Not used.

        -- Bus arbitration control:
        BRn                         => BRn,
        BGn                         => BG_68K30Ln,
        BGACKn                      => BGACK_BLTn
    );

    I_BLITTER: WF101643IP_TOP_SOC
        port map(
            -- System controls:
            CLK                     => CLK_1,
            RESETn                  => RESET_INn,

            AS_INn                  => ASn,
            AS_OUTn                 => AS_OUT_BLTn,
            LDS_INn                 => LDSn,
            LDS_OUTn                => LDS_OUT_BLTn,
            UDS_INn                 => UDSn,
            UDS_OUTn                => UDS_OUT_BLTn,
            RWn_IN                  => RWn,
            RWn_OUT                 => RWn_OUT_BLT,
            DTACK_INn               => DTACK_INn,
            DTACK_OUTn              => DTACK_OUT_BLTn,
            BERRn                   => BERRn,
            FC_IN                   => FC,
            FC_OUT                  => FC_OUT_BLT,
            BUSCTRL_EN              => BUSCTRL_EN_BLT,
            INTn                    => INT_BLTn,

            -- The bus:
            ADR_IN                  => ADR_I(31 downto 1),
            ADR_OUT                 => ADR_OUT_BLT,
            ADR_EN                  => ADR_EN_BLT,
            DATA_IN                 => DATA_I,
            DATA_OUT                => DATA_OUT_BLT,
            DATA_EN                 => DATA_EN_BLT,

            -- Bus arbitration:
            BGIn                    => BG_68K30Ln,
            BGKIn                   => BGACK_GLUEn,
            BRn                     => BR_BLTn,
            BGACK_INn               => '1',
            BGACK_OUTn              => BGACK_BLTn,
            BGOn                    => BG_BLTn
        );

    I_GLUE: WF25915IP_TOP_SOC
        port map(
            -- Clock system:
            CLK_1                   => CLK_1,
            CLK_2                   => CLK_2,
            CLK_0M5                 => CLK_0M5,

            -- Adress decoder:
            EN_RAM_14MB             => EN_RAM_14MB,
            EN_ALTRAM               => EN_ALTRAM,
            ROM_6n                  => ROM6n,
            ROM_5n                  => ROM5n,
            ROM_4n                  => ROM4n,
            ROM_3n                  => ROM3n,
            ROM_2n                  => ROM2n,
            -- ROM_1n               =>,
            -- ROM_0n               =>,

            ACIACS                  => ACIA_CS,
            MFPCSn                  => MFP_CS_In,
            -- SNDCSn               =>, -- Not used.
            FCSn                    => FCSn,

            STE_SNDCS               => SNDCS_I,
            STE_SNDIR               => SNDIR_I,

            -- RP5C15 real time clock:
            STE_RTCCSn              => RP5C15_CSn,
            STE_RTC_WRn             => RP5C15_WRn,
            STE_RTC_RDn             => RP5C15_RDn,

            -- 6800 peripheral control:
            VPAn                    => VPAn,
            VMAn                    => VMA_68K30Ln,

            DEVn                    => DEVn,
            RAMn                    => RAMn,
            EXT_RAMn                => EXT_RAMn,
            DMAn                    => DMAn,

            -- Interrupt system:
            AVECn                   => AVECn,
            STE_FDINT               => FDINT,
            STE_HDINTn              => HDINTn,
            MFPINTn                 => MFPINTn,
            STE_EINT3n              => '1',
            STE_EINT5n              => '1',
            STE_EINT7n              => '1',
            STE_DINTn               => DINTn,
            IACKn                   => MFP_IACKn,
            STE_IPL2n               => IPLn(2),
            STE_IPL1n               => IPLn(1),
            STE_IPL0n               => IPLn(0),

            -- Video timing:
            BLANKn                  => BLANKn,
            DE                      => DE_I,
            MULTISYNC               => MULTISYNC_I,
            VIDEO_HIMODE            => VIDEO_HIMODE_I,
            HSYNC_INn               => not HSYNC,
            HSYNC_OUTn              => HSYNCn,
            VSYNC_INn               => not VSYNC,
            VSYNC_OUTn              => VSYNCn,
            SYNC_OUT_EN             => SYNC_EN,

            -- Bus arbitration control:
            RDY_INn                 => RDY_DMAn,
            RDY_OUTn                => RDY_GLUEn,
            BRn                     => BR_GLUEn,
            BGIn                    => BG_BLTn,
            -- BGOn                 =>,
            BGACK_INn               => BGACK_BLTn,
            BGACK_OUTn              => BGACK_GLUEn,

            -- Adress and data bus:
            ADDRESS                 => ADR_I,
            DATA_IN                 => DATA_I(15 downto 8),
            DATA_OUT                => DATA_OUT_GLUE,
            DATA_EN                 => DATA_EN_GLUE,

            -- Asynchronous bus control:
            RWn_IN                  => RWn,
            RWn_OUT                 => RWn_OUT_GLUE,
            AS_INn                  => ASn,
            AS_OUTn                 => AS_OUT_GLUEn,
            UDS_INn                 => UDSn,
            UDS_OUTn                => UDS_OUT_GLUEn,
            LDS_INn                 => LDSn,
            LDS_OUTn                => LDS_OUT_GLUEn,
            DTACK_INn               => DTACK_INn,
            DTACK_OUTn              => DTACK_OUT_GLUEn,
            CTRL_EN                 => BUSCTRL_EN_GLUE,

            -- System control:
            RESETn                  => RESET_INn,
            BERRn                   => BERRn,

            -- Processor function codes:
            FC_IN                   => FC,
            FC_OUT                  => FC_OUT_GLUE,

            -- STE enhancements:
            -- STE_FDDS             =>,
            -- STE_FCCLK            =>,
            STE_JOY_RHn             => JOY_RHn,
            STE_JOY_RLn             => JOY_RLn,
            --STE_JOY_WL            =>,
            STE_JOY_WEn             => JOY_WEn,
            STE_BUTTONn             => BUTTONn,
            STE_PAD0Xn              => '1',
            STE_PAD0Yn              => '1',
            STE_PAD1Xn              => '1',
            STE_PAD1Yn              => '1',
            -- STE_PADRSTn          =>,
            STE_PENn                => '1',
            --SCCRDn                => not used.
            --SCCWRn                => not used.
            --SCCIACKn              => not used.
            SCCWAITn                => '0' -- Timeout due to no SCC.
            -- STE_CPROGn           =>
            );

    I_MCU: WF25912IP_SD_TOP_BTYPE_SOC
        port map(
            CLK                     => CLK_2,
            SYS_RESET_INn           => RESET_CORE_Sn,
            SYS_RESET_OUTn          => RESET_MCUn,
            RESET_INn               => RESET_INn,

            ASn                     => ASn,
            LDSn                    => LDSn,
            UDSn                    => UDSn,
            RWn                     => RWn,

            ADR                     => MCU_ADR,

            RAMn                    => RAMn,
            DMAn                    => DMAn,
            DEVn                    => DEVn,

            VSYNCn                  => VSYNCn,
            DE                      => DE_I,
            VIDEO_HIMODE            => VIDEO_HIMODE_I,

            DCYCn                   => DCYCn,
            CMPCSn                  => CMPCSn,

            MONOCHROME              => MONOCHROME,

            SREQ                    => SREQ,
            SLOADn                  => SLOADn,
            SINT_TAI                => SINT_TAI,
            SINT_IO7                => SINT_IO7,

            BA                      => RAM_BA,
            MAD                     => RAM_ADR,

            WEn                     => RAM_WEn,

            DQM0H                   => RAM_DQMH,
            DQM0L                   => RAM_DQML,

            RAS0n                   => RAM_RASn,

            CAS0n                   => RAM_CASn,

            RDATn                   => RDATn,
            WDATn                   => WDATn,
            LATCHn                  => LATCHn,

            DTACKn                  => DTACK_OUT_MCUn,

            DATA_IN                 => DATA_I(7 downto 0),
            DATA_OUT                => DATA_OUT_MCU,
            DATA_EN                 => DATA_EN_MCU
        );

    I_DMA: WF25913IP_TOP_SOC
        port map(
            -- system controls:
            RESETn                  => RESET_INn,
            CLK                     => CLK_1,

            FCSn                    => FCSn,
            A1                      => ADR_I(1),
            RWn                     => RWn,
            RDY_INn                 => RDY_GLUEn,
            RDY_OUTn                => RDY_DMAn,
            DATA_IN                 => DATA_I,
            DATA_OUT                => DATA_OUT_DMA,
            DATA_EN                 => DATA_EN_DMA,

            -- ACSI mode selection:
            --DRIVE_SEL       =>,

            -- ACSI section:
            CA2                     => CA2,
            CA1                     => CA1,
            --CA0                   => -- not used.
            CR_Wn                   => CR_Wn,
            CD_IN                   => CD_IN_DMA,
            CD_OUT                  => CD_OUT_DMA,
            --CD_EN                 =>,

            FDCSn                   => FDCSn,
            -- SDCSn                =>,
            -- SCSICSn              =>,
            HDCSn                   => HDCSn,
            FDRQ                    => FDRQ,
            HDRQ                    => HDRQ,
            ACKn                    => HDACKn
        );

    I_FDC: WF1772IP_TOP_SOC
        port map(
            CLK                     => CLK_1,
            RESETn                  => RESET_INn,

            CSn                     => FDCSn,
            RWn                     => CR_Wn,
            A1                      => CA2,
            A0                      => CA1,
            DATA_IN                 => CD_OUT_DMA,
            DATA_OUT                => CD_OUT_FDC,
            DATA_EN                 => CD_EN_FDC,

            RDn                     => FDD_RDn,
            TR00n                   => FDD_TR00n,
            IPn                     => FDD_IPn,
            WPRTn                   => FDD_WPn,
            DDEn                    => '0', -- Fixed to MFM.
            HDTYPE                  => not HALFMOONS_STE(7), -- We use HD disks.
            MO                      => FDD_MO_WDC,
            WG                      => FDD_WG,
            WD                      => FDD_WD,
            STEP                    => FDD_STEP,
            DIRC                    => FDD_DIRC,
            DRQ                     => FDRQ,
            INTRQ                   => FDINT_1772
        );

    JOY_DIS <= '0'; --UMA

    I_DRIVES: WF_SD_DRIVES
        port map(
            RESETn                  => RESET_INn,
            CLK_16MHz               => CLK_1,
            CLK_32MHz               => CLK_2,

            CD_IN                   => CD_OUT_DMA,
            CD_OUT                  => CD_OUT_DRIVES,
            CD_EN                   => CD_EN_DRIVES,
            CR_Wn                   => CR_Wn,
            CA1                     => CA1,

            HDCSn                   => HDCSn,
            HDRQ                    => HDRQ,
            ACKn                    => HDACKn,
            HDINTn                  => HDINTn,

            FDD_MO                  => FDD_MO,
            FDD_WG                  => FDD_WG,
            FDD_WD                  => FDD_WD,
            FDD_STEP                => FDD_STEP,
            FDD_DIRC                => FDD_DIRC,
            FDD_D1SELn              => FDD_D1SELn,
            FDD_D0SELn              => FDD_D0SELn,
            FDD_SDSEL               => FDD_SDSEL,
            FDD_DRIVETYPE           => not HALFMOONS_STE(7), -- We use HD disks.
            FDD_RDn                 => FDD_RDn,
            FDD_TR00n               => FDD_TR00n,
            FDD_IPn                 => FDD_IPn,
            FDD_WPn                 => FDD_WPn,

            JOY_DIS                 => open, --UMA JOY_DIS,
            LED_1                   => LED1_I,
            LED_2                   => LED2_I,

            DRIVES_BSYn             => DRIVES_BSYn,
            SDC_MISO                => MISO,
            SDC_MOSI                => SDC_MOSI,
            SDC_CSn                 => SDC_CSn,
            SDC_SCK                 => SDC_CLK,
            SDC_CDn                 => SDC_CDn,
            SDC_WP                  => SDC_WP,
            SDC_PWRn                => SDC_PWR_In
        );

    I_SHIFTER: WF25914IP_TOP_SOC
        port map(
            CLK                     => CLK_2,
            RESETn                  => RESET_INn,

            SH_A                    => ADR_I(6 downto 1),
            SH_D_IN                 => RAM_DATA,
            SH_D_OUT                => DATA_SHFT,
            SH_DATA_HI_EN           => DATA_EN_HI_SHFT,
            SH_DATA_LO_EN           => DATA_EN_LO_SHFT,
            SH_RWn                  => RWn,
            SH_CSn                  => CMPCSn,

            MULTISYNC               => MULTISYNC_I,
            SH_LOADn                => DCYCn,
            SH_DE                   => DE_I,
            SH_BLANKn               => BLANKn,
            -- CR_1512              =>, -- Not used.
            SH_R                    => CRT_R,
            SH_G                    => CRT_G,
            SH_B                    => CRT_B,
            -- SH_MONO              =>,
            -- SH_CSYNCn            =>, -- Not used.

            SH_SCLK                 => SCLK_6M4,
            SH_FCLK                 => FCLK,
            SH_SLOADn               => SLOADn,
            SH_SREQ                 => SREQ,
            SH_SDATA_L              => SDATA_L_DMA,
            SH_SDATA_R              => SDATA_R_DMA,

            -- SH_MWK               =>,
            -- SH_MWD               =>,
            -- SH_MWEn              =>,

            xFF827E_D               => XFF827D
        );

    I_MFP: WF68901IP_TOP_SOC
        port map(
            -- System control:
            CLK                     => CLK_1,
            RESETn                  => RESET_INn,

            -- Asynchronous bus control:
            DSn                     => LDSn,
            CSn                     => MFP_CS_In,
            RWn                     => RWn,
            DTACKn                  => DTACK_OUT_MFPn,

            -- Data and Adresses:
            RS                      => ADR_I(5 downto 1),
            DATA_IN                 => DATA_I(7 downto 0),
            DATA_OUT                => DATA_OUT_MFP,
            DATA_EN                 => DATA_EN_MFP,
            GPIP_IN(7)              => SINT_IO7,
            GPIP_IN(6)              => '1',
            GPIP_IN(5)              => DINTn,
            GPIP_IN(4)              => IRQ_ACIAn,
            GPIP_IN(3)              => INT_BLTn,
            GPIP_IN(2)              => '1',
            GPIP_IN(1)              => '1',
            GPIP_IN(0)              => '1',
            -- GPIP_OUT             =>, -- Not used; all GPIPs are direction input.
            -- GPIP_EN              =>, -- Not used; all GPIPs are direction input.

            -- Interrupt control:
            IACKn                   => MFP_IACKn,
            IEIn                    => '0',
            -- IEOn                 =>, -- Not used.
            IRQn                    => MFPINTn,

            -- Timers and timer control:
            XTAL1                   => CLK_24576,
            TAI                     => SINT_TAI,
            TBI                     => DE_MSYNC,
            -- TAO                  =>, -- Not used.
            -- TBO                  =>, -- Not used.
            -- TCO                  =>, -- Not used.
            TDO                     => TDO,

            -- Serial I/O control:
            RC                      => CLK_MFP_UART,
            TC                      => CLK_MFP_UART,
            SI                      => '1'
            -- SO                   =>,
            -- SO_EN                =>

            -- DMA control:
            -- RRn                  =>, -- Not used.
            -- TRn                  => -- Not used.
        );

    I_SOUND: WF2149IP_DIGOUT_TOP_SOC
        port map(
            SYS_CLK                 => CLK_1,
            RESETn                  => RESET_INn,

            WAV_CLK                 => CLK_2M0,
            SELn                    => '1',

            BDIR                    => SNDIR_I,
            BC2                     => '1',
            BC1                     => SNDCS_I,

            A9n                     => '0',
            A8                      => '1',
            DA_IN                   => DATA_I(15 downto 8),
            DA_OUT                  => DATA_OUT_SOUND,
            DA_EN                   => DATA_EN_SOUND,

            IO_A_IN                 => x"00", -- All port pins are dedicated outputs.
            -- IO_A_OUT(7)          =>, -- Not used so far.
            -- IO_A_OUT(6)          =>,
            -- IO_A_OUT(5)          =>,
            -- IO_A_OUT(4)          =>,
            -- IO_A_OUT(3)          =>,
            IO_A_OUT(2)             => FDD_D1SELn,
            IO_A_OUT(1)             => FDD_D0SELn,
            IO_A_OUT(0)             => FDD_SDSEL,
            -- IO_A_EN              =>, -- Not required.
            IO_B_IN                 => x"00", -- Printer port.
            -- IO_B_OUT             =>,
            -- IO_B_EN              =>,

            OUT_ALL                 => SDATA_YM
        );

    I_ACIA_KEYBOARD: WF6850IP_TOP_SOC
      port map(
            CLK                     => CLK_1,
            RESETn                  => RESET_INn,

            CS2n                    => ADR_I(2),
            CS1                     => '1',
            CS0                     => ACIA_CS,
            E                       => E_I,
            RWn                     => RWn,
            RS                      => ADR_I(1),

            DATA_IN                 => DATA_I(15 downto 8),
            DATA_OUT                => DATA_OUT_ACIA_I,
            DATA_EN                 => DATA_EN_ACIA_I,

            TXCLK                   => CLK_0M5,
            RXCLK                   => CLK_0M5,
            RXDATA                  => KEYB_RxD,
            CTSn                    => '0',
            DCDn                    => '0',

            IRQn                    => IRQ_KEYBDn,
            TXDATA                  => KEYB_TxD_I
            --RTSn                  => -- Not used.
        );

    I_ACIA_MIDI: WF6850IP_TOP_SOC
        port map(
            CLK                 => CLK_1,
            RESETn              => RESET_INn,

            CS2n                => '0',
            CS1                 => ADR_I(2),
            CS0                 => ACIA_CS,
            E                   => E_I,
            RWn                 => RWn,
            RS                  => ADR_I(1),

            DATA_IN             => DATA_I(15 downto 8),
            DATA_OUT            => DATA_OUT_ACIA_II,
            DATA_EN             => DATA_EN_ACIA_II,

            TXCLK               => CLK_0M5,
            RXCLK               => CLK_0M5,
            RXDATA              => '1', --MIDI_IN,
            CTSn                => '0',
            DCDn                => '0',

            IRQn                => IRQ_MIDIn
            --TXDATA            => MIDI_OUT,
            --RTSn              => -- Not used.
        );

    I_RTC5C15: WF5C15_139xIP_TOP
        port map(
            CLK                     => CLK_1,
            RESETn                  => RESET_INn,

            -- The bus interface:
            ADR                     => ADR_I(4 downto 1),
            DATA_IN                 => DATA_I(3 downto 0),
            DATA_OUT                => DATA_OUT_RP5C15,
            DATA_EN                 => DATA_EN_RP5C15,
            CS                      => '1',
            CSn                     => RP5C15_CSn,
            WRn                     => RP5C15_WRn,
            RDn                     => RP5C15_RDn,

            -- The SPI lines:
            SPI_IN                  => DS1392_D,
            SPI_OUT                 => DS1392_OUT,
            SPI_EN                  => DS1392_OUT_EN,
            SPI_SCL                 => DS1392_SCL,
            SPI_CE                  => DS1392_CE
        );

    I_AUDIODAC: WF_AUDIO_DAC
        port map(
            CLK                     => CLK_1, -- 16MHz.
            RESETn                  => RESET_INn,

            FCLK                    => FCLK,

            SDATA_L                 => SDATA_L,
            SDATA_R                 => SDATA_R,
            DAC_SCLK                => DAC_SCLK,
            DAC_SDATA               => DAC_SDATA,
            DAC_SYNCn               => DAC_SYNCn,
            DAC_LDACn               => DAC_LDACn
        );

    I_FLASHBOOT: FLASHBOOT_UMASPI
        port map(
            CLK                     => CLK_1, -- 16MHz.
            PLL_LOCK                => PLL_LOCKS,
            RESET_COREn             => RESET_CORE_Sn,
            RESET_INn               => RESET_Sn,
            RESET_OUTn              => RESET_BOOTn,

            CORETYPE                => CORETYPE,
            VERSION                 => VERSION,

            --JOY                   => -- Currently not used.
            --KEY                   => -- Currently not used.

            --RAMADDR               => -- Currently not used.
            --RAMDATA               => -- Currently not used.

            ROM_CEn                 => ROM_CEn,
            ADR_OUT                 => ADR_OUT_BOOT, -- ADR(24 downto 23) currently not in use (LED1).
            ADR_EN                  => ADR_EN_BOOT,
            DATA_IN                 => DATA_I,
            DATA_OUT                => DATA_OUT_BOOT,
            DATA_EN                 => DATA_EN_BOOT,
            FLASH_RDY               => FLASH_RDY,
            FLASH_RESETn            => FLASH_RESETn,
            FLASH_WEn               => FLASH_WEn,
            FLASH_OEn               => FLASH_OEn,
            FLASH_CEn               => FLASH_CEn,
            SPI_CLK                 => SDC_SPI_CLK,
            SPI_DIN                 => MOSI,
            SPI_DOUT                => SPI_MISO,
            SPI_SSn(2)              => SPI_SS2n,
            SPI_SSn(1)              => SPI_SS1n,
            SPI_SSn(0)              => SPI_SS0n,
            BOOT_ACK                => BOOT_ACK,
            BOOT_REQ                => BOOT_REQ,
            BOOT_LED                => BOOT_LED
        );
end architecture STRUCTURE;
