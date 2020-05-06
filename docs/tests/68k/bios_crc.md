## BIOS CRC32 Test
---

The diag bios rom is 128KB / 1MBit in size, but the running diag bios code only
resides within the first 16384 (0x4000) bytes of the rom.  The remaining is used
by the [upper address](sp1_upper_address.md) test.

At offset 16380 (0x3ffc) of the diag bio rom is the expected CRC32 value and is
filled in by gen-crc-mirror as part of the build process.  The CRC32 value
for the test is calculated from bytes 0 to 16379 (0x3ffb) of the running
rom.  If the calculated CRC32 doesn't match up with the expected CRC32 value
it will result in the following error.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x40 |     64 |  *1000000 |       x0 / 64 | BIOS CRC ERROR |

No beep code will be played since this test happens before the 68k <=> Z80
communication test.

In addition to the error message, both the expected and calculated CRC32
values will be provided.

```
BIOS CRC ERROR

ACTUAL:   1234ABCD
EXPECTED: ABCD1234
```
