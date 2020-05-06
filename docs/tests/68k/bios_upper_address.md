### BIOS Upper Address Test
---

The running diag bios code is only 16384 (0x4000) bytes, while the diag bios
rom is 128KB / 1Mbit.  The remaining 116KB is filled with 7 copies of the
diag bios code.  At byte offset 16379 (0x3ffb) of each copy contains the copy
number.  The running code will be 0x0, first copy is 0x01, 2nd is 0x02,
... 7th is 0x7.  These values are filling in by gen-crc-mirror as part of the
build process.

The upper address test consists of verifying each copy has the correct
copy number value.  If there is a mismatch it will result in the following
error.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x41 |     65 |  *1000001 |       x0 / 65 | BIOS ADDRESS (A13-A15)] |

No beep code will be played since this test happens before the 68k <=> Z80
communication test.

In addition to the error message, both the expected and actual copy numbers
will be provided.

```
BIOS ADDRESS (A13-A15)

ACTUAL:    01
EXPECTED:  00
```

These values can give you an idea of which address line(s) are having issues.

#### EXPECTED == 0:
When expected is 0, it implies one or more of the a13 to a15 address lines are
stuck high or maybe floating.  This causes the diag bios to be running from one
of the copies instead of 0x000000 of the diag bios rom.  The following table
should give an idea of what address line(s) to look at given the actual value.

| EXPECTED | ACTUAL | Suspect Address Line(s) |
| :------: | :----: | :---------------------- |
|        0 |      1 |                     a13 |
|        0 |      2 |                     a14 |
|        0 |      3 |               a13 + a14 |
|        0 |      4 |                     a15 |
|        0 |      5 |               a13 + a15 |
|        0 |      6 |               a14 + a15 |
|        0 |      7 |         a13 + a14 + a15 |

#### EXPECTED != 0:
When expected is not 0, it implies one or more of the a13 to a15 address lines
are stuck low or maybe floating.  In this scenario the actual value should
always be less then the expected.

In theory there should only be 3 possible combinations when expected != 0,
since the remaining expected values are the result of a combination of the
a13, a14 and a15 address lines. If more then one of the a13 to a15 address
lines are stuck low the test will only report about the first one.

| EXPECTED | ACTUAL | Suspect Address Line(s) |
| :------: | :----: | :---------------------- |
|        1 |      0 |                     a13 |
|        2 |      1 |                     a14 |
|        4 |      2 |                     a15 |
