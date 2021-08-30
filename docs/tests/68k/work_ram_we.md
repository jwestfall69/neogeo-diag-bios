### Work RAM Write Enable Tests
---

This test consists of the reading a byte from ram, writing data to the same
byte in ram, re-reading it and verifying it isn't the original byte.

Separate tests are performed to isolate testing the upper and lower RAM chips.

No beep code will be played since these tests happen before the 68k <=> Z80
communication test.

#### Work RAM
Work RAM lower is tested first, then work RAM Upper.  These will result in the
corresponding error below if one fails.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x70 |    112 |  *1110000 |       x1 / 12 | WRAM UNWRITABLE (LOWER) |
|  0x71 |    113 |  *1110001 |       x1 / 13 | WRAM UNWRITABLE (UPPER) |
