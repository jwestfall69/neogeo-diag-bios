# RAM Details
---

#### Upper vs Lower:
The 68k CPU has a 16 bit data bus, thus every read or write the 68k does must
be 16 bits.  All of the RAM chip on the Neo Geo are 8 bit wide for data.  
This makes it necessary to double up the RAM chips such that one RAM chip is
responsible for the upper 8 bits, and the other the lower 8 bits.  This is
why you see the upper and lower in error messages.

In some cases it won't tell you which chip is bad but you can figure it out.
For example:

```
WRAM DATA (AAAA)

ADDRESS:   110000
ACTUAL:    AAA8
EXPECTED:  AAAA
```

The upper 2 hex values `AA` of the `ACTUAL` value are from the upper RAM chip
and the lower 2 hex values `A8` are from the lower RAM chip.  In this case `A8`
doesn't match the `EXPECTED` lower 2 hex values `AA`, so something is wrong
with the lower RAM chip or the traces to it.

#### 2K VRAM vs 32K VRAM:
The VRAM data and address test don't (currently) tell if the issue is with the
2K or 32K VRAM chips.  However you can deduce which it is by looking at the
address that had the error.

```
VRAM DATA (0000)

ADDRESS:   0080F0
ACTUAL:    0100
EXPECTED:  0000
```

Addresses 0x000000 to 0x007FFF are the 32K VRAM<br>
Addresses 0x008000 to 0x0087FF are the 2K VRAM

In short, if the address is 0x008XXX then its 2K VRAM, otherwise its 32K VRAM.
The same logic above about upper vs lower applies to `ACTUAL` vs `EXPECTED`
for these errors.  The above example error is pointing so something being wrong
with the upper 2K VRAM chip.

More details about VRAM can be found on the [VRAM](https://wiki.neogeodev.org/index.php?title=VRAM)
page of the [Neo-Geo Dev Wiki](https://wiki.neogeodev.org/index.php?title=Main_Page).

#### AES RAM Locations:

NEO-AES<br>
[NEO-AES3-2](ram_locations/neo-aes3.md)<br>
[NEO-AES3-3](ram_locations/neo-aes3.md)<br>
[NEO-AES3-4](ram_locations/neo-aes3.md)<br>
[NEO-AES3-5](ram_locations/neo-aes3.md)<br>
[NEO-AES3-6](ram_locations/neo-aes3.md)<br>
NEO-AES4-1<br>

#### MVS RAM Locations:

[MV1](ram_locations/mv1.md)<br>
[MV1-1](ram_locations/mv1.md)<br>
[MV1A](ram_locations/mv1a.md)<br>
[MV1ACH](ram_locations/mv1a.md)<br>
[MV1ACHX](ram_locations/mv1a.md)<br>
[MV1AX](ram_locations/mv1a.md)<br>
[MV1B](ram_locations/mv1b.md)<br>
[MV1B CHX](ram_locations/mv1b.md)<br>
[MV1B1](ram_locations/mv1b.md)<br>
[MV1C](ram_locations/mv1c.md)<br>
[MV1F](ram_locations/mv1f.md)<br>
[MV1FS](ram_locations/mv1f.md)<br>
[MV1FT](ram_locations/mv1ft.md)<br>
[MV1FZ](ram_locations/mv1fz.md)<br>
[MV1FZNB2](ram_locations/mv1fz.md)<br>
[MV1FZS](ram_locations/mv1fz.md)<br>
[MV1FZSB](ram_locations/mv1fz.md)<br>
[MV1FZSB-2](ram_locations/mv1fz.md)<br>
[MV1T](ram_locations/mv1.md)<br>
[MV2](ram_locations/mv2.md)<br>
[MV2-01](ram_locations/mv2.md)<br>
[MV2B](ram_locations/mv2.md)<br>
[MV2F](ram_locations/mv2f.md)<br>
[MV2FS](ram_locations/mv2f.md)<br>
[MV4](ram_locations/mv4.md)<br>
[MV4F](ram_locations/mv4f.md)<br>
[MV4FS](ram_locations/mv4ft.md)<br>
[MV4FT](ram_locations/mv4ft.md)<br>
[MV4FT2](ram_locations/mv4ft.md)<br>
[MV4FT3](ram_locations/mv4ft.md)<br>
[MV6](ram_locations/mv6.md)<br>
