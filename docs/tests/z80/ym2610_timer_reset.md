### YM2610 Timer Reset Test
----
The diag resets and disables the timers on the YM2610, but when we query them
they are still active. If this happens it will trigger the following error.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x1b |     27 |    011011 |       x0 / 27 | YM2610 TIMER RESET |
