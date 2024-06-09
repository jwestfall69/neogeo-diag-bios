
# Error Codes

This document contains a list of possible errors that may occur and how
those error are communicated to the user.

### Beep Codes:
The diag m1 (when active) supports generating a beep code to help identify
an error that may not be visible from a corrupt/bad video output.

The diag m1 may generate a beep code by itself, if it detects an issue within
the audio/Z80 subsystem, or it may play one on behalf of the diag bios.  An
error code sent from the diag bios to the diag m1 will only happen after the
(successful) 68k <=> Z80 comm test.  As such, any diag bios test that happens
before the comm test will not generate a beep code.  These tests are identified
by the beep code having an * in front of it in the 68k Error codes table below.
Error codes >= 0x80 will not generate a beep code.

Beeps consist of a series of high and low tones that correspond to the Beep
Codes in the tables below.  A 1 will be a high tone and 0 an low tone, going
left to right.

Z80 / diag m1 generated errors have 6 beeps.<br>
68k / diag bios generated errors have 7 beeps.

### Credit Leds:
On MVS hardware the diag bios will also display the error number on the
player1/2 credit leds.  Player 1 credit leds will have the 2 upper digits of the
error and Player 2 the lower 2 digits.  The neo geo hardware doesn't seem to
allow the left digit on a player's credit leds to be 0 and instead just leaves
it off/empty.  Error codes >= 0x80 will not display to the credit leds.

In the tables below a value of 'x' in meant to represent the digit is off/empty.

### Error Addresses:
Error addresses are an additional way to get the error code, specifically in the case
where your screen/fix layer is messed up and don't have a diag cart or sound isn't working.

To enable error addresses you need to press and hold down 'A' while automatic tests
are running.  If an error is encountered during automatic testing, after printing
the error, if the 'A' button is pressed it will cause the CPU to jump to specific
addresses in the diag rom that are a tight loop. The address it jumps to (and stays
near) will have the error code encoded into the address.

68k CPU error address = `0xc06000 | (error_code << 5)`

Using a logic probe you probe the 68k's address lines to figure out the error code.

| ADDRESS LINE | MEANING | DIP CPU PIN | PLCC CPU PIN |
|---|---|---|---|
| A1 | None (pulsing) | 29 | 32 |
| A2 | None (pulsing) | 30 | 33 |
| A3 | None (low) | 31 | 34 |
| A4 | None (low) | 32 | 35 |
| A5 | Error Code Bit 0 | 33 | 36 |
| A6 | Error Code Bit 1 | 34 | 37 |
| A7 | Error Code Bit 2 | 35 | 38 |
| A8 | Error Code Bit 3 | 36 | 39 |
| A9 | Error Code Bit 4 | 37 | 40 |
| A10 | Error Code Bit 5 | 38| 41 |
| A11 | Error Code Bit 6 | 39 | 42 |
| A12 | Error Code Bit 7 (always low) | 40 | 43 |
| A13 | None (pulsing)| 41 | 44 |
| A14 | None (pulsing)| 42 | 45 |
| A15 | None (low)| 43 | 46 |
| A16 | None (low)| 44 | 47 |
| A17 | None (low)| 45 | 48 |
| A18 | None (low)| 46 | 49 |
| A19 | None (low)| 47 | 50 |
| A20 | None (low)| 48 | 51 |

When probing the error code address lines, if its pulsing consider it a 1, if its 100%
low its a 0. You should first verify that A12-A15 are low, pulsing, pulsing, low as shown
in the table to confirm the diag bios successfully jumped to an error address.  Once you
have the error code byte look it up in the 68k Error Codes table below.

Additionally, if an error address is jumped to it should print "ERROR ADDRESS TRIGGERED"
near the bottom of the screen.

### Z80 Error Codes:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x01 |      1 |    000001 |       x0 / x1 | [M1 CRC ERROR (fixed region)](tests/z80/m1_crc.md) |  
|  0x02 |      2 |    000010 |       x0 / x2 | [M1 UPPER ADDRESS (fixed region)](tests/z80/m1_upper_address.md) |
|  0x04 |      4 |    000100 |       x0 / x4 | [RAM DATA (00)](tests/z80/ram_data.md) |
|  0x05 |      5 |    000101 |       x0 / x5 | [RAM DATA (55)](tests/z80/ram_data.md) |
|  0x06 |      6 |    000110 |       x0 / x6 | [RAM DATA (AA)](tests/z80/ram_data.md) |
|  0x07 |      7 |    000111 |       x0 / x7 | [RAM DATA (FF)](tests/z80/ram_data.md) |
|  0x08 |      8 |    001000 |       x0 / x8 | [RAM ADDRESS (A0-A7)](tests/z80/ram_addres.md) |
|  0x09 |      9 |    001001 |       x0 / x9 | [RAM ADDRESS (A8-A10)](tests/z80/ram_addres.md) |
|  0x0a |     10 |    001010 |       x0 / 10 | [RAM DEAD OUTPUT](tests/z80/ram_oe.md) |
|  0x0b |     11 |    001011 |       x0 / 11 | [RAM UNWRITABLE](tests/z80/ram_we.md) |
|  0x0c |     12 |    001100 |       x0 / 12 | [68k->Z80 COMM ISSUE (HANDSHAKE)](tests/comm_test.md) |
|  0x0d |     13 |    001101 |       x0 / 13 | [68k->Z80 COMM ISSUE (CLEAR)](tests/comm_test.md) |
|  0x0e |     14 |    001110 |       x0 / 14 | [SM1 DEAD OUTPUT](tests/z80/sm1_oe.md) |
|  0x0f |     15 |    001111 |       x0 / 15 | [SM1 CRC ERROR](tests/z80/sm1_crc.md) |
|  0x10 |     16 |    010000 |       x0 / 16 | [YM2610 I/O ERROR](tests/z80/ym2610_io.md) |
|  0x11 |     17 |    010001 |       x0 / 17 | [YM2610 TIMER TIMING (FLAG)](tests/z80/ym2610_timer_flag.md) |
|  0x12 |     18 |    010010 |       x0 / 18 | [YM2610 TIMER TIMING (IRQ)](tests/z80/ym2610_timer_irq.md) |
|  0x13 |     19 |    010011 |       x0 / 19 | [YM2610 UNEXPECTED IRQ](tests/z80/ym2610_stuck_irq.md) |
|  0x14 |     20 |    010100 |       x0 / 20 | [M1 BANK ERROR (16K)](tests/z80/m1_bank.md) |
|  0x15 |     21 |    010101 |       x0 / 21 | [M1 BANK ERROR (8K)](tests/z80/m1_bank.md) |
|  0x16 |     22 |    010110 |       x0 / 22 | [M1 BANK ERROR (4K)](tests/z80/m1_bank.md) |
|  0x17 |     23 |    010111 |       x0 / 23 | [M1 BANK ERROR (2K)](tests/z80/m1_bank.md) |
|  0x18 |     24 |    011000 |       x0 / 24 | [YM2610 TIMER INIT (FLAG)](tests/z80/ym2610_timer_flag.md) |
|  0x19 |     25 |    011001 |       x0 / 25 | [YM2610 TIMER INIT (IRQ)](tests/z80/ym2610_timer_irq.md) |

### 68k Error Codes:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x40 |     64 |  *1000000 |       x0 / 64 | [BIOS CRC ERROR](tests/68k/bios_crc.md) |
|  0x41 |     65 |  *1000001 |       x0 / 65 | [BIOS ADDRESS (A14-A15)](tests/68k/bios_upper_address.md) |
|  0x44 |     68 |  *1000100 |       x0 / 68 | [WRAM DEAD OUTPUT (LOWER)](tests/68k/wbram_oe.md) |
|  0x45 |     69 |  *1000101 |       x0 / 69 | [WRAM DEAD OUTPUT (UPPER)](tests/68k/wbram_oe.md) |
|  0x46 |     70 |  *1000110 |       x0 / 70 | [BRAM DEAD OUTPUT (LOWER)](tests/68k/wbram_oe.md) |
|  0x47 |     71 |  *1000111 |       x0 / 71 | [BRAM DEAD OUTPUT (UPPER)](tests/68k/wbram_oe.md) |
|  0x48 |     72 |  *1001000 |       x0 / 72 | WRAM DATA (LOWER) |
|  0x49 |     73 |  *1001001 |       x0 / 73 | WRAM DATA (UPPER) |
|  0x4a |     74 |  *1001010 |       x0 / 74 | WRAM DATA (BOTH) |
|  0x4c |     76 |   1001100 |       x0 / 76 | BRAM DATA (LOWER) |
|  0x4d |     77 |   1001101 |       x0 / 77 | BRAM DATA (UPPER) |
|  0x4e |     78 |   1001110 |       x0 / 78 | BRAM DATA (BOTH) |
|  0x50 |     80 |   1010000 |       x0 / 80 | WRAM ADDRESS (A0-A7) |
|  0x51 |     81 |   1010001 |       x0 / 81 | WRAM ADDRESS (A8-A14) |
|  0x52 |     82 |   1010010 |       x0 / 82 | BRAM ADDRESS (A0-A7) |
|  0x53 |     83 |   1010011 |       x0 / 83 | BRAM ADDRESS (A8-A14) |
|  0x54 |     84 |   1010100 |       x0 / 84 | PALETTE BANK0 DATA (LOWER) |
|  0x55 |     85 |   1010101 |       x0 / 85 | PALETTE BANK0 DATA (UPPER) |
|  0x56 |     86 |   1010110 |       x0 / 86 | PALETTE BANK0 DATA (BOTH) |
|  0x58 |     88 |   1011100 |       x0 / 88 | PALETTE BANK1 DATA (LOWER) |
|  0x59 |     89 |   1011101 |       x0 / 89 | PALETTE BANK1 DATA (UPPER) |
|  0x5a |     90 |   1011110 |       x0 / 90 | PALETTE BANK1 DATA (BOTH) |
|  0x5c |     92 |   1011100 |       x0 / 92 | PALETTE ADDRESS (A0-A7) |
|  0x5d |     93 |   1011101 |       x0 / 93 | PALETTE ADDRESS (A8-A12) |
|  0x5e |     94 |   1011110 |       x0 / 94 | VRAM 32K DATA (LOWER) |
|  0x5f |     95 |   1011111 |       x0 / 95 | VRAM 32K DATA (UPPER) |
|  0x60 |     96 |   1100000 |       x0 / 96 | VRAM 32K DATA (BOTH) |
|  0x61 |     97 |   1100001 |       x0 / 97 | VRAM 2K DATA (LOWER) |
|  0x62 |     98 |   1100010 |       x0 / 98 | VRAM 2K DATA (UPPER) |
|  0x63 |     99 |   1100011 |       x0 / 99 | VRAM 2K DATA (BOTH) |
|  0x64 |    100 |   1100100 |       x1 / x0 | VRAM 32K ADDRESS (A0-A7) |
|  0x65 |    101 |   1100101 |       x1 / x1 | VRAM 32K ADDRESS (A8-A14) |
|  0x66 |    102 |   1100110 |       x1 / x2 | VRAM 2K ADDRESS (A0-A7) |
|  0x67 |    103 |   1100111 |       x1 / x3 | VRAM 2K ADDRESS (A8-A10) |
|  0x68 |    104 |   1101000 |       x1 / x4 | VRAM 32K DEAD OUTPUT (LOWER) |
|  0x69 |    105 |   1101001 |       x1 / x5 | VRAM 32K DEAD OUTPUT (UPPER) |
|  0x6a |    106 |   1101010 |       x1 / x6 | VRAM 2K DEAD OUTPUT (LOWER) |
|  0x6b |    107 |   1101011 |       x1 / x7 | VRAM 2K DEAD OUTPUT (UPPER) |
|  0x6c |    108 |   1101100 |       x1 / x8 | PALETTE RAM DEAD OUTPUT (LOWER) |
|  0x6d |    109 |   1101101 |       x1 / x9 | PALETTE RAM DEAD OUTPUT (UPPER) |
|  0x6e |    110 |   1101110 |       x1 / 10 | PALETTE 74245 DEAD OUTPUT (LOWER) |
|  0x6f |    111 |   1101111 |       x1 / 11 | PALETTE 74245 DEAD OUTPUT (UPPER) |
|  0x70 |    112 |  *1110000 |       x1 / 12 | [WRAM UNWRITABLE (LOWER)](tests/68k/wbram_we.md) |
|  0x71 |    113 |  *1110001 |       x1 / 13 | [WRAM UNWRITABLE (UPPER)](tests/68k/wbram_we.md) |
|  0x72 |    114 |  *1110010 |       x1 / 14 | [BRAM UNWRITABLE (LOWER)](tests/68k/wbram_we.md) |
|  0x73 |    115 |  *1110011 |       x1 / 15 | [BRAM UNWRITABLE (UPPER)](tests/68k/wbram_we.md) |
|  0x74 |    116 |   1110100 |       x1 / 16 | PALETTE RAM UNWRITABLE (LOWER) |
|  0x75 |    117 |   1110101 |       x1 / 17 | PALETTE RAM UNWRITABLE (UPPER) |
|  0x78 |    120 |   1111000 |       x1 / 20 | VRAM 32K UNWRITABLE (LOWER) |
|  0x79 |    121 |   1111001 |       x1 / 21 | VRAM 32K UNWRITABLE (UPPER) |
|  0x7a |    122 |   1111010 |       x1 / 22 | VRAM 2K UNWRITABLE (LOWER) |
|  0x7b |    123 |   1111011 |       x1 / 23 | VRAM 2K UNWRITABLE (UPPER) |
|  0x7c |    124 |   1111100 |       x1 / 24 | MMIO DEAD OUTPUT |
|  0x80 |    128 |       N/A |           N/A | [MEMCARD 245/G0 DEAD OUTPUT (LOWER)](tests/68k/memcard_output.md) |
|  0x81 |    129 |       N/A |           N/A | [MEMCARD 245/G0 DEAD OUTPUT (UPPER)](tests/68k/memcard_output.md) |
|  0x82 |    130 |       N/A |           N/A | [MEMCARD DEAD OUTPUT (LOWER)](tests/68k/memcard_output.md) |
|  0x83 |    131 |       N/A |           N/A | [MEMCARD UNWRITABLE (LOWER)](tests/68k/memcard_writable.md) |
|  0x84 |    132 |       N/A |           N/A | [MEMCARD UNWRITABLE (UPPER)](tests/68k/memcard_writable.md) |
|  0x85 |    133 |       N/A |           N/A | [MEMCARD DATA](tests/68k/memcard_data.md) |
|  0x88 |    136 |       N/A |           N/A | [MEMCARD ADDRESS](tests/68k/memcard_address.md) |

### 68k Errors, No Error Code:
The following are error messages that do not generate an error code.

These are all associated with the [68k <=> Z80 Comm Test](tests/comm_test.md).

```
Z80 SLOT SWITCH IGNORED (SM1)
SM1 OTHERWISE LOOKS UNRESPONSIVE
```
```
Z80->68k COMM ISSUE (HELLO)
```
```
Z80->68k COMM ISSUE (ACK)
```

This message is associated with the [Watchdog Stuck Test](tests/68k/watchdog_stuck.md)

```
WATCHDOG DELAY...

IF THIS TEXT REMAINS HERE...
THEN SYSTEM IS STUCK IN WATCHDOG
```
