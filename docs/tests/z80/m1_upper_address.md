### M1 Upper Address Test
---

The running diag m1 code is only 2048 (0x800) bytes, while the diag rom is
128KB / 1Mbit.  The first 32KB of the rom is filled with copies of the running
code (rest is used by [bankswitch](m1_bank.md) tests).  At offset byte 2043
(0x7fb) of each copy contains the copy number.  The running code will be 0x0,
first copy is 0x01, 2nd is 0x02, ... 15th is 0xf.

The upper address test consists of verifying each copy has the correct
copy number value.  If there is a mismatch it will result in the following
error.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :---------- |
|  0x02 |      2 |    000010 |       x0 / x2 | M1 UPPER ADDRESS (fixed region) |
