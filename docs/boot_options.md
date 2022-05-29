### Boot Options
---

Certain button combinations held down during boot up will modify the behavior
of the diag bios.  These are outlined below

| Button Combo | Behavior |
| :---------- | :------- |
| none         | Automatic testing without diag m1 tests |
| A+B+C+D      | Go directly to the menu system |
| C            | Do a backup RAM test on AES.  This would only be valid if you did a hardware mod that added backup ram to your AES |
| D            | Automatic testing with diag m1 tests using slot 1.  Slot switch will be performed on MVS hardware |
| B+D          | Automatic testing with diag m1 tests, no slot switch.  (Use if MV-1B/C MVS Boards) |
| D+UP         | Automatic testing with diag m1 tests using slot 2 |
| D+UP+RIGHT   | Automatic testing with diag m1 tests using slot 3 |
| D+RIGHT      | Automatic testing with diag m1 tests using slot 4 |
| D+RIGHT+DOWN | Automatic testing with diag m1 tests using slot 5 |
| D+DOWN       | Automatic testing with diag m1 tests using slot 6 |

The diag bios will not prevent you from trying to switch to an invalid slot
for diag m1 tests.  This will usually result in the hardware ignoring the
invalid bits in the request and will cause you to switch to a valid slot for
your board.  For example if you have a 4 slot board and try to use D+DOWN,
you will likely end up actually switching to slot 2.

A specific note for AES and MV-1B/C hardware.  These do not have SM1 roms, so
on boot they will always use the m1 rom from the inserted cartridge.  If the
inserted cartridge contains the diag m1 and you don't boot with D for AES or
B+D for MV-1B/C it will result in the diag m1 giving the comm test failure
beep code.  This is because the diag m1 is trying to do the comm test, while
the diag bios is not.
