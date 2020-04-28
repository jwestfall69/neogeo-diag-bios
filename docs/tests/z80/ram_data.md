### RAM Data Tests
---

The RAM Data tests consists of writing a byte and reading it back from each
memory location.  This is done using bytes 0x00, 0x55, 0xaa and 0xff bytes.
Should the read byte not match the written byte it will result in one of the
following errors:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x04 |      4 |    000100 |       x0 / x4 | RAM DATA (00) |
|  0x05 |      5 |    000101 |       x0 / x5 | RAM DATA (55) |
|  0x06 |      6 |    000110 |       x0 / x6 | RAM DATA (AA) |
|  0x07 |      7 |    000111 |       x0 / x7 | RAM DATA (FF) |

The order of the tests are 0x00, 0x55, 0xaa and then 0xff.
