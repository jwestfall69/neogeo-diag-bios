	include "macros.inc"
	include "menu.inc"
	include "neogeo.inc"
	include "diag.inc"

	global menu
	global r_menu_cursor

	section code

MENU_X_OFFSET		equ LEFT_MARGIN
MENU_Y_OFFSET		equ $7

CURSOR_CLEAR_CHAR	equ $20
CURSOR_CHAR		equ $11

; params:
;  a0 = array of menu entries
menu:
		move.l	a0, r_menu_list

		bsr	print_menu_list
		move.b	d0, d6			; max menu entries
		subq.b	#1, d6

		RSUB	print_header

		lea	d_xys_d_exit_menu, a0
		RSUB	print_xys_string_clear

		move.b	r_menu_cursor, d4	; current menu entry
		move.b	d4, d5			; previous menu entry

		; wait for user to release D button to void
		; double menu exit
		move.b	#INPUT_D, d0
		jsr	wait_p1_input

	.update_cursor:
		; clear old
		moveq	#(MENU_X_OFFSET - 1), d0
		moveq	#MENU_Y_OFFSET, d1
		add.b	d5, d1
		move.b	#CURSOR_CLEAR_CHAR, d2
		RSUB	print_xy_char

		; add new
		moveq	#(MENU_X_OFFSET - 1), d0
		moveq	#MENU_Y_OFFSET, d1
		add.b	d4, d1
		move.b	#CURSOR_CHAR, d2
		RSUB	print_xy_char

	.loop_menu_input:
		WATCHDOG

		bsr	check_reset_request
		bsr	p1p2_input_update
		move.b	r_p1_input_edge, d0

		btst	#INPUT_UP_BIT, d0
		beq	.up_not_pressed

		move.b	d4, d5
		subq.b	#1, d4
		bpl	.update_cursor
		move.b	d6, d4
		bra	.update_cursor


	.up_not_pressed:
		btst	#INPUT_DOWN_BIT, d0
		beq	.down_not_pressed

		move.b	d4, d5
		addq.b	#1, d4
		cmp.b	d4, d6
		bge	.update_cursor
		moveq	#0, d4
		bra	.update_cursor


	.down_not_pressed:
		btst	#INPUT_D_BIT, r_p1_input_edge
		beq	.d_not_pressed
		moveq	#MENU_EXIT, d0
		rts

	.d_not_pressed:
		btst	#INPUT_A_BIT, r_p1_input_edge
		bne	.a_pressed
		bsr	wait_frame
		bra	.loop_menu_input

	.a_pressed:
		move.b	d4, r_menu_cursor
		move.l	r_menu_list, a1
		move.b	d4, d0
		and.l	#$ff, d0
		mulu.w	#s_me_struct_size, d0			; goto the entry in the list
		add.l	d0, a1

		tst.b	REG_STATUS_B
		bpl	.system_aes
		bra	.menu_entry_run

	.system_aes:
		cmp.w	#1, s_me_mvs_only(a1)			; block call on aes, if mvs-only function
		beq	.loop_menu_input

	.menu_entry_run:
		SSA3	fix_clear

		move.l	s_me_name_ptr(a1), a0
		moveq	#LEFT_MARGIN, d0
		moveq	#5, d1
		RSUB	print_xy_string

		move.b	r_menu_cursor, -(a7)
		move.l	s_me_function_ptr(a1), a1
		jsr	(a1)
		move.b	(a7)+, r_menu_cursor

		SSA3	fix_clear
		moveq	#MENU_CONTINUE, d0
		rts

; params
;  a0 = address of start of MENU struct list
; returns
;  d0 = number of items printed
print_menu_list:
		moveq	#0, d4		; number of entries
		move.l	a0, a1

	.loop_next_entry:
		cmp.l	#0, (a1)
		beq	.list_end

		moveq	#$0, d2		; default palette

		tst.b	REG_STATUS_B
		bpl	.system_aes
		bra	.print_entry

	.system_aes:
		cmp.w	#1, s_me_mvs_only(a1)
		bne	.print_entry
		moveq	#$10, d2	; gray'd out palette for aes if mvs only

	.print_entry:
		moveq	#MENU_X_OFFSET, d0
		moveq	#MENU_Y_OFFSET, d1
		add.b	d4, d1
		move.l	s_me_name_ptr(a1), a0
		jsr	print_xyp_string

		add.l	#s_me_struct_size, a1
		addq.b	#1, d4
		bra	.loop_next_entry

	.list_end:
		move.b	d4, d0
		rts

	section data
	align 1

d_xys_d_exit_menu:	XY_STRING LEFT_MARGIN, 27, "D: EXIT MENU"

	section bss
	align 1

r_menu_list:		dc.l	$0
r_menu_cursor:		dc.b	$0
