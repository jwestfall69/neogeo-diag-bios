	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"
	include "../common/error_codes.inc"
	include "../common/comm.inc"

	global _start
	global manual_tests

	global d_xys_a_to_resume
	global d_xys_d_main_menu
	global d_xys_address
	global d_xys_actual
	global d_xys_expected
	global d_xys_passes

	global r_main_menu_cursor

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
		move.l	#$07770000, PALETTE_RAM_START+PALETTE_SIZE+$2	;  gray on black for text (disabled menu items)
		clr.w	PALETTE_REFERENCE
		clr.w	PALETTE_BACKDROP

		SSA3	fix_clear

		moveq	#-$10, d0
		and.b	REG_P1CNT, d0			; check for A+B+C+D being pressed, if not auto_tests

		bne	auto_tests

		movea.l	$0, a7				; re-init SP
		moveq	#DSUB_INIT_REAL, d7		; init dsub for real subroutines
		clr.b	r_main_menu_cursor
		bra	manual_tests

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

		btst	#7, REG_P1CNT			; if P1 "D" was pressed at boot
		beq	.z80_test_enabled

	ifnd force_z80_tests
		bne	.skip_z80_test			; skip Z80 tests if "D" not pressed
 	endif

	.z80_test_enabled:

		bset.b	#Z80_TEST_FLAG_ENABLED, r_z80_test_flags

		cmp.b	REG_SOUND, d1
		beq	.skip_slot_switch		; skip slot switch if auto-detected m1

		tst.b	REG_STATUS_B
		bpl	.skip_slot_switch		; skip slot switch if AES

		btst	#5, REG_P1CNT
		beq	.skip_slot_switch		; skip slot switch if P1 "B" is pressed

		btst	#6, REG_P1CNT			; if P1 "C", add flag to bypass SM1 OE/CRC tests
		bne	.do_slot_switch

		bset.b	#Z80_TEST_FLAG_SKIP_SM1_TESTS, r_z80_test_flags

	.do_slot_switch:

		bsr	z80_slot_switch

	.skip_slot_switch:

		lea	d_xys_z80_waiting, a0
		RSUB	print_xy_string_struct_clear
		bsr	auto_z80_tests

	.skip_z80_test:

		bsr	auto_func_tests
		lea	d_xys_all_tests_passed, a0
		RSUB	print_xy_string_struct_clear

		lea	d_xys_abcd_main_menu, a0
		RSUB	print_xy_string_struct_clear

		tst.b	r_z80_test_flags

		bne	.loop_user_input

		lea	d_xys_z80_tests_skipped, a0
		RSUB	print_xy_string_struct_clear

		lea	d_xys_z80_hold_d_and_soft, a0
		RSUB	print_xy_string_struct_clear

		lea	d_xys_z80_reset_with_cart, a0
		RSUB	print_xy_string_struct_clear

	.loop_user_input:
		WATCHDOG
		bsr	check_reset_request

		moveq	#-$10, d0
		and.b	REG_P1CNT, d0		; ABCD pressed?
		bne	.loop_user_input

		movea.l	$0, a7			; re-init SP
		moveq	#DSUB_INIT_REAL, d7	; init dsub for real subroutines
		clr.b	r_main_menu_cursor
		SSA3	fix_clear
		bra	manual_tests

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

manual_tests:
		bsr	main_menu_draw
		bsr	main_menu_loop
		bra	manual_tests

main_menu_draw:
		RSUB	print_header
		lea	MAIN_MENU_ITEMS_START, a1
		moveq	#((MAIN_MENU_ITEMS_END - MAIN_MENU_ITEMS_START) / 10 - 1), d4
		moveq	#5, d5					; row to start drawing menu items at

	.loop_next_entry:
		movea.l	(a1)+, a0
		addq.l	#4, a1
		moveq	#0, d2
		move.w	(a1)+, d0
		cmp	#0, d0
		beq	.print_entry				; if flags == 0, print entry on both systems (mvs/aes)

		tst.b	REG_STATUS_B
		bpl	.system_aes

		cmp.w	#1, d0
		beq	.print_entry
		moveq	#$10, d2				; if flag is not 1, adjust palette
		bra	.print_entry

	.system_aes:
		cmp.w	#2, d0
		beq	.print_entry
		moveq	#$10, d2					; if flag is not 2, adjust palette

	.print_entry:
		moveq	#6, d0
		move.b	d5, d1
		jsr	print_xyp_string
		addq.b	#1, d3
		addq.b	#1, d5
		dbra	d4, .loop_next_entry
		bsr	print_hold_ss_to_reset
		rts

main_menu_loop:
		moveq	#-$10, d0
		bsr	wait_p1_input
		bsr	wait_frame

	.loop_run_menu:

		bsr	check_reset_request
		bsr	p1p2_input_update

		moveq	#4, d0
		moveq	#5, d1
		add.b	r_main_menu_cursor, d1
		moveq	#$11, d2
		RSUB	print_xy_char				; draw arrow

		move.b	r_main_menu_cursor, d1
		move.b	r_p1_input_edge, d0
		btst	#UP, d0					; see if p1 up pressed
		beq	.up_not_pressed

		subq.b	#1, d1
		bpl	.update_arrow
		moveq	#((MAIN_MENU_ITEMS_END - MAIN_MENU_ITEMS_START) / 10) - 1, d1
		bra	.update_arrow

	.up_not_pressed:					; up wasnt pressed, see if down was
		btst	#DOWN, d0
		beq	.check_a_pressed			; down not pressed either, see if 'a' is pressed

		addq.b	#1, d1
		cmp.b	#((MAIN_MENU_ITEMS_END - MAIN_MENU_ITEMS_START) / 10), d1
		bne	.update_arrow
		moveq	#0, d1

	.update_arrow:						; up or down was pressed, update the arrow location
		move.w	d1, -(a7)
		moveq	#4, d0
		moveq	#5, d1
		add.b	r_main_menu_cursor, d1
		move.b	(1,a7), r_main_menu_cursor
		moveq	#$20, d2
		RSUB	print_xy_char				; replace existing arrow with space

		moveq	#4, d0
		moveq	#5, d1
		add.w	(a7)+, d1
		moveq	#$11, d2
		RSUB	print_xy_char				; draw arrow at new location

	.check_a_pressed:
		btst	#A_BUTTON, r_p1_input_edge		; 'a' pressed?
		bne	.a_pressed
		bsr	wait_frame
		bra	.loop_run_menu

	.a_pressed:						; 'a' was pressed, do stuff
		clr.w	d0
		move.b	r_main_menu_cursor, d0
		mulu.w	#$a, d0					; find the offset within the main_menu_items array
		lea	(MAIN_MENU_ITEMS_START,PC,d0.w), a1

		moveq	#1, d0					; setup d0 to contain 1 for AES, 2 for MVS
		tst.b	REG_STATUS_B
		bpl	.system_aes
		moveq	#2, d0

	.system_aes:
		cmp.w	($8,a1), d0
		beq	.loop_run_menu				; flags saw its not valid for this system, ignore and loop again

		SSA3	fix_clear

		movea.l	(a1)+, a0
		moveq	#4, d0
		moveq	#5, d1
		RSUB	print_xy_string

		movea.l	(a1), a0
		jsr	(a0)					; call the test function
		SSA3	fix_clear
		rts

; array of main menu items
; struct {
;  long string_address,
;  long function_address,
;  word flags,  // 0 = valid for both, 1 = aes disabled, 2 = mvs disable
; }
MAIN_MENU_ITEMS_START:
	MAIN_MENU_ITEM d_str_calendar_io, manual_calendar_tests, 1
	MAIN_MENU_ITEM d_str_color_bars_basic, manual_color_bars_basic_test, 0
	MAIN_MENU_ITEM d_str_color_bars_smpte, manual_color_bars_smpte_test, 0
	MAIN_MENU_ITEM d_str_video_dac_tests, manual_video_dac_tests, 0
	MAIN_MENU_ITEM d_str_controller_tests, manual_controller_tests, 0
	MAIN_MENU_ITEM d_str_work_ram_test_loop, manual_work_ram_tests, 0
	MAIN_MENU_ITEM d_str_backup_ram_test_loop, manual_backup_ram_tests, 1
	MAIN_MENU_ITEM d_str_pal_ram_test_loop, manual_palette_ram_tests, 0
	MAIN_MENU_ITEM d_str_vram_test_loop_32k, manual_video_ram_32k_tests, 0
	MAIN_MENU_ITEM d_str_vram_test_loop_2k, manual_video_ram_2k_tests, 0
	MAIN_MENU_ITEM d_str_misc_input_test, manual_misc_input_tests, 0
	MAIN_MENU_ITEM d_str_cpu_pal_addr_test, manual_cpu_pal_addr_test, 0
	MAIN_MENU_ITEM d_str_memcard_tests, manual_memcard_tests, 0
	MAIN_MENU_ITEM d_str_p_rom_bus_tests, manual_p_rom_bus_tests, 0
MAIN_MENU_ITEMS_END:

	section data

d_str_version_header:		STRING "NEO DIAGNOSTICS v0.19a03 - SMKDAN/ACK"

d_xys_a_to_resume:		XY_STRING  4, 26, "A: Release to Resume"
d_xys_d_main_menu:		XY_STRING  4, 27, "D: Return to menu"

d_xys_address:			XY_STRING  4,  8, "ADDRESS:"
d_xys_actual:			XY_STRING  4, 10, "ACTUAL:"
d_xys_expected:			XY_STRING  4, 12, "EXPECTED:"
d_xys_passes:			XY_STRING  4, 14, "PASSES:"

d_xys_all_tests_passed:		XY_STRING  4,  5, "ALL TESTS PASSED"
d_xys_abcd_main_menu:		XY_STRING  4, 21, "PRESS ABCD FOR MAIN MENU"

d_xys_z80_waiting:		XY_STRING  4,  5, "WAITING FOR Z80 TO FINISH TESTS..."
d_xys_z80_tests_skipped:	XY_STRING  4, 23, "NOTE: Z80 TESTING WAS SKIPPED. TO"
d_xys_z80_hold_d_and_soft:	XY_STRING  4, 24, "TEST Z80, HOLD BUTTON D AND SOFT"
d_xys_z80_reset_with_cart:	XY_STRING  4, 25, "RESET WITH TEST CART INSERTED."

	section bss
	align 2

r_main_menu_cursor:		dc.b $0
