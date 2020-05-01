### YM2610 Timer Test (IRQ)
----

The YM2610 attached to the Z80 and has supports for 2 timers.  When a timer is
up it will trigger an interrupt (if enabled) and also set a timer bit/flag
indicating the timer fired.

This test consists of the following

1. With Z80 interrupts disabled
2. Setup the timer
3. Z80 enable interrupts
4. Wait for the timer interrupt
5. Z80 disable interrupts

If the timer interrupt get triggered too soon, takes too long, or never gets
triggered, it will result the following error code:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x12 |     18 |    010010 |       x0 / 18 | YM2610 TIMER TIMING (IRQ) |

There is also an error code associated with setting up the timer.  Once we
tell the YM2610 to setup the timer we wait for it to verify its completed the
request.  If this takes to long it will result in the following error:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x19 |     25 |    011001 |       x0 / 25 | YM2610 TIMER INIT (IRQ) |
