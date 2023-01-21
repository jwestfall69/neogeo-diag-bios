### Work RAM Output Enable Tests
---

When trying to load data from a ram chip into a register and ram chip doesn't
output anything, it often results in the next instruction (because of prefetching)
ending up in the register.

A loop is used with each loop containing 3 tests where the instruction after
the `move.b (a0), d1` instruction is different.  If all 3 of these test fail
in a given loop, the test is considered failed.

Separate tests are performed to isolate testing the upper and lower RAM chips.

No beep code will be played since these tests happen before the 68k <=> Z80
communication test.

#### Work RAM
Work RAM upper is tested first, then work RAM lower.  These will result in the
corresponding error below if one fails.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x44 |     68 |  *1000100 |       x0 / 68 | WRAM DEAD OUTPUT (LOWER) |
|  0x45 |     69 |  *1000101 |       x0 / 69 | WRAM DEAD OUTPUT (UPPER) |
