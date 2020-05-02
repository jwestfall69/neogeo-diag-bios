### YM2610 Timer Test (Flag)
----

The YM2610 attached to the Z80 and has supports for 2 timers.  When a timer is
up it will trigger an interrupt (if enabled) and also set a timer bit/flag
indicating the timer fired.

This test consists of the following

1. Setup the timer
2. Poll the timer status port for the flag to be set, indicating the timer
fired.

When setting up the timer the diag m1 will verify the ym2610 has taken the
request by polling the busy bit of the register.  If this busy bit takes to
long to become unset it will result in the following error.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x18 |     24 |    011000 |       x0 / 24 | YM2610 TIMER INIT (FLAG) |

If the timer flag gets set too soon, takes too long, or never gets set, it will
trigger the following error code:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x11 |     17 |    010001 |       x0 / 17 | YM2610 TIMER TIMING (FLAG) |
