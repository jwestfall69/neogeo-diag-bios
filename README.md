# neogeo-diag-bios
Disassembly of smkdan's Neo Geo Diagnostics BIOS with new features.

http://smkdan.eludevisibility.org/neo/diag/

This is a disassembly of smkdan's diag bios, both sp1 and m1 are included.  I
originally did this as a personal project to learn 68k/z80 assembly and neo geo
hardware.  However with smkdan having disappeared in late 2014 I thought others
might find this useful.  I've started adding new features which you can see in
the [CHANGELOG](CHANGELOG.md)

Please use the [v0.19](https://github.com/jwestfall69/neogeo-diag-bios/tree/v0.19)
branch of the disassembly if you want compiled rom files to match up with the
original smkdan roms.

## Pre-Built
You can grab the lastest build from the master branch at

https://www.mvs-scans.com/neogeo-diag-bios/19a00-master.zip

## Building
I tried to make it as simple as possible to build the rom files.  All you really
need are vasm and a host compiler.  (Additional steps maybe required if trying
to build on a windows box)

You can get vasm from

http://sun.hasenbraten.de/vasm/

Specifically you will need vasmm68k_mot and vasmz80_mot binaries.  If you are
building vasm from source, like I did, you can build them with the following
commands

```
$ make CPU=m68k SYNTAX=mot
$ make CPU=z80 SYNTAX=mot
```

Copy the resulting vasmm68k_mot and vasmz80_mot binaries so they are within
your $PATH

Then its just a matter of going into the sp1 and m1 directories and running
make.  The resulting rom file for each will be placed in the output/ directory.
