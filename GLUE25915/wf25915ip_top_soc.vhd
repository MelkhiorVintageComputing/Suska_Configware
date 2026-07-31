------------------------------------------------------------------------
----                                                                ----
---- ATARI GLUE compatible IP Core                                  ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- Atari's ST Glue with all features to reach                     ----
---- ATARI STE compatibility.                                       ----
----                                                                ----
---- Top level file for use in systems on programmable chips.       ----
---- To guarantee proper operation of the DMA interchange between   ----
---- MCU, GLUE, DMA, the 8MHz clock edges must have a small delay   ----
---- (one logic element delay) to the clock edges of the 16MHz      ----
---- clock.                                                         ----
----                                                                ----
---- Important Notice concerning the clock system:                  ----
---- To use this code in a stand alone GLUE chip or in a system     ----
---- on a programmable chip (SOC), the clock frequency may be       ----
---- selected via the CLKSEL setting. Use CLK_8M for the original   ----
---- GLUE frequency (8MHz) or CLK_16M for the 16MHz SOC-GLUE.       ----
---- Affected by the clock selection is the video timing and the    ----
---- paddle counter in the STE enhancements file.                   ----
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
---- To Do:                                                         ----
---- -                                                              ----
----                                                                ----
---- Author(s):                                                     ----
----   Wolfgang Foerster, wf@experiment-s.de; wf@inventronik.de     ----
----   Udo Matthe, umatthe@web.de                                   ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2005... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K6A  2006/06/03 WF
--   Initial Release.
-- Revision 2K6B    2006/11/05 WF
--   Modified Source to compile with the Xilinx ISE.
--   Top level file provided for SOC (systems on programmable chips).
-- Revision 2K7A  2007/01/02 WF
--   Changes to the clock system and related
--   hardware as video timing or paddles.
-- Revision 2K8A  2008/02/13 WF
--   Version V1:
--     Introduced signal GL_DMA_SYNC.
-- Revision 2K8B  2008/12/24 WF
--   Introduced EN_RAM_14MB.
-- Revision 2K12A  20120620 WF
--   Introduced GL_STE_A4299_CS for the audio codec.
--   Removed DTACKn for the RTC_CS in ST section (validated via VPAn).
-- Revision 2K15B  20151224 WF
--   Replaced the data type bit by std_logic.
--   TOS_CONFIG is now generic.
--   CLKSEL is now generic.
-- Revision 2K20A  20200620 WF
--   Bus arbiter: changed the clock rate of the arbiter. Now it is the same as the MCU clock.
--   Bus arbiter: numerous changes in the arbiter to use The same time slices as in the MCU controller instead of SYNC states.
-- Revision 2K21A 20211224 UMA/WF
--   Address decoder, top level, package: Implemented USB1160 Chip address logic.
--   Address decoder: introduced an explicit user mode to avoid CPU space mismatch.
--   GLUE has now 32 bit address bus and address decoding.
--   Address decoder provides ALTRAM decoding.
--   Udo Matthe: changed polarity of STE_JOY_WEn to be enabled when not read.
-- Revision 2K23A 20230620 UMA
--   Implemented Udo Matthe Shadow TOS.
-- Revision 2K23B 20231224
--   Removed the ROMSEL_FC_E0n switch ROM_2n is now valid in both address spaces (UMA).
--   Fixed a SHADOW_TOS write issue (UMA).
-- Revision 2K24A 20240620
--   USB1160 has now a waitstate cycle.
--   SCC enhancements.
--

library work;
use work.wf25915ip_pkg.all;
library ieee;
use ieee.std_logic_1164.all;

entity WF25915IP_TOP_SOC is
    -- TOS operating system configuration:
    -- TOS_CONFIG = 0 for TOS 2.05 or higher in STE machines or for the 512K emuTOS ROMS.
    -- TOS_CONFIG = 1 for TOS 1.62 or lower in ST machines.
    -- TOS_CONFIG = 2 for TOS 2.05 or higher in ST machines.
        -- Explanation for the patched mode: the TOS 2.05 or 2.06 is installed on older ST machines
        -- in four 512 Mbit EPROMS. Additionally there is a part of the older TOS 1.62 or lower in
        -- two 512 Mbit EPROMS. It is patched. To get the machine working, it is necessary to control
        -- the DTACKn in a way, that it is asserted in the old TOS RAM space and in the new one. This
        -- behavior is controlled via the PATCHn. For further information, the TOS adaption is
        -- described in detail in c't 1992 Heft1; "Das zweite Gesicht" and in c't 1993 Heft 1
        -- "Teile und rueste auf".
    -- TOS_CONFIG = 4 for the Suska-III core 512K or 128K ROMs.
    -- TOS_CONFIG = 5 or higher: reserved do not select this choices; all chip selects disabled.
    generic (TOS_CONFIG : integer range 0 to 7 := 4;
             CLKSEL     : CLKSEL_TYPE := CLK_16M);
    port (
        -- Clock system:
        CLK_1                   : in std_logic; -- Originally 8MHz.
        CLK_2                   : in std_logic; -- Originally 16MHz.
        CLK_0M5                 : in std_logic; -- One sixteenth of CLK.

        -- Core address select:
        EN_RAM_14MB             : in std_logic; -- '1' = 14MB RAM address space.
        EN_ALTRAM               : in std_logic; -- '1' = ALTRAM RAM address space.

        -- Adress decoder outputs:
        ROM_6n                  : out std_logic;    -- STE.
        ROM_5n                  : out std_logic;    -- STE.
        ROM_4n                  : out std_logic;    -- ST.
        ROM_3n                  : out std_logic;    -- ST.
        ROM_2n                  : out std_logic;
        ROM_1n                  : out std_logic;
        ROM_0n                  : out std_logic;

        ACIACS                  : out std_logic;
        MFPCSn                  : out std_logic;
        SNDCSn                  : out std_logic;
        FCSn                    : out std_logic;

        STE_SNDCS               : out std_logic;    -- STE: Sound chip select.
        STE_SNDIR               : out std_logic;    -- STE: Data flow direction control.

        STE_RTCCSn              : out std_logic;    --STE only.
        STE_RTC_WRn             : out std_logic;    --STE only.
        STE_RTC_RDn             : out std_logic;    --STE only.

        -- 6800 peripheral control,
        VPAn                    : out std_logic;
        VMAn                    : in std_logic;

        DEVn                    : out std_logic;
        RAMn                    : out std_logic;
        EXT_RAMn                : out std_logic;
        DMAn                    : out std_logic;

        -- Interrupt system:
        -- Comment out AVECn for CPUs which do not provide the VMAn signal.
        AVECn                   : out std_logic;
        STE_FDINT               : in std_logic; -- Floppy disk interrupt; STE only.
        STE_HDINTn              : in std_logic; -- Hard disk interrupt; STE only.
        MFPINTn                 : in std_logic; -- ST.
        STE_EINT3n              : in std_logic; -- STE only.
        STE_EINT5n              : in std_logic; -- STE only.
        STE_EINT7n              : in std_logic; -- STE only.
        STE_DINTn               : out std_logic; -- Disk interrupt (floppy or hard disk); STE only.
        IACKn                   : out std_logic; -- ST.
        STE_IPL2n               : out std_logic; -- STE only.
        STE_IPL1n               : out std_logic; -- STE only.
        STE_IPL0n               : out std_logic; -- STE only.

        -- Video timing:
        BLANKn                  : out std_logic;
        DE                      : out std_logic;
        MULTISYNC               : in std_logic_vector(1 downto 0); -- Selection for multisync compatible video modi.
        VIDEO_HIMODE            : out std_logic;
        HSYNC_INn               : in std_logic;
        HSYNC_OUTn              : out std_logic;
        VSYNC_INn               : in std_logic;
        VSYNC_OUTn              : out std_logic;
        SYNC_OUT_EN             : out std_logic;

        -- Bus arbitration control:
        RDY_INn                 : in std_logic;
        RDY_OUTn                : out std_logic;
        BRn                     : out std_logic;
        BGIn                    : in std_logic;
        BGOn                    : out std_logic;
        BGACK_INn               : in std_logic;
        BGACK_OUTn              : out std_logic;

        -- Adress and data bus:
        ADDRESS                 : in std_logic_vector(31 downto 1);
        DATA_IN                 : in std_logic_vector(7 downto 0);
        -- ST: put the data out bus to 1 downto 0.
        -- STE: put the data out bus to 15 downto 0.
        DATA_OUT                : out std_logic_vector(15 downto 0);
        DATA_EN                 : out std_logic;

        -- Asynchronous bus control:
        RWn_IN                  : in std_logic;
        RWn_OUT                 : out std_logic;
        AS_INn                  : in std_logic;
        AS_OUTn                 : out std_logic;
        UDS_INn                 : in std_logic;
        UDS_OUTn                : out std_logic;
        LDS_INn                 : in std_logic;
        LDS_OUTn                : out std_logic;
        DTACK_INn               : in std_logic;
        DTACK_OUTn              : out std_logic;
        CTRL_EN                 : out std_logic;

        -- System control:
        RESETn                  : in std_logic;
        BERRn                   : out std_logic;

        -- Processor function codes:
        FC_IN                   : in std_logic_vector(2 downto 0);
        FC_OUT                  : out std_logic_vector(2 downto 0);

        -- STE enhancements:
        STE_FDDS                : out std_logic; -- Floppy type select (HD or DD).
        STE_FCCLK               : out std_logic; -- Floppy controller clock select.
        STE_JOY_RHn             : out std_logic; -- Read only FF9202 high byte.
        STE_JOY_RLn             : out std_logic; -- Read only FF9202 low byte.
        STE_JOY_WL              : out std_logic; -- Write only FF9202 low byte.
        STE_JOY_WEn             : out std_logic; -- Write only FF9202 output enable.
        STE_BUTTONn             : out std_logic; -- Read only FF9000 low byte.
        STE_PAD0Xn              : in std_logic;  -- Counter input for the Paddle 0X.
        STE_PAD0Yn              : in std_logic;  -- Counter input for the Paddle 0Y.
        STE_PAD1Xn              : in std_logic;  -- Counter input for the Paddle 1X.
        STE_PAD1Yn              : in std_logic;  -- Counter input for the Paddle 1Y.
        STE_PADRSTn             : out std_logic; -- Paddle monoflops reset.
        STE_PENn                : in std_logic;  -- Input of the light pen.
        STE_CPROGn              : out std_logic; -- Select signal for the STE's cache processor.

        -- SCC chip:
        SCCABn                  : out std_logic;
        SCCRDn                  : out std_logic;
        SCCWRn                  : out std_logic;
        SCCIACKn                : out std_logic;
        SCCWAITn                : in std_logic;

        -- Further enhancements:
        STE_A4299_CS            : out std_logic; -- Select signal for the Suska codec.
        USB1160_CSn             : out std_logic -- ISP1160 compatible core.
        );
end entity WF25915IP_TOP_SOC;

architecture STRUCTURE of WF25915IP_TOP_SOC is
signal DATA_OUT_VT              : std_logic_vector(1 downto 0);
signal DATA_OUT_ENH             : std_logic_vector(15 downto 0);
signal DATA_EN_VT               : std_logic;
signal DATA_EN_ENH              : std_logic;
signal ROM_6_In                 : std_logic;
signal ROM_5_In                 : std_logic;
signal ROM_4_In                 : std_logic;
signal ROM_3_In                 : std_logic;
signal ROM_2_In                 : std_logic;
signal ROM_1_In                 : std_logic;
signal ROM_0_In                 : std_logic;
signal PATCH_In                 : std_logic;
signal SNDCS_In                 : std_logic;
signal FCS_In                   : std_logic;
signal HD_REG_CS_In             : std_logic;
signal SYNCMODE_CS_In           : std_logic;
signal SHIFTMODE_CS_In          : std_logic;
signal DMA_MODE_CS_In           : std_logic;
signal DMA_In                   : std_logic;
signal BERR_In                  : std_logic;
signal VPA_In                   : std_logic; -- VPAn is used also for autovectoring (AVECn).
signal VMA_In                   : std_logic;
signal AVEC_In                  : std_logic; -- The newer MC68EC000 use this signal instead of VPAn.
signal DE_I                     : std_logic;
signal CTRL_EN_I                : std_logic;
signal AS_OUT_In                : std_logic;
signal RWn_OUT_I                : std_logic;
signal UDS_OUT_In               : std_logic;
signal LDS_OUT_In               : std_logic;
signal STE_EINT3_In             : std_logic;
signal STE_EINT5_In             : std_logic;
signal STE_EINT7_In             : std_logic;
signal RTCCS_In                 : std_logic;
signal JOY_CS_I                 : std_logic;
signal PAD0X_CS_I               : std_logic;
signal PAD0Y_CS_I               : std_logic;
signal PAD1X_CS_I               : std_logic;
signal PAD1Y_CS_I               : std_logic;
signal BUTTON_CS_I              : std_logic;
signal XPEN_REG_CS_I            : std_logic;
signal YPEN_REG_CS_I            : std_logic;
signal SCCn                     : std_logic;
signal STE_PAD0X_In             : std_logic;
signal STE_PAD0Y_In             : std_logic;
signal STE_PAD1X_In             : std_logic;
signal STE_PAD1Y_In             : std_logic;
signal STE_PEN_In               : std_logic;
signal STE_CPROG_In             : std_logic;
signal BR_In                    : std_logic;
signal VIDEO_HIMODE_I           : std_logic;
signal RAM_In                   : std_logic;
signal A4299_CS_I               : std_logic;
signal USB1160_CS_In            : std_logic;
signal USB1160_RDY              : std_logic;
signal MCURAM_In                : std_logic;
signal ADR_IN                   : std_logic_vector(31 downto 0);
signal SHADOW_TOS_CSn_I         : std_logic;
signal LIGHTNING_CSn_I          : std_logic;
signal LIGHTNING_REG            : std_logic_vector(7 downto 0);
signal LIGHTNINGDATA_EN         : std_logic;
signal SHADOW_CONFIG            : std_logic_vector(7 downto 0);
signal SHADOWDATA_EN            : std_logic;
signal ALTRAM_In                : std_logic;
signal EN_RAM_14MB_I            : std_logic;

alias SHADOW_TOSn               : std_logic is SHADOW_CONFIG(0);  -- 0 = ShadowTOS active / 1 = FlashTOS active
alias SHADOW_TOS_WEn            : std_logic is SHADOW_CONFIG(1);  -- 0 = ShadowTOS rw / 1 = ShadowTOS readonly
alias SHADOW_CARTn              : std_logic is SHADOW_CONFIG(2);  -- 0 = ShadowCART active / 1 = FlashCART active
alias SHADOW_CART_WEn           : std_logic is SHADOW_CONFIG(3);  -- 0 = ShadowCART rw / 1 = ShadowCART readonly
alias SHADOW_EN_RAM_14MB        : std_logic is SHADOW_CONFIG(6);  -- 0 = RAM_14MB switch valid / 1 = 14MB always active
alias SHADOW_ALTRAMn            : std_logic is SHADOW_CONFIG(7);  -- 0 = 48MB possible / 1 = no Alram active
begin

    ADR_IN <= ADDRESS & '0';

    -- TOS configuration:
    -- The configuration of the TOS operating system is done in the
    -- wf25915ip_adrdec file via a generic statement.
    -- Have a look at the beginning of the entity in this file.

    -- Configuration:
    --------------------------------------------
    -- Comment these lines out for ST features:
    --  STE_EINT3n  <= '1';
    --  STE_EINT5n  <= '1';
    --  STE_EINT7n  <= '1';
    --  STE_PAD0Xn  <= '1';
    --  STE_PAD0Yn  <= '1';
    --  STE_PAD1Xn  <= '1';
    --  STE_PAD1Yn  <= '1';
    --  STE_PENn    <= '1';
    --  DATA_OUT <= DATA_OUT_VT;
    --  DATA_EN     <= DATA_EN_VT;
    --------------------------------------------
    -- Comment these lines out for STE features:
    STE_EINT3_In    <= STE_EINT3n;
    STE_EINT5_In    <= STE_EINT5n;
    STE_EINT7_In    <= STE_EINT7n;
    STE_PEN_In      <= STE_PENn;
    STE_PAD0X_In    <= STE_PAD0Xn;
    STE_PAD0Y_In    <= STE_PAD0Yn;
    STE_PAD1X_In    <= STE_PAD1Xn;
    STE_PAD1Y_In    <= STE_PAD1Yn;


    DATA_OUT <= DATA_OUT_ENH when DATA_EN_ENH = '1' else
                x"000" & "00" & DATA_OUT_VT when DATA_EN_VT = '1' else
                SHADOW_CONFIG & x"00" when SHADOWDATA_EN = '1' else
                LIGHTNING_REG & LIGHTNING_REG when LIGHTNINGDATA_EN = '1' else (others => '0');

    DATA_EN <= DATA_EN_ENH or DATA_EN_VT or SHADOWDATA_EN or LIGHTNINGDATA_EN or SHADOWDATA_EN;

    LIGHTNINGDATA_EN <= '1' when RWn_IN = '1' and LIGHTNING_CSn_I = '0' else '0';
    SHADOWDATA_EN <= '1' when RWn_IN = '1' and SHADOW_TOS_CSn_I = '0' else '0'; 
     

    STE_DINTn <= '1' when STE_HDINTn = '1' and STE_FDINT = '0' else '0';
    STE_SNDCS <= '1' when SNDCS_In = '0' and ADDRESS(1) = '0' else '0';
    STE_SNDIR <= '1' when RWn_IN = '0' and SNDCS_In = '0' else '0';
    STE_RTCCSn <= RTCCS_In;
    STE_RTC_RDn <= '0' when RWn_IN = '1' and LDS_INn = '0' and VMA_In = '0' else '1';
    STE_RTC_WRn <= '0' when RWn_IN = '0' and LDS_INn = '0' and VMA_In = '0' else '1';
    STE_JOY_RHn <= '0' when JOY_CS_I = '1' and RWn_IN = '1' and UDS_INn = '0' else '1';
    STE_JOY_RLn <= '0' when JOY_CS_I = '1' and RWn_IN = '1' and LDS_INn = '0' else '1';
    STE_JOY_WL <= '1' when JOY_CS_I = '1' and RWn_IN = '0' and LDS_INn = '0' else '0';
    STE_JOY_WEn <= '1' when JOY_CS_I = '1' and RWn_IN = '1' and LDS_INn = '0' else '0';
    STE_BUTTONn <= '0' when BUTTON_CS_I = '1' else '1';
    --------------------------------------------
    -- Comment these lines out for Suska features:
    STE_A4299_CS <= A4299_CS_I;
    USB1160_CSn <= USB1160_CS_In;
    --------------------------------------------
    -- End configuration

    DE <= DE_I;
    VIDEO_HIMODE <= VIDEO_HIMODE_I;

    CONTROL_REGISTERS: process
    -- Dummy Lightning CPLD Register
    -- SHADOW configuration register.
    variable LOCK  : boolean;
    begin
        wait until CLK_2 = '0' and CLK_2' event;
        if LIGHTNING_CSn_I = '0' and RWn_IN = '0' then
            LIGHTNING_REG <= DATA_IN;
        end if;
        
        if RESETn = '0' and LOCK = false then
            SHADOW_CONFIG <= "00111111"; -- One time initialization.
            LOCK := true;
        elsif RWn_IN = '0' and SHADOW_TOS_CSn_I = '0' then
            SHADOW_CONFIG <= DATA_IN;
        end if;
    end process CONTROL_REGISTERS;

    EN_RAM_14MB_I <= EN_RAM_14MB or SHADOW_EN_RAM_14MB;

    EXT_RAMn <= '0' when SHADOW_ALTRAMn = '0' and ALTRAM_In = '0' and EN_ALTRAM = '1' else -- ALTRAM portion.
                SHADOW_CARTn and SHADOW_TOSn and SHADOW_TOS_WEn and SHADOW_CART_WEn; -- Shadow RAM portion.

    RAMn <= RAM_In;

    RAM_In <= '0' when ALTRAM_In = '0' and SHADOW_ALTRAMn = '0' and EN_ALTRAM = '1' else
              '0' when SHADOW_CARTn = '0' and ROM_6_In = '0' else  -- Read cartridge RAM.
              '0' when SHADOW_CARTn = '0' and ROM_5_In = '0' else  -- Read cartridge RAM.  
              '0' when SHADOW_CARTn = '0' and ROM_4_In = '0' else  -- Read cartridge RAM.
              '0' when SHADOW_CARTn = '0' and ROM_3_In = '0' else  -- Read cartridge RAM.
              '0' when SHADOW_TOSn = '0'  and ROM_2_In = '0' else  -- Read TOS RAM.
              '0' when SHADOW_TOSn = '0' and ADR_IN >= x"00E00000" and ADR_IN < x"00E80000" and AS_INn = '0' and RWn_IN = '1' else  -- Read TOS RAM.
              '0' when SHADOW_TOSn = '1' and ADR_IN <  x"00000008"    and AS_INn = '0' and RWn_IN = '0' and  SHADOW_TOS_WEn  = '0' else -- write TOS mirroring to Shadow RAM.
              '0' when ADR_IN >= x"00E00000" and ADR_IN < x"00E80000" and AS_INn = '0' and RWn_IN = '0' and  SHADOW_TOS_WEn  = '0' else -- write E00000-E7FFFF RAM.
              '0' when ADR_IN >= x"00FC0000" and ADR_IN < x"00FF0000" and AS_INn = '0' and RWn_IN = '0' and  SHADOW_TOS_WEn  = '0' else -- write FC0000-FEFFFF RAM.
              '0' when ADR_IN >= x"00FA0000" and ADR_IN < x"00FC0000" and AS_INn = '0' and RWn_IN = '0' and  SHADOW_CART_WEn = '0' else  -- write FA0000-FBFFFF Cartridge RAM.
              MCURAM_In;

    BRn <= BR_In;

    BERRn <= BERR_In;
    AVECn <= AVEC_In;
    -- Use the following statement for CPUs which do provide the AVECn signal.
    VPAn <= '0' when VPA_In = '0' else '1';
    -- Use the following statement for CPUs not providing the AVECn signal:
    --  VPAn <= '0' when VPA_In = '0' else
    --          '0' when AVEC_In = '0' else '1';

    VMA_In <= VMAn;

    ROM_6n <= ROM_6_In when SHADOW_CARTn = '1' else '1';
    ROM_5n <= ROM_5_In when SHADOW_CARTn = '1' else '1';
    ROM_4n <= ROM_4_In when SHADOW_CARTn = '1' else '1';
    ROM_3n <= ROM_3_In when SHADOW_CARTn = '1' else '1';
    ROM_2n <= ROM_2_In when SHADOW_TOSn = '1'  else '1';
    ROM_1n <= ROM_1_In when SHADOW_TOSn = '1'  else '1';
    ROM_0n <= ROM_0_In when SHADOW_TOSn = '1'  else '1';

    SNDCSn <= SNDCS_In;
    FCSn <= FCS_In;
    DMAn <= DMA_In;

    -- Comment out for ST:
    -- There are no DTACKn for SHIFTMODE register x"8260" and DMA_MODE
    -- register x"8606" necessary, because SHIFTMODE is a mirror
    -- register of the SHIFTER and DMA_MODE is a shadow of the DMA chip
    -- register. The DTACKn is done for the SHIFTMODE via SHIFTER register
    -- control and for the DMA_MODE via the DMA's RDYn control signal.
    -- During FDC access RDYn indicates DTACKn. The RTC is validated by VPAn.
    --  DTACK_OUTn <=   '0' when ROM_4_In = '0'         else
    --                  '0' when ROM_3_In = '0'         else
    --                  '0' when ROM_2_In = '0'         else
    --                  '0' when ROM_1_In = '0'         else
    --                  '0' when ROM_0_In = '0'         else
    --                  '0' when PATCH_In = '0'         else
    --                  '0' when SNDCS_In = '0'         else
    --                  '0' when SYNCMODE_CS_In = '0'   else
                        -- RDYn indicates FDC ok:
    --                  '0' when FCS_In = '0' and RDY_INn = '1' else '1';

    -- Comment out for STE / Suska:
    -- There are no DTACKn for SHIFTMODE register x"8260" and DMA_MODE
    -- register x"8606" necessary, because SHIFTMODE is a mirror
    -- register of the SHIFTER and DMA_MODE is a shadow of the DMA chip
    -- register. The DTACKn is done for the SHIFTMODE via SHIFTER register
    -- control and for the DMA_MODE via the DMA's RDYn control signal.
    -- During FDC access RDYn indicates DTACKn. The RTC is validated by VPAn.
    DTACK_OUTn <= '0' when ROM_6_In = '0' and SHADOW_CARTn = '1' else
                  '0' when ROM_5_In = '0' and SHADOW_CARTn = '1' else
                  '0' when ROM_4_In = '0' and SHADOW_CARTn = '1' else
                  '0' when ROM_3_In = '0' and SHADOW_CARTn = '1' else
                  '0' when ROM_2_In = '0' and SHADOW_TOSn = '1' else
                  '0' when PATCH_In = '0'                 else
                  '0' when SNDCS_In = '0'                 else
                  '0' when SYNCMODE_CS_In = '0'           else
                  '0' when HD_REG_CS_In = '0'             else
                  '0' when SCCn = '0' and SCCWAITn = '1'  else
                  '0' when STE_CPROG_In = '0'             else
                  '0' when JOY_CS_I = '1'                 else
                  '0' when PAD0X_CS_I = '1'               else
                  '0' when PAD0Y_CS_I = '1'               else
                  '0' when PAD1X_CS_I = '1'               else
                  '0' when PAD1Y_CS_I = '1'               else
                  '0' when BUTTON_CS_I = '1'              else
                  '0' when XPEN_REG_CS_I = '1'            else
                  '0' when YPEN_REG_CS_I = '1'            else
                  '0' when USB1160_RDY = '1'              else
                  '0' when SHADOW_TOS_CSn_I = '0'         else
                  '0' when SHADOW_TOS_CSn_I = '0'         else
                  '0' when LIGHTNING_CSn_I = '0'          else
                  '0' when A4299_CS_I = '1'               else -- Comment out for Suska.
                  -- RDYn indicates FDC ok:
                  '0' when FCS_In = '0' and RDY_INn = '1' else '1';

    -- Serial communication controller:
    SCCRDn <= '0' when SCCn = '0' and RWn_IN = '1' else '1';
    SCCWRn <= '0' when SCCn = '0' and RWn_IN = '0' else '1';

    P_WAITSTATES: process
    -- The latency of the USB controller is in case of
    -- operating ISO and ATL transfer too long for a non
    -- delayed bus cycle. For more information refer to 
    -- the USB1160 top level header.
    begin
        wait until CLK_1 = '1' and CLK_1' event;
        USB1160_RDY <= not USB1160_CS_In;
    end process P_WAITSTATES;

    -- Bus controls (three state):
    AS_OUTn <= AS_OUT_In when CTRL_EN_I = '1' else '0';
    RWn_OUT <= RWn_OUT_I when CTRL_EN_I = '1' else '0';
    UDS_OUTn <= UDS_OUT_In when CTRL_EN_I = '1' else '0';
    LDS_OUTn <= LDS_OUT_In when CTRL_EN_I = '1' else '0';
    CTRL_EN <= CTRL_EN_I;

    -- STE stuff:
    STE_CPROGn <= STE_CPROG_In;

    I_INTERRUPT: WF25915IP_INTERRUPTS
    port map(
        RESETn          => RESETn,
        CLK             => CLK_1,
        ADR_HI          => ADDRESS(19 downto 16),
        ADR_LO          => ADDRESS(3 downto 1),
        FC              => FC_IN,
        ASn             => AS_INn,
        EINT3n          => STE_EINT3_In, -- STE GLUE.
        EINT5n          => STE_EINT5_In, -- STE GLUE.
        EINT7n          => STE_EINT7_In, -- STE GLUE.
        MFPINTn         => MFPINTn,
        HSYNCn          => HSYNC_INn,
        VSYNCn          => VSYNC_INn,
        VIDEO_HIMODE    => VIDEO_HIMODE_I,
        AVECn           => AVEC_In,
        IACKn           => IACKn,
        SCCIACKn        => SCCIACKn,
        -- GI2n         => , -- ST GLUE, not used.
        -- GI1n         => , -- ST GLUE, not used.
        IPLn(2)         => STE_IPL2n, -- STE GLUE.
        IPLn(1)         => STE_IPL1n, -- STE GLUE.
        IPLn(0)         => STE_IPL0n  -- STE GLUE.
    );

    I_ADRDEC: WF25915IP_ADRDEC
    generic map(TOS_CONFIG => TOS_CONFIG)
    port map(
        ADR             => ADDRESS,
        RWn             => RWn_IN,

        RESETn          => RESETn,

        EN_RAM_14MB     => EN_RAM_14MB_I,

        LDSn            => LDS_INn,
        UDSn            => UDS_INn,

        ASn             => AS_INn,
        VPAn            => VPA_In,
        VMAn            => VMA_In,

        FC              => FC_IN,

        DMAn            => DMA_In,

        ROM_0n          => ROM_0_In,
        ROM_1n          => ROM_1_In,
        ROM_2n          => ROM_2_In,
        ROM_3n          => ROM_3_In,
        ROM_4n          => ROM_4_In,
        ROM_5n          => ROM_5_In,
        ROM_6n          => ROM_6_In,
        PATCHn          => PATCH_In,

        ACIACS          => ACIACS,
        MFPCSn          => MFPCSn,
        SNDCSn          => SNDCS_In,
        A4299_CS        => A4299_CS_I,
        FCSn            => FCS_In,
        SCCn            => SCCn,
        SCCABn          => SCCABn,
        CPROGn          => STE_CPROG_In,
        HD_REG_CSn      => HD_REG_CS_In,
        RTCCSn          => RTCCS_In,
        SYNCMODE_CSn    => SYNCMODE_CS_In,
        SHIFTMODE_CSn   => SHIFTMODE_CS_In,
        DMA_MODE_CSn    => DMA_MODE_CS_In,

        JOY_CS          => JOY_CS_I,

        PAD0X_CS        => PAD0X_CS_I,
        PAD0Y_CS        => PAD0Y_CS_I,
        PAD1X_CS        => PAD1X_CS_I,
        PAD1Y_CS        => PAD1Y_CS_I,

        BUTTON_CS       => BUTTON_CS_I,

        XPEN_REG_CS     => XPEN_REG_CS_I,
        YPEN_REG_CS     => YPEN_REG_CS_I,

        USB1160_CSn     => USB1160_CS_In,
        SHADOW_TOS_CSn  => SHADOW_TOS_CSn_I,
        Lightning_CSn   => LIGHTNING_CSn_I,

        DEVn            => DEVn,
        RAMn            => MCURAM_In,
        ALTRAMn         => ALTRAM_In
    );

    I_VIDEO: WF25915IP_VIDEO_TIMING
    generic map(CLKSEL  => CLKSEL)
    port map(
        RESETn          => RESETn,
        CLK             => CLK_1,

        DATA_IN         => DATA_IN,
        DATA_OUT        => DATA_OUT_VT,
        DATA_EN         => DATA_EN_VT,
        RWn             => RWn_IN,
        SYNCMODE_CSn    => SYNCMODE_CS_In,
        SHIFTMODE_CSn   => SHIFTMODE_CS_In,
        DE              => DE_I,
        MULTISYNC       => MULTISYNC,
        VIDEO_HIMODE    => VIDEO_HIMODE_I,
        BLANKn          => BLANKn,

        VSYNC_INn       => VSYNC_INn,
        HSYNC_INn       => HSYNC_INn,
        VSYNC_OUTn      => VSYNC_OUTn,
        HSYNC_OUTn      => HSYNC_OUTn,
        SYNC_OUT_EN     => SYNC_OUT_EN
    );

    I_ErrorHandler: WF25915IP_ERRHANDLE
    port map(
        RESETn      => RESETn,
        CLK         => CLK_1,
        ASn         => AS_INn,
        BERRn       => BERR_In
    );

    I_Arbitration: WF25915IP_BUS_ARBITER
    port map(
        RESETn          => RESETn,
        CLK             => CLK_2, -- We use the same clock like the MCU.

        D8              => DATA_IN(0), -- Input only.

        RAMn            => RAM_In,
        DTACKn          => DTACK_INn,

        AS_INn          => AS_INn,
        AS_OUTn         => AS_OUT_In,
        RWn_OUT         => RWn_OUT_I,
        LDS_OUTn        => LDS_OUT_In,
        UDS_OUTn        => UDS_OUT_In,
        FC_OUT          => FC_OUT,
        CTRL_EN         => CTRL_EN_I,

        DMA_MODE_CSn    => DMA_MODE_CS_In,

        RDY_INn         => RDY_INn,
        RDY_OUTn        => RDY_OUTn,
        BGACK_INn       => BGACK_INn,
        BGACK_OUTn      => BGACK_OUTn,
        BRn             => BR_In,
        BGIn            => BGIn,
        BGOn            => BGOn,
        DMAn            => DMA_In
    );

    I_STE_ENHANCEMENTS: WF25915IP_STE_ENH
    generic map(CLKSEL  => CLKSEL)
    port map(
        CLK             => CLK_1,
        CLK_0M5         => CLK_0M5,
        RESETn          => RESETn,

        RWn             => RWn_IN,
        DATA_IN         => DATA_IN(1 downto 0),
        DATA_OUT        => DATA_OUT_ENH,
        DATA_EN         => DATA_EN_ENH,

        HD_REG_CSn      => HD_REG_CS_In,
        FDDS            => STE_FDDS,
        FCCLK           => STE_FCCLK,

        PAD0X_CS        => PAD0X_CS_I,
        PAD0Y_CS        => PAD0Y_CS_I,
        PAD1X_CS        => PAD1X_CS_I,
        PAD1Y_CS        => PAD1Y_CS_I,

        PAD0X_INHn      => STE_PAD0X_In,
        PAD0Y_INHn      => STE_PAD0Y_In,
        PAD1X_INHn      => STE_PAD1X_In,
        PAD1Y_INHn      => STE_PAD1Y_In,
        PADRSTn         => STE_PADRSTn,

        XPEN_REG_CS     => XPEN_REG_CS_I,
        YPEN_REG_CS     => YPEN_REG_CS_I,

        HSYNCn          => HSYNC_INn,
        VSYNCn          => VSYNC_INn,
        DE              => DE_I,

        PENn            => STE_PEN_In
    );
end STRUCTURE;
