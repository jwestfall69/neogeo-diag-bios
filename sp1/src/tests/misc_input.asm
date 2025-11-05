	include "neogeo.inc"
	include "macros.inc"
	include "diag.inc"

	global misc_input_tests

	section code

misc_input_tests:
		lea	d_xys_d_main_menu, a0
		RSUB	print_xys_string_clear
		bsr	misc_input_print_static
	.loop_run_test:
		bsr	p1p2_input_update
		bsr	misc_input_update_dynamic
		bsr	wait_frame
		btst	#INPUT_D_BIT, r_p1_input_edge
		beq	.loop_run_test			; if d pressed, exit test
		rts

misc_input_print_static:
		lea	d_xys_memory_card, a0
		RSUB	print_xys_string_clear

		lea	d_mi_item_cd1, a0
		moveq	#$9, d0
		moveq	#$3, d1
		bsr	misc_input_print_static_items

		lea	d_xys_system_type, a0
		RSUB	print_xys_string_clear

		lea	d_mi_item_type, a0
		moveq	#$e, d0
		moveq	#$1, d1
		bsr	misc_input_print_static_items

		tst.b	REG_STATUS_B
		bpl	.system_aes

		lea	d_mi_item_cfg_a, a0
		moveq	#$f, d0
		moveq	#$2, d1
		bsr	misc_input_print_static_items

		lea	d_xys_hard_dips, a0
		RSUB	print_xys_string_clear

	.system_aes:
		rts


misc_input_update_dynamic:
		lea	d_mi_item_cd1,a0
		moveq	#$9, d0
		moveq	#$3, d1
		bsr	misc_input_print_dynamic_items

		lea	d_mi_item_type, a0
		moveq	#$e, d0
		moveq	#$1, d1
		bsr	misc_input_print_dynamic_items

		tst.b	REG_STATUS_B
		bpl	.system_aes

		lea	d_mi_item_cfg_a, a0
		moveq	#$f, d0
		moveq	#$2, d1
		bsr	misc_input_print_dynamic_items

		lea	d_xys_system_config_as, a0
		RSUB	print_xys_string

		bsr	get_slot_count
		move.b	d0, d2
		moveq	#$1b, d0
		moveq	#$12, d1
		RSUB	print_digit

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

	section data
	align 1

; struct misc_input {
;  byte test_bit;                ; bit to test on mmio address
;  byte mmio_address[3];         ; minus top byte
;  long bit_name_string_address;
;  long bit_disabled_string_address;
;  long bit_enabled_string_address;
;}
d_mi_item_cd1:			MISC_INPUT_ITEM $04, $38, $00, $00, d_str_cd1, d_str_card_detected, d_str_card_empty
d_mi_item_cd2:			MISC_INPUT_ITEM $05, $38, $00, $00, d_str_cd2, d_str_card_detected, d_str_card_empty
d_mi_item_wp:			MISC_INPUT_ITEM $06, $38, $00, $00, d_str_wp, d_str_card_wp_off, d_str_card_wp_on
d_mi_item_type:			MISC_INPUT_ITEM $07, $38, $00, $00, d_str_type, d_str_type_aes, d_str_type_mvs
d_mi_item_cfg_a:		MISC_INPUT_ITEM $05, $32, $00, $01, d_str_cfg_a, d_str_cfg_a_low, d_str_cfg_a_high
d_mi_item_cfg_b:		MISC_INPUT_ITEM $06, $30, $00, $81, d_str_cfg_b, d_str_cfg_b_low, d_str_cfg_b_high

d_str_cd1:			STRING "/CD1"
d_str_cd2:			STRING "/CD2"
d_str_card_detected:		STRING "(CARD DETECTED)"
d_str_card_empty:		STRING "(CARD SLOT EMPTY)"
d_str_wp:			STRING "/WP"
d_str_card_wp_off:		STRING "(CARD WP OFF)"
d_str_card_wp_on:		STRING "(CARD WP ON)"
d_str_type:			STRING "TYPE"
d_str_type_aes:			STRING "(SYSTEM IS AES)"
d_str_type_mvs:			STRING "(SYSTEM IS MVS)"
d_str_cfg_a:			STRING "CFG-A"
d_str_cfg_a_low:		STRING "(CFG-A LOW)"
d_str_cfg_a_high:		STRING "(CFG-A HIGH)"
d_str_cfg_b:			STRING "CFG-B"
d_str_cfg_b_low:		STRING "(CFG-B LOW)"
d_str_cfg_b_high:		STRING "(CFG-B HIGH)"

d_xys_system_config_as:		XY_STRING LEFT_MARGIN, 18, "SYSTEM CONFIGURED AS A   SLOT"
d_xys_memory_card:		XY_STRING LEFT_MARGIN,  8, "MEMORY CARD:"
d_xys_system_type:		XY_STRING LEFT_MARGIN, 13, "SYSTEM TYPE:"
d_xys_hard_dips:		XY_STRING LEFT_MARGIN, 20, "HARD DIPS 12345678"
