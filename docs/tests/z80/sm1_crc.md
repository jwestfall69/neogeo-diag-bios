# SM1 ROM CRC32 Test
---

This test will only run if a slot switch is performed in order to make the
diag m1 active.  If sm1 related tests are run `[SM1]` will be printed in the
top right of the screen to the left of `[SSx]`.  Please refer to [sm1 tests](../sm1_tests.md)
for more details on how sm1 tests are performed.

This test will check the crc32 of the sm1 rom.  Doing a crc32 check of the
entire rom isn't really practical as it would take ~30 seconds to complete and
add a bunch of complexity having to bankswitch in order to access the whole
rom.  Instead just the first 21504 (0x5400) bytes are used when doing the crc32
check, this is enough to cover all of the running code from the rom.

The expected checksum for this range is 0xbd94a5a6.  If the checksum doesn't
match it will result in the following error.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x0f |     15 |    001111 |       x0 / 15 | SM1 CRC ERROR |

**NOTE:**<br>
A failed sm1 crc doesn't necessarily mean the sm1 rom is bad.  The data read
from it was bad, but the cause of the bad data could be other things.  There
for example could be a cut address or data trace going to the rom causing the
read data to be wrong.
