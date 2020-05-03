### RAM Write Enable Test
---

This test consists of the following steps

1. Read byte from ram
2. Negate the byte's bits
3. Write byte back to the same memory location
4. Re-read byte from the same memory location

The re-read byte is then compared to the originally read byte.  As long as they
don't match the test will pass, otherwise it will result in the following error.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x0b |     11 |    001011 |       x0 / 11 | RAM UNWRITABLE |
