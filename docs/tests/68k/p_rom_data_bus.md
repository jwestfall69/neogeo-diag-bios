# P ROM Data Bus Test

This test requires a custom diag prog board.

The purpose of this test is to verify the data lines between the P roms and the CPU are working correctly.  This done by writing/reading a series of test patterns (0x0000, 0x5555, 0xaaaa, 0xffff) to a small subset of the SRAM on the diag prog board. If the read data doesn't match what was written its an indication of a data bus issue and will trigger the following alert:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x93 |    147 |       N/A |           N/A | P DATA BUS |


Example
```
P DATA BUS

ADDRESS:  200200
ACTUAL:   8000
EXPECTED: 0000
