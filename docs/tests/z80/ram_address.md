### RAM Address Tests
---

The RAM Address tests consists of writing a incrementing byte to memory
addresses then going back and re-reading to verify the bytes match up with
what was written.  Because there are only 256 possible values of a byte, the
test is broken up to into 2.

1. Memory locations 0xf800 to 0xf8ff (address lines 0 to 7), writing an
incrementing byte at each memory location.
2. Memory locations 0xf800 to 0xffff (address lines 8 to 10), writing an
incrementing bytes for every 256 bytes of ram.

If one of these fail it will result in one of the following errors:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x08 |      8 |    001000 |       x0 / x8 | RAM ADDRESS (A0-A7) |
|  0x09 |      9 |    001001 |       x0 / x9 | RAM ADDRESS (A8-A10) |
