	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"

	global manual_misc_input_tests
	global STR_MISC_INPUT_TEST

	section text

manual_misc_input_tests:
		lea	XY_STR_D_MAIN_MENU, a0
		RSUB	print_xy_string_struct_clear
		bsr	misc_input_print_static
	.loop_run_test:
		bsr	p1p2_input_update
		bsr	misc_input_update_dynamic
		bsr	wait_frame
		btst	#D_BUTTON, p1_input_edge
		beq	.loop_run_test			; if d pressed, exit test
		rts

misc_input_print_static:
		lea	XY_STR_MEMORY_CARD, a0
		RSUB	print_xy_string_struct_clear

		lea	MI_ITEM_CD1, a0
		moveq	#$9, d0
		moveq	#$3, d1
		bsr	misc_input_print_static_items

		lea	XY_STR_SYSTEM_TYPE, a0
		RSUB	print_xy_string_struct_clear

		lea	MI_ITEM_TYPE, a0
		moveq	#$1, d1
		bsr	misc_input_print_static_items

		tst.b	REG_STATUS_B
		bpl	.system_aes

		lea	MI_ITEM_CFG_A, a0
		moveq	#$f, d0
		moveq	#$2, d1
		bsr	misc_input_print_static_items

		lea	XY_STR_HARD_DIPS, a0
		RSUB	print_xy_string_struct_clear

	.system_aes:
		rts


misc_input_update_dynamic:
		lea	MI_ITEM_CD1,a0
		moveq	#$9, d0
		moveq	#$3, d1
		bsr	misc_input_print_dynamic_items

		lea	MI_ITEM_TYPE, a0
		moveq	#$e, d0
		moveq	#$1, d1
		bsr	misc_input_print_dynamic_items

		tst.b	REG_STATUS_B
		bpl	.system_aes

		lea	MI_ITEM_CFG_A, a0
		moveq	#$f, d0
		moveq	#$2, d1
		bsr	misc_input_print_dynamic_items

		lea	STR_SYSTEM_CONFIG_AS, a0
		moveq	#$4, d0
		moveq	#$12, d1
		RSUB	print_xy_string

		btst	#$6, REG_SYSTYPE
		bne	.system_4_or_6_slots
		lea	STR_12SLOT, a0
		bra	.system_type_print

	.system_4_or_6_slots:
		btst	#$5, REG_STATUS_A
		bne	.system_6_slot
		lea	STR_4SLOT, a0
		bra	.system_type_print

	.system_6_slot:
		lea	STR_6SLOT, a0

	.system_type_print:
		moveq	#$19, d0
		moveq	#$12, d1
		RSUB	print_xy_string

		move.b	REG_DIPSW, d2
		not.b	d2
		moveq	#14, d0
		moveq	#21, d1
		moveq	#7, d3
	.loop_next_dip_bit:
		movem.l	d0-d2, -(a7)
		RSUB	print_bit
		movem.l	(a7)+, d0-d2
		add.b	#1, d0
		ror.b	d2
		dbra	d3, .loop_next_dip_bit

	.system_aes:
		rts


; d0 = start row
; d1 = numer of misc_input structs to process
; a0 = address of first misc_input struct
misc_input_print_dynamic_items:
		movea.l	a0, a1
		move.b	d0, d5
		moveq	#$7f, d6
		and.w	d1, d6
		subq.w	#1, d6

	.loop_next_entry:
		movea.l	(a1), a2
		move.b	(a1), d0			; test_bit
		movea.l	($8,a1), a0			; bit_disabled_string_address
		moveq	#$30, d2
		btst	d0, (a2)
		beq	.print_description

		movea.l	($c,a1), a0			; bit_enabled_string_address
		moveq	#$31, d2

	.print_description:
		moveq	#$d, d0
		move.b	d5, d1
		RSUB	print_xy_char

		moveq	#$15, d0
		move.b	d5, d1
		moveq	#$0, d2
		moveq	#$20, d3
		moveq	#$13, d4
		RSUB	print_char_repeat		; empty out part of the line stuff

		moveq	#$15, d0
		move.b	d5, d1
		RSUB	print_xy_string

		lea	($10,a1), a1			; load up next struct
		addq.b	#1, d5
		dbra	d6, .loop_next_entry
		rts

; d0 = start row
; d1 = numer of misc_input structs to process
; a0 = address of first misc_input struct
misc_input_print_static_items:
		movea.l	a0, a1
		move.b	d0, d3
		moveq	#$7f, d6
		and.w	d1, d6
		subq.w	#1, d6

	.loop_next_entry:
		move.l	(a1)+, d2			; load the test_bit and mmio_address
		moveq	#$4, d0
		move.b	d3, d1
		RSUB	print_hex_3_bytes		; print the mmio_address

		moveq	#$2e, d2
		moveq	#$a, d0
		move.b	d3, d1
		RSUB	print_xy_char

		move.b	(-$4,a1), d2			; reload test_bit
		moveq	#$b, d0
		move.b	d3, d1
		RSUB	print_hex_nibble

		moveq	#$3d, d2
		moveq	#$c, d0
		move.b	d3, d1
		RSUB	print_xy_char

		movea.l	(a1)+, a0			; load bit_name_string_address
		moveq	#$f, d0
		move.b	d3, d1
		RSUB	print_xy_string

		addq.l	#8, a1				; skip over bit_(disabled|enabled)_string_address
		addq.b	#1, d3
		dbra	d6, .loop_next_entry
		rts

; struct misc_input {
;  byte test_bit;                ; bit to test on mmio address
;  byte mmio_address[3];         ; minus top byte
;  long bit_name_string_address;
;  long bit_disabled_string_address;
;  long bit_enabled_string_address;
;}
MI_ITEM_CD1:	MISC_INPUT_ITEM $04, $38, $00, $00, STR_CD1, STR_CARD_DETECTED, STR_CARD_EMPTY
MI_ITEM_CD2:	MISC_INPUT_ITEM $05, $38, $00, $00, STR_CD2, STR_CARD_DETECTED, STR_CARD_EMPTY
MI_ITEM_WP:	MISC_INPUT_ITEM $06, $38, $00, $00, STR_WP, STR_CARD_WP_OFF, STR_CARD_WP_ON
MI_ITEM_TYPE:	MISC_INPUT_ITEM $07, $38, $00, $00, STR_TYPE, STR_TYPE_AES, STR_TYPE_MVS
MI_ITEM_CFG_A:	MISC_INPUT_ITEM $05, $32, $00, $01, STR_CFG_A, STR_CFG_A_LOW, STR_CFG_A_HIGH
MI_ITEM_CFG_B:	MISC_INPUT_ITEM $06, $30, $00, $81, STR_CFG_B, STR_CFG_B_LOW, STR_CFG_B_HIGH

STR_SYSTEM_CONFIG_AS:		STRING "SYSTEM CONFIGURED AS "
STR_12SLOT:			STRING "1SLOT/2SLOT"
STR_4SLOT:			STRING "4SLOT      ";
STR_6SLOT:			STRING "6SLOT      ";

STR_MISC_INPUT_TEST:		STRING "MISC. INPUT TEST"

XY_STR_MEMORY_CARD:		XY_STRING  4,  8, "MEMORY CARD:"
XY_STR_SYSTEM_TYPE:		XY_STRING  4, 13, "SYSTEM TYPE:"
XY_STR_HARD_DIPS:		XY_STRING  4, 20, "HARD DIPS 12345678"
STR_CD1:			STRING "/CD1"
STR_CD2:			STRING "/CD2"
STR_CARD_DETECTED:		STRING "(CARD DETECTED)"
STR_CARD_EMPTY:			STRING "(CARD SLOT EMPTY)"
STR_WP:				STRING "/WP"
STR_CARD_WP_OFF:		STRING "(CARD WP OFF)"
STR_CARD_WP_ON:			STRING "(CARD WP ON)"
STR_TYPE:			STRING "TYPE"
STR_TYPE_AES:			STRING "(SYSTEM IS AES)"
STR_TYPE_MVS:			STRING "(SYSTEM IS MVS)"
STR_CFG_A:			STRING "CFG-A"
STR_CFG_A_LOW:			STRING "(CFG-A LOW)"
STR_CFG_A_HIGH:			STRING "(CFG-A HIGH)"
STR_CFG_B:			STRING "CFG-B"
STR_CFG_B_LOW:			STRING "(CFG-B LOW)"
STR_CFG_B_HIGH:			STRING "(CFG-B HIGH)"
