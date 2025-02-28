	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"

	global error_address_test

	section code

error_address_test:
		RSUB	print_header

		lea	d_screen_xys_list, a0
		RSUB	print_xys_string_clear_list

		lea	d_xys_d_main_menu, a0
		RSUB	print_xys_string_clear

		moveq	#$0, d4		; error num

	.update_byte:
		and.l	#$7f, d4

		move.b	d4, d2
		moveq	#(LEFT_MARGIN + 19), d0
		moveq	#9, d1
		RSUB	print_hex_byte

		move.b	d4, d2
		and.l	#$ff, d2
		lsl.l	#5, d2
		or.l	#$c06000, d2
		moveq	#(LEFT_MARGIN + 15), d0
		moveq	#10, d1
		RSUB	print_hex_3_bytes

	.loop_input:
		WATCHDOG

		bsr	check_reset_request
		bsr	p1p2_input_update
		move.b	r_p1_input_edge, d0

		btst	#INPUT_UP_BIT, d0
		beq	.up_not_pressed
		add.w	#1, d4
		bra	.update_byte
	.up_not_pressed:

		btst	#INPUT_DOWN_BIT, d0
		beq	.down_not_pressed
		sub.w	#1, d4
		bra	.update_byte

	.down_not_pressed:
		btst	#INPUT_LEFT_BIT, d0
		beq	.left_not_pressed
		sub.w	#$10, d4
		bra	.update_byte

	.left_not_pressed:
		btst	#INPUT_RIGHT_BIT, d0
		beq	.right_not_pressed
		add.w	#$10, d4
		bra	.update_byte

	.right_not_pressed:
		btst	#INPUT_A_BIT, d0
		beq	.a_not_pressed

		moveq	#26, d0
		SSA3	fix_clear_line

		move.w	d4, d0
		RSUB	error_address

	.a_not_pressed:
		btst	#INPUT_D_BIT, d0
		beq	.loop_input
		rts

	section data
	align 1

d_screen_xys_list:
	XY_STRING LEFT_MARGIN, 9, "ERROR NUM:"
	XY_STRING LEFT_MARGIN, 10, "ERROR ADDRESS:"
	XY_STRING LEFT_MARGIN, 26, "A: TRIGGER ERROR ADDRESS"
	XY_STRING_LIST_END
