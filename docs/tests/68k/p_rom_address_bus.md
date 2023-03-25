## P ROM Address Bus Test

This test requires a custom diag prog board.

The purpose of this test is to verify the address lines between the P roms and the CPU are working correctly.  This test consists of writing an incrementing word at each address line.  These values are then re-read to verify they are correct.

|  Address |  Value | Address Line |
| :------: | :-----:|:------------:|
| 0x200000 | 0x0101 | none
| 0x200002 | 0x0202 | A1
| 0x200004 | 0x0303 | A2
| 0x200008 | 0x0404 | A3
| 0x200010 | 0x0505 | A4
| 0x200020 | 0x0606 | A5
| 0x200040 | 0x0707 | A6
| ...      | ...    |
| 0x240000 | 0x1313 | A18
| 0x280000 | 0x1414 | A19


In the event one of the re-read has the wrong data it will print out the following error, along with the address with the error, 'actual' data read, and 'expected' data read.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x94 |    148 |       N/A |           N/A | P ADDRESS BUS |

```
P ADDRESS BUS

ADDRESS:  200000
ACTUAL:   0505
EXPECTED: 0101
```

From the values you can deduce which address line is being problematic.  In the example there are 2 possibilities both pointing to an issue with address line A4.

1. A4 is stuck high, causing the 0x0101 written to 0x200000 to actually end up in 0x200010.
2. A4 is stuck low, causing the 0x0505 written to 0x200010 to actually end up in 0x200000

In both cases when we goto read the value from 0x200000 we end up with 0x0505.