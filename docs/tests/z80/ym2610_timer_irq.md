### YM2610 Timer IRQ Test
----

The YM2610 attached to the Z80 and has supports for 2 timers.  When a timer is
up it will trigger an interrupt (if enabled) and also set a timer bit/flag
indicating the timer fired.

This test consists of the following

1. Setup the timer
2. Z80 enable interrupts
3. Wait for the timer interrupt
4. Z80 disable interrupts

When setting up the timer the diag m1 will verify the ym2610 has taken the
request by polling the busy bit of the register.  If this busy bit takes to
long to become unset it will result in the following error.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x19 |     25 |    011001 |       x0 / 25 | YM2610 TIMER INIT (IRQ) |

If the timer interrupt gets triggered too soon, takes too long, or never gets
triggered, it will result the following error code.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x12 |     18 |    010010 |       x0 / 18 | YM2610 TIMER TIMING (IRQ) |
