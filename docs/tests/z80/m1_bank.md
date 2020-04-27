### M1 Bankswitching Tests
---
This test verifies z80 bankswitching is working.  Please refer to the
[Z80 bankswitching](https://wiki.neogeodev.org/index.php?title=Z80_bankswitching)
on the [Neo-Geo Dev Wiki](https://wiki.neogeodev.org/index.php?title=Main_Page)
for more specific detail on how bankswitching works.

The first 32KB of the diag m1 is used by the running code and for
[upper address](m1_upper_address.md) testing.  The remaining 96KB of space is
used for bankswitch testing.  The 96KB is broken down into 48x2KB chunks and
the last 4 bytes each chunk contain counter data.  The counter data gets filled
in by gen-crc-mirror-bank at build time.

Each zone size has its own counter location/byte in each 2KB chunk as follows:

zone0 (2KB) counter is at 0xffc and starts with 0x10<br>
zone1 (4KB) counter is at 0xffd and starts with 0x08<br>
zone2 (8KB) counter is at 0xffe and starts with 0x04<br>
zone3 (16K) counter is at 0xfff and starts with 0x02

Within the 96KB of space, each zone's counter is only increased for each
block of its size.  Meaning zone0's counter will increase for each 2KB chunk,
while zone3's counter will increase every 8x 2KB chunks.

When doing the bankswitch testing these counters are checked to make sure
they match up with the expected values based on the zone size and bank offset
within the 96KB.  If any of them end up not matching it will results in one of
the following errors:

|  Hex  | Number | Beep Code |  Credit Leds  | Error Text |
| ----: | -----: | --------: | :-----------: | :---------- |
|  0x14 |     20 |    010100 |       x0 / 20 | M1 BANK ERROR (16K) |
|  0x15 |     21 |    010101 |       x0 / 21 | M1 BANK ERROR (8K) |
|  0x16 |     22 |    010110 |       x0 / 22 | M1 BANK ERROR (4K) |
|  0x17 |     23 |    010111 |       x0 / 23 | M1 BANK ERROR (2K) |

Note: The ordering in which the different zones are tested goes zone3,
zone2, zone1, and then zone0.
