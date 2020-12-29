# Memory Card Data Tests
---
The memory card data tests consist of writing a word to a memory address,
writing a poison word (xor of original written data) to an alternate memory
address and then re-reading the original memory address to make sure the data
is correct.  This is repeated for each address and each data pattern.

In testing it was found if a data pin is floating between the memory card's
memory and the 245/NEO-G0 it will result in a read taking on the same bit state
as the last written immediate value.  This is reason for the added poison write
for this test vs other data tests.

While data is being read/written as words, if the card is 8-bit only the lower
byte will be compared.  In this case if an error is detected the upper byte
for the 'actual' and 'expected' will be displayed as 0x00

In the event one of the re-read has the wrong data it will print out the
following error, along with the address with the error, 'actual' data read,
and 'expected' data read.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x85 |    133 |       N/A |           N/A | MEMCARD DATA |

The following test patterns are done 0x0000, 0x5555, 0xaaaa, 0xffff

Example
```
MEMCARD DATA

ADDRESS:  800000
ACTUAL:   0080
EXPECTED: 0000



DETECTED:

DATA BUS: 8-BIT
    SIZE:    2 KB

D: Return to menu
```
