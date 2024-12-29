	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"

	global fix_tile_viewer

; TODO: look into games with a NEO-CMC chip.  They have
; issues when switching to them.  Likely related to
; bankswitching

START_COLUMN	equ LEFT_MARGIN
START_ROW	equ 7

OFFSET_MASK	equ $0fff
PALETTE_NUM	equ $2

	section code

fix_tile_viewer:
		move.w	#0, r_tile_offset

		bsr	get_slot_count
		move.b	d0, r_slot_max

		RSUB	print_header

		lea	d_screen_xys_list, a0
		RSUB	print_xys_string_clear_list

		lea	d_xys_d_main_menu, a0
		RSUB	print_xys_string

		moveq	#(START_COLUMN + 2), d0
		moveq	#START_ROW, d1
		lea	d_str_0f, a0
		RSUB	print_xy_string

		lea	d_palette_data, a0
		lea	PALETTE_RAM_START + (PALETTE_SIZE * PALETTE_NUM), a1
		moveq	#15, d0
	.loop_next_color:
		move.w	(a0)+, (a1)+
		dbra	d0, .loop_next_color

		tst.b	REG_STATUS_B
		bpl	.aes_system

		move.b	#0, r_slot_num
		bra	.loop_redraw

	.aes_system:
		move.b	#1, r_slot_num

	.loop_redraw:

		moveq	#(LEFT_MARGIN + 26), d0
		moveq	#10, d1
		move.b	r_slot_num, d2
		RSUB	print_digit

		moveq	#(LEFT_MARGIN + 28), d0
		moveq	#10, d1
		move.b	r_slot_max, d2
		RSUB	print_digit

		move.w	(r_tile_offset), d6
		and.w	#OFFSET_MASK, d6
		move.w	d6, (r_tile_offset)

		moveq	#15, d5				; number of rows - 1
		moveq	#(START_ROW + 2), d2			; current row number

		lea	d_str_0f, a1

	.loop_next_row:
		moveq	#START_COLUMN, d3		; reset with each row

		move.l	d3, d0
		move.l	d2, d1
		SSA3	fix_seek_xy

		move.b	(a1)+, d0
		and.w	#$ff, d0
		move.w	d0, (a6)

		addq.b	#2, d3				; skip from header to first tile position for the row
		moveq	#15, d4				; number of bytes per row - 1

	.loop_next_byte:
		move.l	d3, d0
		move.l	d2, d1
		SSA3	fix_seek_xy
		move.w	d6, d0
		or.w	#(PALETTE_NUM << 12), d0	; pppp tttt tttt tttt
		move.w	d0, (a6)

		addq.b	#1, d3				; next position over
		addq.b	#1, d6				; next byte to print
		dbra	d4, .loop_next_byte

		addq.b	#1, d2				; next row
		dbra	d5, .loop_next_row

	.loop_input:
		WATCHDOG

		moveq	#(LEFT_MARGIN + 28), d0
		moveq	#12, d1
		move.w	r_tile_offset, d2
		RSUB	print_hex_word

		bsr	p1_input_update
		move.b	r_p1_input_edge, d0

		btst	#INPUT_UP_BIT, d0
		beq	.up_not_pressed
		sub.w	#$100, r_tile_offset
		bra	.loop_redraw
	.up_not_pressed:

		btst	#INPUT_DOWN_BIT, d0
		beq	.down_not_pressed
		add.w	#$100, r_tile_offset
		bra	.loop_redraw
	.down_not_pressed:

		btst	#INPUT_LEFT_BIT, d0
		beq	.left_not_pressed
		sub.w	#$1000, r_tile_offset
		bra	.loop_redraw
	.left_not_pressed:

		btst	#INPUT_RIGHT_BIT, d0
		beq	.right_not_pressed
		add.w	#$1000, r_tile_offset
		bra	.loop_redraw
	.right_not_pressed:

		btst	#INPUT_A_BIT, d0
		beq	.a_not_pressed
		bsr	handle_slot_change
		bra	.loop_redraw

	.a_not_pressed:

		btst	#INPUT_D_BIT, d0
		beq	.loop_input

		; when exiting we need to we switch to the sm1 rom (where
		; valid).  If the user did the z80 tests on boot and a slot
		; switch happened, we need to clear out the z80 flags.  This will
		; cause us to send the sm1 stall code if the user were to run the
		; fix tile viewer again, otherwise the diag m1 code we run.
		btst	#Z80_TEST_FLAG_SLOT_SWITCH, r_z80_test_flags
		beq	.no_change
		clr.b	r_z80_test_flags
	.no_change:
		move.b	d0, REG_BRDFIX
		rts

; Handle going to the next slot.  Slot ranges
; from 0 to r_slot_max.  If the slot is 0,
; switch to the motherboards sm1/fix
handle_slot_change:
		tst.b	REG_STATUS_B
		bmi	.mvs_system
		rts

	.mvs_system:
		move.b	r_slot_num, d0
		move.b	r_slot_max, d1

		addq.b	#1, d0
		cmp.b	d1, d0
		bls	.slot_num_ok
		moveq	#0, d0

	.slot_num_ok:
		move.b	d0, r_slot_num
		;tst.b	d0
		beq	.motherboard_fix

		subq.b	#1, d0
		move.b	d0, REG_SLOT
		move.b	d0, REG_CRTFIX
		rts

	.motherboard_fix:
		move.b	d0, REG_BRDFIX
		rts

	section data
	align 2

d_palette_data:
	dc.w	$0000, $7fff, $0000, $fe00, $5864, $8064, $e519
	dc.w	$d126, $e277, $8271, $0e78, $aa39, $f725, $0e5e
	dc.w	$9532, $f043

d_screen_xys_list:
	XY_STRING LEFT_MARGIN,  5, "FIX TILE VIEWER"
	XY_STRING (LEFT_MARGIN + 20), 10, "SLOT:  /"
	XY_STRING (LEFT_MARGIN + 20), 12, "OFFSET:"
	XY_STRING LEFT_MARGIN, 26, "A: Slot Switch"
	XY_STRING LEFT_MARGIN, 28, "UP/DN: Change offset"
	XY_STRING_LIST_END

; not part of d_screen_xys_list so we can use in row headers
d_str_0f:		STRING "0123456789ABCDEF"

	section bss
	align 2

r_tile_offset:		dc.w	$0
r_slot_num:		dc.b	$0
r_slot_max:		dc.b	$0

