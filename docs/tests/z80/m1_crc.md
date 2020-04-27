### M1 CRC32 Test
---

The diag m1 rom is 128KB / 1MBit in size, but the running diag m1 code only
resides within the first 2048 (0x800) bytes of the rom.  The remaining is used
by the [upper address](m1_upper_address.md) and [bank](m1_bank.md) tests.

At offset 2044 (0x7fc) of the diag m1 rom is the expected CRC32 value and is
filled in by gen-crc-mirror-bank as part of the build process.  The CRC32
value for the test is calculated from bytes 0 to 2043 (0x7fb) of the rom.  If
the calculated CRC32 doesn't match up with the expected CRC32 value it will
result in the following error.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :---------- |
|  0x01 |      1 |    000001 |       x0 / x1 | M1 CRC ERROR (fixed region) |  
