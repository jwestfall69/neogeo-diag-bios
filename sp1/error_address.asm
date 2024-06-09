	include "neogeo.inc"
	include "macros.inc"

	global error_address_dsub

	section text
; params
;  d0 = error code
error_address_dsub:

		move.b	d0, d6
		lea	XY_STR_EA_TRIGGERED, a0
		DSUB	print_xy_string_struct
		move.b	d6, d0

		; convert the error code into a error_address
		; then jump to it.  jump address is $c06000 | (d0 << 5)
		and.l	#$ff, d0
		lsl.l	#5, d0
		or.l	#$c06000, d0
		move.l	d0, a1
		lea	REG_WATCHDOG, a0
		jmp	(a1)

XY_STR_EA_TRIGGERED:	XY_STRING 4, 27, "ERROR ADDRESS TRIGGERED"

	; $6000 to a little bit before $8000 of the rom is dedicated to
	; error addresses.  This block of the rom is filled with
	; .loop:
	;	move.b d0, (a0)		; watchdog
	;	bra .loop
	; which translates into opcodes $1080 $60fc
	section error_addresses

		blk.l ($1fe2 / 4), $108060fc
