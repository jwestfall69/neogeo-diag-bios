# Tests
---

#### BIOS/68k Automatic Tests:
Below is a breakdown of the tests and the order they are performed during
automatic testing.

This first chunk of tests are written such that they don't touch the work ram.
* [Watchdog Stuck Test](tests/68k/watchdog_stuck.md)
* [BIOS Upper Address](tests/68k/bios_upper_address.md)
* [BIOS CRC32 Test](tests/68k/bios_crc.md)
* [Work Output Enable Tests](tests/68k/work_ram_oe.md)
  * Work RAM Upper
  * Work RAM Lower
* [Work RAM Write Enable Tests](tests/68k/work_ram_we.md)
  * Work RAM Lower
  * Work RAM Upper
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
  * [Backup RAM Output Enable Tests](tests/68k/backup_ram_oe.md)
    * Backup RAM Upper
    * Backup RAM Lower
  * [Backup RAM Write Enable Tests](tests/68k/backup_ram_we.md)
    * Backup RAM Upper
    * Backup RAM Lower
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
* Video RAM 2k Tests
  * Video RAM 2K Output Enable Tests
    * Video RAM 2K Lower
    * Video RAM 2K Upper
  * Video RAM 2K Write Enable Test
    * Video RAM 2K Lower
    * Video RAM 2K Upper
  * Video RAM 2K Data Tests
    * Pattern 0x0000
    * Pattern 0x5555
    * Pattern 0xaaaa
    * Pattern 0xffff
  * Video RAM 2K Address Tests
    * Address Lines a0 to a7
    * Address Lines a8 to a10
* Video RAM 32k Tests
  * Video RAM 32K Output Enable Tests
    * Video RAM 32K Lower
    * Video RAM 32K Upper
  * Video RAM 32K Write Enable Test
    * Video RAM 32K Lower
    * Video RAM 32K Upper
  * Video RAM 32K Data Tests
    * Pattern 0x0000
    * Pattern 0x5555
    * Pattern 0xaaaa
    * Pattern 0xffff
  * Video RAM 32K Address Tests
    * Address Lines a0 to a7
    * Address Lines a8 to a14
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

 #### BIOS/68k Manual Tests:
 These are the tests started by via the menu.

 * Calendar I/O (MVS Only)
 * Color Bars Basic
 * Color Bars SMPTE
 * [Video Dac Tests](tests/68k/video_dac.md)
 * Controller Test
 * Work RAM Test Loop
   * Work RAM Data Tests
     * Pattern 0x0000
     * Pattern 0x5555
     * Pattern 0xaaaa
     * Pattern 0xffff
   * Work RAM Address Tests
     * Address Lines a0 to a7
     * Address Lines a8 to a14
 * Backup RAM Test Loop (MVS only)
   * Backup RAM Data Tests
     * Pattern 0x0000
     * Pattern 0x5555
     * Pattern 0xaaaa
     * Pattern 0xffff
   * Backup RAM Address Tests
     * Address Lines a0 to a7
     * Address Lines a8 to a14
 * Palette RAM Test Loop
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
 * 32K Video RAM Test Loop
   * 32K Video RAM Data Tests
     * Pattern 0x0000
     * Pattern 0x5555
     * Pattern 0xaaaa
     * Pattern 0xffff
   * 32K Video RAM Address Tests
     * Address Lines a0 to a7
     * Address Lines a8 to a14
 * 2K Video RAM Test Loop
   * 2K Video RAM Data Tests
     * Pattern 0x0000
     * Pattern 0x5555
     * Pattern 0xaaaa
     * Pattern 0xffff
   * 2K Video RAM Address Tests
     * Address Lines a0 to a7
     * Address Lines a8 to a10
 * Misc Input Test
 * [CPU/PAL Address Test](tests/68k/cpu_pal_addr.md)
 * [Memory Card Tests](tests/68k/memcard.md)
   * [Memory Card Inserted](tests/68k/memcard_detect.md)
   * [Memory Card Write Protect Check](tests/68k/memcard_detect.md)
   * [Memory Card Output Tests](tests/68k/memcard_output.md)
     * Memory Card 245/G0 Lower
     * Memory Card 245/G0 Upper
     * Memory Card Lower
   * [Memory Card Detect Size + Bus Width](tests/68k/memcard_detect.md)
   * [Memory Card Writable Tests](tests/68k/memcard_writable.md)
     * Memory Card Lower
     * Memory Card Upper
   * [Memory Card Data Tests](tests/68k/memcard_data.md)
     * Pattern 0x0000
     * Pattern 0x5555
     * Pattern 0xaaaa
     * Pattern 0xffff
   * [Memory Card Address Test](tests/68k/memcard_address.md)
 * [P ROM Bus Tests (Custom Cart)](tests/68k/p_rom_bus.md)
   * [P ROM Bus Output Tests](tests/68k/p_rom_output.md)
     * P1 ROM Bus 245/NEO-G0/NEO-BUF Lower
     * P1 ROM Bus 245/NEO-G0/NEO-BUF Upper
     * P2 ROM Bus 245/NEO-G0/NEO-BUF Lower
     * P2 ROM Bus 245/NEO-G0/NEO-BUF Upper
     * P1 ROM Bus Lower
     * P1 ROM Bus Upper
     * P2 ROM Bus Lower
     * P2 ROM Bus Upper
   * [P2 ROM Bus Writable](tests/68k/p_rom_writable.md)
     * P2 ROM Bus Lower
     * P2 ROM Bus Upper
   * [P ROM Bus Data Tests](tests/68k/p_rom_data_bus.md)
     * Pattern 0x0000
     * Pattern 0x5555
     * Pattern 0xaaaa
     * Pattern 0xffff
   * [P ROM Bus Address Tests](tests/68k/p_rom_address_bus.md)




 #### M1/Z80 Tests:
 Below is a breakdown of the tests and the order they are preformed during
 automatic testing.

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
 * [SM1 ROM Output Enable Test](tests/z80/sm1_oe.md) (if slot switch)
 * [SM1 ROM CRC32 Test](tests/z80/sm1_crc.md) (if slot switch)

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
