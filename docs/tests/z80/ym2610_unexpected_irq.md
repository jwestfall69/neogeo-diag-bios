### YM2610 Unexpected IRQ
----

The [YM2610 io test](ym2610_io.md) disables the ym2610's timers and interrupt
generation.  The unexpected IRQ test temp enables interrupts on the Z80 and
if one is received it will result in the following error.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x13 |     19 |    010011 |       x0 / 19 | YM2610 UNEXPECTED IRQ |
