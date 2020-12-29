# Memory Card Writable Tests
---
This test will try to determine if we are able to write to the memory on the
memory card.  The test is done against the low byte, then the upper byte if
the card is 16-bit.

The test consists of reading 0x800000, writing the xor'd read data back to
0x800000, then re-reading 0x800000.  If the re-read data is the same as the
originally read data it will trigger one of the following errors.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x83 |    131 |       N/A |           N/A | MEMCARD UNWRITABLE (LOWER) |
|  0x84 |    132 |       N/A |           N/A | MEMCARD UNWRITABLE (UPPER) |
