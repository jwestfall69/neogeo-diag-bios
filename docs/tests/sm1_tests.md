# SM1 Tests
---

In order to run sm1 related tests is necessary for the diag m1 to be running
code out of ram, so its possible to swap to the sm1.  This requires
coordination between the diag m1 and bios for when to switch to/from the sm1
rom.  Below outlines how that happens.

After a successful [68k <=> Z80 Communication Test](comm_test.md) the
diag m1 starts its sm1 tests routine.

* m1: copy sm1 related test code into ram and jump to it
* m1 -> bios: send request to switch to sm1 (0xb0)

If the bios didn't do a slot switch to make the diag m1 active it will reply
back with a deny (0xb1) message, which prompts the diag m1 to abandon its
sm1 testing and continue on.  If the bios never responds, which will
happen if you use the original 0.19 bios, it will also cause the diag m1 to
abandon its sm1 testing and continue on.

Assuming it did do a slot switch

* bios: switches to sm1 ("[SM1]" is printed on top right of screen)
* bios -> m1: send sm1 swap done (0xb2) message
* m1: does sm1 related tests
* m1 -> bios: send request to switch back to m1 (0xb3)
* bios: switches to m1
* bios -> m1: send m1 swap done (0xb4) message
* m1: jump back to running from m1 rom

At this point if one of the sm1 tests had failed the error would be sent to the
bios and the diag m1 would play the beep code for it.

If there was no error
* m1 -> bios: send (0xe7) indicating all tests (including non-sm1) were
successful
