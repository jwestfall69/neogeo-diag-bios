	include "diag.inc"
	include "neogeo.inc"
	include "macros.inc"

	global memory_viewer

	section code

NUM_ROWS	equ 16
START_ROW	equ 8

; a0 = start memory location
; d0 = 0 = normal memory, 1 = vram
memory_viewer:

		movem.l	a0, -(a7)
		move.b	d0, r_is_vram

		bsr	get_slot_count
		move.b	d0, r_slot_max

		RSUB	print_header

		lea	d_xys_screen_list, a0
		RSUB	print_xys_string_clear_list

		lea	d_xys_d_main_menu, a0
		RSUB	print_xys_string

		tst.b	r_is_vram
		beq	.not_vram

		lea	d_xys_vram, a0
		RSUB	print_xys_string

	.not_vram:

		movem.l	(a7)+, a0

		tst.b	r_z80_test_flags	; z80 tests were run
		bne	.skip_sm1_stall

		; if z80 tests weren't run, make the sm1 stall
		; by telling it to prepare for slot switch.  This
		; should prevent the diag m1 from becoming active
		; if we do slot switches
		move.b	#$01, REG_SOUND
		move.l	#$1388, d0
		RSUB	delay

	.skip_sm1_stall:
		tst.b	REG_STATUS_B
		bpl	.aes_system

		move.b	#0, r_slot_num
		bra	.loop_next_input

	.aes_system:
		move.b	#1, r_slot_num

	.loop_next_input:
		WATCHDOG

		moveq	#(LEFT_MARGIN + 27), d0
		moveq	#5, d1
		move.b	r_slot_num, d2
		RSUB	print_digit

		moveq	#(LEFT_MARGIN + 29), d0
		moveq	#5, d1
		move.b	r_slot_max, d2
		RSUB	print_digit

		; limit address to 24 bit
		move.l	a0, d0
		and.l	#$ffffff, d0
		move.l	d0, a0

		tst.b	r_is_vram
		beq	.do_dump

		; for vram limit address range to 0 to last displayed line of $7ffe
		btst	#23, d0
		bne	.vram_negative
		cmp.l	#($8800 - (NUM_ROWS * 2)), d0
		ble	.do_dump
		movea.l	#($8800 - (NUM_ROWS * 2)), a0
		bra	.do_dump

	.vram_negative:
		movea.l	#$0, a0

	.do_dump:
		bsr	memory_dump
		bsr	p1_input_update
		move.b	r_p1_input_edge, d0

		btst	#INPUT_UP_BIT, d0
		beq	.up_not_pressed
		suba.l	#4, a0
		bra	.loop_next_input

	.up_not_pressed:
		btst	#INPUT_DOWN_BIT, d0
		beq	.down_not_pressed
		adda.l	#4, a0
		bra	.loop_next_input

	.down_not_pressed:
		btst	#INPUT_LEFT_BIT, d0
		beq	.left_not_pressed
		bsr	get_offset
		suba.l	d0, a0
		bra	.loop_next_input

	.left_not_pressed:
		btst	#INPUT_RIGHT_BIT, d0
		beq	.right_not_pressed
		bsr	get_offset
		adda.l	d0, a0
		bra	.loop_next_input

	.right_not_pressed:
		btst	#INPUT_A_BIT, d0
		beq	.a_not_pressed
		bsr	handle_slot_change
		bra	.loop_next_input

	.a_not_pressed:
		btst	#INPUT_D_BIT, d0
		beq	.loop_next_input

		; when exiting we need to we switch to the sm1 rom (where
		; valid).  If the user did the z80 tests on boot and a slot
		; switch happened, we need to clear out the z80 flags.  This will
		; cause us to send the sm1 stall code if the user were to run the
		; memory viewer again, otherwise the diag m1 code we run.
		btst	#Z80_TEST_FLAG_SLOT_SWITCH, r_z80_test_flags
		beq	.no_change
		clr.b	r_z80_test_flags
	.no_change:
		move.b	d0, REG_BRDFIX
		rts

; params:
;  a0 = start adddress
memory_dump:

		movem.l	d0-d6/a0, -(a7)

		moveq	#START_ROW, d3
		moveq	#(NUM_ROWS - 1), d4

		bra	.loop_start_address

	.loop_next_address:
		add.b	#$1, d3			; line number

	.loop_start_address:

		moveq	#(LEFT_MARGIN + 4), d0
		move.w	d3, d1
		move.l	a0, d2
		RSUB	print_hex_3_bytes	; address

		bsr	read_data
		move.l	d0, d5
		move.l	d0, d2

		moveq	#(LEFT_MARGIN + 17), d0
		move.w	d3, d1

		RSUB	print_hex_word			; lower word

		moveq	#(LEFT_MARGIN + 12), d0
		move.w	d3, d1

		move.l	d5, d2
		swap	d2
		RSUB	print_hex_word			; upper word

		moveq	#(LEFT_MARGIN + 26), d2		; x offset
		moveq	#3, d6				; num of chars

	.loop_next_char:
		movem.l	d2, -(a7)

		move.w	d2, d0
		move.w	d3, d1
		move.l	d5, d2
		RSUB	print_xy_char

		lsr.l	#8, d5
		movem.l	(a7)+, d2
		sub.b	#1, d2
		dbra	d6, .loop_next_char


		adda.l	#2, a0
		tst.b	r_is_vram
		bne	.increment_done
		adda.l	#2, a0

	.increment_done:
		dbra	d4, .loop_next_address
		movem.l (a7)+, d0-d6/a0
		rts

; params:
;  a0 = address
; returns:
;  d0.l = data
read_data:
		tst.b	r_is_vram
		beq	.normal_ram
		move.l	a0, d1
		move.w	d1, (-2, a6)
		move.w 	(a6), d0
		swap	d0
		addq.w	#1, d1
		move.w	d1, (-2, a6)
		move.w	(a6), d0
		rts

	.normal_ram:
		move.w	(a0), d0
		swap	d0
		move.w	(2, a0), d0
		rts

; Figure out how far to jump based on the user
; pressing or not pressing the B/C buttons
; returns:
;  d0 = offset
get_offset:
		move.b	r_p1_input, d0
		and.b	#(INPUT_B|INPUT_C), d0
		cmp.b	#(INPUT_B|INPUT_C), d0
		bne	.b_and_c_not_pressed
		move.l	#$10000, d0
		rts

	.b_and_c_not_pressed:
		cmp.b	#INPUT_B, d0
		bne	.b_not_pressed
		move.l	#$100, d0
		rts

	.b_not_pressed:
		cmp.b	#INPUT_C, d0
		bne	.c_not_pressed
		move.l	#$1000, d0
		rts

	.c_not_pressed:
		move.l	#(NUM_ROWS * 2), d0
		tst.b	r_is_vram
		bne	.skip_adjust
		lsl.l	#1, d0
	.skip_adjust:
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
	align 1

d_xys_screen_list:
	XY_STRING LEFT_MARGIN, 5, "MEMORY VIEWER -- SLOT NUM:  /"
	XY_STRING (LEFT_MARGIN + 5), 7, "ADDR      HEX     CHAR"
	XY_STRING LEFT_MARGIN, 25, "A: Slot Switch"
	XY_STRING LEFT_MARGIN, 26, "B/C: Page Up/Down Rate"
	XY_STRING_LIST_END

d_xys_vram:	XY_STRING LEFT_MARGIN, 7, "VRAM"

	section bss
	align 2

r_is_vram:	dc.b	$0
r_slot_num:	dc.b	$0
r_slot_max:	dc.b	$0
