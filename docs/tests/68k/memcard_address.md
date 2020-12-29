## Memory Card Address Test
---
The memory card address test consists of writing an incrementing word at each
address line up to the needed address lines for the memory card size.  These
values are then re-read to verify they are correct.

|  Address |  Value |
| :------: | :-----:|
| 0x800000 | 0x0101 |
| 0x800002<sup>1</sup>| 0x0202 |
| 0x800004 | 0x0303 |
| 0x800008 | 0x0404 |
| 0x800010 | 0x0505 |
| 0x800020 | 0x0606 |
| 0x800040 | 0x0707 |
|  etc     |  etc   |

<sup>1</sup> If the memory card is 16-bit double wide, address 0x800002 is skipped for
testing as it gets mapped to address 0x800000.  The value is still incremented
though.

While data is being read/written as words, if the card is 8-bit only the lower
byte will be compared. In this case if an error is detected the upper byte for
the 'actual' and 'expected' will be displayed as 0x00

In the event one of the re-read has the wrong data it will print out the
following error, along with the address with the error, 'actual' data read, and
'expected' data read.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x85 |    133 |       N/A |           N/A | MEMCARD ADDRESS |

```
MEMCARD ADDRESS

ADDRESS:  800000
ACTUAL:   0005
EXPECTED: 0001



DETECTED:

DATA BUS: 8-BIT
    SIZE:    2 KB

D: Return to menu
```

Based on the 'actual' value you can deduce the likely bad address line.  In
this case 0x800010 (68k's A4 <=> IC <=> memory card's A3).
