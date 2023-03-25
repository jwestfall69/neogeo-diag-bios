# P ROM Bus Tests
The purpose of these tests is to validate the data and address bus between the main CPU and the P ROMs on the cart slot.  These tests require a custom PROG board where the P ROM has been replaced with static ram.

The details on the custom PROG boards can be found here:

[AES Version](https://github.com/jwestfall69/neogeo-diag-aes-prog)<br>
[MVS Version](https://github.com/jwestfall69/neogeo-diag-mvs-prog)

The P ROMs are mapped into 2 addresses ranges on the 68K CPU.

| Start | End | Description | Notes |
|:-----:|:---:|:------------|:------|
|0x000000|0x0FFFFF| P1 Range | Read-Only |
|0x200000|0x2FFFFF| P2 Range | Read/Write |

Both of these ranges share the same address and data lines on the cart edge.  Writes to the P2 range get used for stuff like bank switching or communicating to custom chips on the prog board.

Read/Write signals (active low) on the slot for the ranges are:
  * ROMOEL - P1 Low Byte Read Enable
  * ROMOEU - P1 High Byte Read Enable
  * ROMOE - P1 Low or High Byte Read Enable
  * PORTOEL - P2 Low Byte Read Enable
  * PORTOEU - P2 High Byte Read Enable
  * PORTADRS - P2 Low or High Byte Read Enable
  * PORTWEL - P2 Low Byte Write Enable
  * PORTWEU - P2 High Byte Write Enable

On MVS boards there is also a SLOTCS signal that will got low if the slot itself is active/selected.

## Address Paths
These are the address paths between the P roms and the CPU.
| Board   | P ROM Address Path from CPU |
|:--------|:-----------------------|
| MV1<br>MV1-1<br>MV1T | SLOT <= CPU |
| MV1A<br>MV1ACH<br>MV1ACHX<br>MV1AX    | SLOT <= CPU |
| MV1B<br>MV1B CHX<br>MV1B1    | SLOT <= CPU |
| MV1C    | SLOT <= CPU |
| MV1F<br>MV1FS<br>MV1FT    | SLOT <= CPU |
| MV1FZ   | SLOT <= CPU |
| MV2<br>MV2-01<br>MV2B    | SLOT1/2 <= NEO-E0 @ H6 <= CPU |
| MV2F<br>MV2FS   | SLOT1/2 <= NEO-E0 @ F3 <= CPU |
| MV4     | SLOT1 <= 74LS/F244 @ D2/D3/D4 <= CN10 <= CN10 <= 74HC/AS244 @ B9/B10/B11 <= CPU<br>SLOT2 <= 74LS/F244 @ H2/H3/H4 <= CN10 <= CN10 <= 74HC/AS244 @ B9/B10/B11 <= CPU<br>SLOT3 <= 74LS/F244 @ M2/M3/M4 <= CN10 <= CN10 <= 74HC/AS244 @ B9/B10/B11 <= CPU<br>SLOT4 <= 74LS/F244 @ S2/S3/S4 <= CN10 <= CN10 <= 74HC/AS244 @ B9/B10/B11 <= CPU |
| MV4F<br>MV4FS<br>MV4FT<br>MV4FT2<br>MV4FT3   | TODO |
| MV6     | TODO |

## Data Paths
These are the data paths between the P roms on the slot to the CPU.

| Board   | P ROM Data Path to/from CPU |
|:--------|:-----------------------|
| MV1<br>MV1-1<br>MV1T | SLOT <=> CPU |
| MV1A<br>MV1ACH<br>MV1ACHX<br>MV1AX    | SLOT <=> NEO-BUF (GA11) LEFT OF NEO-GRC <=> CPU |
| MV1B<br>MV1B CHX<br>MV1B1    | SLOT <=> NEO-BUF (GA1) ON SLOT BOARD <=> CPU |
| MV1C    | SLOT <=> CPU |
| MV1F<br>MV1FS<br>MV1FT    | SLOT <=> CPU |
| MV1FZ   | SLOT <=> CPU |
| MV2<br>MV2-01<br>MV2B    | SLOT1/2 <=> NEO-G0 @ J4 <=> CPU |
| MV2F<br>MV2FS   | SLOT1/2 <=> NEO-G0 @ H2.5 <=> CPU |
| MV4     | SLOT 1 <=> 74LS245s @ C3/C4 <=> CN10 <=> CN10 <=> 74AS245s @ B7/B8 <=> CPU<br>SLOT 2 <=> 74LS245s @ G3/G4 <=> CN10 <=> CN10 <=> 74AS245s @ B7/B8 <=> CPU<br>SLOT 3 <=> 74LS245s @ L3/L4 <=> CN10 <=> CN10 <=> 74AS245s @ B7/B8 <=> CPU<br>SLOT 4 <=> 74LS245s @ R3/R4 <=> CN10 <=> CN10 <=> 74AS245s @ B7/B8 <=> CPU |
| MV4F<br>MV4FS<br>MV4FT<br>MV4FT2<br>MV4FT3   | SLOT 1/2 <=> NEO-G0 @ B1 <=> CN10 <=> CN10 <=> 72AS245s @ C11/D11 <=> CPU<br>SLOT 3/4 <=> NEO-G0 @ D1 <=> CN10 <=> CN10 <=> 72AS245s @ C11/D11 <=> CPU |
| MV6     | SLOT1 <=> 74LS245s @ L6/M6 <=> CN10 <=> CN10 <=> 74AS245s @ B7/B8 <=> CPU<br>SLOT2 <=> 74LS245s @ L10/M10 <=> CN10 <=> CN10 <=> 74AS245s @ B7/B8 <=> CPU<br>SLOT3 <=> 74LS245s @ L14/M14 <=> CN10 <=> CN10 <=> 74AS245s @ B7/B8 <=> CPU<br>SLOT4 <=> 74LS245s @ L18/M18 <=> CN10 <=> CN10 <=> 74AS245s @ B7/B8 <=> CPU<br>SLOT5 <=> 74LS245s @ L22/M22 <=> CN10 <=> CN10 <=> 74AS245s @ B7/B8 <=> CPU<br>SLOT6 <=> 74LS245s @ L26/M26 <=> CN10 <=> CN10 <=> 74AS245s @ B7/B8 <=> CPU |

## Enable/Write Paths
These are the paths for the enable/write lines the P roms.

| Board   | P ROM Enable/Write Paths |
|:--------|:-----------------------|
| MV1<br>MV1-1<br>MV1T | SLOT <= PRO-C0 @ F4 |
| MV1A<br>MV1ACH<br>MV1ACHX<br>MV1AX    |  SLOT <= 74HC32s @ U1/U2 <= PALCE20V8Hs @ PAL1/PAL2 |
| MV1B<br>MV1B CHX<br>MV1B1    | SLOT <= NEO-DCR-T (GA1) |
| MV1C    | SLOT <= NEO-DCR-T (GA1) |
| MV1F<br>MV1FS<br>MV1FT    | SLOT <= NEO-C1 @ L5 |
| MV1FZ   | SLOT <= NEO-C1 (GU1) |
| MV2<br>MV2-01<br>MV2B    | SLOT1/2 <= NEO-E0s @ G6/F7 <= PRO-C0 |
| MV2F<br>MV2FS   | SLOT1/2 <= NEO-E0s @ F3/F8 <= PRO-C0  |
| MV4     | SLOT 1 PORTOE*/PORTWE*/ROMOE* <= 74F244 @ C2 <= CN10 <= CN10 <= 74AS244 @ C11 <= PRO-C0 @ L6<br>SLOT 1 ROMOE <= 74F244 @ D2 <= CN11 <= CN11 <= 74LS244 @ F2 <= 74LS08 @ K2 <= PRO-C0 @ L6<br>SLOT 1 PORTADRS <= 74LS244 @ C6 <= CN11 <= CN11 <= 74AS244 @ B11 <= PRO-C0 @ L6<hr>SLOT 2 PORTOE*/PORTWE*/ROMOE* <= 74F244 @ G2 <= CN10 <= CN10 <= 74AS244 @ C11 <= PRO-C0 @ L6<br>SLOT 2 ROMOE <= 74F244 @ H2 <= CN11 <= CN11 <= 74LS244 @ F2 <= 74LS08 @ K2 <= PRO-C0 @ L6<br>SLOT 2 PORTADRS <= 74LS244 @ G6 <= CN11 <= CN11 <= 74AS244 @ B11 <= PRO-C0 @ L6<hr>SLOT 3 PORTOE*/PORTWE*/ROMOE* <= 74F244 @ L2 <= CN10 <= CN10 <= 74AS244 @ C11 <= PRO-C0 @ L6<br>SLOT 3 ROMOE <= 74F244 @ M2 <= CN11 <= CN11 <= 74LS244 @ F2 <= 74LS08 @ K2 <= PRO-C0 @ L6<br>SLOT 3 PORTADRS <= 74LS244 @ L6 <= CN11 <= CN11 <= 74AS244 @ B11 <= PRO-C0 @ L6<hr>SLOT 4 PORTOE*/PORTWE*/ROMOE* <= 74F244 @ R2 <= CN10 <= CN10 <= 74AS244 @ C11 <= PRO-C0 @ L6<br>SLOT 4 ROMOE <= 74F244 @ S2 <= CN11 <= CN11 <= 74LS244 @ F2 <= 74LS08 @ K2 <= PRO-C0 @ L6<br>SLOT 4 PORTADRS <= 74LS244 @ R6 <= CN11 <= CN11 <= 74AS244 @ B11 <= PRO-C0 @ L6<br> |
| MV4F<br>MV4FS<br>MV4FT<br>MV4FT2<br>MV4FT3   | TODO |
| MV6     | TODO |