### Backup RAM Write Enable Tests
---

This test consists of the reading a byte from ram, writing data to the same
byte in ram, re-reading it and verifying it isn't the original byte.

Separate tests are performed to isolate testing the upper and lower RAM chips.

No beep code will be played since these tests happen before the 68k <=> Z80
communication test.

#### Backup RAM
The backup RAM test will only run on MVS hardware.

Backup RAM lower is tested first, then backup RAM upper.  These will result in
the corresponding error below if one fails.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x72 |    114 |  *1110010 |       x1 / 14 | BRAM UNWRITABLE (LOWER) |
|  0x73 |    115 |  *1110011 |       x1 / 15 | BRAM UNWRITABLE (UPPER) |
