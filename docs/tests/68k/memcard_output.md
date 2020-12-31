# Memory Card Output Tests
---
The memory card output test happen before detecting the memory card's data bus
width.  So tests treat the card as if its 8-bit.

NOTE: The output tests are only checking for output using the first handful of
words at the start of the memory card address range.  This is fine for official
and reproduction cards as they only have one underlying memory chip.  However
generic SRAM cards are likely backed by multiple memory chips, anyone of which
could have an output issue.  The output tests will not be able to detect an
output issue on generic SRAM cards unless it effects the start of the memory
range.  In this case the issue will likely show up as a data test error. 

#### 74HCT245s / NEO-G0 to 68k CPU
This test attempts to verify the data lines from the 74HCT245s / NEO-G0 to the
68k CPU are outputting data.  This test works the same as the
[Work + Backup RAM Output Tests](wbram_oe.md) test.

If an error is detected one of the following errors will happen.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x80 |    128 |       N/A |           N/A | MEMCARD 245/G0 DEAD OUTPUT (LOWER) |
|  0x81 |    129 |       N/A |           N/A | MEMCARD 245/G0 DEAD OUTPUT (UPPER) |

You will note there is an error for the upper byte.  In this case even if the
card is only 8-bit the 74HCT245 / NEO-G0 will still output something if its
working for the upper byte which will cause it to pass the test.

#### Memory Card to 74HCT245s / NEO-G0
This test attempts to verify the memory on the memory card is outputting data
to the 74HCT245s / NEO-G0.  In testing it would found that when this is
happening the last written immediate data written is what will be read back
on an alternate address.

The test consists of writing 0x5555 to 0x800004, reading 0x800000, writing
0xaaaa to 0x800008, reading 0x800000.  If both reads end up with the lower byte
being the written data it will trigger the following error.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x82 |    130 |       N/A |           N/A | MEMCARD DEAD OUTPUT (LOWER) |

You will note there is no error for the upper byte.  This is because we do not
know if the card is 16-bit at this point.  Attempting this test on the upper
byte on a 8-bit card would trigger an error.  The code that handles detecting
a 16-bit card is essentially using this test to determine if the upper byte on
the memory card is outputting anything, and is thus a 16-bit card.
