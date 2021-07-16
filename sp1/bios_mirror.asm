	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"
	include "../common/error_codes.inc"

	global auto_bios_mirror_test_dsub

	section text

; The bios code is only 32k ($8000).  3 copies/mirrors
; of it are used to fill the entire 128k of the bios rom.
; At offset $7ffb of each mirror is a byte that contains
; the mirror number.  The running bios is $00, first
; mirror is $01, 2nd mirror $02, and 3th mirror $03.
; This test checks each of these to verify they are correct.
; If they end up being wrong it will trigger the "BIOS ADDRESS (A14-A15)"
; error.
; on error:
;  d1 = actual value
;  d2 = expected value
auto_bios_mirror_test_dsub:
		lea	$bffffb, a0
		moveq	#3, d0
		moveq	#-1, d2
	.loop_next_offset:
		addq.b	#1, d2
		adda.l	#$8000, a0
		move.b	(a0), d1
		cmp.b	d2, d1
		dbne	d0, .loop_next_offset
		bne	.test_failed

		moveq	#$0, d0
		DSUB_RETURN

	.test_failed:
		moveq	#EC_BIOS_MIRROR, d0
		DSUB_RETURN
