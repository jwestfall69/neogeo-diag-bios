	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"
	include "../common/error_codes.inc"

	global rom_mirror_test_psub

	section code

; This source gets compiled to a size of 2048 ($0800) and
; is mirror'ed 15 times to make up the first 32k of the
; m1 rom.  At $07fb of each mirror contains a byte that
; represents the mirror number.  The running copy is
; 0, first mirror is 1, 2nd mirror is 2, etc.  The below
; function makes sure these mirror numbers match up. If
; they dont it points to there being a problem with
; one or more of the address lines between the z80 and
; m1 rom
	rom_mirror_test_psub:
		ld	hl, ROM_MIRROR_OFFSET
		ld	de, $800		; size of each mirror
		ld	a, $00
		ld	b, $10

	.loop_next_mirror:
		cp	(hl)
		jr	nz, .test_failed_abort
		inc	a
		add	hl, de
		djnz	.loop_next_mirror

		xor	a
		PSUB_RETURN

	.test_failed_abort:
		ld	a, EC_Z80_M1_UPPER_ADDRESS
		or	a
		PSUB_RETURN
