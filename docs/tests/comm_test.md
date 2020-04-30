### 68k <=> Z80 Communication Test
----

The neo-geo hardware allows the 68k and Z80 to pass a single byte of data
at a time between them in each direction.  If the proper [boot option](../boot_options.md) is used the diag bios will enable testing that communication.

**Slot Switch:**<br>
On MVS hardware (except for MV-1B/C boards) when the board powers on, the Z80
will boot running the program code on the sm1 rom.  Its up to the bios to switch
to a cartridges m1 rom (and s1 rom).  Under nominal conditions the slot switch
should happen as follows:

1. bios -> z80/sm1: prepare for slot switch (0x01)
2. z80/sm1: copies code into ram and jumps to it
3. z80/sm1 -> bios: ready (0x01)
4. bios: switches to the cartridges m1/s1 roms
5. bios -> z80/sm1: switch is complete (0x03)
6. z80/sm1: jumps execution to 0x0000, which is the start of the cartridge's m1
rom.  The m1 rom is now in control.

More in depth details can be found on the [Z80 Communication](https://wiki.neogeodev.org/index.php?title=68k/Z80_communication) page of the [Neo-Geo Dev Wiki](https://wiki.neogeodev.org/index.php?title=Main_Page).

The AES and MV-1B/C board do not have a built in sm1 rom and will directly
boot the carts m1 rom.  Thus a slot switch is not needed for the diag bios
to do the comm test for these boards.  The diag bios is able to detect AES
hardware and won't do a slot switch if you enable the comm test.  However its
impossible to tell if a board is an MV-1B/C vs other 1 slot board, so its
necessary to let the diag bios know it shouldn't do a slot switch by pressing
B+D during power on.

**Slot Switch Ignored:**<br>
One of the error messages you may encounter from the diag bios when enabling
the comm test is

```
Z80 SLOT SWITCH IGNORED (SM1)
SM1 OTHERWISE LOOKS UNRESPONSIVE
IF MV-1B/1C: SOFT RESET & HOLD B
PRESS START TO CONTINUE
```

This message is indicating the diag bios requested the z80/sm1 prepare for the
slot switch, but the z80/sm1 never replied back or replied with the wrong
response.

Pressing start to continue will force the switch even though the Z80/sm1 might
not be in the proper state to handle it.  Specifically the program counter (PC)
of the Z80 maybe be within the rom space, which will get swapped out beneath
it by the slot switch.  This can lead to a crash of the Z80 or execution of
the diag m1 code starting a the current PC instead of 0x0000.  The diag m1 has
code in it that attempts to recover from this situation if/when an IRQ/NMI is
received by jumping to its expected entry point function.

**Comm Test:**<br>
The comm test requires both the diag bios and diag m1 to be running their
respected comm test code.  Both run tests before running their comm test
code, which can cause variance for when they start their comm test.  To cope
with this variance in timing both will wait up to 5 seconds for the initial
request from the other.

Under nominal conditions the comm tests will go something like this

1. bios: wait for HELLO (0xc3) messages<sup>1</sub>
2. m1 -> bios: send HELLO (0xc3) message
3. bios: accept HELLO (0xc3) message
4. bios -> m1: send HANDSHAKE (0x5a)
5. m1: accept HANDSHAKE (0x5a)
6. m1 -> bios: send ACK (0x3c)
7. bios: accept ACK (0x3c) message
8. m1: test clearing the receive data port.

<sup>1</sup>As mentioned above the diag m1 runs some tests before the comm test,
if one of those tests fails the diag m1 will send the [error code] & 0x40
instead of the HELLO message.  The diag bios is also looking for those error
messages while waiting for the HELLO message. If one is encountered the error
message will be displayed and the comm test will stop.

If the diag bios doesn't receive the HELLO or ACK message it will result in the
corresponding error message to indicate which one failed.  There is no error
code associated with these messages.

```
Z80->68k COMM ISSUE (HELLO)
80->68k COMM ISSUE (ACK)
```
In addition it will print out the expected message (0xc3 or 0x3c) and the last
received message from the Z80.

If the diag m1 doesn't receive the HANDSHAKE message it will result in the
following error code:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x0c |     12 |    001100 |       x0 / 12 | 68k->Z80 COMM ISSUE (HANDSHAKE) |

I believe its unlikely for the diag bios to ever get this error code, if it
could you would think the comm test would have passed.  So you will like only
hear a beep code for it.  If you have the diag m1 rom cart installed in an
AES or MV-1B/C board and don't enable the comm test, you will get this
beep code.

Additionally the diag m1 will attempt to clear the receive data port, if this
fails it will result in the following error code:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :--------- |
|  0x0d |     13 |    001101 |       x0 / 13 | 68k->Z80 COMM ISSUE (CLEAR) |

**Post Comm Test:**<br>
Once the comm test is successful the diag m1 will continue on with its remaining
tests.  If the it encounters an error, it will send the [error code] & 0x40 to
the diag bios or 0xe7 to indicate all tests were successful.  While this is
going the diag bios will display

```
WAITING FOR Z80 TO FINISH TESTS...
```

and be in a holding pattern until the diag m1 provides an [error code] & 0x40 or
the 0x7e message.  Once this happens the diag m1 will go into a holding pattern
waiting for the diag bios to send it an error code for beep code generation and
the diag bios continues with it's remaining tests.
