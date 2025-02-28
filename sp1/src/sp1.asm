	include "neogeo.inc"
	include "macros.inc"
	include "diag.inc"
	include "../common/include/error_codes.inc"
	include "../common/include/comm.inc"

	global _start
	global print_header_dsub

	global d_xys_a_to_resume
	global d_xys_d_main_menu
	global d_xys_address
	global d_xys_actual
	global d_xys_expected
	global d_xys_passes

	section code

;force_z80_tests 	equ 1

; start
_start:
		WATCHDOG
		clr.b	REG_POUTPUT
		clr.b	r_p1_input
		clr.b	r_p1_input_edge
		clr.b	r_p1_input_aux
		clr.b	r_p1_input_aux_edge
		move.w	#7, REG_IRQACK
		move.w	#$4000, REG_LSPCMODE
		lea	REG_VRAMRW, a6					; a6 will always be REG_VRAMRW
		moveq	#DSUB_INIT_PSEUDO, d7				; init dsub for pseudo subroutines
		move.l	#$7fff0000, PALETTE_RAM_START+$2		; white on black for text
		move.l	#$07770000, PALETTE_RAM_START+PALETTE_SIZE+$2	; gray on black for text (disabled menu items)
		clr.w	PALETTE_REFERENCE
		clr.w	PALETTE_BACKDROP

		SSA3	fix_clear

		move.b	#(INPUT_A|INPUT_B|INPUT_C|INPUT_D), d0
		and.b	REG_P1CNT, d0			; check for A+B+C+D being pressed, if not auto_tests
		bne	auto_tests

		movea.l	$0, a7				; re-init SP
		moveq	#DSUB_INIT_REAL, d7		; init dsub for real subroutines
		clr.b	r_menu_cursor
		bra	main_menu

auto_tests:
		PSUB	print_header
		PSUB	watchdog_stuck_test
		PSUB	auto_psub_tests

		movea.l	$0, a7				; re-init SP
		moveq	#DSUB_INIT_REAL, d7		; init dsub for real subroutines

		clr.b	r_z80_test_flags

		; auto-detect m1 by checking for the HELLO message (ie diag m1 + AES or MV-1B/C)
		move.b	#COMM_TEST_HELLO, d1
		cmp.b	REG_SOUND, d1
		beq	.z80_test_enabled

		btst	#INPUT_D_BIT, REG_P1CNT		; if P1 "D" was pressed at boot
		beq	.z80_test_enabled

	ifnd force_z80_tests
		bne	.skip_z80_test			; skip Z80 tests if "D" not pressed
 	endif

	.z80_test_enabled:

		bset.b	#Z80_TEST_FLAG_ENABLED, r_z80_test_flags

		cmp.b	REG_SOUND, d1			; skip slot switch if auto-detected m1
		beq	.skip_slot_switch

		tst.b	REG_STATUS_B			; skip slot switch if AES
		bpl	.skip_slot_switch

		btst	#INPUT_B_BIT, REG_P1CNT		; skip slot switch if P1 "B" is pressed
		beq	.skip_slot_switch

		btst	#INPUT_C_BIT, REG_P1CNT		; if P1 "C", add flag to bypass SM1 OE/CRC tests
		bne	.do_slot_switch

		bset.b	#Z80_TEST_FLAG_SKIP_SM1_TESTS, r_z80_test_flags

	.do_slot_switch:

		bsr	z80_slot_switch

	.skip_slot_switch:

		lea	d_xys_z80_waiting, a0
		RSUB	print_xys_string_clear
		bsr	auto_z80_tests

	.skip_z80_test:

		bsr	auto_func_tests
		lea	d_xys_all_tests_passed_list, a0
		RSUB	print_xys_string_clear_list

		tst.b	r_z80_test_flags
		bne	.loop_user_input

		lea	d_xys_z80_tests_skipped_list, a0
		RSUB	print_xys_string_clear_list

	.loop_user_input:
		WATCHDOG
		bsr	check_reset_request

		move.b	#(INPUT_A|INPUT_B|INPUT_C|INPUT_D), d0
		and.b	REG_P1CNT, d0		; ABCD pressed?
		bne	.loop_user_input

		movea.l	$0, a7			; re-init SP
		moveq	#DSUB_INIT_REAL, d7	; init dsub for real subroutines
		clr.b	r_menu_cursor
		SSA3	fix_clear
		bra	main_menu

; prints headers
; NEO DIAGNOSTICS v0.19aXX - SMKDAN/ACK
; ---------------------------------
print_header_dsub:
		moveq	#0, d0
		moveq	#4, d1
		moveq	#1, d2
		moveq	#$16, d3
		moveq	#40, d4
		DSUB	print_char_repeat			; $116 which is an overscore line

		moveq	#2, d0
		moveq	#3, d1
		lea	d_str_version_header, a0
		DSUB	print_xy_string_clear
		DSUB_RETURN

	section data
	align 1

d_str_version_header:		STRING "NEO DIAGNOSTICS v0.19a03 - SMKDAN/ACK"

d_xys_a_to_resume:		XY_STRING LEFT_MARGIN, 26, "A: Release to Resume"
d_xys_d_main_menu:		XY_STRING LEFT_MARGIN, 27, "D: Return to menu"

d_xys_address:			XY_STRING LEFT_MARGIN,  8, "ADDRESS:"
d_xys_actual:			XY_STRING LEFT_MARGIN, 10, "ACTUAL:"
d_xys_expected:			XY_STRING LEFT_MARGIN, 12, "EXPECTED:"
d_xys_passes:			XY_STRING LEFT_MARGIN, 14, "PASSES:"

d_xys_z80_waiting:		XY_STRING LEFT_MARGIN,  5, "WAITING FOR Z80 TO FINISH TESTS..."

d_xys_all_tests_passed_list:
	XY_STRING LEFT_MARGIN,  5, "ALL TESTS PASSED"
	XY_STRING LEFT_MARGIN, 21, "PRESS ABCD FOR MAIN MENU"
	XY_STRING LEFT_MARGIN, 27, "HOLD START/SELECT TO SOFT RESET"
	XY_STRING_LIST_END

d_xys_z80_tests_skipped_list:
	XY_STRING LEFT_MARGIN, 23, "NOTE: Z80 TESTING WAS SKIPPED. TO"
	XY_STRING LEFT_MARGIN, 24, "TEST Z80, HOLD BUTTON D AND SOFT"
	XY_STRING LEFT_MARGIN, 25, "RESET WITH TEST CART INSERTED."
	XY_STRING_LIST_END
