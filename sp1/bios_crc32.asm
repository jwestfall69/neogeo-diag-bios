	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"
	include "../common/error_codes.inc"

	global auto_bios_crc32_test_dsub

	section text

; verifies the bios crc is correct.  The expected crc32 value
; are the 4 bytes located at $7ffc ($c07ffc) of the bios.
; on error:
;  d1 = actual crc32
auto_bios_crc32_test_dsub:
		move.l	#$7ffb, d0			; length
		lea	$c00000, a0			; start address
		move.b	d0, REG_SWPROM			; use carts vector table?
		DSUB	calc_crc32

		move.b	d0, REG_SWPBIOS			; use bios vector table
		cmp.l	$c07ffc, d0
		beq	.test_passed

		move.l	d0, d1
		moveq	#EC_BIOS_CRC32, d0
		DSUB_RETURN

	.test_passed:
		moveq	#0, d0
		DSUB_RETURN

; calculate the crc32 value
; params:
;  d0 = length
;  a0 = start address
; returns:
;  d0 = crc value
calc_crc32_dsub:
		subq.l	#1, d0
		move.w	d0, d3
		swap	d0
		move.w	d0, d4
		lea	REG_WATCHDOG, a1
		move.l	#$edb88320, d5			; P
		moveq	#-1, d0
	.loop_outer:
		move.b	d0, (a1)			; WATCHDOG
		moveq	#7, d2
		move.b	(a0)+, d1
		eor.b	d1, d0
	.loop_inner:
		lsr.l	#1, d0
		bcc	.no_carry
		eor.l	d5, d0
	.no_carry:
		dbra	d2, .loop_inner
		dbra	d3, .loop_outer
		dbra	d4, .loop_outer
		not.l	d0
		DSUB_RETURN
