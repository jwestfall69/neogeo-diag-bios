	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"
	include "../common/include/error_codes.inc"

	global rom_crc32_test_psub

	section code

rom_crc32_test_psub:
		ld	bc, $0000
		exx
		ld	bc, ROM_CRC32_OFFSET
		exx
		PSUB	crc32

		cp	a
		ld	hl, (ROM_CRC32_OFFSET)
		sbc	hl, bc
		jr	nz, .test_failed

		ld	hl, (ROM_CRC32_OFFSET + 2)
		sbc	hl, de
		jr	nz, .test_failed

		xor	a
		PSUB_RETURN

	.test_failed:
		ld	a, EC_Z80_M1_CRC
		or	a
		PSUB_RETURN
