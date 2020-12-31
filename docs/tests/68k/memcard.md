# Memory Card
---
This page covers some info about memory cards to help with debugging issues.
Additional information about them can be found on the [memory card](https://wiki.neogeodev.org/index.php?title=Memory_card) of the [Neo-Geo Dev Wiki](https://wiki.neogeodev.org/index.php?title=Main_Page).

## Memory Card Types
#### Official Cards
The official cards contains a single 8-bit / 2KB SRAM chip + battery.

#### Reproduction Cards
Most reproduction cards contains a single 8-bit / 32KB FRAM that is broken up
into 2x16KB regions.  Only one of the 16KB regions is visible to the NEO GEO. A
hard switch on the memory card determines which 16KB region is active.  Some
early reproduction cards were SRAM + battery based.

Couple reproduction cards:<br>
[NeoSaveMasta](https://www.neogeofanclub.com/projects)<br>
[Apocalypse's](https://www.arcade-projects.com/threads/neo-geo-aes-mvs-memory-card-no-battery.5509/)<br>
[NeoMemCard2](https://github.com/neogeodev/NeoMemCard2)<br>
[JGO](https://stoneagegamer.com/jgo-neo-geo-memory-card-for-aes-and-mvs-consoles.html)<br>

If you plan on doing a bunch of memory card testing, you may wish to consider
using a SRAM backed card instead of FRAM.  FRAM will have a limited number of
write cycles.

#### Generic SRAM Cards
Generic SRAM cards can be found on [ebay](https://www.ebay.com/sch/i.html?_nkw=(card%2Cpcmcia)+sram),
but often cost more then getting a reproduction card.  I would advise against
using any 16-bit cards for actual game use.  Both stock/unibios have issues with
them.  For example:

* Memory card error on power-on if the 16-bit card isn't formatted, 8-bit cards don't cause this
* Formatted 16-bit card will still result in MEMORY CARD NG in hardware test
* Unibios seems to get stuck in a loop when a formatted 16-bit card is inserted at power on

Generic SRAM cards can be a mixed bag as on what you get.  While you might be
able to identify the size based on labels, they often don't provide any info on
the data base width.  They could be 8-bit, 16-bit only, 16-bit with 8-bit
support.

While the official and reproduction cards are a single chip which makes them a
bit easier to debug issues, generic SRAM cards could have many underlying chips.
Any one of which could have issues.

Depending on your goals with testing, a 16-bit generic SRAM card maybe desirable
as it allows testing the upper data byte.  Likewise a larger size card will
also allow testing the higher address lines.



## General Testing Info
#### Max Used Memory Card Memory
The stock/unibios BIOSes will only use up to the first 16KB of a memory
card for storing game data.  This is why reproduction cards break their 32KB
memory into 2x16KB regions.

#### Break Up Testing Into Parts
When testing the memory card its best to look at it as 2-3 separate parts.  The
memory card itself, the memory card subsystem on the motherboard, and MV-IC if
your motherboard requires one.  When testing one of those parts it will be best
to have known working parts for the others.  ie: unknown memory card, but known
working motherboard/MV-IC board.  

## Wiring Notes
#### Address / Data Bus Connections
The memory card is not directly connected to the CPU's address and data buses.
Instead there are ICs in between the them as outlined in the below table.

|    Board   |       Address IC(s) |          Data IC(s) |                     Notes  |
| :--------- | ------------------: | ------------------: | :------------------------- |
|   NEO-AES3 | 3x 74HCT244 @ F-H12 | 2x 74HCT245 @ F-G11 | Unconfirmed, based on pics |
| NEO-AES3-2 |      NEO-E0 @ D10   |      NEO-G0 @ J5    |                            |
| NEO-AES3-3 |      NEO-E0 @ D10   |      NEO-G0 @ J5    |                            |
| NEO-AES3-4 |      NEO-E0 @ D10   |      NEO-G0 @ J5    |                            |
| NEO-AES3-5 |      NEO-E0 @ D10   |      NEO-G0 @ J5    |                            |
| NEO-AES3-6 |      NEO-E0 @ D10   |      NEO-G0 @ J5    |                            |
| NEO-AES4-1 |      NEO-E0 @ ??    |      NEO-G0 @ ??    | No grid for locations      |
|        MV1 |      NEO-E0 @ B5    |      NEO-G0 @ G10   | Uses MV-IC                 |
|      MV1-1 |      NEO-E0 @ B5    |      NEO-G0 @ G10   | Uses MV-IC                 |
|       MV1T |      NEO-E0 @ B5    |      NEO-G0 @ G10   | Uses MV-IC                 |
|        MV2 |      NEO-E0 @ G2    |      NEO-G0 @ C8    |                            |
|     MV2-01 |      NEO-E0 @ G2    |      NEO-G0 @ C8    |                            |
|       MV2B |      NEO-E0 @ G2    |      NEO-G0 @ C8    | Uses MV-IC                 |
|       MV2F |      NEO-E0 @ E1    |      NEO-G0 @ B7    |                            |
|      MV2FS |      NEO-E0 @ E1    |      NEO-G0 @ B7    |                            |
|        MV4 | 3x 74HCT244 @ A9-11 | 2x 74HCT245 @ A7-8  | Uses MV-IC                 |
|       MV4F |      NEO-E0 @ A8    |      NEO-G0 @ D6    | Uses MV-IC                 |
|      MV4FS |      NEO-E0 @ A7    |      NEO-G0 @ E5    | Uses MV-IC                 |
|      MV4FT |      NEO-E0 @ A7    |      NEO-G0 @ E5    | Uses MV-IC                 |
|     MV4FT2 |      NEO-E0 @ A7    |      NEO-G0 @ E5    | Uses MV-IC                 |
|     MV4FT3 |      NEO-E0 @ A7    |      NEO-G0 @ E5    | Uses MV-IC                 |
|        MV6 | 3x 74HCT244 @ A9-11 | 2x 74HCT245 @ A7-8  | Uses MV-IC                 |

Address mapping between the 68k and memory card are off by one.<br>
```
68k  A1 <=> IC <=> memcard  A0
68k  A2 <=> IC <=> memcard  A1
..
68k A21 <=> IC <=> memcard A20
```

The effect of which will mean accessing 0xBFFFFE on the 68k will get mapped to
address 0x1FFFFF on the memory card.  The Neo Geo gives you access to set
A21-A23 addresses on the memory card by using the REG_CRDBANK register, I have
not tested this though.

There also exists [NeoBiosMasta VMC](https://www.neogeofanclub.com/projects/neobiosmasta-vmc)
which allows adding a virtual memory card to MV1B, MV1C, MV1A, and MV1FZ boards.
This board hasn't been tested as of yet with the memory card tests.

#### MV-IC
MV-IC is memory slot board used by 4/6-slot boards, MV2B and some first gen
1-slot boards.  It contains the memory card slot and has 2 ribbon cables that
connect it to the motherboard.  It was mounted in cabinets in such a way to
allow the player to insert their own memory card.

There are no logic chips on the board and is just a straight extension to the
memory card slot.

If memory cards are not detected when inserted into the MV-IC, it can be an
indication the ribbon cables need to be swapped between the IDC connectors on
the motherboard.

Its also pretty common for the IDC connectors to be dirty and/or have corrosion
and cause problems.  If you are having issues verify continuity between the
motherboard/MV-IC IDC connectors.

Some different replacements for the MV-IC:<br>
[NeoSaveMasta IC-VMC](https://www.neogeofanclub.com/projects/neosavemasta-vmc)<br>
[Neo Geo MVSCARD Socket](http://www.neogeoledmarquee.info/product/neo-geo-mvscard-socket/)<br>
[Neo Geo MVS-NVMOD](http://www.neogeoledmarquee.info/product/neo-geo-mvs-nvmod/)<br>
[Neo Geo MV-IC Repro](http://www.neogeoledmarquee.info/product/neo-geo-mv-ic-save-game-memory-card-repro/)</br>

#### Card Enable #1 and #2
The Neo Geo has CE#1 and CE#2 pins tied together.  CE#1 is normally used to
signal to a memory card to enable data lines D0-D7 and CE#2 to enable data
lines D8-D15.  Some (most?) generic SRAM cards that support a 16 bit also
support running in 8 bit mode.  However such cards will always run in 16 bit
mode because of the CE#1 and CE#2 being tied together.

#### 16-Bit Double Wide
The 68k cpu doesn't have an A0 address line since all memory access is done via
words.  However the 68k's A1 is connected to A0 of the memory card (via the
ICs).  When a 16 bit card is accessed they are expecting word aligned requests
and thus drop/ignore their A0 address line.  This causes a double wide effect
when the Neo Geo accesses the memory card's memory.

| 68k Address | Memory Card Address |  Data  |
| ----------: | ------------------: | -----: |
|    0x800000 |            0x000000 | 0x1122 |
|    0x800002 |            0x000000 | 0x1122 |
|    0x800004 |            0x000002 | 0x3344 |
|    0x800006 |            0x000002 | 0x3344 |

NOTE: I've never come across a 16-bit card that wasn't double wide.  I think
would require a non-standard/custom card that was wired up like the neo geo's
work/backup ram for it to be non-double wide.
