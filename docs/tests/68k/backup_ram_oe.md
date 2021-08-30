### Backup RAM Output Enable Tests
---

When trying to load data from a ram chip into a register and ram chip doesn't
output anything, it often results in the last data read on the data bus ending
up in the register.  Because of instruction prefetching, this ends up being
(part) of the instruction after our `move.b (a0), d1` instruction.

A loop is used with each loop containing 3 tests where the instruction after
the `move.b (a0), d1` instruction is different.  If all 3 of these test fail
in a given loop, the test is considered failed.

Separate tests are performed to isolate testing the upper and lower RAM chips.

No beep code will be played since these tests happen before the 68k <=> Z80
communication test.

#### Backup RAM
The backup RAM test will run on all MVS hardware and only on AES hardware
if 'C' is pressed.  This would only be needed if the AES had a hardware
modification that added backup RAM, which is unlikely.

Backup RAM upper is tested first, then backup RAM lower.  These will result in
the corresponding error below if one fails.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x46 |     70 |  *1000110 |       x0 / 70 | BRAM DEAD OUTPUT (LOWER) |
|  0x47 |     71 |  *1000111 |       x0 / 71 | BRAM DEAD OUTPUT (UPPER) |
