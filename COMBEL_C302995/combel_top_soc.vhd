------------------------------------------------------------------------
----                                                                ----
---- ATARI Falcon COMBEL compatible IP Core                         ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Atari's COMBEL with all features to reach                      ----
---- ATARI Falcon compatibility.                                    ----
----                                                                ----
---- Top level file for use in systems on programmable chips.       ----
----                                                                ----
---- From version 2K23A there is a ROM shadow feature.              ----
---- It is controlled via a ROM shadow register wich is located al  ----
---- address 0x"00F82000". The register is defined as follows:      ----
---- bit7    bit6  bit5  bit4  bit3      bit2   bit1     bit0       ----
---- ALTRAM  14MB  ----  ----  CART_WEn  CARTn  TOS_WEn  TOSn       ----
----                                                                ----
---- To enable the shadowtos the following procedure is required:   ----
---- 1. Disable all Interupts (ORI #$700,SR), disable shadowing and ----
----    write protection by writing 1 to TOSn and 0 to TOS_WEn bit. ----
---- 2. Copy the desired content to the ROM address.                ----
---- 3. Copy the first 4 words starting from ROM base address to    ----
----    address 0++.                                                ----
---- 4. Enable shadowing and disable write access by writing 0 to   ----
----    TOSn and 1 to TOS_WEn.                                      ----
---- 5. (Cold)- reboot TOS.                                         ----
----                                                                ----
---- Author(s):                                                     ----
----   Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----   Udo Matthe, umatthe@web.de                                   ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2009... Wolfgang Foerster - Inventronik GmbH.      ----
---- Copyright © 2023... Udo Matthe.                                ----
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
-- Revision 2K9B  2009/12/24 WF
--   Initial Release.
-- Revision 2K15B  2015/12/24 WF
--   Several changes and fixes:
--   Added CSn_18B20 for the onewire device.
--   Added CSn_MP34DB01 for the microphone.
-- Revision 2K21A 20211224 WF
--   Removed CSn_18B20 for the onewire device; no more required.
--   Removed CSn_MP34DB01 for the microphone; no more required.
--   This is a complete code lifting with several changes and bug fixes.
--   Address decoder: introduced an explicit user mode to avoid CPU space mismatch.
--   We have now ALTRAM.
--   Udo Matthe: changed polarity of STE_JOY_WEn to be enabled when not read.
-- Revision 2K22A 20221224 WF
--   The MCU has now fully 32 bit adress bus width to meet the requirements to handle misaligned long RAM access.
-- Revision 2K23A 20230620 UMA
--   Implemented Udo Matthe Shadow TOS.
-- Revision 2K23B 20231224
--   Fixed a SHADOW_TOS write issue (UMA).
-- Revision 2K24A 20240620
--   USB1160 has now a waitstate cycle.
--

library work;
use work.COMBEL_PKG.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity COMBEL_TOP is
    generic(RAM_16      : boolean := false); -- Set true, if we have a 16 bit RAM data bus, false for 32 bit.
    port (
        -- System and core control:
        SYS_RESET_INn           : in std_logic;
        SYS_RESET_OUTn          : out std_logic;
        RESET                   : in std_logic;

        CLK_32                  : in std_logic;
        CLK_16                  : in std_logic;
        CLK_CPU                 : out std_logic;
        CLK_8                   : out std_logic;
        CLK_4                   : out std_logic;
        KHz_500                 : out std_logic; -- Clock for the MIDI ACIA and the keyboard ACIA (receiver).
        KHz_500W                : out std_logic; -- Clock for the transmitter of the keyboard ACIA.

        -- Adress and data bus:
        ADR_IN                  : in std_logic_vector(31 downto 0);
        ADR_OUT                 : out std_logic_vector(31 downto 1);
        ADR_EN                  : out std_logic; -- Used for the Blitter.

        DATA_IN                 : in std_logic_vector(15 downto 0);
        DATA_OUT                : out std_logic_vector(15 downto 0);
        DATA_EN                 : out std_logic;

        -- RAM interface:
        RAM_CKE                 : out std_logic; -- RAM clock enable.
        RAM_CSn                 : out std_logic; -- RAM chip enable.
        RAM_BA                  : out std_logic_vector(1 downto 0); -- SD-RAM bank select.
        RAM_ADR                 : out std_logic_vector(12 downto 0); -- SD-RAM address bus.
        RAM_ADR_32              : out std_logic_vector(31 downto 2); -- 32 bit linear RAM address (LONG32).
        RAM_WEn                 : out std_logic;
        RAM_RASn                : out std_logic; -- This is for 512Mb chips.
        RAM_CASn                : out std_logic; -- This is for 512Mb chips.
        RAM_RAS0n               : out std_logic; -- This is for 256Mb chips.
        RAM_CAS0n               : out std_logic; -- This is for 256Mb chips.
        RAM_RAS1n               : out std_logic; -- This is for 256Mb chips.
        RAM_CAS1n               : out std_logic; -- This is for 256Mb chips.
        BUS_WIDTH               : in RAMWIDTH_TYPE; -- RAM bus width.
        RAM_DQMn                : out std_logic_vector(3 downto 0); -- SD-RAM output buffer controls.
        SIZE_MCU                : in std_logic_vector(1 downto 0); -- Data size control.

        -- Bus control:
        RWn_IN                  : in std_logic;
        ASn_OUT                 : out std_logic;
        ASn_IN                  : in std_logic;
        RWn_OUT                 : out std_logic;
        UDSn_IN                 : in std_logic;
        UDSn_OUT                : out std_logic;
        LDSn_IN                 : in std_logic;
        LDSn_OUT                : out std_logic;

        RAMn                    : out std_logic; -- Additional signal to handle the 32 bit wide RAM.
        RAMH                    : out std_logic; -- VIDEL's data latch control.

        DTACK_INn               : in std_logic;
        DTACK_OUTn              : out std_logic;

        -- 6800 peripheral control:
        VPAn                    : out std_logic;
        VMAn                    : in std_logic;

        -- Bus status:
        BERRn                   : out std_logic;

        -- Processor function codes:
        FC_IN                   : in std_logic_vector(2 downto 0);
        FC_OUT                  : out std_logic_vector(2 downto 0);

        BUS_EN                  : out std_logic;

        -- Bus arbitration control:
        BRn                     : out std_logic;
        BGIn                    : in std_logic;
        BGOn                    : out std_logic;
        BGAn                    : out std_logic;

        -- Adress decoder stuff:
        -- In original COMBEL ther are only
        -- Pins for ROM2n, ROM3n and ROM4n.
        ROM_6n                  : out std_logic;  -- STE.
        ROM_5n                  : out std_logic;  -- STE.
        ROM_4n                  : out std_logic;  -- ST.
        ROM_3n                  : out std_logic;  -- ST.
        ROM_2n                  : out std_logic;
        ROM_1n                  : out std_logic;
        ROM_0n                  : out std_logic;

        N6850                   : out std_logic;
        MFPCSn                  : out std_logic;

        SNDCS                   : out std_logic; -- STE: Sound chip select.
        SNDIR                   : out std_logic; -- STE: Data flow direction control.
        FPUCS                   : out std_logic; -- Floating point unit
        R8006n                  : out std_logic; -- Falcon's configuration register.

        -- Keyboard stuff:
        TOK                     : in std_logic; -- 'Transmit Ok', to KROK of the Keyboard connector.
        TID                     : in std_logic; -- To TXD of the keyboard ACIA, not used yet.

        -- VIDEL control signals:
        VREQ                    : in std_logic; -- Video data request.
        EVENn_ODD               : in std_logic; -- Indicates the interlaced video frame.
        VCS                     : out std_logic; -- VIDEL chip select.
        VLDn                    : out std_logic; -- Shifter load signal.
        RDATn                   : out std_logic; -- VIDEL's data latch control.
        WDATn                   : out std_logic; -- VIDEL's data latch control.

        -- Bus control signal:
        BMODE                   : in std_logic; -- '0' = 68030 bus timing '1' = 68000 bus timing.

        -- DS1287 real time clock:
        RTCCS                   : out std_logic; -- Real time clock chip select.
        RTCAS                   : out std_logic; -- Address strobe.
        RTCDS                   : out std_logic; -- Data strobe.
        RTC_ACK                 : in std_logic; -- Set to '1' if not used.

        -- RP5C15 real time clock:
        RP5C15_CSn              : out std_logic; -- RP5C15 clock chip control.
        RP5C15_WRn              : out std_logic; -- RP5C15 clock chip control.
        RP5C15_RDn              : out std_logic; -- RP5C15 clock chip control.

        -- Interrupt system:
        HINT                    : in std_logic; -- Horizontal interrupt.
        VINT                    : in std_logic; -- Vertical Interrupt.
        MFPINTn                 : in std_logic;
        EINT1                   : in std_logic;
        EINT3                   : in std_logic;
        EINT5n                  : in std_logic;
        EINT7n                  : in std_logic;
        BINTn                   : out std_logic; -- Blitter.
        AVECn                   : out std_logic; -- Add-On over COMBEL.
        IACKn                   : out std_logic; -- ST.
        IPLn                    : out std_logic_vector(2 downto 0); -- STE only.

        -- IDE interface:
        IDE_RS0n                : out std_logic;
        IDE_RS1n                : out std_logic;
        IDE_IORDn               : out std_logic;
        IDE_IOWRn               : out std_logic;
        IDE_BYTESWAP            : out std_logic;
        IDE_D_EN_INn            : out std_logic; -- In-Buffer control, Add-On over COMBEL.
        IDE_D_EN_OUTn           : out std_logic; -- Out-Buffer control, Add-On over COMBEL.

        -- SCC chip:
        SCCABn                  : out std_logic;
        SCCRDn                  : out std_logic;
        SCCWRn                  : out std_logic;
        SCCIACKn                : out std_logic;
        SCCWAITn                : in std_logic;

        -- Joyport:
        JOY_RHn                 : out std_logic;      -- Read only FF9202 high byte.
        JOY_RLn                 : out std_logic;      -- Read only FF9202 low byte.
        JOY_WL                  : out std_logic;      -- Write only FF9202 low byte.
        JOY_WEn                 : out std_logic;      -- Write only FF9202 output enable.
        BUTTONn                 : out std_logic;      -- Read only FF9000 low byte.
        PAD0Xn                  : in std_logic;       -- Counter input for the Paddle 0X.
        PAD0Yn                  : in std_logic;       -- Counter input for the Paddle 0Y.
        PAD1Xn                  : in std_logic;       -- Counter input for the Paddle 1X.
        PAD1Yn                  : in std_logic;       -- Counter input for the Paddle 1Y.
        PADRSTn                 : out std_logic;      -- Paddle monoflops reset.

        -- Enhancements:
        USB1160_CSn             : out std_logic -- ISP1160 compatible core.
    );
end entity COMBEL_TOP;

architecture STRUCTURE of COMBEL_TOP is
signal BERR_In                  : std_logic;
signal BMODE_I                  : std_logic;
signal ALTRAM_In                : std_logic;
signal ASn_I                    : std_logic;
signal ASn_BLT                  : std_logic;
signal CLK_BLT                  : std_logic;
signal BUS_EN_BLT               : std_logic;
signal DATA_OUT_BLT             : std_logic_vector(15 downto 0);
signal DATA_EN_BLT              : std_logic;
signal DATA_OUT_MCU             : std_logic_vector(15 downto 0);
signal DATA_EN_MCU              : std_logic;
signal DATA_OUT_JOYPORT         : std_logic_vector(15 downto 0);
signal DATA_EN_JOYPORT          : std_logic;
signal DTACK_OUT_IDEn           : std_logic;
signal DTACK_MCUn               : std_logic;
signal DTACK_IN_BLTn            : std_logic;
signal DTACK_OUT_BLTn           : std_logic;
signal EN_RAM_14MB_I            : std_logic;
signal FC_I                     : std_logic_vector(2 downto 0);
signal FC_BLT                   : std_logic_vector(2 downto 0);
signal MCURAM_In                : std_logic;
signal RAM_16MB                 : std_logic;
signal ROM_6_In                 : std_logic;
signal ROM_5_In                 : std_logic;
signal ROM_4_In                 : std_logic;
signal ROM_3_In                 : std_logic;
signal ROM_2_In                 : std_logic;
signal ROM_1_In                 : std_logic;
signal ROM_0_In                 : std_logic;
signal SNDCS_In                 : std_logic;
signal KHz_500_I                : std_logic;
signal JOY_RS_I                 : std_logic;
signal PAD0X_RS_I               : std_logic;
signal PAD0Y_RS_I               : std_logic;
signal PAD1X_RS_I               : std_logic;
signal PAD1Y_RS_I               : std_logic;
signal BUTTON_RS_I              : std_logic;
signal SCCn                     : std_logic;
signal VCS_I                    : std_logic;
signal LDSn_I                   : std_logic;
signal LDSn_BLT                 : std_logic;
signal MEM_CONFIG_RS_I          : std_logic;
signal LINE_OFFS_RS_I           : std_logic;
signal LINE_WIDTH_RS_I          : std_logic;
signal LIGHTNING_CSn_I          : std_logic;
signal LIGHTNING_REG            : std_logic_vector(7 downto 0);
signal LIGHTNINGDATA_EN         : std_logic;
signal VIDEO_BASE_HI_RS_I       : std_logic;
signal VIDEO_BASE_MID_RS_I      : std_logic;
signal VIDEO_BASE_LOW_RS_I      : std_logic;
signal VIDEO_COUNT_HI_RS_I      : std_logic;
signal VIDEO_COUNT_MID_RS_I     : std_logic;
signal VIDEO_COUNT_LOW_RS_I     : std_logic;
signal R8006_RS                 : std_logic;
signal R8007_RS                 : std_logic;
signal FPUCS_I                  : std_logic;
signal RAM_In                   : std_logic;
signal R8006_REG                : std_logic_vector(7 downto 0);
signal R8007_REG                : std_logic_vector(7 downto 0);
signal RP5C15_CS_I              : std_logic;
signal RTCCS_I                  : std_logic;
signal RWn_I                    : std_logic;
signal RWn_BLT                  : std_logic;
signal SHADOW_TOS_CSn_I         : std_logic;
signal SHADOW_CONFIG            : std_logic_vector(7 downto 0);
signal SHADOWDATA_EN            : std_logic;
signal SHMOD_ST_SHADOW_RS_I     : std_logic;
signal UDS_In                   : std_logic;
signal UDSn_BLT                 : std_logic;
signal USB1160_CS_In            : std_logic;
signal USB1160_RDY              : std_logic;
signal VMODE_SHADOW_RS_I        : std_logic;
signal VIDEO_BASE_HIWORD_RS_I   : std_logic;
signal VIDEO_BASE_LOWORD_RS_I   : std_logic;
signal VIDEO_COUNT_HIWORD_RS_I  : std_logic;
signal VIDEO_COUNT_LOWORD_RS_I  : std_logic;

alias SHADOW_TOSn               : std_logic is SHADOW_CONFIG(0);  -- 0 = ShadowTOS active / 1 = FlashTOS active
alias SHADOW_TOS_WEn            : std_logic is SHADOW_CONFIG(1);  -- 0 = ShadowTOS rw / 1 = ShadowTOS readonly
alias SHADOW_CARTn              : std_logic is SHADOW_CONFIG(2);  -- 0 = ShadowCART active / 1 = FlashCART active
alias SHADOW_CART_WEn           : std_logic is SHADOW_CONFIG(3);  -- 0 = ShadowCART rw / 1 = ShadowCART readonly
alias SHADOW_EN_RAM_14MB        : std_logic is SHADOW_CONFIG(6);  -- 0 = RAM_14MB switch valid / 1 = 14MB always active
alias SHADOW_ALTRAMn            : std_logic is SHADOW_CONFIG(7);  -- 0 = 48MB possible / 1 = no Alram active
begin

    SHADOW_TOS_CONTROL: process
    variable LOCK  : boolean;
    begin
        wait until CLK_32 = '0' and CLK_32' event;

        if LIGHTNING_CSn_I = '0' and RWn_IN = '0' then
            LIGHTNING_REG <= DATA_IN(7 downto 0);
        end if;

        if RESET = '1' and LOCK = false then
            SHADOW_CONFIG <= "00111111"; -- One time initialization.
            LOCK := true;
        elsif RWn_IN = '0' and SHADOW_TOS_CSn_I = '0' then
            SHADOW_CONFIG <= DATA_IN(7 downto 0);
        end if;
    end process SHADOW_TOS_CONTROL;

    EN_RAM_14MB_I <= RAM_16MB or SHADOW_EN_RAM_14MB;
    RAMn <= RAM_In;

    RAM_In <= '0' when ALTRAM_In = '0' and SHADOW_ALTRAMn = '0' else
              '0' when SHADOW_CARTn = '0' and ROM_6_In = '0' else -- Read cartridge RAM.
              '0' when SHADOW_CARTn = '0' and ROM_5_In = '0' else -- Read cartridge RAM.
              '0' when SHADOW_CARTn = '0' and ROM_4_In = '0' else -- Read cartridge RAM.
              '0' when SHADOW_CARTn = '0' and ROM_3_In = '0' else -- Read cartridge RAM.
              '0' when SHADOW_TOSn = '0' and ROM_2_In = '0' else -- Read TOS RAM.
              '0' when SHADOW_TOSn = '0' and ADR_IN >= x"00E00000" and ADR_IN < x"00E80000" and ASn_IN = '0' and RWn_IN = '1' else  -- Read TOS RAM.
              '0' when SHADOW_TOSn = '1' and ADR_IN <  x"00000008"    and ASn_IN = '0' and RWn_IN = '0' and  SHADOW_TOS_WEn  = '0' else -- write TOS mirroring to Shadow RAM.
              '0' when ADR_IN >= x"00E00000" and ADR_IN < x"00E80000" and ASn_IN = '0' and RWn_IN = '0' and  SHADOW_TOS_WEn  = '0' else -- write E00000-E7FFFF RAM.
              '0' when ADR_IN >= x"00FC0000" and ADR_IN < x"00FF0000" and ASn_IN = '0' and RWn_IN = '0' and  SHADOW_TOS_WEn  = '0' else -- write FC0000-FEFFFF RAM.
              '0' when ADR_IN >= x"00FA0000" and ADR_IN < x"00FC0000" and ASn_IN = '0' and RWn_IN = '0' and  SHADOW_CART_WEn = '0' else  -- write FA0000-FBFFFF Cartridge RAM.
              MCURAM_In;

    ASn_I <= ASn_BLT when BUS_EN_BLT = '1' else ASn_IN;

    RWn_I <= RWn_BLT when BUS_EN_BLT = '1' else RWn_IN;
    FC_I <= FC_BLT when BUS_EN_BLT = '1' else FC_IN;

    UDS_In <= UDSn_BLT when BUS_EN_BLT = '1' else UDSn_IN;
    LDSn_I <= LDSn_BLT when BUS_EN_BLT = '1' else LDSn_IN;

    UDSn_OUT <= UDSn_BLT;
    LDSn_OUT <= LDSn_BLT;
    ASn_OUT  <= ASn_BLT;
    RWn_OUT  <= RWn_BLT;
    FC_OUT   <= FC_BLT;

    BUS_EN <= BUS_EN_BLT;

    DATA_EN <= '1' when (DATA_EN_BLT or DATA_EN_MCU or DATA_EN_JOYPORT or SHADOWDATA_EN or LIGHTNINGDATA_EN) = '1' else
               '1' when R8006_RS = '0' and R8007_RS = '1' and RWn_I = '1' else '0'; -- This is reading register x"FFFF8007" byte wide.

    SHADOWDATA_EN <= '1' when SHADOW_TOS_CSn_I = '0' and RWn_IN = '1' else '0';
    LIGHTNINGDATA_EN <= '1' when RWn_IN = '1' and LIGHTNING_CSn_I = '0' else '0';

    DATA_OUT <= DATA_OUT_BLT when DATA_EN_BLT = '1' else
                DATA_OUT_MCU when DATA_EN_MCU = '1' else
                DATA_OUT_JOYPORT when DATA_EN_JOYPORT = '1' else
                SHADOW_CONFIG & x"00" when RWn_IN = '1' and SHADOWDATA_EN = '1' else
                LIGHTNING_REG & LIGHTNING_REG when RWn_IN = '1' and LIGHTNINGDATA_EN = '1' else
                R8007_REG & R8007_REG when R8007_RS = '1' and RWn_I = '1' else (others => '1'); -- x"FFFF" due to pull up resistors in original hardware.

    -- System controls:
    KHz_500 <= KHz_500_I;
    KHz_500W <= KHz_500_I when TOK = '1' else '0';
    BERRn <= BERR_In;

    -- Register selections:
    R8006n <= not R8006_RS; -- Flacon's configuration register.
    FPUCS <= FPUCS_I; -- Floating point unit.
    VCS <= VCS_I; -- VIDEL video chip.

    -- TOS-ROMS:
    ROM_6n <= ROM_6_In when SHADOW_CARTn = '1' else '1';
    ROM_5n <= ROM_5_In when SHADOW_CARTn = '1' else '1';
    ROM_4n <= ROM_4_In when SHADOW_CARTn = '1' else '1';
    ROM_3n <= ROM_3_In when SHADOW_CARTn = '1' else '1';
    ROM_2n <= ROM_2_In when SHADOW_TOSn = '1' else '1';
    ROM_1n <= ROM_1_In when SHADOW_TOSn = '1' else '1';
    ROM_0n <= ROM_0_In when SHADOW_TOSn = '1' else '1';

    -- Soundchip:
    SNDCS   <= '1' when SNDCS_In = '0' and ADR_IN(1) = '0' else '0';
    SNDIR   <= '1' when RWn_I = '0' and SNDCS_In = '0' else '0';

    -- Serial communication controller:
    SCCRDn <= '0' when SCCn = '0' and RWn_I = '1' else '1';
    SCCWRn <= '0' when SCCn = '0' and RWn_I = '0' else '1';

    -- DS1287 real time clock:
    RTCCS   <= RTCCS_I;
    RTCAS <= '1' when RTCCS_I = '1' and ADR_IN(1) = '0' else '0'; -- x"8961" is the address strobe.
    RTCDS <= '1' when RTCCS_I = '1' and ADR_IN(1) = '1' else '0'; -- x"8963" is the data strobe.

    -- RP5C15 real time clock:
    RP5C15_CSn <= not RP5C15_CS_I;
    RP5C15_RDn <= '0' when RWn_I = '1' and LDSn_I = '0' and VMAn = '0' else '1';
    RP5C15_WRn <= '0' when RWn_I = '0' and LDSn_I = '0' and VMAn = '0' else '1';

    -- Joyport:
    JOY_RHn <= '0' when JOY_RS_I = '1' and RWn_I = '1' and UDS_In = '0' else '1';
    JOY_RLn <= '0' when JOY_RS_I = '1' and RWn_I = '1' and LDSn_I = '0' else '1';
    JOY_WEn <= '1' when JOY_RS_I = '1' and RWn_I = '1' and LDSn_I = '0' else '0';
    JOY_WL <= '1' when JOY_RS_I = '1' and RWn_I = '0' and LDSn_I = '0' else '0';
    BUTTONn <= '0' when BUTTON_RS_I = '1' else '1';

    -- Enhancements:
    USB1160_CSn <= USB1160_CS_In;

    -- Feedback for the buscontrollers:
    DTACK_OUTn <= '0' when ROM_6_In = '0' and SHADOW_CARTn = '1' else
                  '0' when ROM_5_In = '0' and SHADOW_CARTn = '1' else
                  '0' when ROM_4_In = '0' and SHADOW_CARTn = '1' else
                  '0' when ROM_3_In = '0' and SHADOW_CARTn = '1' else
                  '0' when ROM_2_In = '0' and SHADOW_TOSn = '1' else
                  '0' when SNDCS_In = '0'                     else
                  '0' when RTCCS_I = '1' and RTC_ACK = '1'    else -- DS1287.
                   -- '0' when RP5C15_CS_I = '1'              else -- Validated via VPAn.
                  '0' when SCCn = '0' and SCCWAITn = '1'      else
                  '0' when JOY_RS_I = '1'                     else
                  '0' when PAD0X_RS_I = '1'                   else
                  '0' when PAD0Y_RS_I = '1'                   else
                  '0' when PAD1X_RS_I = '1'                   else
                  '0' when PAD1Y_RS_I = '1'                   else
                  '0' when BUTTON_RS_I = '1'                  else
                  '0' when R8006_RS = '1'                     else
                  '0' when R8007_RS = '1'                     else
                  -- '0' when FPUCS_I = '1'                   else -- Validated via FPU DSACKn
                  '0' when VCS_I = '1'                        else
                  '0' when LINE_OFFS_RS_I = '1'               else
                  '0' when LINE_WIDTH_RS_I = '1'              else
                  '0' when MEM_CONFIG_RS_I = '1'              else
                  '0' when VIDEO_BASE_HI_RS_I = '1'           else
                  '0' when VIDEO_BASE_MID_RS_I = '1'          else
                  '0' when VIDEO_BASE_LOW_RS_I = '1'          else
                  '0' when VIDEO_COUNT_HI_RS_I = '1'          else
                  '0' when VIDEO_COUNT_MID_RS_I = '1'         else
                  '0' when VIDEO_COUNT_LOW_RS_I = '1'         else
                  '0' when VIDEO_BASE_HIWORD_RS_I = '1'       else
                  '0' when VIDEO_BASE_LOWORD_RS_I = '1'       else
                  '0' when VIDEO_COUNT_HIWORD_RS_I = '1'      else
                  '0' when VIDEO_COUNT_LOWORD_RS_I = '1'      else
                  '0' when DTACK_OUT_IDEn = '0'               else
                  '0' when DTACK_MCUn = '0'                   else
                  '0' when DTACK_OUT_BLTn = '0'               else
                  '0' when SHADOW_TOS_CSn_I = '0'             else
                  '0' when LIGHTNING_CSn_I = '0'              else
                  '0' when USB1160_RDY = '1'                  else '1';

    P_WAITSTATES: process
    -- The latency of the USB controller is in case of
    -- operating ISO and ATL transfer too long for a non
    -- delayed bus cycle. For more information refer to 
    -- the USB1160 top level header.
    begin
        wait until CLK_16 = '1' and CLK_16' event;
        USB1160_RDY <= not USB1160_CS_In;
    end process P_WAITSTATES;

    SYSTEM_REGs: process(CLK_32, R8006_REG, R8007_REG)
    --    $FF8007|Falcon Bus Control          BIT . 6 5 . 3 2 . 0 |R/W
    --           |Reset behaviour ( 0 = cold boot) -' |   | |   |
    --           |STe Bus Emulation (0 - on) ---------'   | |   |
    --           |Blitter Switch (0 = 0n) ----------------' |   |
    --           |Blitter (0 - 8MHz, 1 - 16MHz) ------------'   |
    --           |68030 (0 - 8MHz, 1 - 16MHz) ------------------'
    begin
        if CLK_32 = '1' and CLK_32' event then
            if RESET = '1' then
                R8006_REG <= x"00";
                R8007_REG <= x"00";
            elsif R8006_RS = '1' and RWn_I = '1' then -- Read access.
                R8006_REG <= DATA_IN(15 downto 8); -- Store halfmoon values here.
            elsif R8007_RS = '1' and RWn_I = '0' then
                R8007_REG <= DATA_IN(7 downto 0);
            end if;
        end if;
        --
        -- R8006_REG(7 downto 6) Monitor type is set in the VIDEL video core.
        RAM_16MB <= R8006_REG(5) and not R8006_REG(4);
        -- R8006_REG(3 downto 2) ROM_WAITSTATES are not used here.
        -- R8006_REG(1) VIDEO_RAM_WIDTH is fixed to 32 bits.
        -- R8006_REG(0) RAM_WAITSTATES are not used here.
        CLK_CPU <= R8007_REG(0); -- '1' is not delayed, '0' is delayed.
        CLK_BLT <= R8007_REG(2); -- '1' is not delayed, '0' is delayed.
        -- BLT_ONn <= R8007_REG(3); -- This is a software flag.
        BMODE_I <= R8007_REG(5);
        -- RESET_MODE <= R8007_REG(6); -- This is a software flag.
    end process SYSTEM_REGs;

    SLOW_BLITTER: process(CLK_16, DTACK_INn, CLK_BLT, RAM_In, RWn_BLT)
    -- For software compatibility, it is sometimes necessary to
    -- slow down the Blitter. This is achieved by a delay of
    -- DTACKn during RAM read access which causes the Blitter to
    -- insert waitstates. The switch for this logic is bit 2 of
    -- register x"FFFF8007"  (CLK_BLT).
    -- Remark: in the original hardware there are clock switches
    -- between 16MHz and 8MHz. To improve the stability of this
    -- ip core we do not realize such switches but operate the
    -- Blitter with a fixed frequency.
    -- Adjust the TMP value for your requirements. The higher
    -- the value, the slower the bus access.
    variable TMP : std_logic_vector(3 downto 0);
    begin
        if CLK_16 = '1' and CLK_16' event then
            if RAM_In = '1' then
                TMP := x"0";
            elsif TMP /= x"9" then
                TMP := TMP + '1';
            end if;
        end if;
        --
        if CLK_BLT = '0' and RAM_In = '0' and RWn_BLT = '1' and TMP /= x"9" then
            DTACK_IN_BLTn <= '1'; -- Slow down...
        else
            DTACK_IN_BLTn <= DTACK_INn; -- Not delayed.
        end if;
    end process SLOW_BLITTER;

    I_AUXCLOCKS: CLOCKS
    port map(
        CLK                     => CLK_32,
        CLK_04                  => CLK_8,
        CLK_08                  => CLK_4,
        CLK_064                 => KHz_500_I
    );

    I_BLT: BLITTER_TOP
        port map(
        CLK                     => CLK_16,
        RESET                   => RESET,
        AS_INn                  => ASn_I,
        AS_OUTn                 => ASn_BLT,
        LDS_INn                 => LDSn_I,
        LDS_OUTn                => LDSn_BLT,
        UDS_INn                 => UDS_In,
        UDS_OUTn                => UDSn_BLT,
        RWn_IN                  => RWn_I,
        RWn_OUT                 => RWn_BLT,
        DTACK_INn               => DTACK_IN_BLTn,
        DTACK_OUTn              => DTACK_OUT_BLTn,
        BERRn                   => BERR_In,
        BMODE                   => BMODE or BMODE_I,
        FC_IN                   => FC_I,
        FC_OUT                  => FC_BLT,
        BUSCTRL_EN              => BUS_EN_BLT,
        INTn                    => BINTn,

        ADR_IN                  => ADR_IN(31 downto 1),
        ADR_OUT                 => ADR_OUT,
        ADR_EN                  => ADR_EN,
        DATA_IN                 => DATA_IN,
        DATA_OUT                => DATA_OUT_BLT,
        DATA_EN                 => DATA_EN_BLT,

        BGIn                    => BGIn,
        BRn                     => BRn,
        BGACK_INn               => '1',
        BGACK_OUTn              => BGAn,
        BGOn                    => BGOn
        );

    I_ADRDEC: ADRDEC
    port map(
        ADR                     => ADR_IN(31 downto 1), -- Word addresses.
        RWn                     => RWn_I,

        LDSn                    => LDSn_I,
        UDSn                    => UDS_In,

        ASn                     => ASn_I,

        VPAn                    => VPAn,
        VMAn                    => VMAn,

        FC                      => FC_I,

        ROM_0n                  => ROM_0_In,
        ROM_1n                  => ROM_1_In,
        ROM_2n                  => ROM_2_In,
        ROM_3n                  => ROM_3_In,
        ROM_4n                  => ROM_4_In,
        ROM_5n                  => ROM_5_In,
        ROM_6n                  => ROM_6_In,

        ACIACS                  => N6850,
        MFPCSn                  => MFPCSn,
        SNDCSn                  => SNDCS_In,
        SCCn                    => SCCn,
        SCCABn                  => SCCABn,
        RTCCS                   => RTCCS_I,
        RP5C15_CS               => RP5C15_CS_I,

        JOY_RS                  => JOY_RS_I,

        PAD0X_RS                => PAD0X_RS_I,
        PAD0Y_RS                => PAD0Y_RS_I,
        PAD1X_RS                => PAD1X_RS_I,
        PAD1Y_RS                => PAD1Y_RS_I,

        BUTTON_RS               => BUTTON_RS_I,

        R8006_RS                => R8006_RS,
        R8007_RS                => R8007_RS,

        FPUCS                   => FPUCS_I,

        VCS                     => VCS_I,

        MEM_CONFIG_RS           => MEM_CONFIG_RS_I,
        LINE_OFFS_RS            => LINE_OFFS_RS_I,
        LINE_WIDTH_RS           => LINE_WIDTH_RS_I,

        VIDEO_BASE_HIWORD_RS    => VIDEO_BASE_HIWORD_RS_I,
        VIDEO_BASE_LOWORD_RS    => VIDEO_BASE_LOWORD_RS_I,
        VIDEO_COUNT_HIWORD_RS   => VIDEO_COUNT_HIWORD_RS_I,
        VIDEO_COUNT_LOWORD_RS   => VIDEO_COUNT_LOWORD_RS_I,
        VIDEO_BASE_HI_RS        => VIDEO_BASE_HI_RS_I,
        VIDEO_BASE_MID_RS       => VIDEO_BASE_MID_RS_I,
        VIDEO_BASE_LOW_RS       => VIDEO_BASE_LOW_RS_I,
        VIDEO_COUNT_HI_RS       => VIDEO_COUNT_HI_RS_I,
        VIDEO_COUNT_MID_RS      => VIDEO_COUNT_MID_RS_I,
        VIDEO_COUNT_LOW_RS      => VIDEO_COUNT_LOW_RS_I,

        SHMOD_ST_SHADOW_RS      => SHMOD_ST_SHADOW_RS_I,
        VMODE_SHADOW_RS         => VMODE_SHADOW_RS_I,

        RAM_16MB                => EN_RAM_14MB_I, --UMA RAM_16MB,
        RAM_512MB               => '0', -- For future enhancements.
        RAMn                    => MCURAM_In,
        ALTRAMn                 => ALTRAM_In,

        SHADOW_TOS_CSn          => SHADOW_TOS_CSn_I,
        Lightning_CSn           => LIGHTNING_CSn_I,
        USB1160_CSn             => USB1160_CS_In
    );

    I_MCU: MCU_TOP
    generic map(RAM_16          => RAM_16)
    port map(
        CLK                     => CLK_32,

        SYS_RESET_INn           => SYS_RESET_INn,
        SYS_RESET_OUTn          => SYS_RESET_OUTn,
        RESET                   => RESET,

        ASn                     => ASn_I,
        LDSn                    => LDSn_I,
        UDSn                    => UDS_In,
        RWn                     => RWn_I,

        ADR                     => ADR_IN,

        RAMn                    => RAM_In,
        VREQ                    => VREQ,
        EVENn_ODD               => EVENn_ODD,

        RDATn                   => RDATn,
        WDATn                   => WDATn,
        RAMH                    => RAMH,

        VINT                    => VINT,

        VIDEO_BASE_HIWORD_RS    => VIDEO_BASE_HIWORD_RS_I,
        VIDEO_BASE_LOWORD_RS    => VIDEO_BASE_LOWORD_RS_I,
        VIDEO_COUNT_HIWORD_RS   => VIDEO_COUNT_HIWORD_RS_I,
        VIDEO_COUNT_LOWORD_RS   => VIDEO_COUNT_LOWORD_RS_I,
        VIDEO_BASE_HI_RS        => VIDEO_BASE_HI_RS_I,
        VIDEO_BASE_MID_RS       => VIDEO_BASE_MID_RS_I,
        VIDEO_BASE_LOW_RS       => VIDEO_BASE_LOW_RS_I,
        VIDEO_COUNT_HI_RS       => VIDEO_COUNT_HI_RS_I,
        VIDEO_COUNT_MID_RS      => VIDEO_COUNT_MID_RS_I,
        VIDEO_COUNT_LOW_RS      => VIDEO_COUNT_LOW_RS_I,

        R8006_SHADOW_RS         => R8006_RS,
        SHMOD_ST_SHADOW_RS      => SHMOD_ST_SHADOW_RS_I,
        VMODE_SHADOW_RS         => VMODE_SHADOW_RS_I,
        MEM_CONFIG_RS           => MEM_CONFIG_RS_I,
        LINE_OFFS_RS            => LINE_OFFS_RS_I,
        LINE_WIDTH_RS           => LINE_WIDTH_RS_I,

        DTACKn                  => DTACK_MCUn,

        DATA_IN                 => DATA_IN,
        DATA_OUT                => DATA_OUT_MCU,
        DATA_EN                 => DATA_EN_MCU,

        CKE                     => RAM_CKE,
        CSn                     => RAM_CSn,
        BA                      => RAM_BA,
        MAD                     => RAM_ADR,
        MAD_32                  => RAM_ADR_32,
        WEn                     => RAM_WEn,
        RASn                    => RAM_RASn,
        CASn                    => RAM_CASn,
        RAS0n                   => RAM_RAS0n,
        CAS0n                   => RAM_CAS0n,
        RAS1n                   => RAM_RAS1n,
        CAS1n                   => RAM_CAS1n,

        RAM_16MB                => RAM_16MB,
        BUS_WIDTH               => BUS_WIDTH,
        DQMn                    => RAM_DQMn,
        SIZE                    => SIZE_MCU,
        VLDn                    => VLDn
    );

    I_INTERRUPT: INTERRUPTS
    port map(
        RESET                   => RESET,
        CLK                     => CLK_32,
        ADR_HI                  => ADR_IN(19 downto 16),
        ADR_LO                  => ADR_IN(3 downto 1),
        FC                      => FC_I,
        ASn                     => ASn_IN, -- Use Combel input and not ASn_I.
        EINT1                   => EINT1,
        EINT3                   => EINT3,
        EINT5n                  => EINT5n,
        EINT7n                  => EINT7n,
        MFPINTn                 => MFPINTn,
        HINT                    => HINT,
        VINT                    => VINT,
        AVECn                   => AVECn,
        IACKn                   => IACKn,
        SCCIACKn                => SCCIACKn,
        IPLn                    => IPLn
    );

    I_ErrorHandler: ERRHANDLER
    port map(
        RESET                   => RESET,
        CLK                     => CLK_32,
        ASn                     => ASn_I,
        BERRn                   => BERR_In
    );

    I_JOYPORT: JOYPORT_PADDLES
    port map(
        CLK                     => CLK_32,
        KHz_500                 => KHz_500_I,
        RESET                   => RESET,

        RWn                     => RWn_I,
        DATA_IN                 => DATA_IN(1 downto 0),
        DATA_OUT                => DATA_OUT_JOYPORT,
        DATA_EN                 => DATA_EN_JOYPORT,

        PAD0X_RS                => PAD0X_RS_I,
        PAD0Y_RS                => PAD0Y_RS_I,
        PAD1X_RS                => PAD1X_RS_I,
        PAD1Y_RS                => PAD1Y_RS_I,

        PAD0X_INHn              => PAD0Xn,
        PAD0Y_INHn              => PAD0Yn,
        PAD1X_INHn              => PAD1Xn,
        PAD1Y_INHn              => PAD1Yn,
        PADRSTn                 => PADRSTn
    );

    I_IDE: WF_IDE
    port map(
        CLK                     => CLK_16,
        RESET                   => RESET,

        ADR                     => ADR_IN(31 downto 1),
        DATA_IN                 => DATA_IN(7 downto 0),

        ASn                     => ASn_I,
        LDSn                    => LDSn_I,
        RWn                     => RWn_I,
        DTACKn                  => DTACK_OUT_IDEn,

        -- Interrupt:
        -- HDINTn               =>, -- Not used so far.

        -- IDE section:
        IDE_INTRQ               => '0', -- Not used.
        IDE_IORDY               => '1', -- Not used.
        -- PDIAG                =>, -- Not used so far.
        -- DASP                 =>, -- See pinout above.
        -- DMARQ                =>, -- Not used so far.
        -- DMACKn               =>, -- See pinout above.
        -- IDE_RESn             =>, -- Not used.
        CS0n                    => IDE_RS0n,
        CS1n                    => IDE_RS1n,
        IORDn                   => IDE_IORDn,
        IOWRn                   => IDE_IOWRn,

        IDE_BYTESWAP            => IDE_BYTESWAP,
        IDE_D_EN_INn            => IDE_D_EN_INn,
        IDE_D_EN_OUTn           => IDE_D_EN_OUTn
      );
end STRUCTURE;
