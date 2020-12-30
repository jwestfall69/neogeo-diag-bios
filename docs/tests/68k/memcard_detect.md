# Memory Card Detection
---
#### Card Inserted (CD#1 and CD#2)
Prior to running any memory card tests the diag bios will verify a memory card
is inserted using the CD#1 and CD#2 signal states, which is provided by bits
4 & 5 of the REG_STATUS_B register.  These signals come from pins 36 (CD#1) and
67 (CD#2).

If a card is not detected the following will be printed on screen

```
MEMORY CARD TESTS

ERROR: MEMORY CARD NOT DETECTED



D: Return to menu
```

The exact state of the CD#1/2 signals is provided in Misc Input Tests

#### Write Protect (WP)
Prior to running any memory card tests the diag bios will verify a memory card
is not write protected using the WP signal state, which is provided by bit 6 of
the REG_STATUS_B register.  This signal comes from pin 33 of the memory card.

If a card is write protected the following will be printed on screen

```
MEMORY CARD TESTS

ERROR: MEMORY CARD WRITE PROTECTED



D: Return to menu
```

#### Card Data Bus Width
Once memory card output tests have completed, the diag bios will attempt to
determine if the memory card has a 16-bit or 16-bit double wide data bus.  This
is done by writing 0xaaaa to 0x800000, writing 0x5555 (poison) to 0x800004,
then re-reading 0x800000.

If the lower byte is not 0xaa, we assume there is a data issue, which makes it
impossible to detect 16-bit or the card size.  In this case we flag the card
as having bad data, which will force it to be an 8-bit/2KB card.  The bad data
state will also be disabled in the detected info as follows.

```
DETECTED: (BAD DATA)

DATA BUS: 8-BIT
    SIZE:    2 KB
```

If the upper byte matches 0xaa we will flag the card as being 16-bit, then an
additional check is made to see if its 16-bit double wide.  This is done by
writing 0x5555 to 0x800002, then reading 0x800000, if the read value is 0x5555
then we flag it as being double wide.


#### Card Size
Once the data bus width has been detected the diag bios will next try to figure
out the size.  If the memory card was flagged as having bad data, this will
force the card size to be 2KB.

The memory card is mapped into $800000 to $BFFFFF ($400000/4MB bytes).  We have
to deal with there being possible bad addresses lines, so we checked each
address line and use the last working one to figure out the memory card size.

The test consists of writing 0xaa to the test address, writing 0x55 to 0x800000,
then re-reading the test address.  If the result is 0xaa the address line is
considered valid.  The premise here is that if the address line is dead, writing
to it will actually cause the write to go to 0x800000, and thus by overwriting
0x800000 it will cause the re-read of the test address it be wrong.

When a specific address line passes the test we assume all addresses until the
next address line are valid.  For example if 0x802000 passed testing, we assume
up to 0x803fff are also valid too.

This means we are assuming the memory card size is a power of 2.  There are
some (uncommon) generic SRAM cards that are not a power of 2.  If one of these
are used it will be detected as being the next highest power of 2 and
ultimately trigger an error when doing the data tests.

Something it keep in mind, if the last address line needed by your memory card
is bad it will cause the card size to be detected as half its actual size.

Memory cards larger then 2048KB require using bank switching via the
REG_CRDBANK register to set A21-A23 address lines.  This is not something the
diag bios currently supports so those cards will be detected as 2048KB.
