	include "diag.inc"
	include "neogeo.inc"
	include "macros.inc"

	global error_address_dsub

	section code
; params
;  d0 = error code
error_address_dsub:

		move.b	d0, d6
		lea	d_xys_ea_triggered, a0
		DSUB	print_xys_string
		move.b	d6, d0

		; convert the error code into a error_address
		; then jump to it.  jump address is $c06000 | (d0 << 5)
		and.l	#$7f, d0
		lsl.l	#5, d0
		or.l	#$c06000, d0
		move.l	d0, a1
		lea	REG_WATCHDOG, a0
		jmp	(a1)

	section error_addresses
	; The sp1.ld file is setup to put the error_addresses section
	; starting at $c06000.  Below will fill $c06000 to $c07000.
	rept $1000 / 4
	inline
	.loop:
		move.b	d0, (a0)	; $1080 (watchdog)
		bra	.loop		; $60fc
	einline
	endr

	section data
	align 1

d_xys_ea_triggered:	XY_STRING LEFT_MARGIN, 27, "ERROR ADDRESS TRIGGERED"
