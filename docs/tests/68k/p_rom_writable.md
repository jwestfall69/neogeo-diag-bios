# P2 ROM Writable Test

This test requires a custom diag prog board.

The purpose of this test is to verify the P2 ROM region is writable.  Writes to this region are often used for P ROM bank switching and/or communicating with custom chips on the prog board.

The test consists of reading from address 0x200000, writing the xor'd read data back to 0x200000, then re-reading 0x200000.  If the re-read data is the same as the originally read data it will trigger one of the following errors.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x91 |    145 |       N/A |           N/A | P2 UNWRITABLE (LOWER) |
|  0x92 |    146 |       N/A |           N/A | P2 UNWRITABLE (UPPER) |

If this test fails you will want to look into PORTWEL (lower) and/or PORTWEU (upper) signals on the cart slot.
