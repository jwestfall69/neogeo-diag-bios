### YM2610 Busy Bit Test
----
When not having any active commands going with the YM2610, query the status and
if the busy bit is set it indicates something is wrong.  If this happens trigger
the following error.

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x1a |     26 |    011010 |       x0 / 26 | YM2610 BUSY BIT |
