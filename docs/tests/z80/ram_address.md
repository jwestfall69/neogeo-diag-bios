### RAM Address Tests
---

The RAM address tests consists of writing a incrementing byte to RAM
addresses then going back and re-reading to verify the bytes match up with
what was written.  Because there are only 256 possible values of a byte, the
test is broken up to into 2.

1. RAM locations 0xf800 to 0xf8ff (address lines a0 to a7), writing an
incrementing byte at each memory location.
2. RAM locations 0xf800 to 0xffff (address lines a8 to a10), writing an
incrementing byte for every 256 bytes of ram.

If one of these fail it will result in one of the following errors:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x08 |      8 |    001000 |       x0 / x8 | RAM ADDRESS (A0-A7) |
|  0x09 |      9 |    001001 |       x0 / x9 | RAM ADDRESS (A8-A10) |
