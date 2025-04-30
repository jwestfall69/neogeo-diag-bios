### YM2610 Data Tests
----
The YM2610 data tests consist of writing a byte and reading it back from the
YM2610.  This is done using bytes 0x00, 0x55, 0xaa and 0xff.  Should the
read byte not match the written byte it will result in one of the following
errors.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x1c |     28 |    011100 |       x0 / 28 | YM2610 DATA (00) |
|  0x1d |     29 |    011101 |       x0 / 29 | YM2610 DATA (55) |
|  0x1e |     30 |    011110 |       x0 / 30 | YM2610 DATA (AA) |
|  0x1f |     31 |    011111 |       x0 / 31 | YM2610 DATA (FF) |
