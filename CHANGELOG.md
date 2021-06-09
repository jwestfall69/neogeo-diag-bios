# Change Log
---

#### v0.19a00 (master/unreleased)
* SP1: Re-implement color bars so they work on AES
* SP1: Add SMPTE color bars
* SP1: Go back to main menu after manual work/backup ram test
* SP1: Send error code to credit leds on MVS hardware
* SP1: Attempt to auto-detect if M1 is active (ie: on AES & MV1-B/C)
* SP1: Display when M1 is active
* SP1: Display slot number if a slot switch was done
* SP1: Display when SM1 tests were run
* SP1: Pressing ABCD after automatic tests will goto the main menu
* SP1: Memory Card testing
* SP1: Video DAC test
* SP1+M1: Make 68k <=> Z80 communication test less finicky about timings
* SP1+M1: Split 68k <=> Z80 communication into 2 error codes (HELLO vs ACK)
* SP1+M1: SM1 output enable test
* SP1+M1: SM1 checksum test
* M1: Fix broken ram address test
* M1: Add ram output enable test
* M1: Add ram write enable test
* M1: Use rogue YM2610 IRQ as a way to recover from a failed slot switch
* M1: Fix looping forever waiting on unset of YM2610's busy bit

Below is smkdan's original change log

#### v0.19 (6/4/2013)
* SP1: Added "MISC. INPUT TEST" to test state of memory card and system config inputs.
* SP1: Added "WATCHDOG DELAY" text which will stay on screen if system is stuck in watchdog.
* SP1: Grayed MVS specific options in the menu.
* SP1: Changed inputs to be more intuitive:
  * Holding D is required for Z80 testing (previously, holding D skipped it).
  * Holding C is required for backup RAM testing on AES (previously, holding C skipped it).
  * For AES, holding B when doing Z80 test is no longer needed (still required for MV1B/MV1C).

#### v0.18b (13/9/2012)
* SP1: Fixed MMIO read tests accidentally testing MVS specific hardware on AES systems.

#### v0.18 (13/9/2012)
* SP1: Added some MMIO read tests with onscreen repair info (mainly for 2nd generation chips).

#### v0.17 (31/8/2012)
* SP1: Added VRAM + palette RAM test loops.
* SP1: Changed RAM test loop counters to use larger hex values for consistency.

#### v0.16 (25/8/2012)
* SP1: Added WRAM/BRAM test loop similar to what the MVS BIOS does with all DIPs on.

#### v0.15 (21/8/2012)
* SP1: Fixed regression stopping expected Z80 code from appearing (did not affect actual tests).

#### v0.14 (18/8/2012)
* SP1: Added option to try and continue Z80 testing when slot switch appears to fail.

#### v0.13 (7/8/2012)
* SP1: Fixed regression that would stop WRAM/BRAM tests from reporting errors.
* SP1: Added tests that attempt to detect unwritable RAM.

#### v0.12 (5/8/2012)
* SP1: Added controller test.

#### v0.11 (2/8/2012)
* SP1: BRAM address test incorrectly came before data test. Swapped them around.

#### v0.10 (1/8/2012)
* SP1+M1: Initial release
