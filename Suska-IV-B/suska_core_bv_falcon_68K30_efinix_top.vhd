------------------------------------------------------------------------
----                                                                ----
---- Atari Falcon compatible IP Core for the Suska-IV-F board.      ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- This model provides the top level file of a Falcon compatible  ----
---- machine including CPU, Blitter, MCU, DMA, Shifter, GLUE,       ----
---- MFP, SOUND, ACIA and RTC. The CPU in this core is the 68K30.   ----
----                                                                ----
---- This toplevel file targets system hardware which is equipped   ----
---- with a Trion T120 FPGA from Efinix and a 32 bit wide SDRAM     ----
---- organized as 4 banks x 4MBit x 32, 512Mb it total.             ----
----                                                                ----
---- Important Notice concerning the clock system:                  ----
---- The systems of the original Falcon machines uses several       ----
---- clocks which must stand in a fixed relation to each other.     ----
---- This core uses one central system clock of 16MHz. From this    ----
---- clock all required clocks are derived. Each phase locked loop  ----
---- generates several output clocks. Refer to the PLL instances    ----
---- I_SYSCLOCKS and I_AUXCLOCKS for detailed information.          ----
----                                                                ----
---- The phase locked loops are located outside the core fabric of  ----
---- the Trion FPGA. To handle these phase locked loops refer to    ----
---- the interface designer of the development software (Efinity).  ----
----                                                                ----
---- Recommendations for the signal termination:                    ----
----  Some signals should be terminated with a weak pull up         ----
----  resistor (~22K). This feature is optional and can be selected ----
----  in the interface designer of the Efinity IDE. In the entity   ----
----  all signals which are recommended to be wired with sucha      ----
----  termination are marked as 'Use weak pull up.'                 ----
----                                                                ----
---- Falcon machines use half moon switches which select features.  ----
---- In this core the half moons are modelled generic and have the  ----
---- following functionality:                                       ----
---- The bits are low active.                                       ----
----   HALFMOON_I(8)    : '0' = DMA sound off.                      ----
----   HALFMOON_I(7)    : '0' = HD type Floppy.                     ----
----   HALFMOON_I(6)    : '0' = Quad Density Floppy.                ----
----   HALFMOON_I(5)    : reserved.                                 ----
----   HALFMOON_I(4)    : reserved.                                 ----
----   HALFMOON_I(3)    : reserved.                                 ----
----   HALFMOON_I(2)    : reserved.                                 ----
----   HALFMOON_I(1)    : reserved.                                 ----
----                                                                ----
----   HALFMOON_II(8)   : Monitor Type Y1.                          ----
----   HALFMOON_II(7)   : Monitor Type Y0.                          ----
----   HALFMOON_II(6)   : DRAM1.                                    ----
----   HALFMOON_II(5)   : DRAM0.                                    ----
----   HALFMOON_II(4)   : ROM Wait State Setting.                   ----
----   HALFMOON_II(3)   : ROM Wait State Setting.                   ----
----   HALFMOON_II(2)   : 16/32 Bit Video Bus.                      ----
----   HALFMOON_II(1)   : RAM Wait State.                           ----
----                                                                ----
---- $FFFF8006 [R/W] B 76543210  HALFMOONS_II register listing      ----
----                   ||||||||                                     ----
----                   |||||||+- RAM Wait Status                    ----
----                   |||||||   0 =  1 Wait (default)              ----
----                   |||||||   1 =  0 Wait                        ----
----                   ||||||+-- Video Bus Width                    ----
----                   ||||||    0 = 16 Bit                         ----
----                   ||||||    1 = 32 Bit (default)               ----
----                   ||||++--- ROM Wait States                    ----
----                   ||||      00 = Reserved                      ----
----                   ||||      01 =  2 Wait (default)             ----
----                   ||||      10 =  1 Wait                       ----
----                   ||||      11 =  0 Wait                       ----
----                   ||++----- RAM Size                           ----
----                   ||        01 =  4 MB                         ----
----                   ||        10 = 16 MB                         ----
----                   ++------- Monitor-Type                       ----
----                             00 Monochrom                       ----
----                             01 RGB Colour Monitor              ----
----                             10 VGA Colour Monitor              ----
----                             11 Televisio (over Modulator)      ----
----                                                                ----
---- The SLOW_CPU feature is enabled by the CLK_CPU switch. In the  ----
---- original Falcon hardware the CPU clock is switched from 16MHz  ----
---- to 8MHz. In this core we do not use such gated clocks but slow ----
---- down the CPU with waitstates during bus access.                ----
----                                                                ----
---- This core features the SCC serial communication controller.    ----
---- It works in the CLK_16M0 domain. Be aware that the baud rate   ----
---- generator feeds baud rates twice the values of the original    ----
---- Falcon SCC chips which are operated at a clock rate of 8MHz.   ----
----                                                                ----
---- The F hardware has ten configuration switches which provide    ----
---- the following features:                                        ----
---- Config Switch 1 and 2 (1 is leftmost on the F board) are       ----
---- intended to select the connected monitor as follows:           ----
----   "11" : TV via modulator (not supported by the BF board).     ----
----   "10" : We use a VGA monitor.                                 ----
----   "01" : We use a RGB colour monitor.                          ----
----   "00" : We use a monochrome monitor (SM124).                  ----
---- Config Switch 3 to 6 switches 1 from 16 operating system flash ----
---- space. x"0" is the lowest address block and x"F" the highest.  ----
---- The size of each address block is 256k x 16 bit. The selector  ----
---- switches are arranged in binary order. Switch 3 is MSB and     ----
---- switch 6 is LSB.                                               ----
---- Config Switch 7        : ON disables the 68K30 caches.         ----
---- Config Switch 8        : ON disables the 68K30 MMU.            ----
---- Config Switch 9 and 10 : These are the TRION configuration     ----
----                          boot select (CBSEL) switches:         ----
----                          "00" selects this core.               ----
----                          "01" reserved for future use.         ----
----                          "10" reserved for future use.         ----
----                          "11" reserved for future use.         ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2025... Wolfgang Foerster - Inventronik GmbH.      ----
----                                                                ----
---- All rights reserved. No portion of this sourcecode may be      ----
---- reproduced or transmitted in any form by any means, whether    ----
---- by electronic, mechanical, photocopying, recording or          ----
---- otherwise, without my written permission.                      ----
----                                                                ----
------------------------------------------------------------------------
--
-- Revision History
--
-- Revision 2K25A 20250620 WF
--   Initial Release.
--
--   !!! See the header for actual configuration switch settings!!!

library work;
use work.SUSKA_CORE_B_FALCON_PKG.all;
use work.COMBEL_PKG.all; -- Required for RAMWIDTH_TYPE.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity SUSKA_IV_B_FALCON_68K30_TOP is
    generic(CORETYPE                : std_logic_vector(15 downto 0) := x"0730"; -- Core Type is 'Board IV Suska-Falcon-68K30'.
            VERSION                 : std_logic_vector(31 downto 0) := x"20231224"; -- Core version.
            HALFMOONS_I             : std_logic_vector(8 downto 1) := x"BF"; -- Configuration switches.
            HALFMOONS_II            : std_logic_vector(6 downto 1) := "101111"; -- Configuration switches. The upper two significant bits are now CONFIG(1 to 2).
NO_FLOPPY               : boolean := true; -- Set true to disable floppy on SD card otherwise false.
            BUS_WIDTH               : RAMWIDTH_TYPE := L32; -- CPU-RAM data width used. Valid values are L32, W16, B8.
            RAM_16                  : boolean := false; -- For this Falcon core we have 32 wide RAM. So the only choice is 'false'.
            DMA_ACSI_FIFO_DEPTH     : integer := 16; -- Number of registers.
            DMA_REPLAY_FIFO_DEPTH   : integer := 16; -- Number of registers.
            DMA_CAPTURE_FIFO_DEPTH  : integer := 16; -- Number of registers.
            MFP_UART_FIXED_SPEED    : boolean := true; -- Set true to use fixed Speed 38400 baud.
            USB1164_LITTLE_ENDIAN   : boolean := false); 

    port(
        -- System controls:
        RESET_COREn                 : in std_logic; -- FPGA reset.
        RESETn                      : in std_logic; -- System and CPU reset.

        SYSCLK                      : in std_logic; -- System clock.

        CLK_16M0                    : in std_logic; -- PLL provided clock.
        CLK_32M0                    : in std_logic; -- PLL provided clock.
        CLK_2M4576                  : in std_logic; -- PLL provided clock.
        CLK_2M0                     : in std_logic; -- PLL provided clock.
        CLK_24M976                  : in std_logic; -- PLL provided clock.
        CLK_48M0                    : in std_logic; -- PLL provided clock.

        PLL_BR1_LOCKED              : in std_logic; -- PLL provided signal.
        PLL_BR2_LOCKED              : in std_logic; -- PLL provided signal.
        PLL_TR1_LOCKED              : in std_logic; -- PLL provided signal.

        -- Data and address busses:
        DATA_IN                     : in std_logic_vector(15 downto 0); -- Use weak pull up.
        DATA_OUT                    : out std_logic_vector(15 downto 0);
        DATA_EN                     : out std_logic_vector(15 downto 0);
        ADR                         : out std_logic_vector(23 downto 1); -- Use weak pull up.

        -- The RAM interface:
        RAM_CKE                     : out std_logic; -- RAM clock enable.
        RAM_CSn                     : out std_logic; -- RAM chip enable.
        RAM_BA                      : out std_logic_vector(1 downto 0); -- SD-RAM bank select.
        RAM_ADR                     : out std_logic_vector(12 downto 0); -- SD-RAM linear address bus.
        RAM_WEn                     : out std_logic;
        RAM_RASn                    : out std_logic;
        RAM_CASn                    : out std_logic;
        RAM_DQMn                    : out std_logic_vector(3 downto 0); -- SD-RAM output buffer controls.
        RAM_D_IN                    : in std_logic_vector(31 downto 0);
        RAM_D_OUT                   : out std_logic_vector(31 downto 0);
        RAM_D_EN                    : out std_logic_vector(31 downto 0);

        -- Video interface:
        V_R                         : out std_logic_vector(9 downto 0);
        V_G                         : out std_logic_vector(9 downto 0);
        V_B                         : out std_logic_vector(9 downto 0);
        V_HSYNC                     : out std_logic;
        V_VSYNC                     : out std_logic;
        VDAC_CLK                    : out std_logic;

        -- Keyboard:
        KEYB_RxD                    : in std_logic;
        KEYB_TxD                    : out std_logic;

        -- UART:
        MFP_RxD                     : in std_logic;
        MFP_TxD                     : out std_logic;
        SCC_RxD                     : in std_logic;
        SCC_TxD                     : out std_logic;

        -- RTC:
        PCF85363_TS                 : in std_logic;
        PCF85363_SDA_IN             : in std_logic;
        PCF85363_SDA_OUT            : out std_logic;
        PCF85363_SDA_EN             : out std_logic;
        PCF85363_SCL_OUT            : out std_logic;
        PCF85363_SCL_EN             : out std_logic;
        PCF85363_INTn               : in std_logic; -- Use weak pull up.

        -- Flash controls:
        FLASH_RDY                   : in std_logic;
        FLASH_WEn                   : out std_logic;
        FLASH_OEn                   : out std_logic;
        FLASH_CEn                   : out std_logic;
        FLASH_RESETn                : out std_logic;

        -- Audio DAC AD5302:
        DAC_SCLK                    : out std_logic;
        DAC_SYNCn                   : out std_logic;
        DAC_SDATA                   : out std_logic;
        DAC_LDACn                   : out std_logic;

        -- Other system signals:
        LED4                        : out std_logic; -- Indicates power on.
        LED3                        : out std_logic; -- Indicates unlocked PLLs or bootloader.
        LED2                        : out std_logic; -- SD card and Boot loader active...
        LED1                        : out std_logic; -- SD card LED.
        CONFIG                      : in std_logic_vector(1 to 8); -- Configuration switches, use weak pull up.

        -- SD card interface:
        SDC1_MISO                   : in std_logic;
        SDC1_CDn                    : in std_logic; -- Use weak pull up.
        SDC1_WP                     : in std_logic; -- Use weak pull up.
        SDC1_CLK                    : out std_logic;
        SDC1_PWRn                   : out std_logic; -- Power switch.
        SDC1_MOSI                   : out std_logic;
        SDC1_D2                     : out std_logic;
        SDC1_D1                     : out std_logic;
        SDC1_CSn                    : out std_logic;

        -- USB1164 Interface:
        USB1164_DM1_IN              : in std_logic;
        USB1164_DM1_OUT             : out std_logic;
        USB1164_DM1_EN              : out std_logic;
        USB1164_DP1_IN              : in std_logic;
        USB1164_DP1_OUT             : out std_logic;
        USB1164_DP1_EN              : out std_logic;
        USB1164_DM2_IN              : in std_logic;
        USB1164_DM2_OUT             : out std_logic;
        USB1164_DM2_EN              : out std_logic;
        USB1164_DP2_IN              : in std_logic;
        USB1164_DP2_OUT             : out std_logic;
        USB1164_DP2_EN              : out std_logic;
        USB1164_DM3_IN              : in std_logic;
        USB1164_DM3_OUT             : out std_logic;
        USB1164_DM3_EN              : out std_logic;
        USB1164_DP3_IN              : in std_logic;
        USB1164_DP3_OUT             : out std_logic;
        USB1164_DP3_EN              : out std_logic;
        USB1164_PWR1                : out std_logic;
        USB1164_PWR2                : out std_logic;
        USB1164_PWR3                : out std_logic;

        -- Microcontroller interface:
        DRIVES_BSYn                 : buffer std_logic;
        MC_PE2                      : in std_logic; -- For future use.
        MC_PE3                      : in std_logic; -- For future use.
        MC_PE4                      : in std_logic; -- For future use.

        SPI_CLK                     : in std_logic;
        SPI_MOSI                    : in std_logic; -- SD-Drive is master, bootloader is slave.
        SPI_MISO                    : out std_logic; -- SD-Drive is master, bootloader is slave.
        SPI_SSn                     : in std_logic_vector(2 downto 0);

        BOOT_ACK                    : in std_logic;
        BOOT_REQ                    : out std_logic
    );
end entity SUSKA_IV_B_FALCON_68K30_TOP;

architecture STRUCTURE of SUSKA_IV_B_FALCON_68K30_TOP is
signal ACIA_CS                      : std_logic;
signal ADR_EN_BOOT                  : std_logic;
signal ADR_EN_COMBEL                : std_logic;
signal ADR_EN_DMA                   : std_logic;
signal ADR_I                        : std_logic_vector(31 downto 0);
signal ADR_68K30                    : std_logic_vector(31 downto 0);
signal ADR_BOOT                     : std_logic_vector(24 downto 1);
signal ADR_DMA                      : std_logic_vector(31 downto 1);
signal ADR_CMBL                     : std_logic_vector(31 downto 1);
signal ASn                          : std_logic;
signal ASn_CMBL                     : std_logic;
signal AS_68K30n                    : std_logic;
signal AS_DMAn                      : std_logic;
signal AVECn                        : std_logic;
signal BERRn                        : std_logic;
signal BG030n                       : std_logic;
signal BGACKn                       : std_logic;
signal BGACK_CMBLn                  : std_logic;
signal BGACK_DMAn                   : std_logic;
signal BOOT_LED                     : std_logic;
signal BRn                          : std_logic;
signal BR_CMBLn                     : std_logic;
signal BR_DMAn                      : std_logic;
signal BUS_EN_68K30                 : std_logic;
signal BUS_EN_CMBL                  : std_logic;
signal BUTTONn                      : std_logic;
signal CA                           : std_logic_vector(2 downto 0);
signal CD                           : std_logic_vector(7 downto 0);
signal CD_EN_DRIVES                 : std_logic;
signal CD_EN_FDC                    : std_logic;
signal CD_DMA                       : std_logic_vector(7 downto 0);
signal CD_DRIVES                    : std_logic_vector(7 downto 0);
signal CD_FDC                       : std_logic_vector(7 downto 0);
signal CIINn                        : std_logic;
signal CLK_0M5                      : std_logic;
signal CLK_0M5_W                    : std_logic;
signal CLK_3M672                    : std_logic;
signal CLK_38400x16                 : std_logic;
signal CLK_MFP_UART                 : std_logic;
signal CLK_CPU                      : std_logic; -- CPU and FPU.
signal CPUBGn                       : std_logic;
signal CR_Wn                        : std_logic;
signal DATA_EN_68K30                : std_logic;
signal DATA_EN_ACIA_I               : std_logic;
signal DATA_EN_ACIA_II              : std_logic;
signal DATA_EN_BOOT                 : std_logic;
signal DATA_EN_COMBEL               : std_logic;
signal DATA_EN_DMA                  : std_logic;
signal DATA_EN_MFP                  : std_logic;
signal DATA_EN_RTC                  : std_logic;
signal DATA_EN_SCC                  : std_logic;
signal DATA_EN_SOUND                : std_logic;
signal DATA_EN_USB1164              : std_logic;
signal DATA_I                       : std_logic_vector(31 downto 0);
signal DATA_OUT_68K30               : std_logic_vector(31 downto 0);
signal DATA_OUT_VIDEL               : std_logic_vector(31 downto 0);
signal DATA_OUT_ACIA_I              : std_logic_vector(7 downto 0);
signal DATA_OUT_ACIA_II             : std_logic_vector(7 downto 0);
signal DATA_OUT_BOOT                : std_logic_vector(15 downto 0);
signal DATA_OUT_COMBEL              : std_logic_vector(15 downto 0);
signal DATA_OUT_DMA                 : std_logic_vector(15 downto 0);
signal DATA_OUT_MFP                 : std_logic_vector(7 downto 0);
signal DATA_OUT_RTC                 : std_logic_vector(7 downto 0);
signal DATA_OUT_SCC                 : std_logic_vector(7 downto 0);
signal DATA_OUT_SOUND               : std_logic_vector(7 downto 0);
signal DATA_OUT_USB1164             : std_logic_vector(15 downto 0);
signal DE                           : std_logic;
signal FDD_DISKCHNG                 : std_logic;
signal DISKIRQn                     : std_logic;
signal DMA_SOUND_EN                 : std_logic;
signal DOTCK                        : std_logic;
signal DS_68K30n                    : std_logic;
signal DSACK_In                     : std_logic_vector(1 downto 0);
signal DSACKn                       : std_logic_vector(1 downto 0);
signal DTACKn                       : std_logic;
signal DTACK_DMAn                   : std_logic;
signal DTACK_COMBELn                : std_logic;
signal DTACK_MFPn                   : std_logic;
signal E                            : std_logic;
signal EINT5n                       : std_logic;
signal EVENn_ODD                    : std_logic;
signal EXPBGn                       : std_logic;
signal FC                           : std_logic_vector(2 downto 0);
signal FC_68K30                     : std_logic_vector(2 downto 0);
signal FC_CMBL                      : std_logic_vector(2 downto 0);
signal FC_DMA                       : std_logic_vector(2 downto 0);
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
signal HALT_INn                     : std_logic;
signal HDACKn                       : std_logic;
signal HDCSn                        : std_logic;
signal HDINTn                       : std_logic;
signal HDRQ                         : std_logic;
signal HINT                         : std_logic;
signal HSYNC_VIDEL                  : std_logic;
signal IACKn                        : std_logic;
signal IPLn                         : std_logic_vector(2 downto 0);
signal IRQ_ACIAn                    : std_logic;
signal IRQ_KEYBDn                   : std_logic;
signal IRQ_MIDIn                    : std_logic;
signal LED1_I                       : std_logic;
signal LED2_I                       : std_logic;
signal LDS_68K30n                   : std_logic;
signal LDSn_CMBL                    : std_logic;
signal LDSn_DMA                     : std_logic;
signal LDSn                         : std_logic;
signal MFP_CS_In                    : std_logic;
signal MFPINTn                      : std_logic;
signal MIDI_OUT                     : std_logic;
signal PLL_FAULT                    : std_logic;
signal PLL_LOCKS                    : std_logic;
signal R8006n                       : std_logic;
signal RAM_D_EN_VIDEL               : std_logic;
signal RAMn                         : std_logic;
signal RDATn                        : std_logic;
signal RESET_CORE_Sn                : std_logic;
signal RESET_BOOTn                  : std_logic;
signal RESET_EN_68K30               : std_logic;
signal RESET_INn                    : std_logic;
signal RESET_MCUn                   : std_logic;
signal RESET_Sn                     : std_logic;
signal ROM_CEn                      : std_logic;
signal ROM2n                        : std_logic;
signal ROM3n                        : std_logic;
signal ROM4n                        : std_logic;
signal ROM5n                        : std_logic;
signal ROM6n                        : std_logic;
signal RP5C15_CSn                   : std_logic;
signal RTCAS                        : std_logic;
signal RTCCS                        : std_logic;
signal RTCDS                        : std_logic;
signal RWn_68K30                    : std_logic;
signal RWn_CMBL                     : std_logic;
signal RWn_DMA                      : std_logic;
signal RWn                          : std_logic;
signal SCC_RDn                      : std_logic;
signal SCC_WRn                      : std_logic;
signal SCC_IACKn                    : std_logic;
signal SCC_WAITn                    : std_logic;
signal SDMABGn                      : std_logic;
signal SDATA_L                      : std_logic_vector(7 downto 0);
signal SDATA_L_DMA                  : std_logic_vector(7 downto 0);
signal SDATA_R                      : std_logic_vector(7 downto 0);
signal SDATA_R_DMA                  : std_logic_vector(7 downto 0);
signal SDATA_YM                     : std_logic_vector(7 downto 0);
signal SIZE_68K30                   : std_logic_vector(1 downto 0);
signal SIZE_MCU                     : std_logic_vector(1 downto 0);
signal SNDCS_I                      : std_logic;
signal SNDIR_I                      : std_logic;
signal SNDINT                       : std_logic;
signal SOUNDINT                     : std_logic;
signal SYNCn                        : std_logic;
signal TDO                          : std_logic;
signal UDS_68K30n                   : std_logic;
signal UDSn_CMBL                    : std_logic;
signal UDSn_DMA                     : std_logic;
signal UDSn                         : std_logic;
signal USB1164_CSn                  : std_logic;
signal USB_PSW1n                    : std_logic;
signal USB_PSW2n                    : std_logic;
signal USB_PSW3n                    : std_logic;
signal USB1164_DPM1_EN              : std_logic;
signal USB1164_DPM2_EN              : std_logic;
signal USB1164_DPM3_EN              : std_logic;
signal VCS                          : std_logic;
signal VIDEL_WAITSTATE              : std_logic;
signal VINT                         : std_logic;
signal VLDn                         : std_logic;
signal RAMH                         : std_logic;
signal VMAn                         : std_logic;
signal VPAn                         : std_logic;
signal VREQ                         : std_logic;
signal VSYNC_VIDEL                  : std_logic;
signal WDATn                        : std_logic;
signal YM_OUT_A                     : std_logic;
signal YM_OUT_B                     : std_logic;
signal YM_OUT_C                     : std_logic;
begin
    PLL_LOCK_FLT: process
    -- This process provides a filter for the PLL status
    -- information.
    variable TMP : integer range 0 to 31;
    begin
        wait until SYSCLK = '1' and SYSCLK' event;
        if (PLL_BR2_LOCKED = '0' or PLL_BR1_LOCKED = '0' or PLL_TR1_LOCKED = '0') and TMP = 0 then
            PLL_LOCKS <= '0';
            PLL_FAULT <= '1';
        elsif PLL_BR2_LOCKED = '0' or PLL_BR1_LOCKED = '0' or PLL_TR1_LOCKED = '0' then
            TMP := TMP -1;
            PLL_LOCKS <= '1';
            PLL_FAULT <= '0';
        else
            TMP := 31;
            PLL_LOCKS <= '1';
            PLL_FAULT <= '0';
        end if;
    end process PLL_LOCK_FLT;

    P_38400: process
    -- This process provides the 38400x16Hz clock for the MFP-UART
    -- It is derived from a 2.457600MHz PLL clock divided by 4
    variable TMP_38400: std_logic_vector(1 downto 0);
    begin
        wait until CLK_2M4576 = '1' and CLK_2M4576' event;
        TMP_38400 := TMP_38400 + '1';
        CLK_38400x16 <= TMP_38400(1);
    end process P_38400;

    CLK_MFP_UART <= TDO when MFP_UART_FIXED_SPEED = false else CLK_38400x16;

    P_3M672: process
    -- This process provides the 3.6720MHz clock for the SCC.
    -- It is derived from a 25.6MHz PLL clock divided by 7 
    -- which results in a 3.5680 MHz clock.
    variable TMP_3M672: std_logic_vector(2 downto 0);
    begin
        wait until CLK_24M976 = '1' and CLK_24M976' event;
        if TMP_3M672 < "110" then
            TMP_3M672 := TMP_3M672 + '1';
        else
            TMP_3M672 := "000";
        end if;
        
        case TMP_3M672 is
            when "011" | "010" | "001" | "000" => CLK_3M672 <= '0';
            when others => CLK_3M672 <= '1';
        end case;
    end process P_3M672;

    KEY_SCAN: process
    -- Sample the RESETn and the RESET_COREn buttons
    -- about every 5ms. This provides stability against
    -- push button jitter.
    variable SCAN_TIMER    : std_logic_vector(19 downto 0);
    begin
        wait until CLK_16M0 = '1' and CLK_16M0' event;
        if SCAN_TIMER <= x"4E200" then -- 20ms@16MHz.
            SCAN_TIMER := SCAN_TIMER + '1';
        else
            SCAN_TIMER := (others => '0');
            RESET_Sn <= RESETn;
            RESET_CORE_Sn <= RESET_COREn;
        end if;
    end process KEY_SCAN;

    -- Video:
    VDAC_CLK <= DOTCK;
    V_R(1 downto 0) <= "00";
    V_G(1 downto 0) <= "00";
    V_B(1 downto 0) <= "00";

    -- The RESETs are as follows:
    -- RESET_Sn is the user's reset button.
    -- RESET_CORE_Sn is the system's reset button.
    -- RESET_BOOTn is the bootloader's reset during flash load operation.
    -- RESET_MCUn is the memory controller's reset during RAM initialisation.
    -- PLL_LOCKS reset the system when the PLLs do not lock.
    -- RESET_EN_68K30 is the CPU reset output.
    RESET_INn <= RESET_Sn and RESET_BOOTn and not RESET_EN_68K30 and RESET_MCUn and PLL_LOCKS;
    HALT_INn <= '0' when RESET_INn = '0' and RESET_EN_68K30 = '0' else '1';

    ADR_I <= x"FF" & ADR_68K30(23 downto 0) when BUS_EN_68K30 = '1' and ADR_68K30(23 downto 16) = x"FF" and ADR_68K30(31 downto 20) < x"010" else -- Memory map for OS with ALTRAM.
             x"FF" & ADR_68K30(23 downto 0) when BUS_EN_68K30 = '1' and ADR_68K30(31 downto 20) >= x"040" else -- Memory map by sign extension for OS with ALTRAM.
             ADR_68K30 when BUS_EN_68K30 = '1' else -- ALTRAM capable.
             x"FF" & ADR_CMBL(23 downto 1) & '0' when ADR_EN_COMBEL = '1' and ADR_CMBL(31 downto 20) > x"00FE" and ADR_CMBL(31 downto 20) < x"010" else -- Memory map.
             ADR_CMBL(31 downto 1) & '0' when ADR_EN_COMBEL = '1' else
             x"FF" & ADR_DMA(23 downto 1) & '0' when ADR_EN_DMA = '1' and ADR_DMA(31 downto 20) > x"00FE" and ADR_DMA(31 downto 20) < x"010" else -- Memory map.
             x"00" & ADR_DMA(23 downto 1) & '0' when ADR_EN_DMA = '1' else (others => '1');

    ADR <= '0' & ADR_BOOT(22 downto 1) when ADR_EN_BOOT = '1' else
           '0' & CONFIG(3 to 6) & "10" & ADR_I(16 downto 1) when ROM6n = '0' else -- Cartridge space x"FB0000 to FBFFFF" is mapped to Flash space x"4/C_0000 to x5/D_FFFF" (STE).
           '0' & CONFIG(3 to 6) & "11" & ADR_I(16 downto 1) when ROM5n = '0' else -- Cartridge space x"FB0000 to FBFFFF" is mapped to Flash space x"6/E_0000 to x7/F_FFFF" (STE).
           '0' & CONFIG(3 to 6) & "100" & ADR_I(15 downto 1) when ROM4n = '0' else -- Cartridge space x"FA0000 to FAFFFF" is mapped to Flash space x"4/C_0000 to x4/C_FFFF".
           '0' & CONFIG(3 to 6) & "101" & ADR_I(15 downto 1) when ROM3n = '0' else -- Cartridge space x"FB0000 to FBFFFF" is mapped to Flash space x"5/D_0000 to x5/D_FFFF".
           '0' & CONFIG(3 to 6) & ADR_I(18 downto 1); -- Cartridges or ROM space x"E00000" to x"E3FFFF".

    ROM_CEn <= ROM2n and ROM3n and ROM4n and ROM5n and ROM6n; -- The flash contains also ROM cartridge information.

    DATA_OUT <= DATA_OUT_BOOT; -- ROM data.
    DATA_EN <= x"FFFF" when DATA_EN_BOOT = '1' else x"0000";

    -- We have a 32 bit wide data bus:
    DATA_I <= DATA_IN & x"0000" when RESET_BOOTn = '0' else -- This is the Flash to bootloader path.
              DATA_OUT_68K30 when DATA_EN_68K30 = '1' else -- Valid for BUS_WIDTH L32, W16 and B8 (see 68K30 output multiplexer).
              DATA_OUT_COMBEL & x"0000" when DATA_EN_COMBEL = '1' and ADR_I(1) = '0' and WDATn = '0' else -- Hi word (Blitter).
              x"0000" & DATA_OUT_COMBEL when DATA_EN_COMBEL = '1' and WDATn = '0' else -- Lo word (Blitter).
              DATA_OUT_COMBEL & x"0000" when DATA_EN_COMBEL = '1' else -- COMBEL register access is 16 bit wide.
              DATA_OUT_DMA & x"0000" when DATA_EN_DMA = '1' and WDATn = '0' and ADR_I(1) = '0' else -- Hi Word (DMA access).
              x"0000" & DATA_OUT_DMA when DATA_EN_DMA = '1' and WDATn = '0' else -- Lo word (DMA access).
              DATA_OUT_DMA & x"0000" when DATA_EN_DMA = '1' else -- DMA register access is 16 bit wide.
              DATA_OUT_MFP & DATA_OUT_MFP & x"0000" when DATA_EN_MFP = '1' else -- Byte access.
              DATA_OUT_SOUND & DATA_OUT_SOUND & x"0000" when DATA_EN_SOUND = '1' else -- Byte access.
              DATA_OUT_ACIA_I & DATA_OUT_ACIA_I & x"0000" when DATA_EN_ACIA_I = '1' else -- Byte access.
              DATA_OUT_ACIA_II & DATA_OUT_ACIA_II & x"0000" when DATA_EN_ACIA_II = '1' else -- Byte access.
              DATA_OUT_RTC & DATA_OUT_RTC & x"0000" when DATA_EN_RTC = '1' else
              DATA_OUT_SCC & DATA_OUT_SCC & x"0000" when DATA_EN_SCC = '1' else -- Byte access.
              DATA_OUT_USB1164 & x"0000" when DATA_EN_USB1164 = '1' else
              HALFMOONS_I & HALFMOONS_I & x"0000" when BUTTONn = '0' else -- Byte access.
              CONFIG(1 to 2) & HALFMOONS_II & DATA_OUT_COMBEL(7 downto 0) & x"0000" when R8006n = '0' else -- Read Register x"FFFF8006" and x"FFFF8007" word wide.
              DATA_IN & x"0000" when ROM_CEn = '0' else -- This is the Flash data.
              --
              -- The following is the read access from RAM. The data is switched directly to the data bus, when the LATCH is transparent.
              -- Switching the data directly saves one CLK_2 period. The reason is the critical bus timing.
               -- 32 bit CPU access:
              DATA_OUT_VIDEL when RAMn = '0' and BUS_EN_68K30 = '1' and BUS_WIDTH = L32 else
               -- 16 bit CPU access:
              DATA_OUT_VIDEL(31 downto 16) & x"0000" when RAMn = '0' and BUS_EN_68K30 = '1' and BUS_WIDTH = W16 and ADR_I(1 downto 0) < "10" else
              DATA_OUT_VIDEL(15 downto 0) & x"0000" when RAMn = '0' and BUS_EN_68K30 = '1' and BUS_WIDTH = W16 else
               -- 8 bit CPU access:
              DATA_OUT_VIDEL(31 downto 24) & x"000000" when RAMn = '0' and BUS_EN_68K30 = '1' and BUS_WIDTH = B8 and ADR_I(1 downto 0) = "00" else
              DATA_OUT_VIDEL(23 downto 16) & x"000000" when RAMn = '0' and BUS_EN_68K30 = '1' and BUS_WIDTH = B8 and ADR_I(1 downto 0) = "01" else
              DATA_OUT_VIDEL(15 downto 8) & x"000000" when RAMn = '0' and BUS_EN_68K30 = '1' and BUS_WIDTH = B8 and ADR_I(1 downto 0) = "10" else
              DATA_OUT_VIDEL(7 downto 0) & x"000000" when RAMn = '0' and BUS_EN_68K30 = '1' and BUS_WIDTH = B8 else
              --
              -- The following 16 bit wide access is for Blitter, DMA, VIDEO and DMA sound.
              DATA_OUT_VIDEL(31 downto 16) & x"0000" when ADR_I(1) = '0' else
              DATA_OUT_VIDEL(15 downto 0) & x"0000";

    RAM_D_EN <= x"FFFFFFFF" when RAM_D_EN_VIDEL = '1' else x"00000000";

    -- Data strobes:
    UDS_68K30n <= '1' when SIZE_68K30 = "01" and ADR_68K30(0) = '1' else DS_68K30n;
    LDS_68K30n <= '1' when SIZE_68K30 = "01" and ADR_68K30(0) = '0' else DS_68K30n;

    -- Bus controls:
    UDSn <= UDS_68K30n when BUS_EN_68K30 = '1' else
            UDSn_CMBL when BUS_EN_CMBL = '1' else
            UDSn_DMA;

    LDSn <= LDS_68K30n when BUS_EN_68K30 = '1' else
            LDSn_CMBL when BUS_EN_CMBL = '1' else
            LDSn_DMA;

    -- The first condition of ASn is important for the COMBEL's bus error
    -- logic. See process FLASH_WS.
    ASn <= AS_68K30n when BUS_EN_68K30 = '1' else
           ASn_CMBL when BUS_EN_CMBL = '1' else
           AS_DMAn;

    RWn <= RWn_68K30 when BUS_EN_68K30 = '1' else
           RWn_CMBL when BUS_EN_CMBL = '1' else
           RWn_DMA;

    FC <= FC_68K30 when BUS_EN_68K30 = '1' else
          FC_CMBL when BUS_EN_CMBL = '1' else
          FC_DMA;

    SIZE_MCU <= SIZE_68K30 when BUS_EN_68K30 = '1' else "10"; -- CPU has 32 bit RAM access.

    DTACKn <= '1' when RP5C15_CSn = '0' else -- Suppress, no RP5C15.
              '1' when VIDEL_WAITSTATE = '1' else -- Wait for Falcon pallette clock switchover.
              '0' when DTACK_DMAn = '0' or DTACK_COMBELn = '0' else
              '0' when DTACK_MFPn = '0' else '1';

    DSACK_In <= "01" when BUS_WIDTH = B8 and DTACKn = '0' and RAMn = '1' else -- This is peripheral stuff.
                "10" when BUS_WIDTH = B8 and DTACKn = '0' and RAMn = '0' else -- This is RAM access.
                "01" when BUS_WIDTH = W16 and DTACKn = '0' else -- Any access is 16 bit wide.
                "01" when BUS_WIDTH = L32 and DTACKn = '0' and RAMn = '1' else -- This is peripheral stuff.
                "00" when BUS_WIDTH = L32 and DTACKn = '0' and RAMn = '0' else -- This is RAM access.
                "10" when SYNCn = '0' else "11"; -- SYNCn is used for interrupt vectoring.

    -- The memory mapped register addresses will be read during cache filling.
    -- To avoid bus errors we inhibit the cache on a cycle by cycle basis.
    -- In the original Falcon machine this signal is connected to the half moon selector CCHDIS.
    CIINn <= '0' when ADR_I >= x"00F80000" and ADR_I < x"00F80009" else -- This is the USB1164.
             '0' when ADR_I(31 downto 16) = x"FFFF" else '1'; -- Other memory mapped stuff.

    -- Bus arbitration:
    -- PAL U68                          : BGKn
    -- Expansion connector J16 Pin 3    : BGKn
    -- Expansion connector J16 Pin 16   : BRn
    BRn <= BR_CMBLn and BR_DMAn; -- Request.
    BGACKn <= BGACK_CMBLn and BGACK_DMAn; -- Acknowledge.
    -- The BGI-BGO daisy chaining is as follows:
    -- CPU out                          : BG030n
    -- PAL U68 in                       : BG030n
    -- PAL U68 out                      : CPUBGn
    -- Expansion connector J20 Pin 22   : CPUBGn
    -- Expansion connector J20 Pin 20   : EXPBGn
    -- DMA controller in                : EXPBGn
    -- DMA controller out               : SDMABGn
    -- COMBEL in                        : SDMABGn
    -- COMBEL out                       : CMBLBGOn
    -- Expansion connector J16 Pin 15   : CMBLBGOn

    CPUBGn <= BG030n;
    EXPBGn <= CPUBGn;
    -- Expansion J16P15 <= CMBLBGOn;

    -- SD card section:
    SDC1_D2 <= '0';
    SDC1_D1 <= '0';

    USB1164_DM1_EN <= USB1164_DPM1_EN;
    USB1164_DP1_EN <= USB1164_DPM1_EN;
    USB1164_DM2_EN <= USB1164_DPM2_EN;
    USB1164_DP2_EN <= USB1164_DPM2_EN;
    USB1164_DM3_EN <= USB1164_DPM3_EN;
    USB1164_DP3_EN <= USB1164_DPM3_EN;

    USB1164_PWR1 <= not USB_PSW1n;
    USB1164_PWR2 <= not USB_PSW2n;
    USB1164_PWR3 <= not USB_PSW3n;

    P_LED: process
    -- Efinity requires a clock to be connected
    -- at least to one clock input of a flip-flop.
    -- The CLK_2M0 is used synchronously in the
    -- 2149 entity. So we meet here the compiler
    -- requirement.    
    begin
        wait until CLK_2M0 = '1' and CLK_2M0' event;
        LED4 <= '1';
        LED3 <= PLL_FAULT or BOOT_LED;
        LED2 <= LED2_I;
        if ADR_BOOT(24 downto 23) /= "00" then
            LED1 <= '1';
        else 
            LED1 <= LED1_I;
        end if;
    end process P_LED;

    -- ACSI section:
    CD <= CD_FDC when CD_EN_FDC = '1' else
          CD_DRIVES when CD_EN_DRIVES = '1' else (others => '0');

    -- Video section:
    V_HSYNC <= not HSYNC_VIDEL;
    V_VSYNC <= not VSYNC_VIDEL;

    DMA_SOUND: process
    -- This Flip Flop is a shadow of the DMA_SOUND_REG(0)
    -- in the WF25912IP_DMA_SOUND_SD module.
    begin
        wait until CLK_32M0 = '1' and CLK_32M0' event;
        if RESET_INn = '0' then
            DMA_SOUND_EN <= '0';
        elsif ASn = '0' and ADR_I(31 downto 1) & '0' = x"FFFF8900" and LDSn = '0' and RWn = '0' then  -- x"FFFF8901".
            DMA_SOUND_EN <= DATA_I(16);
        end if;
    end process DMA_SOUND;

    SDATA_L_DMA <= x"00"; -- Not in use.
    SDATA_R_DMA <= x"00"; -- Not in use.

    -- Sound Multiplexer:
    SDATA_L <= SDATA_L_DMA when DMA_SOUND_EN = '1' else SDATA_YM;
    SDATA_R <= SDATA_R_DMA when DMA_SOUND_EN = '1' else SDATA_YM;

    IRQ_ACIAn <= IRQ_KEYBDn and IRQ_MIDIn;
    FDINT <= FDINT_1772 when DRIVES_BSYn = '1' else '0'; -- This delay is important during floppy access to the SD card (writeback mode).

    -- This is the floppy drive select feature:
    FDD_MO <= FDD_MO_WDC when NO_FLOPPY = false else '0';

    E_TIMER: process
    -- The E clock is a free running clock with a period of 10 times
    -- the CLK period. The pulse ratio is 4 CLK high and 6 CLK low.
    -- Use a synchronous reset due to FPGA constraints.
    variable TMP : std_logic_vector(3 downto 0);
    begin
        wait until CLK_16M0 = '1' and CLK_16M0' event;
        if RESET_INn = '0' then
            TMP := x"0";
            VMAn <= '1';
            E <= '1';
        elsif TMP < x"9" then
            TMP := TMP + '1';
        else
            TMP := x"0";
        end if;

        -- E logic:
        if TMP = x"0" then
            E <= '1';
        elsif TMP = x"4" then
            E <= '0';
        end if;

        -- VMA logic:
        if VPAn = '0' and TMP >= x"4" then -- Switch, when E is low.
            VMAn <= '0';
        elsif VPAn = '1' then
            VMAn <= '1';
        end if;

        -- SYNCn logic (wait states controlling for the 68K30).
        -- Used for the legacy synchronous bus termination (ACIAs and RTC).
        if VPAn = '0' and VMAn = '0' and TMP = x"2" then -- Adjust E to S6..
            SYNCn <= '0';
        elsif VPAn = '1' then
            SYNCn <= '1';
        end if;
    end process E_TIMER;

    SLOW_CPU: process(CLK_16M0, DSACK_In, CLK_CPU, RAMn, RWn_68K30)
    -- For software compatibility, it is sometimes necessary to
    -- slow down the CPU. This is achieved by a delay of
    -- DSACKn during RAM read access which causes the CPU to
    -- insert waitstates. The switch for this logic is bit 0 of
    -- register x"FFFF8007" (CLK_CPU).
    -- Remark: in the original hardware there are clock switches
    -- between 16MHz and 8MHz. To improve the stability of this
    -- ip core we do not realize such switches but operate the
    -- CPU with a fixed frequency.
    -- Adjust the TMP value for your requirements. The higher
    -- the value, the slower the bus access.
    variable TMP : std_logic_vector(3 downto 0);
    begin
        if CLK_16M0 = '1' and CLK_16M0' event then
            if RAMn = '1' then
                TMP := x"0";
            elsif TMP /= x"9" then
                TMP := TMP + '1';
            end if;
        end if;
        --
        if CLK_CPU = '0' and RAMn = '0' and RWn_68K30 = '1' and TMP /= x"9" then
            DSACKn <= "11"; -- Slow down...
        else
            DSACKn <= DSACK_In; -- Not delayed.
        end if;
    end process SLOW_CPU;

    I_CPU: WF68K30_TOP
    port map(
        CLK                         => CLK_16M0,

        -- Address and data:
        ADR_OUT                     => ADR_68K30,
        DATA_IN                     => DATA_I,
        DATA_OUT                    => DATA_OUT_68K30,
        DATA_EN                     => DATA_EN_68K30,

        -- System control:
        BERRn                       => BERRn,
        RESET_INn                   => RESET_INn,
        RESET_OUT                   => RESET_EN_68K30,
        HALT_INn                    => HALT_INn,
        --HALT_OUTn                   => HALT_68K30n,

        -- Processor status:
        FC_OUT                      => FC_68K30,

        -- Interrupt control:
        AVECn                       => AVECn,
        IPLn                        => IPLn,
        --IPENDn                    =>, -- Not used.

        -- Aynchronous bus control:
        DSACKn                      => DSACKn,
        SIZE                        => SIZE_68K30,
        ASn                         => AS_68K30n,
        RWn                         => RWn_68K30,
        --RMCn                      =>, -- Not used.
        DSn                         => DS_68K30n,
        --ECSn                      =>, -- Not used.
        --OCSn                      =>, -- Not used.
        --DBENn                     =>, -- Not used.
        BUS_EN                      => BUS_EN_68K30,

        -- Synchronous bus control:
        CBACKn                      => '1', -- Not used.
        STERMn                      => '1', -- Not used.
        --CBREQn                    =>, Not used.

        -- Cache and MMU controls:
        CDISn                       => not CONFIG(7),
        CIINn                       => CIINn,
        --CIOUTn                    =>, Not used.
        MMUDISn                     => not CONFIG(8),
        --STATUSn                   =>, Not used.
        --REFILLn                   =>, Not used.

        -- Bus arbitration control:
        BRn                         => BRn,
        BGn                         => BG030n,
        BGACKn                      => BGACKn
    );

    I_COMBEL: COMBEL_TOP
        generic map(RAM_16          => RAM_16)
        port map(
            -- System and core control:
            SYS_RESET_INn           => RESET_CORE_Sn,
            SYS_RESET_OUTn          => RESET_MCUn,
            RESET                   => not RESET_INn,

            CLK_32                  => CLK_32M0,
            CLK_16                  => CLK_16M0,
            CLK_CPU                 => CLK_CPU,
            --CLK_8                 => , Not used.
            --CLK_4                 => , Not used.
            KHz_500                 => CLK_0M5, -- Clock for the MIDI ACIA and the keyboard ACIA (receiver).
            KHz_500W                => CLK_0M5_W,  -- Clock for the transmitter of the keyboard ACIA.

            -- Adress and data bus:
            ADR_IN                  => ADR_I,
            ADR_OUT                 => ADR_CMBL,
            ADR_EN                  => ADR_EN_COMBEL,

            DATA_IN                 => DATA_I(31 downto 16),
            DATA_OUT                => DATA_OUT_COMBEL,
            DATA_EN                 => DATA_EN_COMBEL,

            -- The RAM interface:
            RAM_CKE                 => RAM_CKE,
            RAM_CSn                 => RAM_CSn,
            RAM_BA                  => RAM_BA,
            RAM_ADR                 => RAM_ADR,
            --RAM_ADR_32            => , -- Not used.
            RAM_WEn                 => RAM_WEn,
            RAM_RASn                => RAM_RASn,
            RAM_CASn                => RAM_CASn,
            --RAM_RAS0n             => -- We use 512Mb chips.
            --RAM_CAS0n             => -- We use 512Mb chips.
            --RAM_RAS1n             => -- We use 512Mb chips.
            --RAM_CAS1n             => -- We use 512Mb chips.

            BUS_WIDTH               => BUS_WIDTH,
            RAM_DQMn                => RAM_DQMn,
            SIZE_MCU                => SIZE_MCU,

            -- Bus control:
            RWn_IN                  => RWn,
            RWn_OUT                 => RWn_CMBL,
            ASn_IN                  => ASn,
            ASn_OUT                 => ASn_CMBL,
            UDSn_IN                 => UDSn,
            UDSn_OUT                => UDSn_CMBL,
            LDSn_IN                 => LDSn,
            LDSn_OUT                => LDSn_CMBL,

            RAMn                    => RAMn,
            RAMH                    => RAMH, -- This is the new VIDEL RAM hold signal, formerly LATCHn.

            DTACK_INn               => DTACKn,
            DTACK_OUTn              => DTACK_COMBELn,

            -- 6800 peripheral control:
            VPAn                    => VPAn,
            VMAn                    => VMAn,

            -- Bus status:
            BERRn                   => BERRn,

            -- Processor function codes:
            FC_IN                   => FC,
            FC_OUT                  => FC_CMBL,

            BUS_EN                  => BUS_EN_CMBL,

            -- Bus arbitration control:
            BRn                     => BR_CMBLn,
            BGIn                    => SDMABGn,
            --BGOn                  => -- Not used.
            BGAn                    => BGACK_CMBLn,

            -- Adress decoder stuff:
            -- In original COMBEL ther are only
            -- Pins for ROM2n, ROM3n and ROM4n.
            ROM_6n                  => ROM6n,
            ROM_5n                  => ROM5n,
            ROM_4n                  => ROM4n,
            ROM_3n                  => ROM3n,
            ROM_2n                  => ROM2n,
            -- ROM_1n               =>,
            -- ROM_0n               =>,

            N6850                   => ACIA_CS,
            MFPCSn                  => MFP_CS_In,

            SNDCS                   => SNDCS_I,
            SNDIR                   => SNDIR_I,
            --FPUCS                   => ,
            R8006n                  => R8006n,

            -- Keyboard stuff:
            TOK                     => '1', -- Originally with weak pull up.
            TID                     => '0', -- Not used.

            -- VIDEL control signals:
            VREQ                    => VREQ,
            EVENn_ODD               => EVENn_ODD,
            VCS                     => VCS,
            VLDn                    => VLDn, -- This is the VIDEL video load signal, formerly DCYCn.
            RDATn                   => RDATn,
            WDATn                   => WDATn,

            -- Bus control signal:
            BMODE                   => '0', -- We use 68030 bus timing; '1' is STE bus emulation.

            -- DS1287 real time clock:
            RTCCS                   => RTCCS,
            RTCAS                   => RTCAS,
            RTCDS                   => RTCDS,

            -- RP5C15 real time clock:
            RP5C15_CSn              => RP5C15_CSn,
            --RP5C15_WRn            => ,
            --RP5C15_RDn            => ,

            -- Interrupt system:
            HINT                    => HINT,
            VINT                    => VINT, -- In the Falcon VSYNC is wired here.
            MFPINTn                 => MFPINTn,
            EINT1                   => '0',
            EINT3                   => '0',
            EINT5n                  => EINT5n,
            EINT7n                  => '1',
            --BINTn                 => -- Not used in the original hardware.
            AVECn                   => AVECn,
            IACKn                   => IACKn,
            IPLn                    => IPLn,

            -- IDE interface:
            --IDE_RS0n            => ,
            --IDE_RS1n            => ,
            --IDE_IORDn           => ,
            --IDE_IOWRn           => ,
            --IDE_BYTESWAP        => ,
            --IDE_D_EN_INn        => ,
            --IDE_D_EN_OUTn       => ,

            -- SCC chip:
            SCCRDn                  => SCC_RDn,
            SCCWRn                  => SCC_WRn,
            SCCIACKn                => SCC_IACKn,
            SCCWAITn                => SCC_WAITn,

            -- Joyport:
            --JOY_RHn               => JOY_RHn,
            --JOY_RLn               => JOY_RLn,
            --JOY_WL                => JOY_WL,
            --JOY_WEn               => JOY_WEn,
            BUTTONn                 => BUTTONn,
            PAD0Xn                  => '0', --PAD0Xn
            PAD0Yn                  => '0', --PAD0Yn
            PAD1Xn                  => '0', --PAD1Xn
            PAD1Yn                  => '0', --PAD1Yn
            --PADRSTn               => PADRSTn,

            -- Enhancements:
            USB1160_CSn             => USB1164_CSn
        );

    I_DMA: FDMA_TOP_SOC
        generic map(
            ACSI_FIFO_DEPTH         => DMA_ACSI_FIFO_DEPTH,
            REPLAY_FIFO_DEPTH       => DMA_REPLAY_FIFO_DEPTH,
            CAPTURE_FIFO_DEPTH      => DMA_CAPTURE_FIFO_DEPTH)

        port map(
            RESET                   => not RESET_INn,

            -- Clock system:
            CLK_32M0                => CLK_32M0,
            CLK_16M0                => CLK_16M0,
            SNCLK                   => CLK_24M976, -- Originally 25.175MHz.
            CLK_EXT                 => '0', -- DSP_EXTCLK.

            -- Adress and data bus:
            FC_IN                   => FC,
            FC_OUT                  => FC_DMA,
            ADR_IN                  => ADR_I(31 downto 1),
            ADR_OUT                 => ADR_DMA,
            ADR_EN                  => ADR_EN_DMA,
            DATA_IN                 => DATA_I(31 downto 16),
            DATA_OUT                => DATA_OUT_DMA,
            DATA_EN                 => DATA_EN_DMA,

            -- Bus control signals:
            BMODE                   => '0', -- '0' = 68030 bus master, '1' = 68000 bus master.
            AS_INn                  => ASn,
            AS_OUTn                 => AS_DMAn,
            LDS_INn                 => LDSn,
            LDS_OUTn                => LDSn_DMA,
            UDS_INn                 => UDSn,
            UDS_OUTn                => UDSn_DMA,
            RWn_IN                  => RWn,
            RWn_OUT                 => RWn_DMA,
            DTACK_INn               => DTACKn,
            DTACK_OUTn              => DTACK_DMAn,

            -- Bus arstd_logicration signals:
            BRn                     => BR_DMAn,
            BGIn                    => EXPBGn,
            BGOn                    => SDMABGn,
            BGAn                    => BGACK_DMAn,
            BERRn                   => BERRn,

            -- ACSI bus:
            CA                      => CA,
            CR_Wn                   => CR_Wn,
            --CRn_W                 => -- Not used.
            CD_IN                   => CD,
            CD_OUT                  => CD_DMA,
            --CD_EN                 => -- Not used.

            --DRIVE_SEL             => -- Not used.
            FDCSn                   => FDCSn,
            HDCSn                   => HDCSn,
            --SCSICSn               => -- Not used.
            --SDCSn                 => -- Not used.
            FDRQ                    => FDRQ,
            HDRQ                    => HDRQ,
            ACKn                    => HDACKn,

            -- Floppy disk drive configuration:
            MDET                    => "11", -- Originally with weak pull up. Not used here.
            DISKCHNG                => FDD_DISKCHNG,
            -- MODE                 => -- Not used.
            -- FCCLK                => -- Not used.

            -- External serial output channel:
            --PLYDATA               => DSP_PLYD,
            --PLYCLK                => DSP_PLYC,
            PLYSYNC_IN              => '0', -- DSP_PLYS_IN.
            --PLYSYNC_OUT           => DSP_PLYS_OUT,
            --PLYSYNC_EN            => DSP_PLYS_EN,

            -- External serial input channel:
            RECDATA                 => '0', --DSP_RECD-
            --RECCLK                => DSP_RECC,
            RECSYNC_IN              => '0', --DSP_RECS_IN.
            --RECSYNC_OUT           => DSP_RECS_OUT,
            --RECSYNC_EN            => DSP_RECS_EN,

            -- DSP connector:
            --DSP_SRD               => DSP_SYNCDO, -- DSP receives data.
            --DSP_SCK               => DSP_SYNCC, -- Transmit clockout.
            DSP_STD                 => '0', --DSP_SYNCDI.
            --DSP_PLY_EN            => DSP_PLY_EN, -- Tristate control.
            --DSP_REC_EN            => DSP_REC_EN, -- Tristate control.
            --DSP_SC0               => DSP_SCTRL0, -- Receive clockout.
            DSP_SC1_IN              => '0', -- DSP_SCTRL1_IN.
            --DSP_SC1_OUT           => DSP_SCTRL1_OUT, -- Receive syncout.
            DSP_SC2_IN              => '0', -- DSP_SCTRL2_IN.
            --DSP_SC2_OUT           => DSP_SCTRL2_OUT, -- Transmit syncout.

            -- Falcon audio codec:
            --SCLOCK                => ,
            --ASCLK                 => ,
            --ASSYNC                => ,
            ASDOUT                  => '0', -- Sampled on the rising edge of ASCLK.
            --ASDIN                 => ,

            -- Interrupt signals:
            SCNT                    => SOUNDINT,
            SINT                    => SNDINT,
            HDINTn                  => HDINTn,
            FDINT                   => FDINT,
            DSKIRQn                 => DISKIRQn,

            -- Microwire Interface:
            GPIO_IN => "000"
            --GPIO_OUT              => ,
            --GPIO_EN               => ,
            --UWC                   => DSP_GP(1),
            --UWD                   => DSP_GP(2),
            --UWEn                  => DSP_GP(0)
        );

    I_VIDEO: VIDEL_TOP
        port map(
            -- System and core control:
            RESET                   => not RESET_INn,
            CLK_32M0                => CLK_32M0,
            CLK_25M175              => CLK_24M976, -- Originally 25.175MHz.
            CLK_EXT                 => CLK_16M0, -- External clock (GENLOCK).

            -- System bus:
            ADR                     => ADR_I(11 downto 1),
            DATA_IN                 => DATA_I,
            DATA_OUT                => DATA_OUT_VIDEL,
            --DATA_EN               => -- Not used here.
            WAITSTATE               => VIDEL_WAITSTATE,
            VCS                     => VCS,
            VLDn                    => VLDn,
            VREQ                    => VREQ,
            RWn                     => RWn,

            -- Memory bus:
            RDATn                   => RDATn,
            WDATn                   => WDATn,
            RAMH                    => RAMH,

            MD_IN                   => RAM_D_IN,
            MD_OUT                  => RAM_D_OUT,
            MD_EN                   => RAM_D_EN_VIDEL,

            -- Videl control inputs:
            PEN                     => '0', --PENn

            -- Video section:
            DE                      => DE,
            VSYNC                   => VSYNC_VIDEL,
            --VSYNC_EN              => Not used.
            HSYNC                   => HSYNC_VIDEL,
            --HSYNC_EN              => Not used.
            --CSYNC                 => Not used, originally wired to the video connector.
            --COLOR                 => Not used, originally wired to the video modulator.
            HINT                    => HINT,
            VINT                    => VINT, -- Not used in the Falcon.
            EVENn_ODD               => EVENn_ODD,
            DOTCK                   => DOTCK,
            --MONO                  => Not used, originally wired to the video connector.
            R_OUT                   =>  V_R(9 downto 2),
            G_OUT                   =>  V_G(9 downto 2),
            B_OUT                   =>  V_B(9 downto 2)
        );

    I_ACIA_KEYBOARD: WF6850IP_TOP_SOC
      port map(
            CLK                     => CLK_16M0,
            RESETn                  => RESET_INn,

            CS2n                    => ADR_I(2),
            CS1                     => '1',
            CS0                     => ACIA_CS,
            E                       => E,
            RWn                     => RWn,
            RS                      => ADR_I(1),

            DATA_IN                 => DATA_I(31 downto 24),
            DATA_OUT                => DATA_OUT_ACIA_I,
            DATA_EN                 => DATA_EN_ACIA_I,

            TXCLK                   => CLK_0M5_W,
            RXCLK                   => CLK_0M5,
            RXDATA                  => KEYB_RxD,
            CTSn                    => '0',
            DCDn                    => '0',

            IRQn                    => IRQ_KEYBDn,
            TXDATA                  => KEYB_TxD
            --RTSn                  => -- Not used.
        );

    I_ACIA_MIDI: WF6850IP_TOP_SOC
        port map(
            CLK                     => CLK_16M0,
            RESETn                  => RESET_INn,

            CS2n                    => '0',
            CS1                     => ADR_I(2),
            CS0                     => ACIA_CS,
            E                       => E,
            RWn                     => RWn,
            RS                      => ADR_I(1),

            DATA_IN                 => DATA_I(31 downto 24),
            DATA_OUT                => DATA_OUT_ACIA_II,
            DATA_EN                 => DATA_EN_ACIA_II,

            TXCLK                   => CLK_0M5,
            RXCLK                   => CLK_0M5,
            RXDATA                  => '1', --MIDI_IN, must be '1' otherwise interrupt deadlock.
            CTSn                    => '0',
            DCDn                    => '0',

            IRQn                    => IRQ_MIDIn
            --TXDATA                => MIDI_OUT
            --RTSn                  => -- Not used.
        );

    I_AUDIODAC: WF_AUDIO_DAC
        port map(
            CLK                     => CLK_16M0, -- 16MHz.
            RESETn                  => RESET_INn,

            FCLK                    => CLK_0M5,

            SDATA_L                 => SDATA_L,
            SDATA_R                 => SDATA_R,
            DAC_SCLK                => DAC_SCLK,
            DAC_SDATA               => DAC_SDATA,
            DAC_SYNCn               => DAC_SYNCn,
            DAC_LDACn               => DAC_LDACn
        );

    I_DRIVES: WF_SD_DRIVES
        port map(
            RESETn                  => RESET_INn,
            CLK_16MHz               => CLK_16M0,
            CLK_32MHz               => CLK_32M0,

            CD_IN                   => CD_DMA,
            CD_OUT                  => CD_DRIVES,
            CD_EN                   => CD_EN_DRIVES,
            CR_Wn                   => CR_Wn,
            CA1                     => CA(1),

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
            FDD_DRIVETYPE           => not HALFMOONS_I(7), -- We use HD disks.
            FDD_DISKCHNG            => FDD_DISKCHNG,
            FDD_RDn                 => FDD_RDn,
            FDD_TR00n               => FDD_TR00n,
            FDD_IPn                 => FDD_IPn,
            FDD_WPn                 => FDD_WPn,

            --JOY_DIS               => Not used.
            LED_1                   => LED1_I,
            LED_2                   => LED2_I,

            DRIVES_BSYn             => DRIVES_BSYn,
            SDC_MISO                => SDC1_MISO,
            SDC_MOSI                => SDC1_MOSI,
            SDC_CSn                 => SDC1_CSn,
            SDC_SCK                 => SDC1_CLK,
            SDC_CDn                 => SDC1_CDn,
            SDC_WP                  => SDC1_WP,
            SDC_PWRn                => SDC1_PWRn
        );

    I_FDC: WF1772IP_TOP_SOC
        port map(
            CLK                     => CLK_16M0, -- In the Falcon originally FCCLK.
            RESETn                  => RESET_INn,

            CSn                     => FDCSn,
            RWn                     => CR_Wn,
            A1                      => CA(2),
            A0                      => CA(1),
            DATA_IN                 => CD_DMA,
            DATA_OUT                => CD_FDC,
            DATA_EN                 => CD_EN_FDC,

            RDn                     => FDD_RDn,
            TR00n                   => FDD_TR00n,
            IPn                     => FDD_IPn,
            WPRTn                   => FDD_WPn,
            DDEn                    => '0', -- Fixed to MFM.
            HDTYPE                  => not HALFMOONS_I(7), -- We use HD disks.
            MO                      => FDD_MO_WDC,
            WG                      => FDD_WG,
            WD                      => FDD_WD,
            STEP                    => FDD_STEP,
            DIRC                    => FDD_DIRC,
            DRQ                     => FDRQ,
            INTRQ                   => FDINT_1772
        );

    I_FLASHBOOT: FLASHBOOT_UMASPI
        port map(
            CLK                     => CLK_16M0, -- 16MHz.
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
            ADR_OUT                 => ADR_BOOT, -- ADR(24 downto 23) currently not in use (LED1).
            ADR_EN                  => ADR_EN_BOOT,
            DATA_IN                 => DATA_I(31 downto 16),
            DATA_OUT                => DATA_OUT_BOOT,
            DATA_EN                 => DATA_EN_BOOT,
            FLASH_RDY               => FLASH_RDY,
            FLASH_RESETn            => FLASH_RESETn,
            FLASH_WEn               => FLASH_WEn,
            FLASH_OEn               => FLASH_OEn,
            FLASH_CEn               => FLASH_CEn,
            SPI_CLK                 => SPI_CLK,
            SPI_DIN                 => SPI_MOSI,
            SPI_DOUT                => SPI_MISO,
            SPI_SSn                 => SPI_SSn,
            BOOT_ACK                => BOOT_ACK,
            BOOT_REQ                => BOOT_REQ,
            BOOT_LED                => BOOT_LED
        );

    I_MFP: WF68901IP_TOP_SOC
        port map(
            -- System control:
            CLK                     => CLK_16M0,
            RESETn                  => RESET_INn,

            -- Asynchronous bus control:
            DSn                     => LDSn,
            CSn                     => MFP_CS_In,
            RWn                     => RWn,
            DTACKn                  => DTACK_MFPn,

            -- Data and Adresses:
            RS                      => ADR_I(5 downto 1),
            DATA_IN                 => DATA_I(23 downto 16),
            DATA_OUT                => DATA_OUT_MFP,
            DATA_EN                 => DATA_EN_MFP,
            GPIP_IN(7)              => SNDINT,
            GPIP_IN(6)              => '1', -- Originally RI of the serial interface.
            GPIP_IN(5)              => DISKIRQn,
            GPIP_IN(4)              => IRQ_ACIAn,
            GPIP_IN(3)              => '0', --DSP_EXTINT.
            GPIP_IN(2)              => IRQ_MIDIn,
            GPIP_IN(1)              => '0', -- LPT_ACK-
            GPIP_IN(0)              => '1', -- LPT_BSYn.
            -- GPIP_OUT             =>, -- Not used; all GPIPs are direction input.
            -- GPIP_EN              =>, -- Not used; all GPIPs are direction input.

            -- Interrupt control:
            IACKn                   => IACKn,
            IEIn                    => '0', -- IEI_MFP
            -- IEOn                 =>, -- IEO_MFP
            IRQn                    => MFPINTn,

            -- Timers and timer control:
            XTAL1                   => CLK_2M4576,
            TAI                     => SOUNDINT,
            TBI                     => DE,
            -- TAO                  =>, -- Not used.
            -- TBO                  =>, -- Not used.
            -- TCO                  =>, -- Not used.
            TDO                     => TDO,

            -- Serial I/O control:
            RC                      => CLK_MFP_UART,
            TC                      => CLK_MFP_UART,
            SI                      => MFP_RxD,
            SO                      => MFP_TxD
            -- SO_EN                =>

            -- DMA control:
            -- RRn                  =>, -- Not used.
            -- TRn                  => -- Not used.
        );

    I_RTC_DS1287: RTC1287_85363
        port map(
            CLK                     => CLK_16M0,
            RESET                   => not RESET_INn,

            -- The bus interface:
            RTC_AD_IN               => DATA_I(31 downto 24),
            RTC_D_OUT               => DATA_OUT_RTC,
            RTC_D_EN                => DATA_EN_RTC,
            RTCCS                   => RTCCS,
            RTCAS                   => RTCAS,
            RTCDS                   => RTCDS,
            RTC_RWn                 => RWn,

            -- The SPI signals:
            PCF85363_SDA_IN         => PCF85363_SDA_IN,
            PCF85363_SDA_OUT        => PCF85363_SDA_OUT,
            PCF85363_SDA_EN         => PCF85363_SDA_EN,
            PCF85363_SCL            => PCF85363_SCL_OUT,
            PCF85363_SCL_EN         => PCF85363_SCL_EN,
            PCF85363_CLK            => '0', -- Not used.
            PCF85363_INTn           => PCF85363_INTn,
            PCF85363_TS             => PCF85363_TS
    );

    I_SCC: SCC8530_TOP
    -- The SCC is wired as follows: 
    -- This core use the Falcon wiring.
    --          TT machine          Falcon
    -- TRxCA    LCLK                SCC connector Pin 7
    -- RTxCA    3.672MHz            3.672MHz
    -- TRxCB    BCLK (2.4576MHz)    BCLKA (2.4576MHz)
    -- RTxCB    TCLK                3.672MHz
        port map(
            -- System controls:
            PCLK                    => CLK_16M0,
    
            -- Bus:
            DATA_IN                 => DATA_I(23 downto 16),
            DATA_OUT                => DATA_OUT_SCC,
            DATA_EN                 => DATA_EN_SCC,
    
            -- Bus controls:
            CEn                     => '0',
            RDn                     => SCC_RDn,
            WRn                     => SCC_WRn,
            A_Bn                    => not ADR_I(2),
            D_Cn                    => ADR_I(1),
    
            -- Interrupt:
            INTACKn                 => SCC_IACKn,
            IEI                     => '1',
            --IEO                   => , -- Not used.
            INTn                    => EINT5n,
    
            -- Serial Data:
            RxDA                    => '1', -- SCC_RDA
            --TxDA                  => SCC_TDA
            --TxDA_EN               => -- Not used.
            RxDB                    => SCC_RxD,
            TxDB                    => SCC_TxD,
    
            -- Channel clocks:
            TRxCA_INn               => '1', --SCC_TRXCA,
            --TRxCA_OUTn            => , -- Not used.
            --TRxCA_EN              => , -- Not used.
            RTxCAn                  => CLK_3M672,
            TRxCB_INn               => CLK_2M4576,
            --TRxCB_OUTn            => , -- Not used.
            --TRxCB_EN              => , -- Not used.
            RTxCBn                  => CLK_3M672,
    
            -- Channel controls:
            SYNCA_IN                => '1', --SCC_SYNCA,
            --SYNCA_OUT             => , -- Not used.
            --SYNCA_EN              => , -- Not used.
            Wn_REQAn                => SCC_WAITn,
            --DTRn_REQAn            => SCC_DTRA,
            --RTSAn                 => SCC_RTSA,
            CTSAn                   => '1', --SCC_CTSA,
            DCDAn                   => '1', --SCC_CDA,
            SYNCB_IN                => '1', -- SCC_DSRB
            --SYNCB_OUT             => , -- Not used.
            --SYNCB_EN              => , -- Not used.
            --Wn_REQBn              => , -- Not used.
            --DTRn_REQBn            => SCC_DTRB,
            --RTSBn                 => SCC_RTSB,
            CTSBn                   => '1', -- SCC_CTSB
            DCDBn                   => '1' -- SCC_CDB
        );

    I_SOUND: WF2149IP_DIGOUT_TOP_SOC
        port map(
            SYS_CLK                 => CLK_16M0,
            RESETn                  => RESET_INn,

            WAV_CLK                 => CLK_2M0,
            SELn                    => '1',

            BDIR                    => SNDIR_I,
            BC2                     => '1',
            BC1                     => SNDCS_I,

            A9n                     => '0',
            A8                      => '1',
            DA_IN                   => DATA_I(31 downto 24),
            DA_OUT                  => DATA_OUT_SOUND,
            DA_EN                   => DATA_EN_SOUND,

            IO_A_IN                 => x"00", -- All port pins are dedicated outputs.
            IO_A_OUT(7)             => open, -- IDE_RESET, not used here.
            IO_A_OUT(6)             => open, -- SPKONn.
            IO_A_OUT(5)             => open, --LPT_STRBn.
            IO_A_OUT(4)             => open, --DSP_RES.
            IO_A_OUT(3)             => open, --LPT_SELn.
            IO_A_OUT(2)             => FDD_D1SELn,
            IO_A_OUT(1)             => FDD_D0SELn,
            IO_A_OUT(0)             => FDD_SDSEL,
            -- IO_A_EN              =>, -- Not required.
            IO_B_IN                 => x"00", --LPT_D_IN. -- Printer port.
            --IO_B_OUT              => LPT_D_OUT.
            --IO_B_EN                 => LPT_D_EN_I.

            OUT_ALL                 => SDATA_YM
        );

    I_USB: USB1164_TOP
    generic map (LITTLE_ENDIAN      => USB1164_LITTLE_ENDIAN)
    port map(
        -- System controls:
        CLK_48MHz                   => CLK_48M0,
        RESETn                      => RESET_INn,

        -- Address and data:
        A0                          => ADR_I(2),
        DATA_IN                     => DATA_I(31 downto 16),
        DATA_OUT                    => DATA_OUT_USB1164,
        DATA_EN                     => DATA_EN_USB1164,

        -- Bus controls:
        CSn                         => USB1164_CSn, -- Chip select.
        RDn                         => not RWn, -- Read data.
        WRn                         => RWn, -- Write data.
        EOT                         => '1', -- End of DMA Transfer.
        DACKn                       => '1', -- DMA data acknowledge.
        DREQ                        => open, -- DMA data request.
        INT                         => open, -- Interrupt.

        -- USB host:
        WAKEUP                      => '0', -- Not used: wakeup from suspend.
        --SUSPEND                   => , -- Suspend status.
        -- AOCEN                    => , -- Analog OC enable.
        -- CLKNS                    => , -- Suspend CLK not stop.
        NDP_SEL                     => "10", -- Number of data ports.
        PSW1n                       => USB_PSW1n, -- Power switch.
        PSW2n                       => USB_PSW2n, -- Power switch.
        PSW3n                       => USB_PSW3n, -- Power switch.
        --PSW4n                     => , -- Power switch.
        OC1n                        => '1', -- Overcurrent detection.
        OC2n                        => '1', -- Overcurrent detection.
        OC3n                        => '1', -- Overcurrent detection.
        OC4n                        => '1', -- Overcurrent detection.
        DM1_IN                      => USB1164_DM1_IN,
        DM1_OUT                     => USB1164_DM1_OUT,
        DP1_IN                      => USB1164_DP1_IN,
        DP1_OUT                     => USB1164_DP1_OUT,
        DPM1_EN                     => USB1164_DPM1_EN,
        DM2_IN                      => USB1164_DM2_IN,
        DM2_OUT                     => USB1164_DM2_OUT,
        DP2_IN                      => USB1164_DP2_IN,
        DP2_OUT                     => USB1164_DP2_OUT,
        DPM2_EN                     => USB1164_DPM2_EN,
        DM3_IN                      => USB1164_DM3_IN,
        DM3_OUT                     => USB1164_DM3_OUT,
        DP3_IN                      => USB1164_DP3_IN,
        DP3_OUT                     => USB1164_DP3_OUT,
        DPM3_EN                     => USB1164_DPM3_EN,
        DM4_IN                      => '0',
        --DM4_OUT                   => ,
        DP4_IN                      => '0'
        --DP4_OUT                   => ,
        --DPM4_EN                   => ,
        --DP15K                     =>  -- Switch for 15K pull down resistors
    );
end architecture STRUCTURE;
