# Tests
---

Below is a breakdown of the tests and the order they are preformed during
automatic testing.


#### BIOS/68k Tests:

This first chunk of tests are written such that they don't touch work ram.
* Watchdog Stuck Test
* BIOS Upper Address
* BIOS CRC32 Test
* RAM Output Enable Tests
  * Work RAM Upper
  * Work RAM Lower
  * Backup RAM Upper (if MVS or force enabled on AES)
  * Backup RAM Lower (if MVS or force enabled on AES)
* RAM Write Enable Tests
  * Work RAM Lower
  * Work RAM Upper
  * Backup RAM Lower (if MVS)
  * Backup RAM Upper (if MVS)
* Work RAM Data Tests
  * Pattern 0x0000
  * Pattern 0x5555
  * Pattern 0xaaaa
  * Pattern 0xffff
* Work RAM Address Tests
  * Address Lines a0 to a7
  * Address Lines a8 to a14

At this point work ram starts getting used.

* [68k <=> Z80 Communication Test](tests/comm_test.md) (if enabled)
* Backup RAM Tests (if MVS or force enabled on AES)
  * Backup RAM Data Tests
    * Pattern 0x0000
    * Pattern 0x5555
    * Pattern 0xaaaa
    * Pattern 0xffff
  * Backup RAM Address Tests
    * Address Lines a0 to a7
    * Address Lines a8 to a14
* Palette RAM Tests
  * Palette RAM Output Enable Tests
    * Palette RAM LS245 Lower
    * Palette RAM LS245 Upper
    * Palette RAM Lower
    * Palette RAM Upper
  * Palette RAM Write Enable Tests
    * Palette RAM Lower
    * Palette RAM Upper
  * Palette RAM Data Tests
    * Palette Bank0
      * Pattern 0x0000
      * Pattern 0x5555
      * Pattern 0xaaaa
      * Pattern 0xffff
    * Palette Bank1
      * Pattern 0x0000
      * Pattern 0x5555
      * Pattern 0xaaaa
      * Pattern 0xffff      
  * Palette RAM Address Tests
    * Address Lines a0 to a7
    * Address Lines a8 to a12
* Video RAM Tests
  * Video RAM Output Enable Tests
    * 32K Video RAM Lower
    * 32K Video RAM Upper
    * 2K Video RAM Lower
    * 2K Video RAM Upper
  * Video RAM Write Enable Tests
    * 32K Video RAM Lower
    * 32K Video RAM Upper
    * 2K Video RAM Lower
    * 2K Video RAM Upper
  * Video RAM Data Tests
    * 32K Video RAM
      * Pattern 0x0000
      * Pattern 0x5555
      * Pattern 0xaaaa
      * Pattern 0xffff
    * 2K Video RAM
      * Pattern 0x0000
      * Pattern 0x5555
      * Pattern 0xaaaa
      * Pattern 0xffff
  * Video RAM Address Tests
    * 32K Video RAM
      * Address Lines a0 to a7
      * Address Lines a8 to a14
    * 2K Video RAM
      * Address Lines a0 to a7
      * Address Lines a8 to a10
* MMIO Tests
  * MMIO Output Enable (Byte)
    * REG_DIPSW (if MVS)
    * REG_SYSTYPE (if MVS)
    * REG_STATUS_A (if MVS)
    * REG_P1CNT
    * REG_SOUND
    * REG_P1CNT
    * REG_STATUS_B
  * MMIO Output Enable (Word)
    * REG_VRAMRW


 #### M1/Z80 Tests:

 This first chunk of tests are written such that they don't touch ram.
 * [YM2610 Noise Maker](tests/z80/ym2610_noise_maker.md)
 * [M1 ROM Upper Address Test](tests/z80/m1_upper_address.md)
 * [M1 ROM CRC32 Test](tests/z80/m1_crc.md)
 * [RAM Output Enable Test](tests/z80/ram_oe.md)
 * [RAM Write Enable Test](tests/z80/ram_we.md)
 * [RAM Data Tests](tests/z80/ram_data.md)
   * Pattern 0x00
   * Pattern 0x55
   * Pattern 0xaa
   * Pattern 0xff
 * [RAM Address Tests](tests/z80/ram_address.md)
   * Address Lines a0 to a7
   * Address Lines a8 to a10
 * [YM2610 IO Tests](tests/z80/ym2610_io.md)
   * YM2610 Busy Bit Test
   * YM2610 Timer Register Write/Re-Read Test
   * YM2610 Register 0x00 Data Tests
     * Pattern 0x00
     * Pattern 0x55
     * Pattern 0xaa
     * Pattern 0xff
 * [68k <=> Z80 Communication Test](tests/comm_test.md)

At this point ram starts getting used.

 * [YM2610 Stuck IRQ Test](tests/z80/ym2610_stuck_irq.md)
 * [YM2610 Timer Flag Test](tests/z80/ym2610_timer_flag.md)
 * [YM2610 Timer IRQ Test](tests/z80/ym2610_timer_irq.md)
 * [M1 ROM Zone/Bank Tests](tests/z80/m1_bank.md)
   * Zone3 (16K)
   * Zone2 (8K)
   * Zone1 (4K)
   * Zone0 (2k)
 * [YM2610 Noise Maker](tests/z80/ym2610_noise_maker.md)
