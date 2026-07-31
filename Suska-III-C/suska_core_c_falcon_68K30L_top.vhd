------------------------------------------------------------------------
----                                                                ----
---- Atari Falcon compatible IP Core for the Suska-III-C board.    ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- This model provides the top level file of a Falcon compatible  ----
---- machine including CPU, Blitter, MCU, DMA, Shifter, GLUE,       ----
---- MFP, SOUND, ACIA and RTC. The CPU in this core is the 68K30L.  ----
----                                                                ----
---- This toplevel file targets system hardware which is equipped   ----
---- with a Cyclone II FPGA of Altera/Intel and a 16 bit wide SDRAM ----
---- organized as 4 banks x 4MBit x 16, 256Mb it total.             ----
----                                                                ----
---- Important Notice concerning the clock system:                  ----
---- The systems of the original Falcon machines used several       ----
---- clocks which must stand in a fixed relation to each other.     ----
---- This core uses one central system clock of 16MHz. From this    ----
---- clock all required clocks are derived. Each phase locked loop  ----
---- generates several output clocks. Refer to the PLL instances    ----
---- I_SYSCLOCKS and I_AUXCLOCKS for detailed information.          ----
----                                                                ----
---- The phase locked loops are customer / hardware specific        ----
---- components and therefore declared in this top level file.      ----
---- In this way the migration to other FPGA hardware is simple by  ----
---- modifying the top level file to meet the requirements of the   ----
---- selected FPGA.                                                 ----
----                                                                ----
---- Recommendations for the signal termination:                    ----
----  Some signals should be terminated with a weak pull up         ----
----  resistor (~22K). This feature is optional and can be selected ----
----  in the assignment editor of the IDE (Integrated Development   ----
----  Environment). In the entity all signals which are recommended ----
----  to be wired with sucha termination are marked as 'Use weak    ----
----  pull up.'                                                     ----
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
----                   ||||||+-- Video Bus Breite                   ----
----                   ||||||    0 = 16 Bit                         ----
----                   ||||||    1 = 32 Bit (default)               ----
----                   ||||++--- ROM Wait Status                    ----
----                   ||||      00 = Reserviert                    ----
----                   ||||      01 =  2 Wait (default)             ----
----                   ||||      10 =  1 Wait                       ----
----                   ||||      11 =  0 Wait                       ----
----                   ||++----- Größe Hauptspeicherkarte           ----
----                   ||        01 =  4 MB                         ----
----                   ||        10 = 16 MB                         ----
----                   ++------- Monitor-Typ                        ----
----                             00 Monochrom                       ----
----                             01 RGB - Farbmonitor               ----
----                             10 VGA - Farbmonitor               ----
----                             11 Fernseher (über Modulator)      ----
----                                                                ----
---- The SLOW_CPU feature is enabled by the CLK_CPU switch. In the  ----
---- original Falcon hardware the CPU clock is switched from 16MHz  ----
---- to 8MHz. In this core we do not use such gated clocks but slow ----
---- down the CPU with waitstates during bus access.                ----
----                                                                ----
---- The C hardware has six configuration switches which provide    ----
---- the following features:                                        ----
---- Config Switch 1 and 2 (1 is leftmost on the C board) are       ----
---- intended to select the connected monitor as follows:           ----
----   "11" : TV via modulator (not supported by the BF board).     ----
----   "10" : We use a VGA monitor.                                 ----
----   "01" : We use a RGB colour monitor.                          ----
----   "00" : We use a monochrome monitor (SM124).                  ----
----   CONFIG(3): reserved.                                         ----
----   CONFIG(4): reserved.                                         ----
----   CONFIG(5): On = ALTRAM for ALTRAM capable operating systems. ----
----   CONFIG(6): reserved.                                         ----
----                                                                ----
---- Due to hardware restrictions some features of the original     ----
---- Falcon hardware cannot be met as follows:                      ----
----  1. The VIDEL video resolutions which require a high RAM data  ----
----     bandwidth do not work correctly.                           ----
----  2. The video output is a kind of 'noisy' The reason is the    ----
----     VIDEO DAC clock which is derived from the RAM clock and    ----
----     not from the DOTCK.                                        ----
----  2. There is no DSP support.                                   ----
----  3. The audio output is limited to the hardware provided by    ----
----     the Suska-III-C hardware.                                  ----
----                                                                ----
---- This core features the following additions over the original   ----
---- Falcon hardware:                                               ----
----  1. There is the SHADOW of the STBOOK built in.                ----
----     Be aware that the SHADOW is foreseen for the ST(E) mono-   ----
----     chrome video mode.                                         ----
----                                                                ----
---- LCD/USB port signals LDATA and UDATA:                          ----
----   Since Core 2K24A there is a dual use of the LCD port. The    ----
----   selection is at boot time when depending on a VDCLK.         ----
----   When during RESET_COREn the CDCLK Pin is tied to ground, the ----
----   USB interface is switched active otherwise the SHADOW LCD.   ----
----   The LCD/USB Connector is used as follows:                    ----
----   LDATA(3) = USB4_DM                                           ----
----   LDATA(2) = USB2_DM                                           ----
----   LDATA(1) = USB4_DP                                           ----
----   LDATA(0) = USB2_DP                                           ----
----   UDATA(3) = USB3_DM                                           ----
----   UDATA(2) = USB1_DM                                           ----
----   UDATA(1) = USB3_DP                                           ----
----   UDATA(0) = USB1_DP                                           ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2021... Wolfgang Foerster - Inventronik GmbH.      ----
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
--   Initial release.
-- Revision 2K24A 20240620
--   We have now a four port root hub USB controller.
--   Implemented dual use of the LCD port to meet the requirement for a new USB extension board.
-- Revision 2K25A 20250620
--   Several code clean ups.
--
--   !!! See the header for actual configuration switch settings!!!

library work;
use work.SUSKA_CORE_C_FALCON_PKG.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity SUSKA_III_C_FALCON_68K30L_TOP is
    generic(CORETYPE                : std_logic_vector(15 downto 0) := x"0520"; -- Core Type is 'Board C Suska-Falcon-68K30L'.
            VERSION                 : std_logic_vector(31 downto 0) := x"20250620"; -- Core version.
            IDE_BYTESWAP_EN         : boolean := false; -- Select true or false. See file header for more information.
            HALFMOONS_I             : std_logic_vector(8 downto 1) := x"BF"; -- Configuration switches.
            HALFMOONS_II            : std_logic_vector(6 downto 1) := "101111"; -- Configuration switches. The upper two significant bits are now CONFIG(1 to 2).
            NO_FLOPPY               : boolean := false; -- Set true to disable floppy on SD card otherwise false.
            BUS_WIDTH               : RAMWIDTH_TYPE := W16; -- Fixed for the C-Board to W16. Valid values are L32, W16, B8.
            RAM_16                  : boolean := true; -- Set true, if we have a 16 bit RAM data bus, false for 32 bit.
            DMA_ACSI_FIFO_DEPTH     : integer := 16; -- Number of registers.
            DMA_REPLAY_FIFO_DEPTH   : integer := 16; -- Number of registers.
            DMA_CAPTURE_FIFO_DEPTH  : integer := 16; -- Number of registers.
            NO_BFOPS                : boolean := true; -- No bitfield operations if true. This saves 30% of the CPU resources.
            MFP_UART_FIXED_SPEED    : boolean := false; -- Set true to use fixed Speed 38400bd
            USB1160_LITTLE_ENDIAN   : boolean := false); 

    port(
        -- System controls:
        RESET_COREn         : in std_logic; -- FPGA reset.
        RESETn              : inout std_logic; -- System and CPU reset.
        CLK_PLL1            : in std_logic; -- 16 MHz system clock.
        CLK_PLL2            : in std_logic; -- 16 MHz system clock.
        CLK_AUX             : out std_logic; -- Auxiliary clock.

        -- Bus status controls:
        FC                  : inout std_logic_vector(2 downto 0); -- Use weak pull up.
        BERRn               : inout std_logic;
        HALTn               : inout std_logic;

        -- Bus arstd_logicration control:
        BRn                 : in std_logic;
        BGOn                : out std_logic;
        BGACKn              : inout std_logic; -- Open drain.

        -- Asynchronous bus interface:
        DTACKn              : inout std_logic;
        UDSn                : inout std_logic;
        LDSn                : inout std_logic;
        ASn                 : inout std_logic;
        RWn                 : inout std_logic;

        -- Data and address busses:
        DATA                : inout std_logic_vector(15 downto 0); -- Use weak pull up.
        ADR                 : inout std_logic_vector(23 downto 1); -- Use weak pull up.

        -- Synchronous bus interface:
        VPAn                : in std_logic; -- Use weak pull up.
        VMAn                : out std_logic;
        E                   : out std_logic;

        -- OS ROM select lines:
        ROM6n               : out std_logic;
        ROM5n               : out std_logic;
        ROM4n               : out std_logic;
        ROM3n               : out std_logic;
        ROM2n               : buffer std_logic;
        ROM1n               : out std_logic;
        ROM0n               : out std_logic;

        -- The SDRAM interface:
        RAM_CLK             : out std_logic;

        RAM_RAS0n           : out std_logic;
        RAM_CAS0n           : out std_logic;
        RAM_WEn             : out std_logic;
        RAM_RAS1n           : out std_logic;
        RAM_CAS1n           : out std_logic;

        RAM_DQM0H           : out std_logic;
        RAM_DQM0L           : out std_logic;
        RAM_DQM1H           : out std_logic;
        RAM_DQM1L           : out std_logic;
        RAM_ADR             : out std_logic_vector(12 downto 0);
        RAM_BA              : out std_logic_vector(1 downto 0);
        RAM_DATA            : inout std_logic_vector(15 downto 0);

        -- LCD control:
        UDATA               : inout std_logic_vector(3 downto 0);
        LDATA               : inout std_logic_vector(3 downto 0);
        LFS                 : out std_logic; -- Line frame strobe.
        VDCLK               : inout std_logic; -- Video data clock, use weak pull up.
        LLCLK               : out std_logic; -- Line latch clock.

        -- Video interface:
        CRT_PIN3            : in std_logic;
        CRT_PIN4_CLK1       : in std_logic;
        CRT_PIN4_CLK2       : in std_logic;
        CRT_R               : out std_logic_vector(3 downto 0);
        CRT_G               : out std_logic_vector(3 downto 0);
        CRT_B               : out std_logic_vector(3 downto 0);
        CRT_MONO            : out std_logic;
        HSYNC               : inout std_logic;
        VSYNC               : inout std_logic;
        GPO                 : out std_logic;

        -- External interrups:
        AVECn               : in std_logic;
        EINT3n              : in std_logic;
        EINT7n              : in std_logic;

        -- Floppy disk interface:
        FDD_TYPE            : in std_logic; -- '1' for HD-, '0' for DD disks.
        FDD_RDn             : in std_logic;
        FDD_TR00n           : in std_logic;
        FDD_IPn             : in std_logic;
        FDD_WPn             : in std_logic;
        FDD_WGn             : out std_logic; -- Open drain.
        FDD_WDn             : out std_logic; -- Open drain.
        FDD_STEPn           : out std_logic; -- Open drain.
        FDD_DIRCn           : out std_logic; -- Open drain.
        FDD_MOn             : out std_logic; -- Open drain.
        FDD_D1SELn          : out std_logic;
        FDD_D0SELn          : out std_logic;
        FDD_SDSEL           : out std_logic;

        -- The ACSI interface:
        CD                  : inout std_logic_vector(7 downto 0); -- Use weak pull up.
        CA1_OUT             : out std_logic;
        HDCSn               : out std_logic;
        HDRQn               : in std_logic;
        HDACKn              : out std_logic;
        HDINTn              : in std_logic;
        ACSI_RDn            : out std_logic;
        ACSI_WRn            : out std_logic;

        -- The SCSI interface:
        SCSI_RDn            : out std_logic;
        SCSI_WRn            : out std_logic;
        SCSI_IDn            : in std_logic_vector(3 downto 1); -- ID of the initiator.
        SCSI_CTRL_ENn       : out std_logic; -- Tri State control.

        SCSI_D              : inout std_logic_vector(7 downto 0);
        SCSI_DP             : inout std_logic;
        SCSI_BSYn           : inout std_logic;
        SCSI_MSGn           : inout std_logic;
        SCSI_REQn           : inout std_logic;
        SCSI_DCn            : inout std_logic;
        SCSI_IOn            : inout std_logic;
        SCSI_ATNn           : inout std_logic;
        SCSI_RSTn           : inout std_logic;
        SCSI_ACKn           : inout std_logic;
        SCSI_SELn           : inout std_logic;

        -- IDE interface:
        IDE_INTRQ           : in std_logic;
        IDE_IORDY           : in std_logic;
        IDE_CS0n            : out std_logic;
        IDE_CS1n            : out std_logic;
        IDE_IORDn           : out std_logic;
        IDE_IOWRn           : out std_logic;
        IDE_D_EN_INn        : buffer std_logic;
        IDE_D_EN_OUTn       : out std_logic;

        -- Keyboard:
        KEYB_RxD            : in std_logic;
        KEYB_TxD            : out std_logic;

        -- MIDI:
        UART_MIDI_RTSn      : out std_logic; -- Not used in original ST machines.
        UART_MIDI_CTSn      : in std_logic;
        UART_MIDI_DCDn      : in std_logic;
        MIDI_OLR            : out std_logic; -- Open drain.
        MIDI_TLR            : out std_logic; -- Open drain.
        MIDI_IN             : in std_logic;

        -- COM Port:
        COM_RxD             : in std_logic;
        COM_TxD             : out std_logic;
        COM_RI              : in std_logic;
        COM_CTS             : in std_logic;
        COM_DCD             : in std_logic;
        COM_RTS             : out std_logic;
        COM_DTR             : out std_logic;

        -- Printer interface:
        LPT_STRB            : out std_logic;
        LPT_D               : inout std_logic_vector(7 downto 0); -- Use weak pull up.
        LPT_BSY             : in std_logic;

        -- Joystick / Paddles / Lightpen:
        JOY_RHn             : buffer std_logic;
        JOY_RLn             : buffer std_logic;
        JOY_WL              : out std_logic;
        JOY_WEn             : out std_logic;
        BUTTONn             : buffer std_logic;
        PAD0Xn              : in std_logic;
        PAD0Yn              : in std_logic;
        PAD1Xn              : in std_logic;
        PAD1Yn              : in std_logic;
        PADRSTn             : out std_logic;
        PENn                : in std_logic;

        -- DS1392 RTC:
        DS1392_D            : inout std_logic;
        DS1392_SCL          : out std_logic;
        DS1392_CE           : out std_logic;

        -- Flash controls:
        FLASH_RDY           : in std_logic;
        FLASH_ADR_19        : out std_logic;
        FLASH_ADR_18        : out std_logic;
        FLASH_WEn           : out std_logic;
        FLASH_OEn           : out std_logic;
        FLASH_CEn           : out std_logic;

        -- TCP/IP (DP83848C):
        C83848_MDIO         : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_MDC          : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_TxD3         : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_TxD2         : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_TxD1         : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_TxD0         : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_TX_CLK       : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_TX_EN        : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_RxD3         : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_RxD2         : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_RxD1         : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_RxD0         : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_RX_CLK       : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_RX_ER        : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_RX_DV        : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_CRS_DV       : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_COL          : in std_logic; -- Switch to appropriate port mode, if used.
        C83848_INTn         : in std_logic; -- Switch to appropriate port mode, if used.

        -- USB interface (MAX3421):
        C3421_SSn           : in std_logic; -- Switch to appropriate port mode, if used.
        C3421_INT           : in std_logic; -- Switch to appropriate port mode, if used.
        C3421_SCLK          : in std_logic; -- Switch to appropriate port mode, if used.
        C3421_MISO          : in std_logic; -- Switch to appropriate port mode, if used.
        C3421_MOSI          : in std_logic; -- Switch to appropriate port mode, if used.

        xFF827E_D           : out std_logic_vector(7 downto 2); -- D2 is DOTCK.

        -- Microwire and sound:
        FCLK                : out std_logic; -- Frame clock.
        MWK                 : out std_logic;
        MWD                 : out std_logic;
        MWEn                : out std_logic;
        -- The original parallel DACs are replaced by a
        -- serial controlled twin device AD5302:
        DAC_SCLK            : out std_logic;
        DAC_SYNCn           : out std_logic;
        DAC_SDATA           : out std_logic;
        DAC_LDACn           : out std_logic;

        -- Sound:
        SPDIF_IN            : in std_logic;
        YM_OUT_A            : out std_logic;
        YM_OUT_B            : out std_logic;
        YM_OUT_C            : out std_logic;

        -- Audio Codec:
        CODEC_SCLK          : in std_logic;
        CODEC_SDOUT         : out std_logic;
        CODEC_SDIN          : in std_logic;
        CODEC_SSYNC         : out std_logic;

        -- Configuration switch:
        -- Use the FPGA's weak pull up feature or external pull up resistors.
        -- Connect the switches to GND.
        CONFIG              : in std_logic_vector(6 downto 1); -- Configuration switches. Use weak pull up.

        -- System status:
        PLL_FAULT           : out std_logic; -- Indicates unlocked PLLs.
        BOOT_LED            : out std_logic; -- Boot loader active...

        -- SD card microcontroller interface:
        SD_RESET_COREn      : in std_logic;
        SD_RESETn           : in std_logic;
        SD_AVR_CLK          : out std_logic; -- 16MHz.
        SD_AVR_ENn          : in std_logic; -- Use weak pull up.
        SD_SPI_CLK          : in std_logic;
        SD_SPI_MOSI         : in std_logic;
        SD_SPI_MISO         : out std_logic;
        SD_SPI_SSn          : in std_logic_vector(2 downto 0);
        SD_BOOT_ACK         : in std_logic;
        SD_BOOT_REQ         : out std_logic;
        SD_RFU1             : in std_logic; -- Reserved for future use.
        SD_RFU2             : in std_logic; -- Reserved for future use.
        SD_RFU3             : in std_logic; -- Reserved for future use.

        -- Power & system microcontroller interface:
        SYS_SPI_CLK         : in std_logic;
        SYS_SPI_MISO        : out std_logic;
        SYS_SPI_MOSI        : in std_logic;
        SYS_BOOT_ACK        : in std_logic;
        SYS_BOOT_REQ        : out std_logic
    );
end entity SUSKA_III_C_FALCON_68K30L_TOP;

architecture STRUCTURE of SUSKA_III_C_FALCON_68K30L_TOP is
-- Hardware specific components. Use these for a Cyclone II:
component cyclone2_pll_1
    PORT
    (
        areset      : IN STD_LOGIC  := '0';
        clkswitch   : IN STD_LOGIC  := '0';
        inclk0      : IN STD_LOGIC  := '0';
        inclk1      : IN STD_LOGIC  := '0';
        c0          : OUT STD_LOGIC ;
        c1          : OUT STD_LOGIC ;
        c2          : OUT STD_LOGIC ;
        locked      : OUT STD_LOGIC
    );
end component;

component cyclone2_pll_2
    PORT
    (
        areset      : IN STD_LOGIC  := '0';
        inclk0      : IN STD_LOGIC  := '0';
        c0          : OUT STD_LOGIC ;
        c1          : OUT STD_LOGIC ;
        c2          : OUT STD_LOGIC ;
        locked      : OUT STD_LOGIC
    );
end component;
-- End of ardware specific components for a Cyclone II.

type VRAM_TYPE is array(0 to 16383) of std_logic_vector(7 downto 0);
signal VRAM                 : VRAM_TYPE;
signal ACIA_CS              : std_logic;
signal ADR_BOOT             : std_logic_vector(20 downto 1);
signal ADR_EN_BOOT          : std_logic;
signal ADR_68K30L           : std_logic_vector(31 downto 0);
signal ASn_68K30L           : std_logic;
signal ASn_DMA              : std_logic;
signal ADR_COMBEL           : std_logic_vector(31 downto 1);
signal ADR_EN_COMBEL        : std_logic;
signal ADR_EN_DMA           : std_logic;
signal ADR_DMA              : std_logic_vector(31 downto 1);
signal ADR_I                : std_logic_vector(31 downto 0);
signal ASn_CMBL             : std_logic;
signal AVEC_INn             : std_logic;
signal AVECn_CMBL           : std_logic;
signal BERR_CMBLn           : std_logic;
signal BERR_In              : std_logic;
signal BG030n               : std_logic;
signal BGACKn_CMBL          : std_logic;
signal BGACKn_DMA           : std_logic;
signal BGACKn_IN            : std_logic;
signal BOOT_ACK             : std_logic;
signal BOOT_REQ             : std_logic;
signal BOOT_RESET_COREn     : std_logic;
signal BOOT_RESETn          : std_logic;
signal BRn_DMA              : std_logic;
signal BRn_CMBL             : std_logic;
signal BRn_I                : std_logic;
signal BUS_EN_68K30L        : std_logic;
signal BUS_EN_CMBL          : std_logic;
signal CA                   : std_logic_vector(2 downto 0);
signal CLK_16M0             : std_logic;
signal CLK_32M0             : std_logic;
signal CLK_48M0             : std_logic;
signal CLK_2M457600         : std_logic;
signal CLK_2M0              : std_logic;
signal CLK_0M5              : std_logic;
signal CLK_0M5_W            : std_logic;
signal CLK_38400x16         : std_logic;
signal CLK_CPU              : std_logic;
signal CLK_MFP_UART         : std_logic;
signal CLK_PLL_394          : std_logic;
signal CLK_PLL_256          : std_logic;
signal CLK_PLL_16000        : std_logic;
signal CD_EN_5380           : std_logic;
signal CD_EN_FDC            : std_logic;
signal CD_5380              : std_logic_vector(7 downto 0);
signal CD_DMA               : std_logic_vector(7 downto 0);
signal CD_EN_DMA            : std_logic;
signal CD_FDC               : std_logic_vector(7 downto 0);
signal CR_Wn                : std_logic;
signal CRn_W                : std_logic;
signal DE                   : std_logic;
signal DATA_I               : std_logic_vector(15 downto 0);
signal DATA_OUT_68K30L      : std_logic_vector(15 downto 0);
signal DATA_EN_68K30L       : std_logic;
signal DATA_OUT_COMBEL      : std_logic_vector(15 downto 0);
signal DATA_EN_COMBEL       : std_logic;
signal DATA_DMA             : std_logic_vector(15 downto 0);
signal DATA_EN_DMA          : std_logic;
signal DATA_OUT_MFP         : std_logic_vector(7 downto 0);
signal DATA_EN_MFP          : std_logic;
signal DATA_OUT_SOUND       : std_logic_vector(7 downto 0);
signal DATA_EN_SOUND        : std_logic;
signal DATA_OUT_ACIA_I      : std_logic_vector(7 downto 0);
signal DATA_EN_ACIA_I       : std_logic;
signal DATA_OUT_ACIA_II     : std_logic_vector(7 downto 0);
signal DATA_EN_ACIA_II      : std_logic;
signal DATA_OUT_RP5C15      : std_logic_vector(3 downto 0);
signal DATA_EN_RP5C15       : std_logic;
signal DATA_OUT_BOOT        : std_logic_vector(15 downto 0);
signal DATA_EN_BOOT         : std_logic;
signal DATA_OUT_USB1160     : std_logic_vector(15 downto 0);
signal DATA_EN_USB1160      : std_logic;
signal DATA_OUT_VIDEL       : std_logic_vector(15 downto 0);
signal DISKIRQn             : std_logic;
signal DM1_OUT              : std_logic;
signal DP1_OUT              : std_logic;
signal DPM1_EN              : std_logic;
signal DM2_OUT              : std_logic;
signal DP2_OUT              : std_logic;
signal DPM2_EN              : std_logic;
signal DM3_OUT              : std_logic;
signal DP3_OUT              : std_logic;
signal DPM3_EN              : std_logic;
signal DM4_OUT              : std_logic;
signal DP4_OUT              : std_logic;
signal DPM4_EN              : std_logic;
signal R8006n               : std_logic;
signal RAMn                 : std_logic;
signal RAM_DQM              : std_logic_vector(3 downto 0);
signal RAM_D_OUT            : std_logic_vector(15 downto 0);
signal RAM_D_EN             : std_logic;
signal DC_5380              : std_logic_vector(7 downto 0);
signal VCS                  : std_logic;
signal VIDEL_WAITSTATE              : std_logic;
signal VDCLK_OUT            : std_logic;
signal VLDn                 : std_logic;
signal VREQ                 : std_logic;
signal DSn                  : std_logic;
signal DS1392_OUT           : std_logic;
signal DS1392_OUT_EN        : std_logic;
signal DSACK_In             : std_logic_vector(1 downto 0);
signal DSACKn               : std_logic_vector(1 downto 0);
signal DTACKn_CMBL          : std_logic;
signal DTACKn_DMA           : std_logic;
signal DTACKn_MFP           : std_logic;
signal E_I                  : std_logic;
signal EVENn_ODD            : std_logic;
signal FC_68K30L            : std_logic_vector(2 downto 0);
signal FC_CMBL              : std_logic_vector(2 downto 0);
signal FC_DMA               : std_logic_vector(2 downto 0);
signal FDCSn                : std_logic;
signal FDD_WG               : std_logic;
signal FDD_WD               : std_logic;
signal FDD_STEP             : std_logic;
signal FDD_DIRC             : std_logic;
signal FDD_MO               : std_logic;
signal FDINT                : std_logic;
signal FDRQ                 : std_logic;
signal FLASH_RESET_In       : std_logic;
signal FLASH_WAITSTATEn     : std_logic;
signal HALT_68K30Ln         : std_logic;
signal HALT_INn             : std_logic;
signal HDACKn_I             : std_logic;
signal HDCS_In              : std_logic;
signal HDINT_5380           : std_logic;
signal HDRQ_5380            : std_logic;
signal HDINT_INn            : std_logic;
signal HDRQ_IN              : std_logic;
signal HINT                 : std_logic;
signal HSYNC_EN             : std_logic;
signal HSYNC_VIDEL          : std_logic;
signal IDE_BYTESWAP         : std_logic;
signal LCD_USBn             : std_logic;
signal LDATA_OUT            : std_logic_vector(3 downto 0);
signal LDATA_EN             : std_logic_vector(3 downto 0);
signal LPT_D_OUT            : std_logic_vector(7 downto 0);
signal LPT_D_EN             : std_logic;
signal IPLn                 : std_logic_vector(2 downto 0);
signal IRQ_KEYBDn           : std_logic;
signal IRQ_MIDIn            : std_logic;
signal IRQ_ACIAn            : std_logic;
signal RAMH                 : std_logic;
signal LDSn_68K30L          : std_logic;
signal LDSn_CMBL            : std_logic;
signal LDSn_DMA             : std_logic;
signal MFP_CS_In            : std_logic;
signal MFP_IACKn            : std_logic;
signal MFP_SO               : std_logic;
signal MFP_SO_EN            : std_logic;
signal MFPINTn              : std_logic;
signal MIDI_OUT             : std_logic;
signal PLL_ARESET           : std_logic;
signal PLL_LOCKS            : std_logic;
signal PLL1_LOCKED          : std_logic;
signal PLL2_LOCKED          : std_logic;
signal RDATn                : std_logic;
signal RESET_Sn             : std_logic;
signal RESET_CORE_Sn        : std_logic;
signal RESET_INn            : std_logic;
signal RESET_EN_68K30L      : std_logic;
signal RESET_BOOTn          : std_logic;
signal RESET_MCUn           : std_logic;
signal RP5C15_CSn           : std_logic;
signal RP5C15_WRn           : std_logic;
signal RP5C15_RDn           : std_logic;
signal RTCCS_DS1287         : std_logic;
signal RWn_68K30L           : std_logic;
signal RWn_CMBL             : std_logic;
signal RWn_DMA              : std_logic;
signal SCC_RDn              : std_logic;
signal SCC_WRn              : std_logic;
signal SCSI_CTRL_EN         : std_logic;
signal SCSI_D_5380          : std_logic_vector(7 downto 0);
signal SCSI_EN_5380         : std_logic;
signal SCSI_DP_5380         : std_logic;
signal SCSI_DP_EN_5380      : std_logic;
signal SCSI_RSTn_5380       : std_logic;
signal SCSI_RST_EN_5380     : std_logic;
signal SCSI_BSYn_5380       : std_logic;
signal SCSI_BSY_EN_5380     : std_logic;
signal SCSI_SELn_5380       : std_logic;
signal SCSI_SEL_EN_5380     : std_logic;
signal SCSI_ACKn_5380       : std_logic;
signal SCSI_ACK_EN_5380     : std_logic;
signal SCSI_ATNn_5380       : std_logic;
signal SCSI_ATN_EN_5380     : std_logic;
signal SCSI_REQn_5380       : std_logic;
signal SCSI_REQ_EN_5380     : std_logic;
signal SCSI_IOn_5380        : std_logic;
signal SCSI_IO_EN_5380      : std_logic;
signal SCSI_CDn_5380        : std_logic;
signal SCSI_CD_EN_5380      : std_logic;
signal SCSI_MSGn_5380       : std_logic;
signal SCSI_MSG_EN_5380     : std_logic;
signal SHADOW_VRAM_ADR      : std_logic_vector(14 downto 0);
signal SHADOW_VRAM_WRn      : std_logic;
signal SIZE_68K30L          : std_logic_vector(1 downto 0);
signal SIZE_MCU             : std_logic_vector(1 downto 0);
signal SDMABGn              : std_logic;
signal SNDCS_I              : std_logic;
signal SNDIR_I              : std_logic;
signal SNDINT               : std_logic;
signal SOUNDINT             : std_logic;
signal SPI_CLK              : std_logic;
signal SPI_MISO             : std_logic;
signal SPI_MOSI             : std_logic;
signal SYNCn                : std_logic;
signal TDO                  : std_logic;
signal UDATA_OUT            : std_logic_vector(3 downto 0);
signal UDATA_EN             : std_logic_vector(3 downto 0);
signal UDSn_68K30L          : std_logic;
signal UDSn_CMBL            : std_logic;
signal UDSn_DMA             : std_logic;
signal USB1160_CSn          : std_logic;
signal VINT                 : std_logic;
signal VMAn_68K30L          : std_logic;
signal VPA_INn              : std_logic;
signal VRAM_D_IN            : std_logic_vector(7 downto 0);
signal VRAM_D_OUT           : std_logic_vector(7 downto 0);
signal VSYNC_EN             : std_logic;
signal VSYNC_VIDEL          : std_logic;
signal VPAn_CMBL            : std_logic;
signal WDATn                : std_logic;
signal YM_OUT_A4            : std_logic;
signal YM_OUT_A3            : std_logic;
begin
    -- Clock system:
    RAM_CLK <= CLK_32M0; -- Use the MCU clock.
    SD_AVR_CLK <= CLK_PLL_16000;

    KEY_SCAN: process
    -- Sample the RESETn and the RESET_COREn buttons
    -- about every 5ms. This provides stability against
    -- push button jitter.
    variable SCAN_TIMER : std_logic_vector(16 downto 0);
    begin
        wait until CLK_16M0 = '1' and CLK_16M0' event;
        if SCAN_TIMER <= '1' & x"3880" then
            SCAN_TIMER := SCAN_TIMER + '1';
        else
            SCAN_TIMER := (others => '0');
            RESET_Sn <= RESETn;
            RESET_CORE_Sn <= RESET_COREn;
        end if;
    end process KEY_SCAN;

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
            PLL_FAULT <= '1' or not LCD_USBn;
        elsif PLL1_LOCKED = '0' or PLL2_LOCKED = '0' then
            TMP := TMP -1;
            PLL_LOCKS <= '1';
            PLL_FAULT <= '0' or not LCD_USBn;
        else
            TMP := 31;
            PLL_LOCKS <= '1';
            PLL_FAULT <= '0' or not LCD_USBn;
        end if;
    end process PLL_LOCK_FLT;

    -- The RESETs are as follows:
    -- The RESET_CORE_Sn is the system's reset button.
    -- The RESET_Sn is the user reset button.
    -- The RESET_BOOTn is the bootloader's reset during flash load operation.
    -- The RESET_MCUn is the memory controller's reset during RAM initialisation.
    -- PLL_LOCKS reset the system when the PLLs do not lock.
    -- RESET_EN_68K30L is the CPU reset output.
    RESET_INn <= RESET_Sn and RESET_BOOTn and RESET_MCUn and SD_RESETn and PLL_LOCKS;
    RESETn <= '0' when RESET_EN_68K30L = '1' or (FLASH_RESET_In = '0' and SD_AVR_ENn = '1') or RESET_MCUn = '0' or PLL_LOCKS = '0' else 'Z';
    HALT_INn <= '0' when HALTn = '0' or (RESET_INn = '0' and RESET_EN_68K30L = '0') else '1';

    -------------------- Hardware specific components --------------------
    ----                  This is for a Cyclone II                    ----
    ---- The following components instantiate the clock phase locked  ----
    ---- loops and the video ram. These are cyclone specific and thus ----
    ---- an object of change, if other devices are used for this core.----
    ----                                                              ----
    I_SYSCLOCKS: cyclone2_pll_1
        port map(
            areset              => PLL_ARESET,
            clkswitch           => not CRT_PIN3,
            inclk0              => CLK_PLL1, -- 16MHz.
            inclk1              => CRT_PIN4_CLK1,
            --inclk1            => CRT_PIN4_CLK2, -- For system flexibility.
            c0                  => CLK_16M0,
            c1                  => CLK_32M0,
            c2                  => CLK_48M0,
            locked              => PLL1_LOCKED
        );

    I_AUXCLOCKS: cyclone2_pll_2
        port map(
            areset              => PLL_ARESET,
            inclk0              => CLK_PLL2, -- 16MHz.
            c0                  => CLK_PLL_256, -- 25.6MHz.
            c1                  => CLK_PLL_394, -- 39.4MHz.
            c2                  => CLK_PLL_16000, -- 16.0MHz.
            locked              => PLL2_LOCKED
        );
    ----                                                              ----
    ------------------ End hardware specific components ------------------

    P_AUX_CLOCKS: process
    -- The sound wave clock CLK_2M0 is slow and therefore 
    -- not possible to be provided by a PLL.
    -- Therefore this clock divider is adjusted to produce
    -- the required frequency of 2MHz The clock is not used
    -- as a clock for d type flip-flops and therefore allowed
    -- as gated clock.
    variable TMP: std_logic_vector(1 downto 0);
    begin
        wait until CLK_PLL_16000 = '1' and CLK_PLL_16000' event; -- 16MHz.
        TMP := TMP + '1';
        case TMP is
            when "00" =>
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
        CLK_2M457600 <= TMP_2M54(3);
        CLK_38400x16 <= TMP_2M54(5);
    end process P_2M4576;

    CLK_MFP_UART <= TDO when MFP_UART_FIXED_SPEED = false else CLK_38400x16;
    CLK_AUX <= CLK_PLL_256;

    DATA <= DATA_OUT_BOOT when DATA_EN_BOOT = '1' else
            DATA_I when DATA_EN_68K30L = '1' or DATA_EN_COMBEL = '1' else (others => 'Z');

    DATA_I <= DATA when RESET_BOOTn = '0' else -- This is the Flash to bootloader path.
              DATA_OUT_68K30L(7 downto 0) & DATA_OUT_68K30L(15 downto 8) when DATA_EN_68K30L = '1' and IDE_BYTESWAP = '1' and IDE_BYTESWAP_EN = true else
              DATA_OUT_68K30L when DATA_EN_68K30L = '1' else
              DATA_OUT_COMBEL when DATA_EN_COMBEL = '1' else
              DATA_DMA when DATA_EN_DMA = '1' else
              DATA_OUT_MFP & DATA_OUT_MFP when DATA_EN_MFP = '1' else --UMA
              DATA_OUT_SOUND & DATA_OUT_SOUND when DATA_EN_SOUND = '1' else
              DATA_OUT_ACIA_I & DATA_OUT_ACIA_I when DATA_EN_ACIA_I = '1' else
              DATA_OUT_ACIA_II & DATA_OUT_ACIA_II when DATA_EN_ACIA_II = '1' else
              x"F" & DATA_OUT_RP5C15 & x"F" & DATA_OUT_RP5C15 when DATA_EN_RP5C15 = '1' else
              DATA(7 downto 0) & DATA(15 downto 8) when IDE_D_EN_INn = '0' and IDE_BYTESWAP = '1' and IDE_BYTESWAP_EN = true else
              DATA when IDE_D_EN_INn = '0' else
              DATA when BUTTONn = '0' else
              DATA_OUT_USB1160 when DATA_EN_USB1160 = '1' else
              DATA when JOY_RHn = '0' and JOY_RLn = '0'  else
              x"FF" & DATA(7 downto 0) when JOY_RLn = '0' else
              DATA(15 downto 8) & x"FF" when JOY_RHn = '0'else
              HALFMOONS_I & HALFMOONS_I when BUTTONn = '0' else -- Byte access.
              not CONFIG(1) & not CONFIG(2) & HALFMOONS_II & DATA_OUT_COMBEL(7 downto 0) when R8006n = '0' else -- Read Register x"FFFF8006" and x"FFFF8007" word wide.
              DATA when ROM2n = '0' else -- This is the Flash operating system data.
              DATA_OUT_VIDEL;

    RAM_DATA <= RAM_D_OUT when RAM_D_EN = '1' else (others => 'Z'); -- 16 Bit.

    RAM_DQM1H <= RAM_DQM(3) and RAM_DQM(1);
    RAM_DQM1L <= RAM_DQM(2) and RAM_DQM(0);
    RAM_DQM0H <= RAM_DQM(3) and RAM_DQM(1);
    RAM_DQM0L <= RAM_DQM(2) and RAM_DQM(0);

    ADR_I <= x"FF" & ADR_68K30L(23 downto 0) when BUS_EN_68K30L = '1' and ADR_68K30L(23 downto 16) = x"FF" and CONFIG(5) = '1' else -- Memory map for operating systems non ALTRAM cabaple.
             x"00" & ADR_68K30L(23 downto 0) when BUS_EN_68K30L = '1' and CONFIG(5) = '1' else -- Non ALTRAM support.
             x"FF" & ADR_68K30L(23 downto 0) when BUS_EN_68K30L = '1' and ADR_68K30L(31 downto 16) = x"00FF" and CONFIG(5) = '0' else -- Memory map for OS with ALTRAM.
             x"00" & ADR_68K30L(23 downto 0) when BUS_EN_68K30L = '1' and ADR_68K30L(31 downto 16) = x"FFF0" and CONFIG(5) = '0' else -- Memory map IDE for OS with ALTRAM.
             x"00" & ADR_68K30L(23 downto 0) when BUS_EN_68K30L = '1' and CONFIG(5) = '1' else -- Non ALTRAM support.
             ADR_68K30L when BUS_EN_68K30L = '1' else -- ALTRAM capable.
             x"FF" & ADR_COMBEL(23 downto 1) & '0' when ADR_EN_COMBEL = '1' and ADR_COMBEL(31 downto 16) > x"00FE" and ADR_COMBEL(31 downto 20) < x"010" else -- Memory map.
             ADR_COMBEL(31 downto 1) & '0' when ADR_EN_COMBEL = '1' else
             x"FF" & ADR_DMA(23 downto 1) & '0' when ADR_EN_DMA = '1' and ADR_DMA(31 downto 16) > x"00FE" and ADR_DMA(31 downto 20) < x"010" else -- Memory map.
             x"00" & ADR_DMA(23 downto 1) & '0' when ADR_EN_DMA = '1' else (others => '1');

    ADR <= "000" & ADR_BOOT when ADR_EN_BOOT = '1' else
           ADR_68K30L(23 downto 1) when BUS_EN_68K30L = '1' else
           ADR_COMBEL(23 downto 1) when ADR_EN_COMBEL = '1' else (others => 'Z');

    FLASH_ADR_19 <= ADR_BOOT(19) when ADR_EN_BOOT = '1' else
                    ADR_68K30L(19) when BUS_EN_68K30L = '1' else
                    ADR_COMBEL(19) when ADR_EN_COMBEL = '1' else '1';

    FLASH_ADR_18 <= ADR_BOOT(18) when ADR_EN_BOOT = '1' else
                    ADR_68K30L(18) when BUS_EN_68K30L = '1' else
                    ADR_COMBEL(18) when ADR_EN_COMBEL = '1' else '1';

    -- Serial port:
    COM_TxD <= MFP_SO when MFP_SO_EN = '1' else 'Z';
    COM_DTR <= not YM_OUT_A4;
    COM_RTS <= not YM_OUT_A3;

    -- Line printer port.
    LPT_D <= LPT_D_OUT when LPT_D_EN = '1' else (others => 'Z');

    -- DMA and ACSI/SCSI/SD section:
    CD <= CD_DMA when CD_EN_DMA = '1' else -- DMA controller.
          CD_FDC when CD_EN_FDC = '1' else -- Floppy disk controller.
          CD_5380 when CD_EN_5380 = '1' else (others => 'Z'); -- 5380 SCSI controller.

    HDCSn <= HDCS_In;
    HDACKn <= HDACKn_I;

    CA1_OUT <= CA(1);

    ACSI_WRn <= CR_Wn;
    ACSI_RDn <= not CR_Wn;

    SCSI_CTRL_EN <= SCSI_DP_EN_5380 or SCSI_ACK_EN_5380 or SCSI_SEL_EN_5380 or SCSI_ATN_EN_5380;
    SCSI_CTRL_ENn <= not SCSI_CTRL_EN;

    SCSI_RDn <= '0' when SCSI_IOn_5380 = '0' and SCSI_IO_EN_5380 = '1' else -- driven from the 5380.
                '0' when SCSI_IOn = '0' else '1'; -- Target to Initiator (Atari) (IOn = '0').
    SCSI_WRn <= '0' when SCSI_IOn_5380 = '1' and SCSI_IO_EN_5380 = '1' else -- driven from the 5380.
                '0' when SCSI_IOn = '1' else '1'; -- Initiator (Atari) to target (IOn = '1').

    SCSI_D <= SCSI_D_5380 when SCSI_EN_5380 = '1' else (others => 'Z');
    SCSI_DP <= SCSI_DP_5380 when SCSI_DP_EN_5380 = '1' else 'Z';

    SCSI_RSTn <= SCSI_RSTn_5380 when SCSI_RST_EN_5380 = '1' else 'Z';
    SCSI_SELn <= SCSI_SELn_5380 when SCSI_SEL_EN_5380 = '1' else 'Z';
    SCSI_ACKn <= SCSI_ACKn_5380 when SCSI_ACK_EN_5380 = '1' else 'Z';
    SCSI_BSYn <= SCSI_BSYn_5380 when SCSI_BSY_EN_5380 = '1' else 'Z';
    SCSI_ATNn <= SCSI_ATNn_5380 when SCSI_ATN_EN_5380 = '1' else 'Z';
    SCSI_REQn <= SCSI_REQn_5380 when SCSI_REQ_EN_5380 = '1' else 'Z';
    SCSI_IOn <= SCSI_IOn_5380 when SCSI_IO_EN_5380 = '1' else 'Z';
    SCSI_DCn <= SCSI_CDn_5380 when SCSI_CD_EN_5380 = '1' else 'Z';
    SCSI_MSGn <= SCSI_MSGn_5380 when SCSI_MSG_EN_5380 = '1' else 'Z';

    -- Floppy Tri-States:
    FDD_WGn <= '0' when FDD_WG = '1' else 'Z';
    FDD_WDn <= '0' when FDD_WD = '1' else 'Z';
    FDD_STEPn <= '0' when FDD_STEP = '1' else 'Z';
    FDD_DIRCn <= '0' when FDD_DIRC = '1' else 'Z';
    FDD_MOn <= '0' when FDD_MO = '1' and NO_FLOPPY = false else 'Z';

    HDRQ_IN <= '1' when HDRQn = '0' or HDRQ_5380 = '1' else '0';
    HDINT_INn <= HDINTn and not IDE_INTRQ and not HDINT_5380;

    -- MIDI interface:
    MIDI_OLR <= '0' when MIDI_OUT = '0' else 'Z';
    MIDI_TLR <= '0' when MIDI_IN = '0' else 'Z';

    -- Bus controls:
    BERR_In <= BERRn;
    BERRn <= '0' when BERR_CMBLn = '0' else 'Z';

    HALTn <= '0' when HALT_68K30Ln = '0' else 'Z';

    DTACKn <= '1' when RTCCS_DS1287 = '1' else -- Suppress, we have no DS1287.
              '1' when VIDEL_WAITSTATE = '1' else -- Wait for Falcon pallette clock switchover.
              '1' when SCC_RDn = '0' or SCC_WRn = '0' else -- Suppress, we have no SCC.
              '0' when DTACKn_CMBL = '0' or DTACKn_MFP = '0' or DTACKn_DMA = '0' else 'Z';

    UDSn <= UDSn_68K30L when BUS_EN_68K30L = '1' else
            UDSn_CMBL when BUS_EN_CMBL = '1' else
            UDSn_DMA when DATA_EN_DMA = '1' else 'Z';

    LDSn <= LDSn_68K30L when BUS_EN_68K30L = '1' else
            LDSn_CMBL when BUS_EN_CMBL = '1' else
            LDSn_DMA when DATA_EN_DMA = '1' else 'Z';

     -- The first condition of ASn is important for system
     -- startup. See process FLASH_WS.
    ASn <=  '1' when FLASH_WAITSTATEn = '0' else
            ASn_68K30L when BUS_EN_68K30L = '1' else
            ASn_CMBL when BUS_EN_CMBL = '1' else 
            ASn_DMA when DATA_EN_DMA = '1' else 'Z';

    RWn <=  RWn_68K30L when BUS_EN_68K30L = '1' else
            RWn_CMBL when BUS_EN_CMBL = '1' else
            RWn_DMA when DATA_EN_DMA = '1' else 'Z';

    FC <=   FC_68K30L when BUS_EN_68K30L = '1' else
            FC_CMBL when BUS_EN_CMBL = '1' else
            FC_DMA when DATA_EN_DMA = '1' else "ZZZ";

    FLASH_WS: process (RESETn, CLK_16M0)
    -- This process provides a delay of seven clock cycles after the
    -- release of the RESETn. This is important for Suska-III-C because
    -- of the flash memory which is also resetted by the RESETn and is
    -- ready to be read at a minimum of 200ns after the release of RESETn.
    -- Without this logic, the CPU reads too fast from the flash memory
    -- when it releases a RESET_MCUn by itself.
    variable TMP: std_logic_vector(2 downto 0);
    begin
        if RESETn = '0' then
            TMP := "000";
            FLASH_WAITSTATEn <= '0';
        elsif CLK_16M0 = '1' and CLK_16M0' event then
            if TMP < "111" then
                TMP := TMP + '1';
                FLASH_WAITSTATEn <= '0';
            else
                FLASH_WAITSTATEn <= '1';
            end if;
        end if;
    end process FLASH_WS;

    VPA_INn <= '0' when VPAn_CMBL = '0' or VPAn = '0' else '1';
    VMAn <=  VMAn_68K30L when BUS_EN_68K30L = '1' else 'Z';

    -- Bus arbitration:
    -- PAL U68                          : BGKn
    -- Expansion connector J16 Pin 3    : BGKn
    -- Expansion connector J16 Pin 16   : BRn
    BRn_I <= BRn_CMBL and BRn_DMA and BRn; -- Request.
    BGACKn_IN <= BGACKn_CMBL and BGACKn_DMA and BGACKn; -- Acknowledge.
    BGACKn <= '0' when BGACKn_CMBL = '0' else 'Z';
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

    -- Video section:
    HSYNC <= not HSYNC_VIDEL when HSYNC_EN = '1' else 'Z'; -- We use external inverters.
    VSYNC <= not VSYNC_VIDEL when VSYNC_EN = '1' else 'Z'; -- We use external inverters.

    -- Interrupt stuff:
    AVEC_INn <= AVECn and AVECn_CMBL; -- One Low active signal is sufficient.
    IRQ_ACIAn <= IRQ_KEYBDn and IRQ_MIDIn;

    -- DS1392 RTC interface:
    DS1392_D <= '1' when DS1392_OUT = '1' and DS1392_OUT_EN = '1' else
                '0' when DS1392_OUT = '0' and DS1392_OUT_EN = '1' else 'Z';

    -- Data strobes:
    UDSn_68K30L <= '1' when SIZE_68K30L = "01" and ADR_68K30L(0) = '1' else DSn;
    LDSn_68K30L <= '1' when SIZE_68K30L = "01" and ADR_68K30L(0) = '0' else DSn;

    SIZE_MCU <= SIZE_68K30L when BUS_EN_68K30L = '1' else "10"; -- CPU has 32 bit RAM access.

    -- Synchronous bus timing:
    DSACK_In <= "01" when  DTACKn = '0' else -- Bus access is 16 bit wide.
                "10" when SYNCn = '0' else "11"; -- SYNCn is used for interrupt vectoring.

    xFF827E_D(7 downto 3) <= "00000"; -- Not used.

    E_TIMER: process
    -- The E clock is a free running clock with a period of 10 times
    -- the CLK period. The pulse ratio is 4 CLK high and 6 CLK low.
    -- Use a synchronous reset due to FPGA constraints.
    variable TMP : std_logic_vector(3 downto 0);
    begin
        wait until CLK_16M0 = '1' and CLK_16M0' event;
        if RESET_INn = '0' then
            TMP := x"0";
            VMAn_68K30L <= '1';
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
        if VPA_INn = '0' and TMP >= x"4" then -- Switch, when E is low.
            VMAn_68K30L <= '0';
        elsif VPA_INn = '1' then
            VMAn_68K30L <= '1';
        end if;
		  
        -- SYNCn logic (wait states controlling for the 68K30).
        -- Used for the legacy synchronous bus termination (ACIAs and RTC).
        if VPA_INn = '0' and VMAn_68K30L = '0' and TMP = x"2" then -- Adjust E to S6..
            SYNCn <= '0';
        elsif VPA_INn = '1' then
            SYNCn <= '1';
        end if;

    end process E_TIMER;

    E <= E_I;

    SLOW_CPU: process(CLK_16M0, DSACK_In, CLK_CPU, RAMn, RWn_68K30L)
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
        if CLK_CPU = '0' and RAMn = '0' and RWn_68K30L = '1' and TMP /= x"9" then
            DSACKn <= "11"; -- Slow down...
        else
            DSACKn <= DSACK_In; -- Not delayed.
        end if;
    end process SLOW_CPU;

    I_CPU: WF68K30L_TOP
    generic map(NO_BFOPS            => NO_BFOPS)
    port map(
        CLK                         => CLK_16M0,

        -- Address and data:
        --ADR_OUT(31 downto 24)     =>, -- Not used.
        ADR_OUT                     => ADR_68K30L,
        DATA_IN(31 downto 16)       => DATA_I,
        DATA_IN(15 downto 0)        => x"0000", -- Not used.
        DATA_OUT(31 downto 16)      => DATA_OUT_68K30L,
        --DATA_OUT(15 downto 0)     => -- Not used.
        DATA_EN                     => DATA_EN_68K30L,

        -- System control:
        BERRn                       => BERR_In,
        RESET_INn                   => RESET_INn,
        RESET_OUT                   => RESET_EN_68K30L,
        HALT_INn                    => HALT_INn,
        HALT_OUTn                   => HALT_68K30Ln,

        -- Processor status:
        FC_OUT                      => FC_68K30L,

        -- Interrupt control:
        AVECn                       => AVEC_INn,
        IPLn                        => IPLn,
        --IPENDn                    =>, -- Not used.

        -- Aynchronous bus control:
        DSACKn                      => DSACKn,
        SIZE                        => SIZE_68K30L,
        ASn                         => ASn_68K30L,
        RWn                         => RWn_68K30L,
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
        BRn                         => BRn_I,
        BGn                         => BG030n,
        BGACKn                      => BGACKn_IN
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
            ADR_OUT                 => ADR_COMBEL,
            ADR_EN                  => ADR_EN_COMBEL,

            DATA_IN                 => DATA_I,
            DATA_OUT                => DATA_OUT_COMBEL,
            DATA_EN                 => DATA_EN_COMBEL,

            -- The RAM interface:
            --RAM_CKE               Not used.
            --RAM_CSn               Not used.
            RAM_BA                  => RAM_BA,
            RAM_ADR                 => RAM_ADR,
            --RAM_ADR_32            => -- Not used here.
            RAM_WEn                 => RAM_WEn,
            --RAM_RASn              => -- We use 256Mb chips.
            --RAM_CASn              => -- We use 256Mb chips.
            RAM_RAS0n               => RAM_RAS0n,
            RAM_CAS0n               => RAM_CAS0n,
            RAM_RAS1n               => RAM_RAS1n,
            RAM_CAS1n               => RAM_CAS1n,

            BUS_WIDTH               => BUS_WIDTH,
            RAM_DQMn                => RAM_DQM,
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
            DTACK_OUTn              => DTACKn_CMBL,

            -- 6800 peripheral control:
            VPAn                    => VPAn_CMBL,
            VMAn                    => VMAn_68K30L,

            -- Bus status:
            BERRn                   => BERR_CMBLn,

            -- Processor function codes:
            FC_IN                   => FC,
            FC_OUT                  => FC_CMBL,

            BUS_EN                  => BUS_EN_CMBL,


            -- Bus arbitration control:
            BRn                     => BRn_CMBL,
            BGIn                    => SDMABGn,
            BGOn                    => BGOn,
            BGAn                    => BGACKn_CMBL,

            -- Adress decoder stuff:
            -- In original COMBEL ther are only
            -- Pins for ROM2n, ROM3n and ROM4n.
            ROM_6n                  => ROM6n,
            ROM_5n                  => ROM5n,
            ROM_4n                  => ROM4n,
            ROM_3n                  => ROM3n,
            ROM_2n                  => ROM2n,
            ROM_1n                  => ROM1n,
            ROM_0n                  => ROM0n,

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
            RTCCS                   => RTCCS_DS1287,
            --RTCAS                 => Not used.
            --RTCDS                 => Not used.

            -- RP5C15 real time clock:
            RP5C15_CSn              => RP5C15_CSn,
            RP5C15_WRn              => RP5C15_WRn,
            RP5C15_RDn              => RP5C15_RDn,

            -- Interrupt system:
            HINT                    => HINT,
            VINT                    => VINT, -- In the Falcon VSYNC is wired here.
            MFPINTn                 => MFPINTn,
            EINT1                   => '0',
            EINT3                   => '0',
            EINT5n                  => '1',
            EINT7n                  => '1',
            --BINTn                 => -- Not used in the original hardware.
            AVECn                   => AVECn_CMBL,
            IACKn                   => MFP_IACKn,
            IPLn                    => IPLn,

            -- IDE interface:
            IDE_RS0n                => IDE_CS0n,
            IDE_RS1n                => IDE_CS1n,
            IDE_IORDn               => IDE_IORDn,
            IDE_IOWRn               => IDE_IOWRn,
            IDE_BYTESWAP            => IDE_BYTESWAP,
            IDE_D_EN_INn            => IDE_D_EN_INn,
            IDE_D_EN_OUTn           => IDE_D_EN_OUTn,

            SCCRDn                  => SCC_RDn,
            SCCWRn                  => SCC_WRn,
            --SCCIACKn              => ,
            SCCWAITn                => '1',

            -- Joyport:
            JOY_RHn                 => JOY_RHn,
            JOY_RLn                 => JOY_RLn,
            JOY_WL                  => JOY_WL,
            JOY_WEn                 => JOY_WEn,
            BUTTONn                 => BUTTONn,
            PAD0Xn                  => PAD0Xn,
            PAD0Yn                  => PAD0Yn,
            PAD1Xn                  => PAD1Xn,
            PAD1Yn                  => PAD1Yn,
            PADRSTn                 => PADRSTn,

            -- Enhancements:
            USB1160_CSn             => USB1160_CSn
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
            SNCLK                   => CLK_PLL_256, -- Originally 25.175MHz.
            CLK_EXT                 => '0', -- GENLOCK clock.

            -- Adress and data bus:
            FC_IN                   => FC,
            FC_OUT                  => FC_DMA,
            ADR_IN                  => ADR_I(31 downto 1),
            ADR_OUT                 => ADR_DMA,
            ADR_EN                  => ADR_EN_DMA,
            DATA_IN                 => DATA_I,
            DATA_OUT                => DATA_DMA,
            DATA_EN                 => DATA_EN_DMA,

            -- Bus control signals:
            BMODE                   => '0', -- '0' = 68030 bus master, '1' = 68000 bus master.
            AS_INn                  => ASn,
            AS_OUTn                 => ASn_DMA,
            LDS_INn                 => LDSn,
            LDS_OUTn                => LDSn_DMA,
            UDS_INn                 => UDSn,
            UDS_OUTn                => UDSn_DMA,
            RWn_IN                  => RWn,
            RWn_OUT                 => RWn_DMA,
            DTACK_INn               => DTACKn,
            DTACK_OUTn              => DTACKn_DMA,

            -- Bus arstd_logicration signals:
            BRn                     => BRn_DMA,
            BGIn                    => BG030n,
            BGOn                    => SDMABGn,
            BGAn                    => BGACKn_DMA,
            BERRn                   => BERRn,

            -- ACSI bus:
            CA                      => CA,
            CR_Wn                   => CR_Wn,
            CRn_W                   => CRn_W,
            CD_IN                   => CD,
            CD_OUT                  => CD_DMA,
            CD_EN                   => CD_EN_DMA,

            --DRIVE_SEL             => -- Not used.
            FDCSn                   => FDCSn,
            HDCSn                   => HDCS_In,
            --SCSICSn               => -- Not used.
            --SDCSn                 => -- Not used.
            FDRQ                    => FDRQ,
            HDRQ                    => HDRQ_IN,
            ACKn                    => HDACKn_I,

            -- Floppy disk drive configuration:
            MDET                    => "11", -- Originally with weak pull up. Not used here.
            DISKCHNG                => '0',
            -- MODE                 => -- Not used.
            -- FCCLK                => -- Not used.

            -- External serial output channel:
            --PLYDATA               => -- Not used.
            PLYCLK                  => FCLK,
            PLYSYNC_IN              => '0',
            --PLYSYNC_OUT           => -- Not used.
            --PLYSYNC_EN            => -- Not used.

            -- External serial input channel:
            RECDATA                 => '0',
            --RECCLK                => -- Not used.
            RECSYNC_IN              => '0',
            --RECSYNC_OUT           => -- Not used.
            --RECSYNC_EN            => -- Not used.

            -- DSP connector:
            --DSP_SRD               => -- Not used.
            --DSP_SCK               => -- Not used.
            DSP_STD                 => '0', -- DSP transmits data.
            --DSP_PLY_EN            => -- Not used.
            --DSP_REC_EN            => -- Not used.
            --DSP_SC0               => -- Not used.
            DSP_SC1_IN              => '0', -- Receive syncout.
            --DSP_SC1_OUT           => -- Not used.
            DSP_SC2_IN              => '0', -- Transmit syncout.
            --DSP_SC2_OUT           => -- Not used.

            -- Falcon audio codec:
            SCLOCK                  => DAC_SCLK,
            ASCLK                   => DAC_LDACn,
            ASSYNC                  => DAC_SYNCn,
            ASDOUT                  => '0',
            ASDIN                   => DAC_SDATA,

            -- Interrupt signals:
            SCNT                    => SOUNDINT,
            SINT                    => SNDINT,
            HDINTn                  => HDINT_INn,
            FDINT                   => FDINT,
            DSKIRQn                 => DISKIRQn,

            -- Microwire Interface:
            GPIO_IN                 => "000",
            --GPIO_OUT              => Not used.
            --GPIO_EN               => Not used.
            UWC                     => MWK,
            UWD                     => MWD,
            UWEn                    => MWEn
        );

    VIDEO_RAM: process(CLK_32M0, VRAM)
    -- Shadow LCD video ram:
    -- This process is written in that manner, that 131072
    -- bits RAM will be inferred.
    variable VRAM_ADR_PNTR  : integer range 0 to 16383;
    begin
        if CLK_32M0 = '1' and CLK_32M0' event then
            VRAM_ADR_PNTR := To_Integer(unsigned(SHADOW_VRAM_ADR));
            if SHADOW_VRAM_WRn = '0' then
                VRAM(VRAM_ADR_PNTR) <= VRAM_D_IN;
            end if;
        end if;
        VRAM_D_OUT <= VRAM(VRAM_ADR_PNTR);
    end process VIDEO_RAM;

    I_SHADOW: WF_SHD101775IP_TOP_SOC
        port map(
            RESETn              => RESET_INn,
            CLK                 => CLK_16M0,

            -- Video control:
            M_DATA              => RAM_DATA,
            SEL_640x400         => '1', -- Select either 640x400 '1' or 640x480 '0'.
            DE                  => DE,
            LOADn               => VLDn,

            R_ADR               => SHADOW_VRAM_ADR,
            R_DATA_IN           => VRAM_D_OUT,
            R_DATA_OUT          => VRAM_D_IN,
            -- R_DATA_EN        =>, -- Not used.
            R_WRn               => SHADOW_VRAM_WRn,

            -- LCD control:
            UDATA               => UDATA_OUT,
            LDATA               => LDATA_OUT,
            LFS                 => LFS,
            VDCLK               => VDCLK_OUT,
            LLCLK               => LLCLK
        );

    I_VIDEO: VIDEL_TOP
        generic map(RAM_16          => RAM_16)
        port map(
            -- System and core control:
            RESET                   => not RESET_INn,
            CLK_32M0                => CLK_32M0,
            CLK_25M175              => CLK_PLL_256, -- Originally 25.175MHz.
            CLK_EXT                 => CLK_16M0,  -- External clock (GENLOCK).

            -- System bus:
            ADR                     => ADR_I(11 downto 1),
            DATA_IN(31 downto 16)   => DATA_I,
            DATA_IN(15 downto 0)    => DATA_I,
            DATA_OUT(15 downto 0)   => DATA_OUT_VIDEL, -- Data(31 downto 16) is not used.
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

            MD_IN(31 downto 16)     => RAM_DATA,
            MD_IN(15 downto 0)      => RAM_DATA,
            MD_OUT(15 downto 0)     => RAM_D_OUT,
            MD_EN                   => RAM_D_EN,

            -- Videl control inputs:
            PEN                     => PENn,

            -- Video section:
            DE                      => DE,
            VSYNC                   => VSYNC_VIDEL,
            VSYNC_EN                => VSYNC_EN,
            HSYNC                   => HSYNC_VIDEL,
            HSYNC_EN                => HSYNC_EN,
            --CSYNC                 => Not used, originally wired to the video connector.
            --COLOR                 => Not used, originally wired to the video modulator.
            --COLOR                 => Not used.
            HINT                    => HINT,
            VINT                    => VINT, -- Not used in the Falcon.
            EVENn_ODD               => EVENn_ODD,
            DOTCK                   => xFF827E_D(2),
            MONO                    => CRT_MONO,
            R_OUT(7 downto 4)       => CRT_R,
            G_OUT(7 downto 4)       => CRT_G,
            B_OUT(7 downto 4)       => CRT_B
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
            MO                      => FDD_MO,
            WG                      => FDD_WG,
            WD                      => FDD_WD,
            STEP                    => FDD_STEP,
            DIRC                    => FDD_DIRC,
            DRQ                     => FDRQ,
            INTRQ                   => FDINT
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
            DTACKn                  => DTACKn_MFP,

            -- Data and Adresses:
            RS                  => ADR(5 downto 1),
            DATA_IN             => DATA_I(7 downto 0),
            DATA_OUT            => DATA_OUT_MFP,
            DATA_EN             => DATA_EN_MFP,

            GPIP_IN(7)          => SNDINT,
            GPIP_IN(6)          => not COM_RI,
            GPIP_IN(5)          => DISKIRQn,
            GPIP_IN(4)          => IRQ_ACIAn,
            GPIP_IN(3)          => '0',
            GPIP_IN(2)          => IRQ_MIDIn, -- Falcon.
            --GPIP_IN(2)          => not COM_CTS, -- STE
            GPIP_IN(1)          => not COM_DCD,
            GPIP_IN(0)          => LPT_BSY,
            -- GPIP_OUT         =>, -- Not used; all GPIPs are direction input.
            -- GPIP_EN          =>, -- Not used; all GPIPs are direction input.

            -- Interrupt control:
            IACKn                   => MFP_IACKn,
            IEIn                    => '0',
            -- IEOn                 =>, -- Not used.
            IRQn                    => MFPINTn,

            -- Timers and timer control:
            XTAL1                   => CLK_2M457600,
            TAI                     => SOUNDINT,
            TBI                     => DE,
            -- TAO                  =>, -- Not used.
            -- TBO                  =>, -- Not used.
            -- TCO                  =>, -- Not used.
            TDO                     => TDO,

            -- Serial I/O control:
            RC                      => CLK_MFP_UART,
            TC                      => CLK_MFP_UART,
            SI                      => COM_RxD,
            SO                      => MFP_SO,
            SO_EN                   => MFP_SO_EN

            -- DMA control:
            -- RRn                  =>, -- Not used.
            -- TRn                  => -- Not used.
        );

    I_SOUND: WF2149IP_TOP_SOC -- This is the Yamaha sound chip.
        port map(
            SYS_CLK             => CLK_16M0,
            RESETn              => RESET_INn,

            WAV_CLK             => CLK_2M0,
            SELn                => '1',

            BDIR                => SNDIR_I,
            BC2                 => '1',
            BC1                 => SNDCS_I,

            A9n                 => '0',
            A8                  => '1',
            DA_IN               => DATA_I(15 downto 8),
            DA_OUT              => DATA_OUT_SOUND,
            DA_EN               => DATA_EN_SOUND,

            IO_A_IN             => x"00", -- All port pins are dedicated outputs.
            IO_A_OUT(7)         => open, -- Not used so far.
            IO_A_OUT(6)         => GPO,
            IO_A_OUT(5)         => LPT_STRB,
            IO_A_OUT(4)         => YM_OUT_A4,
            IO_A_OUT(3)         => YM_OUT_A3,
            IO_A_OUT(2)         => FDD_D1SELn,
            IO_A_OUT(1)         => FDD_D0SELn,
            IO_A_OUT(0)         => FDD_SDSEL,
            -- IO_A_EN          =>, -- Not required.
            IO_B_IN             => LPT_D, -- Printer port.
            IO_B_OUT            => LPT_D_OUT,
            IO_B_EN             => LPT_D_EN,

            OUT_A               => YM_OUT_A,
            OUT_B               => YM_OUT_B,
            OUT_C               => YM_OUT_C
        );

    CODEC_SDOUT <= '0'; -- Not supported by this core.
    CODEC_SSYNC <= '0'; -- Not supported by this core.

    I_ACIA_KEYBOARD: WF6850IP_TOP_SOC
      port map(
            CLK                     => CLK_16M0,
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
            E                       => E_I,
            RWn                     => RWn,
            RS                      => ADR_I(1),

            DATA_IN                 => DATA_I(15 downto 8),
            DATA_OUT                => DATA_OUT_ACIA_II,
            DATA_EN                 => DATA_EN_ACIA_II,

            TXCLK                   => CLK_0M5,
            RXCLK                   => CLK_0M5,
            RXDATA                  => MIDI_IN,
            CTSn                    => UART_MIDI_CTSn,
            DCDn                    => UART_MIDI_DCDn,

            IRQn                    => IRQ_MIDIn,
            TXDATA                  => MIDI_OUT,
            RTSn                    => UART_MIDI_RTSn
        );

    I_RTC_RP5C15: WF5C15_139xIP_TOP
        port map(
            CLK                     => CLK_16M0,
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

    I_5380: WF5380_TOP_SOC
        port map(
            CLK                 => CLK_16M0,
            RESET               => not RESET_INn,
            ADR                 => CA,
            DATA_IN             => CD,
            DATA_OUT            => CD_5380,
            DATA_EN             => CD_EN_5380,
            CSn                 => HDCS_In,
            RDn                 => CR_Wn,
            WRn                 => CRn_W,
            EOPn                => '1',
            DACKn               => HDACKn_I,
            DRQ                 => HDRQ_5380,
            INT                 => HDINT_5380,
            --READY               => , -- We do not use block mode transfers.
            DB_INn              => SCSI_D,
            DB_OUTn             => SCSI_D_5380,
            DB_EN               => SCSI_EN_5380,
            DBP_INn             => SCSI_DP,
            DBP_OUTn            => SCSI_DP_5380,
            DBP_EN              => SCSI_DP_EN_5380,
            RST_INn             => SCSI_RSTn,
            RST_OUTn            => SCSI_RSTn_5380,
            RST_EN              => SCSI_RST_EN_5380,
            BSY_INn             => SCSI_BSYn,
            BSY_OUTn            => SCSI_BSYn_5380,
            BSY_EN              => SCSI_BSY_EN_5380,
            SEL_INn             => SCSI_SELn,
            SEL_OUTn            => SCSI_SELn_5380,
            SEL_EN              => SCSI_SEL_EN_5380,
            ACK_INn             => SCSI_ACKn,
            ACK_OUTn            => SCSI_ACKn_5380,
            ACK_EN              => SCSI_ACK_EN_5380,
            ATN_INn             => SCSI_ATNn,
            ATN_OUTn            => SCSI_ATNn_5380,
            ATN_EN              => SCSI_ATN_EN_5380,
            REQ_INn             => SCSI_REQn,
            REQ_OUTn            => SCSI_REQn_5380,
            REQ_EN              => SCSI_REQ_EN_5380,
            IOn_IN              => SCSI_IOn,
            IOn_OUT             => SCSI_IOn_5380,
            IO_EN               => SCSI_IO_EN_5380,
            DCn_IN              => SCSI_DCn,
            DCn_OUT             => SCSI_CDn_5380,
            DC_EN               => SCSI_CD_EN_5380,
            MSG_INn             => SCSI_MSGn,
            MSG_OUTn            => SCSI_MSGn_5380,
            MSG_EN              => SCSI_MSG_EN_5380
        );

    I_FLASHBOOT: FLASHBOOT_UMASPI
        port map(
            CLK                     => CLK_16M0, -- 16MHz.
            PLL_LOCK                => PLL_LOCKS,
            RESET_COREn             => BOOT_RESET_COREn,
            RESET_INn               => BOOT_RESETn,
            RESET_OUTn              => RESET_BOOTn,

            CORETYPE                => CORETYPE,
            VERSION                 => VERSION,

            --JOY                   => -- Currently not used.
            --KEY                   => -- Currently not used.

            --RAMADDR               => -- Currently not used.
            --RAMDATA               => -- Currently not used.

            ROM_CEn                 => ROM2n,
            ADR_OUT(23 downto 20)   => open, -- High address bits currently not in use.
            ADR_OUT(19 downto 0)    => ADR_BOOT,
            ADR_EN                  => ADR_EN_BOOT,
            DATA_IN                 => DATA_I,
            DATA_OUT                => DATA_OUT_BOOT,
            DATA_EN                 => DATA_EN_BOOT,
            FLASH_RDY               => FLASH_RDY,
            FLASH_RESETn            => FLASH_RESET_In,
            FLASH_WEn               => FLASH_WEn,
            FLASH_OEn               => FLASH_OEn,
            FLASH_CEn               => FLASH_CEn,
            SPI_CLK                 => SPI_CLK,
            SPI_DIN                 => SPI_MOSI,
            SPI_DOUT                => SPI_MISO,
            SPI_SSn                 => SD_SPI_SSn,
            BOOT_ACK                => BOOT_ACK,
            BOOT_REQ                => BOOT_REQ,
            BOOT_LED                => BOOT_LED
        );

   I_USB: USB1164_TOP
    generic map (LITTLE_ENDIAN      => USB1160_LITTLE_ENDIAN)
    port map(
        -- System controls:
        CLK_48MHz                   => CLK_48M0,
        RESETn                      => RESET_INn,
        -- Address and data:
        A0                          => ADR_I(2),
        DATA_IN                     => DATA_I,
        DATA_OUT                    => DATA_OUT_USB1160,
        DATA_EN                     => DATA_EN_USB1160,
        -- Bus controls:
        CSn                         => USB1160_CSn, -- Chip select.
        RDn                         => not RWn, -- Read data.
        WRn                         => RWn, -- Write data.
        EOT                         => '1', -- End of DMA Transfer.
        DACKn                       => '1', -- DMA data acknowledge.
        --DREQ                      => , -- DMA data request.
        --INT                       => , -- Interrupt.
        -- USB host:
        WAKEUP                      => '0', -- Wakeup from suspend.
        --SUSPEND                   => , -- Suspend status.
        -- AOCEN                    => , -- Analog OC enable.
        -- CLKNS                    => , -- Suspend CLK not stop.
        NDP_SEL                     => "10", -- Number of data ports. "00" = 1 Port,"01" = 2 Ports, "10" = 4 ports.
        --PSW1n                     => , -- Power switch.
        --PSW2n                     => , -- Power switch.
        --PSW3n                     => , -- Power switch.
        --PSW4n                     => , -- Power switch.
        OC1n                        => '1', -- Overcurrent detection.
        OC2n                        => '1', -- Overcurrent detection.
        OC3n                        => '1', -- Overcurrent detection.
        OC4n                        => '1', -- Overcurrent detection.

        DM1_IN                      => UDATA(2),
        DM1_OUT                     => DM1_OUT,
        DP1_IN                      => UDATA(0),
        DP1_OUT                     => DP1_OUT,
        DPM1_EN                     => DPM1_EN,
        DM2_IN                      => LDATA(2),
        DM2_OUT                     => DM2_OUT,
        DP2_IN                      => LDATA(0),
        DP2_OUT                     => DP2_OUT,
        DPM2_EN                     => DPM2_EN,
        DM3_IN                      => UDATA(3),
        DM3_OUT                     => DM3_OUT,
        DP3_IN                      => UDATA(1),
        DP3_OUT                     => DP3_OUT,
        DPM3_EN                     => DPM3_EN,
        DM4_IN                      => LDATA(3),
        DM4_OUT                     => DM4_OUT,
        DP4_IN                      => LDATA(1),
        DP4_OUT                     => DP4_OUT,
        DPM4_EN                     => DPM4_EN
        --DP15K                     =>  -- Switch for four 15K pull down resistors
    );

    VDCLK <= 'Z' when BOOT_RESET_COREn = '0' else
             'Z' when LCD_USBn = '0' else VDCLK_OUT;

    LCD_USB_SWITCH: process
    begin
        wait until CLK_16M0 = '1' and CLK_16M0' event;
        if BOOT_RESET_COREn = '0' then
            LCD_USBn <= VDCLK; -- READ the weak pull up.
        end if;
    end process LCD_USB_SWITCH;

    LDATA_EN <= x"F" when LCD_USBn = '1' else 
                x"F" when DPM2_EN = '1' and DPM4_EN = '1' else
                x"5" when DPM2_EN = '1' else
                x"A" when DPM4_EN = '1' else x"0";
    
    UDATA_EN <= x"F" when LCD_USBn = '1' else 
                x"F" when DPM1_EN = '1' and DPM3_EN = '1' else
                x"5" when DPM1_EN = '1' else
                x"A" when DPM3_EN = '1' else x"0";

    LDATA(3) <= LDATA_OUT(3) when LCD_USBn = '1' else DM4_OUT when LDATA_EN(3) = '1' else 'Z';
    LDATA(2) <= LDATA_OUT(2) when LCD_USBn = '1' else DM2_OUT when LDATA_EN(2) = '1' else 'Z';
    LDATA(1) <= LDATA_OUT(1) when LCD_USBn = '1' else DP4_OUT when LDATA_EN(1) = '1' else 'Z';
    LDATA(0) <= LDATA_OUT(0) when LCD_USBn = '1' else DP2_OUT when LDATA_EN(0) = '1' else 'Z';
    UDATA(3) <= UDATA_OUT(3) when LCD_USBn = '1' else DM3_OUT when UDATA_EN(3) = '1' else 'Z';
    UDATA(2) <= UDATA_OUT(2) when LCD_USBn = '1' else DM1_OUT when UDATA_EN(2) = '1' else 'Z';
    UDATA(1) <= UDATA_OUT(1) when LCD_USBn = '1' else DP3_OUT when UDATA_EN(1) = '1' else 'Z';
    UDATA(0) <= UDATA_OUT(0) when LCD_USBn = '1' else DP1_OUT when UDATA_EN(0) = '1' else 'Z';

    BOOT_RESET_COREn <= SD_RESET_COREn when SD_AVR_ENn = '0' else RESET_CORE_Sn;
    BOOT_RESETn <= SD_RESETn when SD_AVR_ENn = '0' else RESET_Sn;
    BOOT_ACK <= SD_BOOT_ACK when  SD_AVR_ENn = '0' else SYS_BOOT_ACK;
    SPI_CLK <= SD_SPI_CLK when SD_AVR_ENn = '0' else SYS_SPI_CLK;
    SPI_MOSI <= SD_SPI_MOSI when SD_AVR_ENn = '0' else SYS_SPI_MOSI;
    SD_BOOT_REQ <= BOOT_REQ when SD_AVR_ENn = '0' else '0';
    SYS_BOOT_REQ <= BOOT_REQ when SD_AVR_ENn = '1' else '0';
    SD_SPI_MISO <= SPI_MISO when SD_AVR_ENn = '0' else '0';
    SYS_SPI_MISO <= SPI_MISO when SD_AVR_ENn = '1' else '0';
end architecture STRUCTURE;
