	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"

        global manual_controller_tests
        global STR_CONTROLLER_TESTS

	section	text

	manual_controller_tests:
		moveq	#$5, d0
		SSA3	fix_clear_line
		bsr	print_labels

	.loop_update:
		WATCHDOG
		bsr	p1p2_input_update
		bsr	update_player_data
		moveq	#$0, d0
		bsr	send_p1p2_controller
		moveq	#$3, d0
		and.b	REG_STATUS_B, d0
		bne	.loop_update				; loop until p1 start + select pressed

	.loop_ss_still_pressed:
		WATCHDOG
		moveq	#$3, d0
		move.b	REG_STATUS_B, d1
		and.b	d0, d1
		cmp.b	d0, d1
		bne	.loop_ss_still_pressed			; wait for p1 start + select released
		rts

print_labels:
		lea	XY_STR_P1, a0
		RSUB	print_xy_string_struct_clear
		lea	XY_STR_P2, a0
		RSUB	print_xy_string_struct_clear
		moveq	#$7, d3
		moveq	#$25, d4
	.loop_next_header:
		move.b	d4, d0
		moveq	#$3, d1
		move.b	d3, d2
		RSUB	print_hex_nibble
		subq.w	#4, d4
		dbra	d3, .loop_next_header

		moveq	#$4, d0
		bsr	print_row_labels
		moveq	#$11, d0
		bsr	print_row_labels
		rts

print_row_labels:
		move.b	d0, d3
		lea	ROW_LABELS, a0
	.loop_next_buttom:
		moveq	#$4, d0
		move.b	d3, d1
		RSUB	print_xy_string
		addq.b	#1, d3
		tst.b	(a0)
		bne	.loop_next_buttom
		rts

update_player_data:
		moveq	#$0, d3
		moveq	#$0, d6

	.loop_next_sample:
		move.b	d6, d0
		bsr	send_p1p2_controller
		bsr	p1p2_input_update

		clr.w	d0
		move.b	p1_input, d0
		move.b	p1_input_aux, d1
		lsl.w	#8, d1
		or.w	d1, d0			; merge input/input_aux into d0
		move.b	d3, d1
		moveq	#$4, d2
		movem.w	d3/d6, -(a7)
		bsr	print_player_data
		movem.w	(a7)+, d3/d6

		clr.w	d0
		move.b	p2_input, d0
		move.b	p2_input_aux, d1
		lsl.w	#8, d1
		or.w	d1, d0
		move.b	d3, d1
		moveq	#$11, d2
		movem.w	d3/d6, -(a7)
		bsr	print_player_data
		movem.w	(a7)+, d3/d6
		addq.b	#4, d3
		addq.b	#1, d6
		cmp.b	#$8, d6
		bne	.loop_next_sample
		rts

; params:
;  d0 = data
;  d1 = x offset?
;  d2 = y start
print_player_data:
		move.w	d0, -(a7)
		move.w	d0, d4
		moveq	#$8, d5

		add.b	d1, d5
		move.b	d2, d6
		moveq	#$9, d3

	.loop_next_bit:
		move.b	d5, d0
		move.b	d6, d1
		move.w	d4, d2
		RSUB	print_bit
		lsr.w	#1, d4
		addq.b	#1, d6
		dbra	d3, .loop_next_bit

		move.b	d5, d0
		move.b	d6, d1
		move.w	(a7), d2
		RSUB	print_hex_byte

		move.b	d5, d0
		move.b	d6, d1
		addq.b	#1, d1
		move.w	(a7)+, d2
		and.w	#$ff, d2
		RSUB	print_3_digits
		rts

STR_CONTROLLER_TESTS:		STRING "CONTROLLER TESTS"

XY_STR_P1:			XY_STRING  1,  4, "P1"
XY_STR_P2:			XY_STRING  1, 17, "P2"

ROW_LABELS:
	dc.b "UP", $0
	dc.b "DN", $0
	dc.b "LF", $0
	dc.b "RT", $0
	dc.b "A", $0
	dc.b "B", $0
	dc.b "C", $0
	dc.b "D", $0
	dc.b "STA", $0
	dc.b "SEL", $0
	dc.b "HEX", $0
	dc.b "DEC", $0
	dc.b $0

