------------------------------------------------------------------------
----                                                                ----
---- Atari STE compatible IP Core                                   ----
----                                                                ----
---- This file is part of the SUSKA ATARI clone project.            ----
---- http://www.experiment-s.de                                     ----
----                                                                ----
---- Description:                                                   ----
---- This model provides the top level file of an STE compatible    ----
---- machine including CPU, Blitter, Shadow, MCU, DMA, FDC,         ----
---- Shifter, GLUE, MFP, SOUND, ACIA and RTC.                       ----
----                                                                ----
---- Important Notice concerning the clock system:                  ----
---- The systems of the original ST or STE machines used several    ----
---- clocks which must stand in a fixed relation to each other.     ----
---- This core uses one central system clock of 16MHz. From this    ----
---- clock all required clocks are derived. These are CLK_1,        ----
---- CLK_2 and CLK_3. These are the clocks used for clocking        ----
---- D type flip-flops of the system and are provided by a first    ----
---- phase locked loop circuit.                                     ----
---- The clocks should used as follows:                             ----
---- CLK_1 for the BLITTER, GLUE, DMA, MFP, 1772, SOUND and UARTs.  ----
---- CLK_2 for the CPU, MCU, SHIFTER, the video RAM component and   ----
---- the external SD-RAMs and the memory data buffer.               ----
---- CLK_3 for the USB1160 unit.                                    ----
---- Beside these 'real' clocks, there are several auxiliary        ----
---- clocks which are processed by one of the above mentioned       ----
---- clocks (CLK_1, CLK_2). There are two clocks SCLK_6M4 and       ----
---- CLK_2M4576 which are provided by a second phase locked loop    ----
---- and a counter process. The SCLK_6M4 controls the DMA sound     ----
---- module whereas the CLK_2M4576 is responsible for a correct     ----
---- timing of the MFP. The clocks are outputs of the counter       ----
---- process for their frequency is too low to provide it directly  ----
---- by a phase locked loop.                                        ----
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
---- SD-RAM section: This core provides a memory of 16MByte ST RAM  ----
----   and aditionally 64MB ALTRAM. The ALTRAM is switched by the   ----
----   OS selector configuration switch. See the info concerning    ----
----   the configuration switch in this file header.                ----
----                                                                ----
---- ACSI/SCSI section:                                             ----
----   The ACSI / SCSI interface of this core is legacy. For        ----
----     more information see the WF_ACSI_SCSI_IF component.        ----
----   Since release 2K13B of this core, the WF5380 SCSI con-       ----
----     troller of the TT machines and Falcons is supported with   ----
----     some limitations: 1. the WF5380 is working as initiator in ----
----     the Suska-III-C hardware. A target role is not possible.   ----
----     2. There are some limitations concerning the electrical    ----
----     interface of Suska-III-C. Refer to the schematics of the   ----
----     board for more information. 3. The SCSI_ATNn signal is now ----
----     routed to the INIT_DONE pin. For this purpose INIT_DONE is ----
----     now disabled. If the SCSI Message system in conjunction    ----
----     with SCSI_ATNn is intended to be used, route the signal    ----
----     according to the SCSI specification to the 25 pos. D-SUB   ----
----     SCSI connector. Be aware, that the signal SCSI_MSGn is a   ----
----     unidirectional signal on the Suska-III-C board. Updates to ----
----     the hardware may change these lacks.                       ----
----   The SCSI_IDn is a switch to select the initiator ID of       ----
----     the SCSI controller of this core. It is inverted, so use   ----
----     weak pull up resistors for it and connect the switch to    ----
----     GND. In this case (all switches on) the SCSI_IDn of        ----
----     "000" will indicate the highest initiator id of 7.         ----
----   Recommendings for the hardware target concerning the SCSI    ----
----    interface:                                                  ----
----     Use for the outputs non inverting buffers ('541).          ----
----     Use for the data in/outputs tri state buffers ('245).      ----
----     Select for the input / output buffers a supply of 3.3V.    ----
----     The VCCIO voltage of the selected FPGAs should also be     ----
----     at 3.3V for the related interface lines.                   ----
----                                                                ----
---- IDE interface:                                                 ----
----   Use a 16 bit wide LVTTL tri state drivers to control the     ----
----   data direction from or to an IDE device.                     ----
----   The IDE_D_EN_INn and IDE_D_EN_OUTn outputs are the           ----
----     respective tri state enables where IDE_D_EN_INn controls   ----
----     the tri state for the read operation from an IDE device    ----
----     and IDE_D_EN_OUTn controls the write operation to an       ----
----     IDE device.                                                ----
----   Select for the output buffers a supply of +5V.               ----
----   Select for the input buffers a supply of VCCIO of the        ----
----     selected programmable logic device.                        ----
----   The following is tested with HDDRIVER (11.01):               ----
----   If you want to boot from the IDE device then select false.   ----
----   No Windows compatibility. If you want Windows compatibility  ----
----   select true. TOS does not boot from IDE.                     ----
----                                                                ----
---- SD card interface:                                             ----
----   The interface is based on the project 'SatanDisk' of         ----
----   Miroslav Nohaj 'Jookie'. Use a clock frequency of 16MHz      ----
----   for this component. Use the same clock frequency for the     ----
----   connected AVR microcontroller.                               ----
----                                                                ----
---- Recommendations for the signal termination:                    ----
----   The following signals should be terminated with a weak       ----
----   pull up resistor (~22K). Use either weak pull up resistors   ----
----   of the FPGAs or external ones:                               ----
----     DATA, ADR, FC.                                             ----
----   Use for the following signals strong pull up resistors       ----
----   with a value of about 6K8:                                   ----
----     ASn, RWn, UDSn, LDSn, DTACKn, BGACKn, BRn,                 ----
----     EINT3, EINT5, EINT7.                                       ----
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
---- The configuration switches for this core are as follows:       ----
----                                                                ----
---- Config Switch 1 and 2 (1 is leftmost on the C board) are       ----
---- intended to select the video mode in sense of resolution and   ----
---- colour as follows:                                             ----
----   "11" : We use an RGB colour monitor. (15kHz@50Hz)            ----
----   "10" : We use a VGA monitor with colour modi. (31kHz@50Hz)   ----
----   "01" : 72Hz compatible modi. (35kHz@72Hz)                    ----
----   "00" : We use a monochrome monitor or VGA monochrome mode.   ----
----   Remark: if SM124 is connected this selector has no effect.   ----
----                                                                ----
----   CONFIG(3): On = 68K10 CPU, Off = 68K00 CPU.                  ----
----   CONFIG(4): On = 14MB RAM, Off = 4MB RAM.                     ----
----   CONFIG(5): On = ALTRAM for ALTRAM capable operating systems. ----
----              ALTRAM is disabled for Config(4) = off.           ----
----   CONFIG(6): reserved for future use.                          ----
----                                                                ----
------------------------------------------------------------------------
----                                                                ----
---- Copyright © 2006... Wolfgang Foerster - Inventronik GmbH.      ----
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
-- Revision 2K6B  2006/12/24 WF
--   Initial Release.
-- Revision 2K7B  2007/12/24 WF
--   Replaced the external SHADOW video ram by an internal component.
--   Connected the UARTs (CTSn and DCDn) to pins.
-- Revision 2K8A  2008/07/14 WF
--   Replaced the original MCU (25912) by a MCU capable driving the
--   SD-RAMs used in the Suska-III hardware.
--   Changes to run on the Suska hardware platform.
-- Revision 2K8B  2008/12/24 WF
--   Introduced EN_RAM_14MB.
-- Revision 2K9A  2009/06/20 WF
--   Enhancements in the video system to drive modern TFTs or multisyncs.
--   The RESETn pin is not asserted by the RESET_BOOTn any more but by
--     the FLASH_RESETn. This change was necessary because the FLASH's
--     reset is on the series boards connected to the system reset.
--   New: PLL_ARESET logic for resetting the phase locked loops during
--     system startup.
--   New: Clock synchronization in the MCU control file (process TIME_SLICES).
--   New: Clock synchronization in the WF25914IP_CR_SHIFT_REG.
--   Changed LATCHn behaviour in the MCU control file.
--   New: process SLOW_CPU for lowering the CPU speed (compatibility reasons).
--   Fixed interrupt polarity for TA_I and TB_I in the MFP core.
--   Minor improvements in the MFP timer section.
--   Several fixes concerning colour corrections in the Shifter's chroma shift registers.
--   Fixed CPU exception processing to improve system startup.
--   A couple of minor bug fixes.
-- Revision 2K9B  2009/12/24 WF
--   RESET_INn is now SYS_RESET_INn in the MCU top level file.
--   RESET_OUTn is now SYS_RESET_OUTn in the MCU top level file.
--   Replaced RESETn filter by new RESET_INn in the MCU top level file.
--   Renamed the comp sync signal SH_COLOR to SH_CSYNCn.
--   Removed DMAn in the module WF_IDE.
--   Changed the MDAT_BUFFER clock from 64MHz to 32MHz due to better stability.
--   Fixed 68000 bus interface: UDSn and LDSn logic not working correct with waitstates in some cases.
--   Changed UNLK A7 logic due to compatibility reasons with MC68000 in the module wf68k00ip_control.
--   Fixed a timing bug in the 68K00 bus arbitration state register.
--   Small improvement the process TIME_SLICES in module wf25912ip_ctrl.
--   Linewidth correction in wf25912ip_video_counter_sd.
--   Bugfix in the BANK_SWITCH concerning 14MB of memory in the MCU control file.
--   Numerous changes in wf25913ip_ctrl due to new wf25915ip_bus_arbiter_v2. These changes result
--    wf25915ip_bus_arbiter_v2.
--   Changed timing of SECT_CNT_ZEROn in module wf25913_registers.
--   Fixed a bug in the sector counter in module wf25913_registers.
--   Fixed bus access timing in module wf25913_registers.
--   Introduced CTRL_SRC_SEL in the wf25913 registers and top level.
--   Replaced port DMA_SRC_SEL by DRIVE_SEL in the wf25913 top level to meet better ACSI bus timing.
--   New modeling of FIFO_HI in the DMA FIFO control section to meet the requirements for the new DMA controller.
--   Adjusted FIFO_LOW in the DMA FIFO control section due to new FIFO_HI.
--   Fixed DMA_EN logic and replaced DMA_RDn, DMA_WRn by DMA_EN in the DMA register section.
--   Removed the unneccesary DMA_LOCKn in the module wf25915ip_adrdec.
--   Changes in the related package and top level files to meet the new wf25915ip_bus_arbiter_V1.
--   IACKn is now also locked by ASn in the module wf25915ip_interrupts.
--   Fixed a FCSn bug in the GLUE's address decoding.
--   Fixed a DMA_MODE_CSn bug in the GLUE's address decoding.
--   Fixed a bug in the GLUE bus arbiter's BRn_LOGIC process not to start the DMA operation unintendedly.
--   Removed DMA_LOCKn in the module wf25915ip_interrupts.
--   Partially rewritten the wf25915ip_bus_arbiter_V1, removed DMA_SYNC again (not necessary any longer).
--    these changes results in version wf25915ip_bus_arbiter_v2.
--   Fixed the interrupt logic in the module wf6850ip_ctrl_status.
--   Introduced a minor RTSn correction in the module wf6850ip_ctrl_status.
--   Fixed the timing for DR_LOAD in the 1772 control section.
-- Revision 2K10A  20010/06/20 WF
--   Changed logic in the 25912 control section to enable the 14MB RAM. Introduced EN_RAM_14MB therefore .
--   Changed DTACKn logic to enable 14MB correctly in the 25912 control section.
--   Reduced MCU_ADR from 25 to 23 bits in this file.
--   Several minor changes in the 68K00 to meet better design tool compatibility.
--   Several changes to meet better compatibility with SCSI-II devices in the module WF_ACSI_SCSI_IF_SOC.
--   Fixes in this top level concerning SCSI_WR, SCSI_RD and SCSI_DPn (SCSI_DP_OUT).
--   Fixed VMAn for RTC access in the GLUE address register section.
--   Several fixes in all WF5C15_139xIP_.. files to get the RTC working properly.
--   Modified the IDE bus access to achieve TOS/PC compatibility with bootable CF cards under TOS.
-- Revision 2K10B  2010/12/27 WF
--   Introduced screen resolution switch SEL_640x400 in the shadow unit.
--   Shadow control section: several optimizations to meet the operation of the LCD with 640x400 resolution.
--   Shadow FIFO unit: changed the data output from pipelined to unpipelined.
--   Changed entity name WF_SD_CARD to WF_ACSI_SDC.
--   A bunch of changes in the Shifter's microwire interface.
--   Changes concerning the monochrome monitor detection in the 25912 top level file.
--   A bunch of changes in the MMU DMA sound control logic.
--   Completely rewritten the DMA sound control logic in the SHIFTER module.
--   There is now a FIFO with a depth of 4 and a width of 16 bits in the SHIFTER's DMA sound control.
--   Minor changes in the MMU control logic concerning the DMA sound.
--   Changes in this top level concerning DMA sound control respective the monochrome detection.
--   25912 top level: minor modification concerning the changes of the DMA sound module.
--   25912 address decoder: Removed the colour monitor processor access for the addressx "8901" because
--   the DMA sound control register resides in the 25912 MCU DMA sound control logic.
--   Several behavioural changes in the audio DAC module.
--   Modified the audio DAC module by introduction of FCLK (this fixes distorted sound).
-- Revision 2K11A 20110620 WF
--   A minor change in the data readback logic of the 68901 timers (RWn is now taken into consideration).
--   Cleaned up the condition code logic in the 68K00 shifter section.
-- Revision 2K11B 20111226 WF
--   Fixed some 68K00 items.
--   RTC5C15-139x control: minor changes to improve data integrity.
--   Fixed an error in the register section of the RTC5C15 module concerning the FORMAT_12_24n flag.
--   Set STARTUP to 250ms in the flash loader module.
--   101775ip_ctrl: Changed to synchronous reset in the LCD_TIMING section.
--   Introduced a temporary fix in this top level concerning RESET_Sn.
-- Revision 2K12A  20120620 WF
--   GLUE: Introduced GL_STE_A4299_CS for the audio codec.
--   WF_RTC5C15 registers: changed TIMER_EN to EOSCn with inverted functionality.
--   New feature: Release of the CS4299 audio codec AC97 controller (WF_SND4299).
--   Removed DTACKn for the RTC_CS in ST section (validated via VPAn) in the GLUE top level.
--   Glue address register section: minor change concerning CMPCSn (UDSn locked now).
--   MCU DMA control: readback of the DMA base and counter register is now 24 bit wide.
--   MCU DMA sound module: a minor change concerning SINTn.
--   Changed the SDATA_L and SDATA_R from linear to 2's complement.
--   Changes in WF_AUDIO_DAC due to audiodata is now 2's complement.
--   GPIP_IN(7) is now: SINT_IO7 or INT_4299.
--   WF_ACSI_SCSI_IF_SOC: implementation of selection timeout.
--   WF_ACSI_SCSI_IF_SOC: provided LINK97 compatibility (see SCSI_MODE).
--   RTC5C15-139x control: minor changes to improve data integrity.
--   Fixed some compatibility issues to the RP5C15 in WF5C15_139xIP_REGISTERS.
--   WF6850IP_RECEIVE: Removed a latch driving PE.
-- Revision 2K12B 20121224 WF
--   WF_ACSI_SCSI_IF_SOC: Introduced the SLOW_MODE to achieve boot capability with TOS.
--   25913 controller: removed some old stuff (package counter).
-- Revision 2K13A 20130620 WF
--   Minor changes in WF_ACSI_SCSI_IF_SOC to improve data integrity (DATA_BUFFER).
--   Improvements in WF_ACSI_SCSI_IF_SOC concerning compatibility to devices using the message phases.
--   WF_ACSI_SCSI_IF_SOC: changed DATA_EN logic for ACSI and SCSI.
--   This top level: changed the logic for the ACSI_RDn and ACSI_WRn signals.
--   Fixed the VMAn timing in the 68K00 bus controller. Thanks to Igor Majstorovic for the information.
--   Top level: changes concerning the ACSI and SCSI bus logic. The both interfaces can now be used in parallel.
--   Top level: removed the RESET_Sn temporary fix. It is not used any more due to a correction in the system
--     microcontroller firmware.
-- Revision 2K13B  20131224 WF
--   68K00 ALU: Fixed the N flag for the CHK operation.
--   68K00 ALU: DIV_RESULT_VAR is now 64 bit wide to handle the overflow correctly.
--   Opcode decoder: Minor optimizations.
--   68K00 interrupt controller: Changed the sequence for sampling the interrupt vector.
--     It is now sampled before stacking.
--   68901 USART: separate Transmit and receive buffer and  some
--      minor changes. Thanks to Peter Neways (20121218).
--   WF_ACSI_SCSI_IF_SOC: changed the selection timeout to work without TIMEOUT.
--   WF_ACSI_SCSI_IF_SOC: some additional minor changes.
--   GLUE address decoder: Disabled signal SCCn (emuTos crashes due to not present SCC).
--   DMA register section: several changes due to implementation of the 5380.
--   This top level: implementation of the 5380 SCSI controller.
-- Revision 2K14A  20140228 WF
--   68K00 address registers: fixed the INDEX logic concerning the use of SSP and USP.
--   68K00 address registers: fixed the index logic concerning scaling.
--   68K00 address registers: fixed the exchange of registers for SSP and USP.
--   68K00 ALU: fixed the ABCD, NBCD and SBCD integer calculation.
--   68K00 ALU: fixed the wrong remainder's sign for the DIVS operation.
--   68K00 Interrupt controller: fixed wrong interrupt vector calculation in autovectoring mode.
--   68K00 top level: Small changes for the IPLn filter.
--   ACSI-SCSI bridge: rearranged the complete selection timeout to improve drive compatibility.
-- Revision 2K15A 20150620 WF
--   WF_ACSI_SCSI_IF: several code optimizations.
--   WF_ACSI_SCSI_IF: fixed a bug in the ACSI_CTRL_ENn logic: enabled also in WAIT_1stBYTE.
--   WF_ACSI_SCSI_IF: Implemented a message out system for rejection of all messages except 'COMMAND COMPLETE'.
-- Revision 2K15B 20151224 WF
--   Introduced a core version number (VERSION).
--   Boot loader: VERSION can be read from  the microcontroller.
--   Replaced data type bit by std_logic in all design units.
--   1772 FCD core: optimized the DATA_OUT multiplexer.
--   DMA_25913: CD_OUT is now registered.
--   Some naming conventions (ROM2_In, ROM2n_I).
--   Slow CPU is now auto switched if a 192kB ROM is selected.
--   WF5380: fixed/modified the interrupt logic.
--   This top level section: fixed HDINT_INn logic.
--   DTACKn of the IDE interface is now in the correct address space.
--   Automated the slow CPU feature for the old operating systems.
--   CONFIG(1) ist not used any more!
--   CONFIG(5) ist not used any more!
-- Revision 2K16A 20160620 WF
--   There is now a generic setting IDE_BYTESWAP_EN. The IDE byte swapping
--     is set to false for compatibility reasons with the Falcon and STBook.
--   DMA registers: CD_IN is now registered for timing stability.
--   68K00-ALU: minor changes to meet Modelsim compatibility.
--   68K00-CONTROL: minor changes to meet Modelsim compatibility.
--   The reset of the CPU is now delayed. See P_CPU for more details.
--   GLUE video timing: minor changes to meet better monitor compatibility.
--   The core is alternatively powered by the pipelined 68K10 processor configured in the 68K00 compatibility mode (alpha).
--   Bugfixes and optimizations in the WF_ACSI_SCSI_IF_SOC module. See the file header for more information.
--   Fixed a bug in the 5380 implementation. This chip is now inactive when xFF827E(1 downto0) /= "11".
--   Fixed a bug in the ACSI-SCSI implementation. This ACSI-SCSI interface is now inactive when xFF827E(1 downto0) /= "00".
-- Revision 2K18A 20161224 WF
--   CONFIG(1) ist now the selector between 68K00 and 68K10 CPU. Off is 68K00, on is 68K10.
-- Revision 2K19A 20190419 WF
-- Revision 2K19B  20191224 WF
--   SD_TOP / SDRAM: Fixed a precharge bug during memory initialisation.
--   Minor changes in the WF25914IP_CR_OUT module to help Multisyns or TFTs to synchronize correctly.
-- Revision 2K20A  20200620 WF
--   Toplevel: restructured DATA bus multiplexers.
--   GLUE25915 changes, see the GLUE top level for more information.
--   MCU25912 changes, see the GLUE top level for more information.
--   DMA25913 changes, see the DMA top level for more information.
--   Toplevel: Udo Matthe fix: changed polarity of COM_TxD.
--   Toplevel: removed obsolete instance I_SD_CARD: WF_ACSI_SDC.
--   Toplevel: implemented SD card microcontroller SPI interface.
--   Implemented the CORETYPE-generic.
-- Revision 2K21A 20211224 WF
--   Rearanged CLK_CPU and CLK_3.
--   Implementation of USB1160.
--   Udo Matthe implementation of generic MFP_UART_FIXED_SPEED.
--   Internal 32 bit wide address bus (for compatibility).
--   Wired xFF827_D(2) to CLK_2. This is the dot clock for the video DAC.
--   The configuration switch settings for the video mode are now similar to the Falcon settings.
--   Changed the HSYNC and VSYNC polarity for VGA monitors.
--   Additionally ALTRAM of 48MB is now accessable.
--   Blitter can now handle 32 address bits.
-- Revision 2K23B 20231224
--   ROMSEL_FC_E0n is now switched via address space (UMA).
--   New unitized video timing settings (UMA).
-- Revision 2K24A 20240620
--   Implemented dual use of the LCD port to meet the requirement for a new USB extension board.
--   SCC enhancements.
--
--   !!! See the header for actual configuration switch settings!!!

library work;
use work.SUSKA_CORE_C_STE_PKG.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity SUSKA_III_C_STE_68K10_TOP is
    generic(CORETYPE                : std_logic_vector(15 downto 0) := x"0010"; -- Core Type is 'Board C Suska-STE-68K10'.
            VERSION                 : std_logic_vector(31 downto 0) := x"20230620"; -- Core version.
            IDE_BYTESWAP_EN         : boolean := false; -- Select true or false. See file header for more information.
            MFP_UART_FIXED_SPEED    : boolean := false; -- Set true to use fixed Speed 38400bd
            USB1160_LITTLE_ENDIAN   : boolean := false);
            -- The following is tested with HDDRIVER (11.01):
            -- If you want to boot from the IDE device then select false. No Windows compatibility.
            -- If you want Windows compatibility select true. TOS does not boot from IDE.
    port(
        -- System controls:
        RESET_COREn         : in std_logic; -- FPGA reset.
        RESETn              : inout std_logic; -- System and CPU reset.
        CLK_PLL1            : in std_logic; -- 16 MHz system clock.
        CLK_PLL2            : in std_logic; -- 16 MHz system clock.
        CLK_AUX             : out std_logic; -- Auxiliary clock.

        -- Bus status controls:
        FC                  : inout std_logic_vector(2 downto 0);
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
        DATA                : inout std_logic_vector(15 downto 0);
        ADR                 : inout std_logic_vector(23 downto 1);

        -- Synchronous bus interface:
        VPAn                : in std_logic; -- Attention: requires at least a weak pull up resistor!
        VMAn                : out std_logic;
        E                   : out std_logic;

        -- OS ROM select lines:
        ROM6n               : out std_logic;
        ROM5n               : out std_logic;
        ROM4n               : out std_logic;
        ROM3n               : buffer std_logic;  -- used for internal Cubase Dongle
        ROM2n               : out std_logic;
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
        -- The CRT_PIN4 is the monochrome detect on STs and is the
        -- monochrome detect or external clock on STEs.
        -- The CRT_PIN3 is the GPO on STs and the external clock
        -- select on STEs (1 = internal clock).
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
        MIDI_OLR            : out std_logic; -- Open drain.
        MIDI_TLR            : out std_logic; -- Open drain.
        MIDI_IN             : in std_logic;

        -- Serial Interfaces:
        SCC_TxDB            : out std_logic;
        SCC_RxDB            : in std_logic;

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
        LPT_D               : inout std_logic_vector(7 downto 0);
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

        -- Shadow register bits of the STBook:
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
        CONFIG              : in std_logic_vector(1 to 6); -- Configuration switches.

        -- System status:
        PLL_FAULT           : out std_logic; -- Indicates unlocked PLLs.
        BOOT_LED            : out std_logic; -- Boot loader active...

        -- SD card microcontroller interface:
        SD_RESET_COREn      : in std_logic;
        SD_RESETn           : in std_logic;
        SD_AVR_CLK          : out std_logic; -- 16MHz.
        SD_AVR_ENn          : in std_logic;
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
end entity SUSKA_III_C_STE_68K10_TOP;

architecture STRUCTURE of SUSKA_III_C_STE_68K10_TOP is
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
signal A4299_CS_I           : std_logic;
signal ACIA_CS              : std_logic;
signal ACSI_SCSI_HDRQn      : std_logic;
signal ACSI_SCSI_CSn        : std_logic;
signal ADR_5380             : std_logic_vector(2 downto 0);
signal ADR_I                : std_logic_vector(31 downto 1);
signal ADR_EN_BLT           : std_logic;
signal ADR_EN_BOOT          : std_logic;
signal ADR_OUT_68K10        : std_logic_vector(31 downto 1);
signal ADR_OUT_BLT          : std_logic_vector(31 downto 1);
signal ADR_OUT_BOOT         : std_logic_vector(20 downto 1);
signal AS_OUT_68K10n        : std_logic;
signal AS_OUT_BLTn          : std_logic;
signal AS_OUT_GLUEn         : std_logic;
signal AVEC_INn             : std_logic;
signal AVEC_GLUEn           : std_logic;
signal AVEC_SCUn            : std_logic;
signal BERR_GLUEn           : std_logic;
signal BERRn_SCU            : std_logic;
signal BERR_In              : std_logic;
signal BG_68K10n            : std_logic;
signal BG_BLTn              : std_logic;
signal BGACK_BLTn           : std_logic;
signal BGACK_GLUEn          : std_logic;
signal BGACK_INn            : std_logic;
signal BLANKn               : std_logic;
signal BOOT_ACK             : std_logic;
signal BOOT_REQ             : std_logic;
signal BOOT_RESET_COREn     : std_logic;
signal BOOT_RESETn          : std_logic;
signal BR_BLTn              : std_logic;
signal BR_GLUEn             : std_logic;
signal BR_In                : std_logic;
signal BUS_EN_68K10         : std_logic;
signal BUSCTRL_EN_BLT       : std_logic;
signal BUSCTRL_EN_GLUE      : std_logic;
signal CA2                  : std_logic;
signal CA1                  : std_logic;
signal CA0                  : std_logic;
signal CLK_1                : std_logic;
signal CLK_2                : std_logic;
signal CLK_3                : std_logic;
signal CLK_2M4576            : std_logic;
signal CLK_2M0              : std_logic;
signal CLK_0M5              : std_logic;
signal CLK_3M672            : std_logic;
signal CLK_38400x16         : std_logic;
signal CLK_MFP_UART         : std_logic;
signal CLK_PLL_394          : std_logic;
signal CLK_PLL_256          : std_logic;
signal CLK_PLL_16000        : std_logic;
signal CD_EN_5380           : std_logic;
signal CD_EN_ACSCSI         : std_logic;
signal CD_EN_FDC            : std_logic;
signal CD_EN_DMA            : std_logic;
signal CD_5380              : std_logic_vector(7 downto 0);
signal CD_OUT_DMA           : std_logic_vector(7 downto 0);
signal CD_OUT_FDC           : std_logic_vector(7 downto 0);
signal CD_OUT_ACSCSI        : std_logic_vector(7 downto 0);
signal CMPCSn               : std_logic;
signal CODEC_4299_DMA       : std_logic;
signal CR_Wn                : std_logic;
signal CSn_5380             : std_logic;
signal SCLK_6M4             : std_logic;
signal SIRQn_SCU            : std_logic;
signal DATA_I               : std_logic_vector(15 downto 0);
signal DATA_OUT_68K10       : std_logic_vector(15 downto 0);
signal DATA_EN_68K10        : std_logic;
signal DATA_OUT_BLT         : std_logic_vector(15 downto 0);
signal DATA_EN_BLT          : std_logic;
signal DATA_OUT_GLUE        : std_logic_vector(15 downto 0);
signal DATA_EN_GLUE         : std_logic;
signal DATA_OUT_MCU         : std_logic_vector(7 downto 0);
signal DATA_EN_MCU          : std_logic;
signal DATA_OUT_DMA         : std_logic_vector(15 downto 0);
signal DATA_EN_DMA          : std_logic;
signal DATA_OUT_MFP         : std_logic_vector(7 downto 0);
signal DATA_EN_MFP          : std_logic;
signal DATA_OUT_SCU         : std_logic_vector(7 downto 0);
signal DATA_EN_SCU          : std_logic;
signal DATA_OUT_SOUND       : std_logic_vector(7 downto 0);
signal DATA_EN_SOUND        : std_logic;
signal DATA_OUT_4299        : std_logic_vector(15 downto 0);
signal DATA_EN_4299         : std_logic;
signal DATA_OUT_ACIA_I      : std_logic_vector(7 downto 0);
signal DATA_EN_ACIA_I       : std_logic;
signal DATA_OUT_ACIA_II     : std_logic_vector(7 downto 0);
signal DATA_EN_ACIA_II      : std_logic;
signal DATA_OUT_RP5C15      : std_logic_vector(3 downto 0);
signal DATA_EN_RP5C15       : std_logic;
signal DATA_OUT_BOOT        : std_logic_vector(15 downto 0);
signal DATA_EN_BOOT         : std_logic;
signal DATA_SHFT            : std_logic_vector(15 downto 0);
signal DATA_EN_HI_SHFT      : std_logic;
signal DATA_EN_LO_SHFT      : std_logic;
signal DATA_EN_SCC          : std_logic;
signal DATA_OUT_SCC         : std_logic_vector(7 downto 0);
signal DATA_OUT_USB1160     : std_logic_vector(15 downto 0);
signal DATA_EN_USB1160      : std_logic;
signal DC_5380              : std_logic_vector(7 downto 0);
signal DCYCn                : std_logic;
signal DE_I                 : std_logic;
signal DE_MSYNC             : std_logic;
signal DEV_In               : std_logic;
signal DINTn                : std_logic;
signal DMA_In               : std_logic;
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
signal DRIVE_SEL_I          : std_logic_vector(1 downto 0);
signal DS1392_OUT           : std_logic;
signal DS1392_OUT_EN        : std_logic;
signal DTACK_INn            : std_logic;
signal DTACK_OUT_BLTn       : std_logic;
signal DTACK_OUT_GLUEn      : std_logic;
signal DTACK_OUT_MCUn       : std_logic;
signal DTACK_OUT_MFPn       : std_logic;
signal DTACK_OUT_IDEn       : std_logic;
signal DTACKn_OUT_SCUn      : std_logic;
signal E_I                  : std_logic;
signal SCCINTn              : std_logic;
signal EOPn_5380            : std_logic;
signal EXT_RAMn             : std_logic;
signal FC_OUT_68K10         : std_logic_vector(2 downto 0);
signal FC_OUT_BLT           : std_logic_vector(2 downto 0);
signal FC_OUT_GLUE          : std_logic_vector(2 downto 0);
signal FCLK_I               : std_logic;
signal FCS_In               : std_logic;
signal FDCS_In              : std_logic;
signal FDD_WG               : std_logic;
signal FDD_WD               : std_logic;
signal FDD_STEP             : std_logic;
signal FDD_DIRC             : std_logic;
signal FDD_MO               : std_logic;
signal FDINT                : std_logic;
signal FDRQ                 : std_logic;
signal FLASH_RESET_In       : std_logic;
signal FLASH_WAITSTATEn     : std_logic;
signal HALT_68K10n          : std_logic;
signal HALT_INn             : std_logic;
signal HDACK_In             : std_logic;
signal HDCS_In              : std_logic;
signal HDINT_5380           : std_logic;
signal HDINT_ACSI_SCSIn     : std_logic;
signal HDINT_IDEn           : std_logic;
signal HDINT_INn            : std_logic;
signal HDRQ_5380            : std_logic;
signal HDRQ_IN              : std_logic;
signal HSYNC_On             : std_logic;
signal IDE_BYTESWAP         : std_logic;
signal IDE_RES_In           : std_logic;
signal INT_4299             : std_logic;
signal INT_BLTn             : std_logic;
signal IO_B_OUT             : std_logic_vector(7 downto 0);
signal IO_B_EN              : std_logic;
signal IPLn                 : std_logic_vector(2 downto 0);
signal IRQ_KEYBDn           : std_logic;
signal IRQ_MIDIn            : std_logic;
signal IRQ_ACIAn            : std_logic;
signal LATCHn               : std_logic;
signal LCD_USBn             : std_logic;
signal LDATA_OUT            : std_logic_vector(3 downto 0);
signal LDATA_EN             : std_logic_vector(3 downto 0);
signal LDS_OUT_68K10n       : std_logic;
signal LDS_OUT_GLUEn        : std_logic;
signal LDS_OUT_BLTn         : std_logic;
signal MAD                  : std_logic_vector(9 downto 0);
signal MCU_ADR              : std_logic_vector(25 downto 1);
signal MDAT_BUFFER          : std_logic_vector(15 downto 0);
signal MFP_CS_In            : std_logic;
signal MFP_IACKn            : std_logic;
signal MFP_SO               : std_logic;
signal MFP_SO_EN            : std_logic;
signal MFPINTn              : std_logic;
signal MIDI_OUT             : std_logic;
signal MONOCHROME           : std_logic;
signal MULTISYNC_I          : std_logic_vector(1 downto 0);
signal PLL_ARESET           : std_logic;
signal PLL_LOCKS            : std_logic;
signal PLL1_LOCKED          : std_logic;
signal PLL2_LOCKED          : std_logic;
signal RAMn                 : std_logic;
signal RDATn                : std_logic;
signal RDn_5380             : std_logic;
signal RDY_DMAn             : std_logic;
signal RDY_GLUEn            : std_logic;
signal RESET_Sn             : std_logic;
signal RESET_CORE_Sn        : std_logic;
signal RESET_INn            : std_logic;
signal RESET_EN_68K10       : std_logic;
signal RESET_BOOTn          : std_logic;
signal RESET_MCUn           : std_logic;
signal RESET_5380           : std_logic;
signal ROM2n_I              : std_logic;
signal ROMSEL_FC_E0n        : std_logic;
signal RP5C15_CSn           : std_logic;
signal RP5C15_WRn           : std_logic;
signal RP5C15_RDn           : std_logic;
signal RWn_OUT_68K10        : std_logic;
signal RWn_OUT_BLT          : std_logic;
signal RWn_OUT_GLUE         : std_logic;
signal SCC_RDn              : std_logic;
signal SCC_WRn              : std_logic;
signal SCC_IACKn            : std_logic;
signal SCC_WAITn            : std_logic;
signal SCSI_CSn             : std_logic;
signal SCSI_D_ACSCSI        : std_logic_vector(7 downto 0);
signal SCSI_DP_ACSCSI       : std_logic;
signal SCSI_D_EN_ACSCSI     : std_logic;
signal SCSI_CTRL_EN         : std_logic;
signal SCSI_RSTn_ACSCSI     : std_logic;
signal SCSI_CTRL_EN_ACSCSI  : std_logic;
signal SCSI_ACKn_ACSCSI     : std_logic;
signal SCSI_SELn_ACSCSI     : std_logic;
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
signal SDATA_L              : std_logic_vector(7 downto 0);
signal SDATA_R              : std_logic_vector(7 downto 0);
signal SDATA_L_4299         : std_logic_vector(19 downto 0);
signal SDATA_R_4299         : std_logic_vector(19 downto 0);
signal SHADOW_DATA          : std_logic_vector(15 downto 0);
signal SHADOW_VRAM_ADR      : std_logic_vector(14 downto 0);
signal SHADOW_VRAM_WRn      : std_logic;
signal SINT_IO7             : std_logic;
signal SINT_TAI             : std_logic;
signal SLOADn               : std_logic;
signal SNDCS_I              : std_logic;
signal SNDIR_I              : std_logic;
signal SPI_CLK              : std_logic;
signal SPI_MISO             : std_logic;
signal SPI_MOSI             : std_logic;
signal SREQ                 : std_logic;
signal SYNC_EN              : std_logic;
signal TDO                  : std_logic;
signal UDS_OUT_68K10n       : std_logic;
signal UDATA_OUT            : std_logic_vector(3 downto 0);
signal UDATA_EN             : std_logic_vector(3 downto 0);
signal UDS_OUT_GLUEn        : std_logic;
signal UDS_OUT_BLTn         : std_logic;
signal USB1160_CSn          : std_logic;
signal VDCLK_OUT            : std_logic;
signal VPA_INn              : std_logic;
signal VMA_OUT_68K10n       : std_logic;
signal VMA_OUT_EN_68K10     : std_logic;
signal VSYNC_On             : std_logic;
signal VIDEO_HIMODE_I       : std_logic;
signal VPA_GLUE_OUTn        : std_logic;
signal VRAM_D_IN            : std_logic_vector(7 downto 0);
signal VRAM_D_OUT           : std_logic_vector(7 downto 0);
signal WDATn                : std_logic;
signal WRn_5380             : std_logic;
signal YM_OUT_A4            : std_logic;
signal YM_OUT_A3            : std_logic;
signal xFF827E_I            : std_logic_vector(1 downto 0);
signal CUBDATA              : std_logic;
signal CUBDATAenable_n      : std_logic;
begin
    -- Clock system:
    RAM_CLK <= CLK_2; -- Use the MCU clock.
    SD_AVR_CLK <= CLK_PLL_16000;

    KEY_SCAN: process
    -- Sample the RESETn and the RESET_COREn buttons
    -- about every 5ms. This provides stability against
    -- push button jitter.
    variable SCAN_TIMER : std_logic_vector(16 downto 0);
    begin
        wait until CLK_1 = '1' and CLK_1' event;
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
    -- RESET_EN_68K10 is the CPU reset output.
    RESET_INn <= RESET_Sn and RESET_BOOTn and RESET_MCUn and SD_RESETn and PLL_LOCKS;
    RESETn <= '0' when RESET_EN_68K10 = '1' or (FLASH_RESET_In = '0' and SD_AVR_ENn = '1') or RESET_MCUn = '0' or PLL_LOCKS = '0' else 'Z';
    HALT_INn <= '0' when HALTn = '0' or (RESET_INn = '0' and RESET_EN_68K10 = '0') else '1';

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
            c0                  => CLK_1, -- 16MHz.
            c1                  => CLK_2, -- 32MHz.
            c2                  => CLK_3, -- 48MHz.
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

    -- This is a Cubase Dongle "red".
    -- Originally it is connected to the ROM port.
    I_CUB3_DONGLE: work.cub3
        port map(
            CLK           => CLK_2,
            RESET_n       => RESET_INn,
            CSn           => ROM3n,
            DATA_IN       => ADR_I(8),
            DATA_OUT      => CUBDATA,
            DATA_ENABLE_n => CUBDATAenable_n
        );

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
        CLK_2M4576 <= TMP_2M54(3);
        CLK_38400x16 <= TMP_2M54(5);
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

    P_3M672: process
    -- This process provides the 3.6720MHz clock for the SCC.
    -- It is derived from a 25.6MHz PLL clock divided by 7
    -- which results in a 3.6674 MHz clock.
    variable TMP_3M672: std_logic_vector(2 downto 0);
    begin
        wait until CLK_PLL_256 = '1' and CLK_PLL_256' event;
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

    MEM_DATA_BUFFER: process(RESET_INn, CLK_2)
    -- This process is the synchronous pendant of the
    -- memory to data bus bridge buffer of the original ST
    -- machine. To work properly, the buffer is driven by
    -- a fast clock.
    begin
        if RESET_INn = '0' then
            MDAT_BUFFER <= (others => '0');
        elsif CLK_2 = '1' and CLK_2' event then -- See change log.
            if LATCHn = '1' then
                MDAT_BUFFER <= RAM_DATA;
            end if;
        end if;
    end process MEM_DATA_BUFFER;

    DATA <= DATA_OUT_BOOT when DATA_EN_BOOT = '1' else
            DATA_I when DATA_EN_68K10 = '1' or DATA_EN_BLT = '1' else (others => 'Z');

    DATA_I <= DATA when RESET_BOOTn = '0' else -- This is the Flash to bootloader path.
              DATA_OUT_68K10(7 downto 0) & DATA_OUT_68K10(15 downto 8) when DATA_EN_68K10 = '1' and IDE_BYTESWAP = '1' and IDE_BYTESWAP_EN = true else
              DATA_OUT_68K10 when DATA_EN_68K10 = '1' else
              DATA_OUT_BLT when DATA_EN_BLT = '1' else
              DATA_OUT_GLUE when DATA_EN_GLUE = '1' else
              x"FF" & DATA_OUT_MCU when DATA_EN_MCU = '1' else -- x"FF" due to pull up resistors in original hardware.
              DATA_OUT_DMA when DATA_EN_DMA = '1' else
              x"FF" & DATA_OUT_MFP when DATA_EN_MFP = '1' else
              DATA_OUT_SOUND & x"FF" when DATA_EN_SOUND = '1' else
              DATA_OUT_4299 when DATA_EN_4299 = '1' else
              DATA_OUT_ACIA_I & x"FF" when DATA_EN_ACIA_I = '1' else
              DATA_OUT_ACIA_II & x"FF" when DATA_EN_ACIA_II = '1' else
              x"FFF" & DATA_OUT_RP5C15 when DATA_EN_RP5C15 = '1' else
              DATA_OUT_SCC & DATA_OUT_SCC when DATA_EN_SCC = '1' else -- Byte access.
              DATA_OUT_SCU & DATA_OUT_SCU when DATA_EN_SCU = '1' else -- Byte access.
              DATA when ROM2n_I = '0' else -- This is the Flash operating system data.
              DATA_OUT_USB1160 when DATA_EN_USB1160 = '1' else
              DATA(7 downto 0) & DATA(15 downto 8) when IDE_D_EN_INn = '0' and IDE_BYTESWAP = '1' and IDE_BYTESWAP_EN = true else
              DATA when IDE_D_EN_INn = '0' else
              DATA when BUTTONn = '0' else
              DATA when JOY_RHn = '0' and JOY_RLn = '0'  else
              x"FF" & DATA(7 downto 0) when JOY_RLn = '0' else
              DATA(15 downto 8) & x"FF" when JOY_RHn = '0'else
              "0000000" & CUBDATA  & x"00" when CUBDATAenable_n = '0' else -- Connect to Data8
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

    ADR <= "000" & ADR_OUT_BOOT when ADR_EN_BOOT = '1' else
           ADR_OUT_68K10(23 downto 1) when BUS_EN_68K10 = '1' else
           ADR_OUT_BLT(23 downto 1) when ADR_EN_BLT = '1' else (others => 'Z');

    ADR_I <= x"FF" & ADR_OUT_68K10(23 downto 1) when BUS_EN_68K10 = '1' and ADR_OUT_68K10(23 downto 16) = x"FF" and CONFIG(5) = '1' else -- Memory map for operating systems non ALTRAM cabaple.
             x"00" & ADR_OUT_68K10(23 downto 1) when BUS_EN_68K10 = '1' and CONFIG(5) = '1' else -- Non ALTRAM support.
             x"FF" & ADR_OUT_68K10(23 downto 1) when BUS_EN_68K10 = '1' and ADR_OUT_68K10(31 downto 16) = x"00FF" and CONFIG(5) = '0' else -- Memory map for OS with ALTRAM.
             x"00" & ADR_OUT_68K10(23 downto 1) when BUS_EN_68K10 = '1' and ADR_OUT_68K10(31 downto 16) = x"FFF0" and CONFIG(5) = '0' else -- Memory map IDE for OS with ALTRAM.
             ADR_OUT_68K10(31 downto 1) when BUS_EN_68K10 = '1' else -- ALTRAM capable.
             x"FF" & ADR_OUT_BLT(23 downto 1) when ADR_EN_BLT = '1' and ADR_OUT_BLT(23 downto 16) = x"FF" else -- Memory map.
             ADR_OUT_BLT when ADR_EN_BLT = '1' else (others => '1');

    FLASH_ADR_19 <= ADR_OUT_BOOT(19) when ADR_EN_BOOT = '1' else
                    '0' when ROMSEL_FC_E0n = '1' else -- Required to get the old TOS' running.
                    ADR_OUT_68K10(19) when BUS_EN_68K10 = '1' else
                    ADR_OUT_BLT(19) when ADR_EN_BLT = '1' else '1';

    FLASH_ADR_18 <= ADR_OUT_BOOT(18) when ADR_EN_BOOT = '1' else
                    '0' when ROMSEL_FC_E0n = '1' else -- Required to get the old TOS' running.
                    ADR_OUT_68K10(18) when BUS_EN_68K10 = '1' else
                    ADR_OUT_BLT(18) when ADR_EN_BLT = '1' else '1';

    -- Operating system ROM:
    ROMSEL_FC_E0n <= '1' when  ADR_I(31 downto 18) = "00000000111111" else '0';

    ROM2n <= ROM2n_I;

    -- SD-type-RAM memory section:
    -- CONFIG(4) = '1' is the ST machines compatibility mode.
    MCU_ADR <= ADR_I(25 downto 1) when EXT_RAMn = '0' else
               "00" & ADR_I(23 downto 1) when CONFIG(4) = '0' else
               x"0" & ADR_I(21 downto 1); -- For ST machines compatibility mode (running old TOS).

    VIDEO_RAM: process(CLK_2, VRAM)
    -- Shadow LCD video ram:
    -- This process is written in that manner, that 131072
    -- bits RAM will be inferred.
    variable VRAM_ADR_PNTR  : integer range 0 to 16383;
    begin
        if CLK_2 = '1' and CLK_2' event then
            VRAM_ADR_PNTR := To_Integer(unsigned(SHADOW_VRAM_ADR));
            if SHADOW_VRAM_WRn = '0' then
                VRAM(VRAM_ADR_PNTR) <= VRAM_D_IN;
            end if;
        end if;
        VRAM_D_OUT <= VRAM(VRAM_ADR_PNTR);
    end process VIDEO_RAM;

    SHADOW_DATA <= RAM_DATA;

    -- Video configuration:
    MONOCHROME <= '1' when CRT_PIN4_CLK1 = '0' and CRT_PIN3 = '1' else -- CRT_PIN3 is the external clock select (low active).
                  '1' when CONFIG(1 to 2) = "11" else '0';

    MULTISYNC_I <= "11" when CRT_PIN4_CLK1 = '0' and CRT_PIN3 = '1' else -- SM124.
                   not CONFIG(1 to 2);

    -- Video section:
    HSYNC <= HSYNC_On when SYNC_EN = '1'and MULTISYNC_I = "10" else
             not HSYNC_On when SynC_EN = '1' else 'Z';
    VSYNC <= not VSYNC_On when SYNC_EN = '1' else 'Z';

    xFF827E_D(2) <= CLK_2; -- On the Suska-III-C this signal is hardwired to the video DAC clock input.

    P_DE_COUNT: process
    -- This flip flop provides a bisection of the DE frequency to
    -- meet a correct line counter value of the multifunction port
    -- timer B in case of the hi video modi with line doubling.
    variable LOCK   : boolean;
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

    -- Serial port:
    COM_TxD <= MFP_SO when MFP_SO_EN = '1' else 'Z';
    COM_DTR <= not YM_OUT_A4;
    COM_RTS <= not YM_OUT_A3;

    -- Line printer port.
    LPT_D <= IO_B_OUT when IO_B_EN = '1' else (others => 'Z');

    -- DMA and ACSI/SCSI/SD section:
    CD <= CD_OUT_DMA when CD_EN_DMA = '1' else -- DMA controller.
          CD_OUT_FDC when CD_EN_FDC = '1' else -- Floppy disk controller.
          CD_5380 when CD_EN_5380 = '1' and xFF827E_I(1 downto 0) = "11" else -- 5380 SCSI controller.
          CD_OUT_ACSCSI when CD_EN_ACSCSI = '1' else (others => 'Z'); -- ACSI-SCSI bridge.

    HDCSn <= HDCS_In;
    HDACKn <= HDACK_In;

    CA1_OUT <= CA1;

    HDRQ_IN <= '1' when HDRQn = '0' or ACSI_SCSI_HDRQn = '0' or HDRQ_5380 = '1' else '0';
    HDINT_INn <= HDINTn and HDINT_IDEn and HDINT_ACSI_SCSIn and not HDINT_5380;

    -- Decoding for DRIVE_SEL: ACSI = "00", SCSI = "01", Floppy = "10", SD card = "11".

    ACSI_WRn <= CR_Wn when DRIVE_SEL_I = "00" else '1';
    ACSI_RDn <= not CR_Wn when DRIVE_SEL_I = "00" else '1';

    SCSI_RDn <= '0' when SCSI_IOn_5380 = '0' and SCSI_IO_EN_5380 = '1' and xFF827E_I(1 downto 0) = "11" else -- driven from the 5380.
                '0' when SCSI_IOn = '0' else '1'; -- Target to Initiator (Atari) (IOn = '0').
    SCSI_WRn <= '0' when SCSI_IOn_5380 = '1' and SCSI_IO_EN_5380 = '1' and xFF827E_I(1 downto 0) = "11" else -- driven from the 5380.
                '0' when SCSI_IOn = '1' else '1'; -- Initiator (Atari) to target (IOn = '1').

    ACSI_SCSI_CSn <= HDCS_In;
    SCSI_CTRL_ENn <= not SCSI_CTRL_EN;

    SCSI_D <= SCSI_D_ACSCSI when SCSI_D_EN_ACSCSI = '1' else
              SCSI_D_5380 when SCSI_EN_5380 = '1' and xFF827E_I(1 downto 0) = "11" else (others => 'Z');

    SCSI_DP <= SCSI_DP_ACSCSI when SCSI_D_EN_ACSCSI = '1' else
               SCSI_DP_5380 when SCSI_DP_EN_5380 = '1' and xFF827E_I(1 downto 0) = "11" else 'Z';

    SCSI_RSTn <= SCSI_RSTn_5380 when SCSI_RST_EN_5380 = '1' and xFF827E_I(1 downto 0) = "11" else
                 SCSI_RSTn_ACSCSI when SCSI_CTRL_EN_ACSCSI = '1' and xFF827E_I(1 downto 0) = "00" else 'Z';
    SCSI_SELn <= SCSI_SELn_5380 when SCSI_SEL_EN_5380 = '1' and xFF827E_I(1 downto 0) = "11" else
                 SCSI_SELn_ACSCSI when SCSI_CTRL_EN_ACSCSI = '1' and xFF827E_I(1 downto 0) = "00" else 'Z';
    SCSI_ACKn <= SCSI_ACKn_5380 when SCSI_ACK_EN_5380 = '1' and xFF827E_I(1 downto 0) = "11" else
                 SCSI_ACKn_ACSCSI when SCSI_CTRL_EN_ACSCSI = '1' and xFF827E_I(1 downto 0) = "00" else 'Z';
    SCSI_BSYn <= SCSI_BSYn_5380 when SCSI_BSY_EN_5380 = '1' and xFF827E_I(1 downto 0) = "11" else 'Z';
    SCSI_ATNn <= SCSI_ATNn_5380 when SCSI_ATN_EN_5380 = '1' and xFF827E_I(1 downto 0) = "11" else 'Z';
    SCSI_REQn <= SCSI_REQn_5380 when SCSI_REQ_EN_5380 = '1' and xFF827E_I(1 downto 0) = "11" else 'Z';
    SCSI_IOn <= SCSI_IOn_5380 when SCSI_IO_EN_5380 = '1' and xFF827E_I(1 downto 0) = "11" else 'Z';
    SCSI_DCn <= SCSI_CDn_5380 when SCSI_CD_EN_5380 = '1' and xFF827E_I(1 downto 0) = "11" else 'Z';
    SCSI_MSGn <= SCSI_MSGn_5380 when SCSI_MSG_EN_5380 = '1' and xFF827E_I(1 downto 0) = "11" else 'Z';

    SCSI_CTRL_EN <= '1' when SCSI_CTRL_EN_ACSCSI = '1' else
                    '1' when (SCSI_DP_EN_5380 or SCSI_ACK_EN_5380 or SCSI_SEL_EN_5380 or SCSI_ATN_EN_5380) = '1' and xFF827E_I(1 downto 0) = "11" else '0';

    ADR_5380 <= CA2 & CA1 & CA0;
    RESET_5380 <= '1' when RESET_INn = '0' else '0';
    CSn_5380 <= '1' when SCSI_CSn = '1' else '0';
    RDn_5380 <= '1' when CR_Wn = '1' else '0';
    WRn_5380 <= '1' when CR_Wn = '0' else '0';

    -- Floppy Tri-States:
    FDD_WGn <= '0' when FDD_WG = '1' else 'Z';
    FDD_WDn <= '0' when FDD_WD = '1' else 'Z';
    FDD_STEPn <= '0' when FDD_STEP = '1' else 'Z';
    FDD_DIRCn <= '0' when FDD_DIRC = '1' else 'Z';
    FDD_MOn <= '0' when FDD_MO = '1' else 'Z';

    -- MIDI interface:
    MIDI_OLR <= '0' when MIDI_OUT = '0' else 'Z';
    MIDI_TLR <= '0' when MIDI_IN = '0' else 'Z';

    -- Bus controls:
    BERR_In <= BERRn;
    BERRn <= '0' when BERR_GLUEn = '0' or BERRn_SCU = '0' else 'Z';

    HALTn <= '0' when HALT_68K10n = '0' else 'Z';

    UDSn <= UDS_OUT_68K10n when BUS_EN_68K10 = '1' else
            UDS_OUT_BLTn when BUSCTRL_EN_BLT = '1' else
            UDS_OUT_GLUEn when BUSCTRL_EN_GLUE = '1' else 'Z';

    LDSn <= LDS_OUT_68K10n when BUS_EN_68K10 = '1' else
            LDS_OUT_BLTn when BUSCTRL_EN_BLT = '1' else
            LDS_OUT_GLUEn when BUSCTRL_EN_GLUE = '1' else 'Z';

     -- The first condition of ASn is important for system
     -- startup. See process FLASH_WS.
    ASn <= '1' when FLASH_WAITSTATEn = '0' else
           AS_OUT_68K10n when BUS_EN_68K10 = '1' else
           AS_OUT_BLTn when BUSCTRL_EN_BLT = '1' else
           AS_OUT_GLUEn when BUSCTRL_EN_GLUE = '1' else 'Z';

    RWn <= RWn_OUT_68K10 when BUS_EN_68K10 = '1' else
           RWn_OUT_BLT when BUSCTRL_EN_BLT = '1' else
           RWn_OUT_GLUE when BUSCTRL_EN_GLUE = '1' else 'Z';

    FC <= FC_OUT_68K10 when BUS_EN_68K10 = '1' else
          FC_OUT_BLT when BUSCTRL_EN_BLT = '1' else
          FC_OUT_GLUE when BUSCTRL_EN_GLUE = '1' else "ZZZ";

    FLASH_WS: process (RESETn, CLK_1)
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
        elsif CLK_1 = '1' and CLK_1' event then
            if TMP < "111" then
                TMP := TMP + '1';
                FLASH_WAITSTATEn <= '0';
            else
                FLASH_WAITSTATEn <= '1';
            end if;
        end if;
    end process FLASH_WS;

    SLOW_CPU: process(CLK_1, DTACKn, ROMSEL_FC_E0n, ROM2n_I)
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
                if ROM2n_I = '0' and TMP = "110" then -- Slow down flash memory access.
                    DTACK_INn <= '0';
                elsif ROM2n_I = '0' then
                    DTACK_INn <= '1';
                else
                    DTACK_INn <= DTACKn;
                end if;
        end case;
    end process SLOW_CPU;

    DTACKn <=
-- Workaround: TOS2.xx does not boot with SCCn enabled.
--'1' when SCC_RDn = '0' or SCC_WRn = '0' else
              '0' when DTACK_OUT_BLTn = '0' or DTACK_OUT_GLUEn = '0' else
              '0' when DTACK_OUT_MCUn = '0' or DTACK_OUT_MFPn = '0' else
              '0' when DTACK_OUT_IDEn = '0' or DTACKn_OUT_SCUn = '0' else 'Z';

    VPA_INn <= '0' when VPA_GLUE_OUTn = '0' or VPAn = '0' else '1';
    VMAn <=  VMA_OUT_68K10n when VMA_OUT_EN_68K10 = '1' else 'Z';

    E <= E_I;
    FCLK <= FCLK_I;

    BR_In <= BR_BLTn and BR_GLUEn and BRn;
    BGACK_INn <= '0' when BGACK_BLTn = '0' or BGACKn = '0' else '1';
    BGACKn <= '0' when BGACK_BLTn = '0' else 'Z';

    -- Interrupt stuff:
    AVEC_INn <= AVECn and AVEC_GLUEn and AVEC_SCUn; -- One Low active signal is sufficient.
    IRQ_ACIAn <= IRQ_KEYBDn and IRQ_MIDIn;

    -- DS1392 RTC interface:
    DS1392_D <= '1' when DS1392_OUT = '1' and DS1392_OUT_EN = '1' else
                '0' when DS1392_OUT = '0' and DS1392_OUT_EN = '1' else 'Z';

    -- Codec sound:
    SDATA_L_4299 <= SDATA_L & x"000";
    SDATA_R_4299 <= SDATA_R & x"000";

    I_CPU: WF68K10_TOP
        port map(
            CLK                     => CLK_1,

            -- Address and data:
            ADR_OUT(31 downto 1)    => ADR_OUT_68K10,
            DATA_IN                 => DATA_I,
            DATA_OUT                => DATA_OUT_68K10,
            DATA_EN                 => DATA_EN_68K10,

            -- System control:
            BERRn                   => BERR_In,
            RESET_INn               => RESET_INn,
            RESET_OUT               => RESET_EN_68K10,
            HALT_INn                => HALT_INn,
            HALT_OUTn               => HALT_68K10n,

            -- Processor status:
            FC_OUT                  => FC_OUT_68K10,

            -- Interrupt control:
            AVECn                   => AVEC_INn,
            IPLn                    => IPLn,

            -- Aynchronous bus control:
            DTACKn                  => DTACK_INn,
            ASn                     => AS_OUT_68K10n,
            RWn                     => RWn_OUT_68K10,
            UDSn                    => UDS_OUT_68K10n,
            LDSn                    => LDS_OUT_68K10n,
            -- DBENn                => , -- Not used.
            BUS_EN                  => BUS_EN_68K10,

            -- Synchronous peripheral control:
            E                       => E_I,
            VMAn                    => VMA_OUT_68K10n,
            VMA_EN                  => VMA_OUT_EN_68K10,
            VPAn                    => VPA_INn,

            -- Bus arbitration control:
            BRn                     => BR_In,
            BGn                     => BG_68K10n,
            BGACKn                  => BGACK_INn,

            -- Other controls:
            K6800n                  => not CONFIG(3) -- Switch on for 68K10 CPU. Off = 68K00 CPU.
        );

    I_BLITTER: WF101643IP_TOP_SOC
        port map(
            -- System controls:
            CLK                 => CLK_1,
            RESETn              => RESET_INn,

            AS_INn              => ASn,
            AS_OUTn             => AS_OUT_BLTn,
            LDS_INn             => LDSn,
            LDS_OUTn            => LDS_OUT_BLTn,
            UDS_INn             => UDSn,
            UDS_OUTn            => UDS_OUT_BLTn,
            RWn_IN              => RWn,
            RWn_OUT             => RWn_OUT_BLT,
            DTACK_INn           => DTACK_INn,
            DTACK_OUTn          => DTACK_OUT_BLTn,
            BERRn               => BERR_In,
            FC_IN               => FC,
            FC_OUT              => FC_OUT_BLT,
            BUSCTRL_EN          => BUSCTRL_EN_BLT,
            INTn                => INT_BLTn,

            -- The bus:
            ADR_IN              => ADR_I(31 downto 1),
            ADR_OUT             => ADR_OUT_BLT,
            ADR_EN              => ADR_EN_BLT,
            DATA_IN             => DATA_I,
            DATA_OUT            => DATA_OUT_BLT,
            DATA_EN             => DATA_EN_BLT,

            -- Bus arbitration:
            BGIn                => BG_68K10n,
            BGKIn               => BGACK_GLUEn,
            BRn                 => BR_BLTn,
            BGACK_INn           => BGACK_INn,
            BGACK_OUTn          => BGACK_BLTn,
            BGOn                => BG_BLTn
        );

    I_GLUE: WF25915IP_TOP_SOC
        port map(
            -- Clock system:
            CLK_1               => CLK_1,
            CLK_2               => CLK_2,
            CLK_0M5             => CLK_0M5,

            -- Adress decoder:
            EN_RAM_14MB         => not CONFIG(4),
            EN_ALTRAM           => not CONFIG(5),
            ROM_6n              => ROM6n,
            ROM_5n              => ROM5n,
            ROM_4n              => ROM4n,
            ROM_3n              => ROM3n,
            ROM_2n              => ROM2n_I,
            ROM_1n              => ROM1n,
            ROM_0n              => ROM0n,

            ACIACS              => ACIA_CS,
            MFPCSn              => MFP_CS_In,
            -- SNDCSn           =>, -- Not used.
            FCSn                => FCS_In,

            STE_SNDCS           => SNDCS_I,
            STE_SNDIR           => SNDIR_I,

            -- RP5C15 real time clock:
            STE_RTCCSn          => RP5C15_CSn,
            STE_RTC_WRn         => RP5C15_WRn,
            STE_RTC_RDn         => RP5C15_RDn,

            -- 6800 peripheral control:
            VPAn                => VPA_GLUE_OUTn,
            VMAn                => VMA_OUT_68K10n,

            DEVn                => DEV_In,
            RAMn                => RAMn,
            EXT_RAMn            => EXT_RAMn,
            DMAn                => DMA_In,

            -- Interrupt system:
            AVECn               => AVEC_GLUEn,
            STE_FDINT           => FDINT,
            STE_HDINTn          => HDINT_INn,
            MFPINTn             => MFPINTn,
            STE_EINT3n          => EINT3n,
            STE_EINT5n          => SCCINTn,
            STE_EINT7n          => EINT7n,
            STE_DINTn           => DINTn,
--            IACKn               => MFP_IACKn,
--            STE_IPL2n           => IPLn(2),
--            STE_IPL1n           => IPLn(1),
--            STE_IPL0n           => IPLn(0),

            -- Video timing:
            BLANKn              => BLANKn,
            DE                  => DE_I,
            MULTISYNC           => MULTISYNC_I,
            VIDEO_HIMODE        => VIDEO_HIMODE_I,
            HSYNC_INn           => not HSYNC,
            HSYNC_OUTn          => HSYNC_On,
            VSYNC_INn           => not VSYNC,
            VSYNC_OUTn          => VSYNC_On,
            SYNC_OUT_EN         => SYNC_EN,

            -- Bus arbitration control:
            RDY_INn             => RDY_DMAn,
            RDY_OUTn            => RDY_GLUEn,
            BRn                 => BR_GLUEn,
            BGIn                => BG_BLTn,
            BGOn                => BGOn,
            BGACK_INn           => BGACK_BLTn,
            BGACK_OUTn          => BGACK_GLUEn,

            -- Adress and data bus:
            ADDRESS             => ADR_I,
            DATA_IN             => DATA_I(15 downto 8),
            DATA_OUT            => DATA_OUT_GLUE,
            DATA_EN             => DATA_EN_GLUE,

            -- Asynchronous bus control:
            RWn_IN              => RWn,
            RWn_OUT             => RWn_OUT_GLUE,
            AS_INn              => ASn,
            AS_OUTn             => AS_OUT_GLUEn,
            UDS_INn             => UDSn,
            UDS_OUTn            => UDS_OUT_GLUEn,
            LDS_INn             => LDSn,
            LDS_OUTn            => LDS_OUT_GLUEn,
            DTACK_INn           => DTACK_INn,
            DTACK_OUTn          => DTACK_OUT_GLUEn,
            CTRL_EN             => BUSCTRL_EN_GLUE,

            -- System control:
            RESETn              => RESET_INn,
            BERRn               => BERR_GLUEn,

            -- Processor function codes:
            FC_IN               => FC,
            FC_OUT              => FC_OUT_GLUE,

            -- STE enhancements:
            -- STE_FDDS         =>, -- Not used yet.
            STE_FCCLK           => CLK_AUX,
            STE_JOY_RHn         => JOY_RHn,
            STE_JOY_RLn         => JOY_RLn,
            STE_JOY_WL          => JOY_WL,
            STE_JOY_WEn         => JOY_WEn,
            STE_BUTTONn         => BUTTONn,
            STE_PAD0Xn          => PAD0Xn,
            STE_PAD0Yn          => PAD0Yn,
            STE_PAD1Xn          => PAD1Xn,
            STE_PAD1Yn          => PAD1Yn,
            STE_PADRSTn         => PADRSTn,
            STE_PENn            => PENn,
            SCCRDn              => SCC_RDn,
            SCCWRn              => SCC_WRn,
--            SCCIACKn            => SCC_IACKn,
            SCCWAITn            => SCC_WAITn,
            -- STE_CPROGn       => -- Not used yet.

            -- Further enhancements:
            STE_A4299_CS        => A4299_CS_I,
            USB1160_CSn         => USB1160_CSn
            );

    I_MCU: WF25912IP_SD_TOP_CTYPE_SOC
        port map(
            CLK                 => CLK_2,
            SYS_RESET_INn       => RESET_CORE_Sn,
            SYS_RESET_OUTn      => RESET_MCUn,
            RESET_INn           => RESET_INn,

            ASn                 => ASn,
            LDSn                => LDSn,
            UDSn                => UDSn,
            RWn                 => RWn,

            ADR                 => MCU_ADR,

            RAMn                => RAMn,
            DMAn                => DMA_In,
            DEVn                => DEV_In,

            VSYNCn              => VSYNC_On,
            DE                  => DE_I,
            VIDEO_HIMODE        => VIDEO_HIMODE_I,

            DCYCn               => DCYCn,
            CMPCSn              => CMPCSn,

            MONOCHROME          => MONOCHROME,
            SREQ                => SREQ,
            SLOADn              => SLOADn,
            CODEC_4299_DMA      => CODEC_4299_DMA,
            SINT_TAI            => SINT_TAI,
            SINT_IO7            => SINT_IO7,

            BA                  => RAM_BA,
            MAD                 => RAM_ADR,

            WEn                 => RAM_WEn,

            DQM0H               => RAM_DQM0H,
            DQM0L               => RAM_DQM0L,
            DQM1H               => RAM_DQM1H,
            DQM1L               => RAM_DQM1L,

            RAS0n               => RAM_RAS0n,
            RAS1n               => RAM_RAS1n,

            CAS0n               => RAM_CAS0n,
            CAS1n               => RAM_CAS1n,

            RDATn               => RDATn,
            WDATn               => WDATn,
            LATCHn              => LATCHn,

            DTACKn              => DTACK_OUT_MCUn,

            DATA_IN             => DATA_I(7 downto 0),
            DATA_OUT            => DATA_OUT_MCU,
            DATA_EN             => DATA_EN_MCU
        );

    I_DMA: WF25913IP_TOP_SOC
        port map(
            -- system controls:
            RESETn              => RESET_INn,
            CLK                 => CLK_1,

            FCSn                => FCS_In,
            A1                  => ADR_I(1),
            RWn                 => RWn,
            RDY_INn             => RDY_GLUEn,
            RDY_OUTn            => RDY_DMAn,
            DATA_IN             => DATA_I,
            DATA_OUT            => DATA_OUT_DMA,
            DATA_EN             => DATA_EN_DMA,

            -- ACSI mode selection:
            DRIVE_SEL           => DRIVE_SEL_I,

            -- ACSI section:
            CA2                 => CA2,
            CA1                 => CA1,
            CA0                 => CA0,
            CR_Wn               => CR_Wn,
            CD_IN               => CD,
            CD_OUT              => CD_OUT_DMA,
            CD_EN               => CD_EN_DMA,

            FDCSn               => FDCS_In,
            SDCSn               => open,
            SCSICSn             => SCSI_CSn,
            HDCSn               => HDCS_In,
            FDRQ                => FDRQ,
            HDRQ                => HDRQ_IN,
            ACKn                => HDACK_In,
            EOPn                => EOPn_5380
        );

    I_FDC: WF1772IP_TOP_SOC
        port map(
            CLK                 => CLK_1,
            RESETn              => RESET_INn,

            CSn                 => FDCS_In,
            RWn                 => CR_Wn,
            A1                  => CA2,
            A0                  => CA1,
            DATA_IN             => CD,
            DATA_OUT            => CD_OUT_FDC,
            DATA_EN             => CD_EN_FDC,
            RDn                 => FDD_RDn,
            TR00n               => FDD_TR00n,
            IPn                 => FDD_IPn,
            WPRTn               => FDD_WPn,
            DDEn                => '0', -- Fixed to MFM.
            HDTYPE              => FDD_TYPE,
            MO                  => FDD_MO,
            WG                  => FDD_WG,
            WD                  => FDD_WD,
            STEP                => FDD_STEP,
            DIRC                => FDD_DIRC,
            DRQ                 => FDRQ,
            INTRQ               => FDINT
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
            --VDAC_CLK              =>, -- Not used.
            SH_R                    => CRT_R,
            SH_G                    => CRT_G,
            SH_B                    => CRT_B,
            SH_MONO                 => CRT_MONO,
            -- SH_CSYNCn            =>, -- Not used.

            SH_SCLK                 => SCLK_6M4,
            SH_FCLK                 => FCLK_I,
            SH_SLOADn               => SLOADn,
            SH_SREQ                 => SREQ,
            SH_SDATA_L              => SDATA_L,
            SH_SDATA_R              => SDATA_R,

            SH_MWK                  => MWK,
            SH_MWD                  => MWD,
            SH_MWEn                 => MWEn,

            xFF827E_D(7 downto 3)   => xFF827E_D(7 downto 3),
            xFF827E_D(1)            => xFF827E_I(1),
            xFF827E_D(0)            => xFF827E_I(0)
        );

    I_SHADOW: WF_SHD101775IP_TOP_SOC
        port map(
            RESETn              => RESET_INn,
            CLK                 => CLK_1,

            -- Video control:
            M_DATA              => SHADOW_DATA,
            SEL_640x400         => '1', -- Select either 640x400 '1' or 640x480 '0'.
            DE                  => DE_I,
            LOADn               => DCYCn,

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

    I_MFP: WF68901IP_TOP_SOC
        port map(
            -- System control:
            CLK                 => CLK_1,
            RESETn              => RESET_INn,

            -- Asynchronous bus control:
            DSn                 => LDSn,
            CSn                 => MFP_CS_In,
            RWn                 => RWn,
            DTACKn              => DTACK_OUT_MFPn,

            -- Data and Adresses:
            RS                  => ADR_I(5 downto 1),
            DATA_IN             => DATA_I(7 downto 0),
            DATA_OUT            => DATA_OUT_MFP,
            DATA_EN             => DATA_EN_MFP,
            GPIP_IN(7)          => SINT_IO7 or INT_4299,
            GPIP_IN(6)          => not COM_RI,
            GPIP_IN(5)          => DINTn,
            GPIP_IN(4)          => IRQ_ACIAn,
            GPIP_IN(3)          => INT_BLTn,
            GPIP_IN(2)          => not COM_CTS,
            GPIP_IN(1)          => not COM_DCD,
            GPIP_IN(0)          => LPT_BSY,
            -- GPIP_OUT         =>, -- Not used; all GPIPs are direction input.
            -- GPIP_EN          =>, -- Not used; all GPIPs are direction input.

            -- Interrupt control:
            IACKn               => MFP_IACKn,
            IEIn                => '0',
            -- IEOn             =>, -- Not used.
            IRQn                => MFPINTn,

            -- Timers and timer control:
            XTAL1               => CLK_2M4576,
            TAI                 => SINT_TAI,
            TBI                 => DE_MSYNC,
            -- TAO              =>, -- Not used.
            -- TBO              =>, -- Not used.
            -- TCO              =>, -- Not used.
            TDO                 => TDO,

            -- Serial I/O control:
            RC                  => CLK_MFP_UART,
            TC                  => CLK_MFP_UART,
            SI                  => COM_RxD,
            SO                  => MFP_SO,
            SO_EN               => MFP_SO_EN

            -- DMA control:
            -- RRn              =>, -- Not used.
            -- TRn              => -- Not used.
        );

    I_SOUND: WF2149IP_TOP_SOC
        port map(
            SYS_CLK             => CLK_1,
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
            IO_B_IN             => LPT_D,
            IO_B_OUT            => IO_B_OUT,
            IO_B_EN             => IO_B_EN,

            OUT_A               => YM_OUT_A,
            OUT_B               => YM_OUT_B,
            OUT_C               => YM_OUT_C
        );

    I_4299: A4299
        port map(
            CLK                 => CLK_1, -- 16MHz.
            RESETn              => RESET_INn,

            ADR                 => ADR_I(7 downto 1),
            A4299_CS            => A4299_CS_I,
            RWn                 => RWn,

            DATA_IN             => DATA_I,
            DATA_OUT            => DATA_OUT_4299,
            DATA_EN             => DATA_EN_4299,

            INT                 => INT_4299,
            DMA_EN              => CODEC_4299_DMA,
            SDATA_L             => SDATA_L_4299,
            SDATA_R             => SDATA_R_4299,

            BIT_CLK             => CODEC_SCLK,
            SYNC                => CODEC_SSYNC,
            SDATA_IN            => CODEC_SDIN,
            SDATA_OUT           => CODEC_SDOUT
        );

    I_AUDIODAC: WF_AUDIO_DAC
        port map(
            CLK                 => CLK_1, -- 16MHz.
            RESETn              => RESET_INn,

            FCLK                => FCLK_I,
            SDATA_L             => SDATA_L,
            SDATA_R             => SDATA_R,
            DAC_SCLK            => DAC_SCLK,
            DAC_SDATA           => DAC_SDATA,
            DAC_SYNCn           => DAC_SYNCn,
            DAC_LDACn           => DAC_LDACn
        );

    I_ACIA_KEYBOARD: WF6850IP_TOP_SOC
      port map(
            CLK                 => CLK_1,
            RESETn              => RESET_INn,

            CS2n                => ADR_I(2),
            CS1                 => '1',
            CS0                 => ACIA_CS,
            E                   => E_I,
            RWn                 => RWn,
            RS                  => ADR_I(1),

            DATA_IN             => DATA_I(15 downto 8),
            DATA_OUT            => DATA_OUT_ACIA_I,
            DATA_EN             => DATA_EN_ACIA_I,

            TXCLK               => CLK_0M5,
            RXCLK               => CLK_0M5,
            RXDATA              => KEYB_RxD,

            CTSn                => '0', -- In original ST machines wired to GND.
            DCDn                => '0', -- In original ST machines wired to GND.

            IRQn                => IRQ_KEYBDn,
            TXDATA              => KEYB_TxD
            --RTSn              => -- Not used.
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
            RXDATA              => MIDI_IN,
            CTSn                => '0',
            DCDn                => '0',

            IRQn                => IRQ_MIDIn,
            TXDATA              => MIDI_OUT,
            RTSn                => UART_MIDI_RTSn
        );

    I_RTC5C15: WF5C15_139xIP_TOP
        port map(
            RESETn              => RESET_INn,
            CLK                 => CLK_1,

            -- The bus interface:
            ADR                 => ADR_I(4 downto 1),
            DATA_IN             => DATA_I(3 downto 0),
            DATA_OUT            => DATA_OUT_RP5C15,
            DATA_EN             => DATA_EN_RP5C15,
            CS                  => '1',
            CSn                 => RP5C15_CSn,
            WRn                 => RP5C15_WRn,
            RDn                 => RP5C15_RDn,

            -- The SPI lines:
            SPI_IN              => DS1392_D,
            SPI_OUT             => DS1392_OUT,
            SPI_EN              => DS1392_OUT_EN,
            SPI_SCL             => DS1392_SCL,
            SPI_CE              => DS1392_CE
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
            PCLK                    => CLK_1,

            -- Bus:
            DATA_IN                 => DATA_I(7 downto 0),
            DATA_OUT                => DATA_OUT_SCC,
            DATA_EN                 => DATA_EN_SCC,

            -- Bus controls:
            CEn                     => '0',
            RDn                     => SCC_RDn,
            WRn                     => SCC_WRn,
            A_Bn                    => ADR_I(2),
            D_Cn                    => ADR_I(1),

            -- Interrupt:
            INTACKn                 => SCC_IACKn,
            IEI                     => '1',
            --IEO                   => , -- Not used.
            INTn                    => SCCINTn,

            -- Serial Data:
            RxDA                    => '1', -- SCC_RDA
--            TxDA                    => SCC_TDA
            --TxDA_EN               => -- Not used.
            RxDB                    => SCC_RxDB,
            TxDB                    => SCC_TxDB,

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
--DTRn_REQAn              => SCC_DTRA,
--RTSAn                   => SCC_RTSA,
CTSAn                   => '1', --SCC_CTSA,
DCDAn                   => '1', --SCC_CDA,
SYNCB_IN                => '1', -- SCC_DSRB
            --SYNCB_OUT             => , -- Not used.
            --SYNCB_EN              => , -- Not used.
            --Wn_REQBn              => , -- Not used.
--DTRn_REQBn              => SCC_DTRB,
--RTSBn                   => SCC_RTSB,
CTSBn                   => '1', -- SCC_CTSB
DCDBn                   => '1' -- SCC_CDB
        );

    I_ACSI_SCSI: WF_ACSI_SCSI_IF_SOC
        port map(
            CLK                 => CLK_1,
            RESETn              => RESET_INn,

            CR_Wn               => CR_Wn,
            CA1                 => CA1,
            HDCSn               => ACSI_SCSI_CSn,
            HDACKn              => HDACK_In,
            HDINTn              => HDINT_ACSI_SCSIn,
            HDRQn               => ACSI_SCSI_HDRQn,
            ACSI_D_IN           => CD,
            ACSI_D_OUT          => CD_OUT_ACSCSI,
            ACSI_D_EN           => CD_EN_ACSCSI,
            --ACSI_CTRL_ENn     => Not used so far.
            SCSI_BUSYn          => SCSI_BSYn,
            SCSI_MSGn           => SCSI_MSGn,
            SCSI_REQn           => SCSI_REQn,
            SCSI_DCn            => SCSI_DCn,
            SCSI_IOn            => SCSI_IOn,
            SCSI_RSTn           => SCSI_RSTn_ACSCSI,
            SCSI_ACKn           => SCSI_ACKn_ACSCSI,
            SCSI_SELn           => SCSI_SELn_ACSCSI,
            --SCSI_ATNn         =>, -- Not used.
            SCSI_DP_IN          => SCSI_DP,
            SCSI_DP_OUT         => SCSI_DP_ACSCSI,
            SCSI_D_IN           => SCSI_D,
            SCSI_D_OUT          => SCSI_D_ACSCSI,
            SCSI_D_EN           => SCSI_D_EN_ACSCSI,
            SCSI_CTRL_EN        => SCSI_CTRL_EN_ACSCSI,
            SCSI_IDn            => SCSI_IDn
            --P24               =>, -- Debugging.
            --P25               => -- Debugging.
        );

    I_5380: WF5380_TOP_SOC
        port map(
            CLK                 => CLK_1,
            RESET               => RESET_5380,
            ADR                 => ADR_5380,
            DATA_IN             => CD,
            DATA_OUT            => CD_5380,
            DATA_EN             => CD_EN_5380,
            CSn                 => CSn_5380,
            RDn                 => RDn_5380,
            WRn                 => WRn_5380,
            EOPn                => EOPn_5380,
            DACKn               => HDACK_In,
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

    I_IDE: WF_IDE
        port map(
            RESETn              => RESET_INn,
            CLK                 => CLK_1,

            ADR                 => ADR_I,
            DATA_IN             => DATA_I(7 downto 0),

            ASn                 => ASn,
            LDSn                => LDSn,
            RWn                 => RWn,
            DTACKn              => DTACK_OUT_IDEn,

            -- Interrupt via ACSI:
            ACSI_HDINTn         => HDINT_IDEn,

            -- IDE section:
            IDE_INTRQ           => IDE_INTRQ,
            IDE_IORDY           => IDE_IORDY,
            --IDE_RESn          => , -- not used.
            CS0n                => IDE_CS0n,
            CS1n                => IDE_CS1n,
            IORDn               => IDE_IORDn,
            IOWRn               => IDE_IOWRn,

            IDE_BYTESWAP        => IDE_BYTESWAP,
            IDE_D_EN_INn        => IDE_D_EN_INn,
            IDE_D_EN_OUTn       => IDE_D_EN_OUTn
          );

    I_FLASHBOOT: FLASHBOOT_UMASPI
        port map(
            CLK                     => CLK_1, -- 16MHz.
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

            ROM_CEn                 => ROM2n_I,
            ADR_OUT(23 downto 20)   => open, -- High address bits currently not in use.
            ADR_OUT(19 downto 0)    => ADR_OUT_BOOT,
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

    BOOT_RESET_COREn <= SD_RESET_COREn when SD_AVR_ENn = '0' else RESET_CORE_Sn;
    BOOT_RESETn <= SD_RESETn when SD_AVR_ENn = '0' else RESET_Sn;
    BOOT_ACK <= SD_BOOT_ACK when  SD_AVR_ENn = '0' else SYS_BOOT_ACK;
    SPI_CLK <= SD_SPI_CLK when SD_AVR_ENn = '0' else SYS_SPI_CLK;
    SPI_MOSI <= SD_SPI_MOSI when SD_AVR_ENn = '0' else SYS_SPI_MOSI;
    SD_BOOT_REQ <= BOOT_REQ when SD_AVR_ENn = '0' else '0';
    SYS_BOOT_REQ <= BOOT_REQ when SD_AVR_ENn = '1' else '0';
    SD_SPI_MISO <= SPI_MISO when SD_AVR_ENn = '0' else '0';
    SYS_SPI_MISO <= SPI_MISO when SD_AVR_ENn = '1' else '0';

    I_SCU: TTSCU -- The wiring of the SCU is like the Mega ST.
        port map(
            -- System and core control:
            RESET                   => RESET_INn,
            CLK                     => CLK_1,

            -- Adress and data bus:
            ADR(31 downto 1)        => ADR_I,
            ADR(0)                  => '0',
            ASn                     => ASn,
            FC                      => FC,

            DATA_IN                 => DATA_I(7 downto 0),
            DATA_OUT                => DATA_OUT_SCU,
            DATA_EN                 => DATA_EN_SCU,

            -- Bus control:
            RWn                     => RWn,
            LDSn                    => LDSn,
            SIZE                    => "00",
            DTACKn                  => DTACKn_OUT_SCUn,
            BERRn                   => BERRn_SCU,

            --FPUn                  => , -- Nou'1' tsed.
            --IOCS1n                => , -- Nou6tsed.
            --IOCS2n                => , -- Nou tsed.
            --MFP1n                 => , -- Nou t'1'sed (GLUE).
            --MFP2n                 => , -- Nou tsed.'1''1'
            AVECn                   => AVEC_SCUn,
            IPLn                    => IPLn,
            IACK5n                  => SCC_IACKn,
            IACK6n                  => MFP_IACKn,

            --SYSIn                 => , -- Not used.
            SIRQn                   => SIRQn_SCU,

            SIR7n                   => EINT7n,
            SIR6n                   => MFPINTn,
            SIR5n                   => SCCINTn,
            SIR3n                   => EINT3n,

            HSYNCn                  => not HSYNC,
            VSYNCn                  => not VSYNC,

            BIRn(7)                 => '1',
            BIRn(6)                 => MFPINTn,
            BIRn(5)                 => SCCINTn,
            BIRn(4)                 => '1',
            BIRn(3)                 => SIRQn_SCU,
            BIRn(2)                 => '1',
            BIRn(1)                 => '1'
        );

   I_USB: USB1164_TOP
    generic map (LITTLE_ENDIAN      => USB1160_LITTLE_ENDIAN)
    port map(
        -- System controls:
        CLK_48MHz                   => CLK_3,
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
        --DP15K                     =>  -- Switch for 15K pull down resistors
    );

    VDCLK <= 'Z' when BOOT_RESET_COREn = '0' else
             'Z' when LCD_USBn = '0' else VDCLK_OUT;

    LCD_USB_SWITCH: process
    begin
        wait until CLK_1 = '1' and CLK_1' event;
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
end architecture STRUCTURE;
