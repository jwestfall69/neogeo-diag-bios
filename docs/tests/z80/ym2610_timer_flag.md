### YM2610 Timer Test (Flag)
----

The YM2610 attached to the Z80 and has supports for 2 timers.  When a timer is
up it will trigger an interrupt (if enabled) and also set a timer bit/flag
indicating the timer fired.

This test consists of the following

1. With Z80 interrupts disabled
2. Setup the timer
3. Poll the timer status port for the flag to be set.

If the timer flag gets set too soon, takes too long, or never gets set, it will
trigger the following error code:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x11 |     17 |    010001 |       x0 / 17 | YM2610 TiMER TIMING (FLAG) |

There is also an error code associated with setting up the timer.  Once we
tell the YM2610 to setup the timer we wait for it to verify its completed the
request.  If this takes to long it will result in the following error:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x18 |     24 |    011000 |       x0 / 24 | YM2610 TIMER INIT (FLAG) |

As part of this test we also set that we are not expecting any interrupts from
the YM2610.  If we do end up getting one it will result in the following error
code:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x13 |     19 |    010011 |       x0 / 19 | YM2610 UNEXPECTED IRQ |
