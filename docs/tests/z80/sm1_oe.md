# SM1 ROM Output Enable Test
---

This test will only run if a slot switch is performed in order to make the
diag m1 active.  If sm1 related tests are run, `[SM1]` will be printed in the
top right of the screen to the left of `[SSx]`.  Please refer to [sm1 tests](../sm1_tests.md)
for more details on how sm1 tests are performed.

When trying to load data from the rom chip into a register and the rom doesn't
output anything, it often results in the last byte read on the data bus ending
up in the register.  The last byte read on a load instruction is the opcode
for the load instruction.  It doesn't happen 100% of the time though.

A loop is used to check for the condition by using 2 different load opcodes
(0x7e for `ld a, (hl)` and 0x1a for `ld a, (de)`).  If both load instructions
result with the corresponding opcode in the `a` register for a given loop, it
will cause the test to fail and results in the following error.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x0e |     14 |    001110 |       x0 / 14 | SM1 DEAD OUTPUT |
