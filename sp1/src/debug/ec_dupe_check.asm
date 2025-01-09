	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"
	include "print_error.inc"

	global ec_dupe_check

	section code

; This is a check to verify I dont accidently have any dupe
; error codes in d_ec_list.
;
; There are 256 possible error codes.  We are using a 32 byte
; array where each bit represents a single error code we've
; seen.  We are doing (error_code / 8), the whole number is the
; byte in our array and the remainder is the bit within that
; byte.  If we already see a bit set it means we have a dupe.
ec_dupe_check:

		RSUB	print_header

		lea	d_xys_d_main_menu, a0
		RSUB	print_xys_string_clear

		lea	r_ec_seen, a0
		move.l	#(32 / 4) - 1, d0
		moveq	#0, d1
	.loop_next_byte:
		move.l	d1, (a0)+
		dbra	d0, .loop_next_byte

		lea	d_ec_list, a1
	.loop_ec_next_entry:
		lea	r_ec_seen, a2
		tst.l	(a1)		; list ends in a $0.l
		beq	.ec_list_end

		move.b	(a1), d3
		and.l	#$ff, d3
		divu	#8, d3

		; figure out the byte in the array
		move.b	d3, d2
		and.l	#$ff, d2
		add.l	d2, a2

		; figure out bit in the byte
		swap	d3
		moveq	#0, d2
		and.l	#$ff, d3
		moveq	#1, d2
		lsl.w	d3, d2

		btst	d3, (a2)
		bne	.found_dupe

		or.b	d2, (a2)
		addq.l	#s_ee_struct_size, a1	; goto next d_ec_list entry
		bra	.loop_ec_next_entry

	.found_dupe:
		moveq	#LEFT_MARGIN, d0
		moveq	#5, d1
		lea	d_str_dupe_found, a0
		RSUB	print_xy_string_clear

		moveq	#(LEFT_MARGIN + 15), d0
		moveq	#5, d1
		move.b	(a1), d2
		RSUB	print_hex_byte
		bra	.loop_input

	.ec_list_end:
		moveq	#LEFT_MARGIN, d0
		moveq	#5, d1
		lea	d_str_no_dupes, a0
		RSUB	print_xy_string

	.loop_input:
		WATCHDOG
		btst	#INPUT_D_BIT, REG_P1CNT
		bne	.loop_input
		rts

	section data
	align 1

d_str_dupe_found: 	STRING "EC DUPE FOUND:"
d_str_no_dupes:		STRING "NO EC DUPES FOUND"

	section bss
	align 1

r_ec_seen:
	dcb.b	32
