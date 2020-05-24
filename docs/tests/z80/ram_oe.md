### RAM Output Enable Test
---

When trying to load data from the ram chip into a register and ram doesn't
output anything, it often results in the last byte read on the data bus ending
up in the register.  The last byte read on a load instruction is the opcode
for the load instruction.  It doesn't happen 100% of the time though.

A loop is used to check for the condition by using 2 different load opcodes
(0x74 for `ld a, (hl)` and 0x1a for `ld a, (de)`).  If both load instructions
result with the corresponding opcode in the `a` register for a given loop, it
will cause the test to fail and results in the following error.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x0a |     10 |    001010 |       x0 / 10 | RAM DEAD OUTPUT |
