	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"
	include "../common/error_codes.inc"
	include "../common/comm.inc"

	global _start
	global error_to_credit_leds_dsub
	global manual_tests
	global timer_interrupt
	global vblank_interrupt
	global STR_ACTUAL
	global STR_ADDRESS
	global STR_EXPECTED
	global STR_HOLD_ABCD_TO_STOP
	global XY_STR_D_MAIN_MENU
	global XY_STR_PASSES

	section	text

	; These are options to force the bios to do
	; z80 or goto manual tests since its not
	; practical to be holding down buttons on boot
	; with mame.

;force_z80_tests 	equ 1
;force_manual_tests 	equ 1

; start
_start:
	WATCHDOG
	clr.b	REG_POUTPUT
	clr.b	p1_input
	clr.b	p1_input_edge
	clr.b	p1_input_aux
	clr.b	p1_input_aux_edge
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
	and.b	REG_P1CNT, d0			; check for A+B+C+D being pressed, if not automatic_tests

	ifnd force_manual_tests
		bne	automatic_tests
	endif

	movea.l	$0, a7				; re-init SP
	moveq	#DSUB_INIT_REAL, d7		; init dsub for real subroutines
	clr.b	main_menu_cursor
	bra	manual_tests

automatic_tests:
	PSUB	print_header
	PSUB	watchdog_stuck_test
	PSUB	automatic_psub_tests

	movea.l	$0, a7				; re-init SP
	moveq	#DSUB_INIT_REAL, d7		; init dsub for real subroutines

	clr.b	z80_test_flags

	btst	#7, REG_P1CNT			; if P1 "D" was pressed at boot
	beq	.z80_test_enabled

	; auto-detect m1 by checking for the HELLO message (ie diag m1 + AES or MV-1B/C)
	move.b	#COMM_TEST_HELLO, d1
	cmp.b	REG_SOUND, d1
	beq	.z80_test_enabled

 	ifnd force_z80_tests
		bne	.skip_z80_test		; skip Z80 tests if "D" not pressed
 	endif

.z80_test_enabled:

	bset.b	#Z80_TEST_FLAG_ENABLED, z80_test_flags

	cmp.b	REG_SOUND, d1
	beq	.skip_slot_switch		; skip slot switch if auto-detected m1

	tst.b	REG_STATUS_B
	bpl	.skip_slot_switch		; skip slot switch if AES

	btst	#5, REG_P1CNT
	beq	.skip_slot_switch		; skip slot switch if P1 "B" is pressed

	bsr	z80_slot_switch

.skip_slot_switch:

	lea	XY_STR_Z80_WAITING, a0
	RSUB	print_xy_string_struct_clear
	bsr	auto_z80_tests

.skip_z80_test:

	bsr	automatic_function_tests
	lea	XY_STR_ALL_TESTS_PASSED, a0
	RSUB	print_xy_string_struct_clear

	lea	XY_STR_ABCD_MAIN_MENU, a0
	RSUB	print_xy_string_struct_clear

	tst.b	z80_test_flags

	bne	.loop_user_input

	lea	XY_STR_Z80_TESTS_SKIPPED, a0
	RSUB	print_xy_string_struct_clear

	lea	XY_STR_Z80_HOLD_D_AND_SOFT, a0
	RSUB	print_xy_string_struct_clear

	lea	XY_STR_Z80_RESET_WITH_CART, a0
	RSUB	print_xy_string_struct_clear

.loop_user_input
	WATCHDOG
	bsr	check_reset_request

	moveq	#-$10, d0
	and.b	REG_P1CNT, d0		; ABCD pressed?
	bne	.loop_user_input

	movea.l	$0, a7			; re-init SP
	moveq	#DSUB_INIT_REAL, d7	; init dsub for real subroutines
	clr.b	main_menu_cursor
	SSA3	fix_clear
	bra	manual_tests

; runs automatic tests that are psub based
automatic_psub_tests_dsub:
	moveq	#0, d6
.loop_next_test:
	movea.l	(AUTOMATIC_PSUB_TEST_STRUCT_START+4,pc,d6.w),a0
	moveq	#4, d0
	moveq	#5, d1
	DSUB	print_xy_string_clear			; print the test description to screen

	movea.l	(AUTOMATIC_PSUB_TEST_STRUCT_START,pc,d6.w), a2
	lea	(.dsub_return), a3			; manually do dsub call since the DSUB macro wont
	bra	dsub_enter				; work in this case
.dsub_return

	tst.b	d0					; check result
	beq	.test_passed

	move.b	d0, d6
	DSUB	print_error
	move.b	d6, d0

	tst.b	REG_STATUS_B
	bpl	.skip_error_to_credit_leds	; skip if aes
	move.b	d6, d0
	DSUB	error_to_credit_leds

.skip_error_to_credit_leds
	bra	loop_reset_check_dsub

.test_passed:
	addq.w	#8, d6
	cmp.w	#(AUTOMATIC_PSUB_TEST_STRUCT_END - AUTOMATIC_PSUB_TEST_STRUCT_START), d6
	bne	.loop_next_test
	DSUB_RETURN


AUTOMATIC_PSUB_TEST_STRUCT_START:
	dc.l	auto_bios_mirror_test_dsub, STR_TESTING_BIOS_MIRROR
	dc.l	auto_bios_crc32_test_dsub, STR_TESTING_BIOS_CRC32
	dc.l	auto_work_ram_oe_tests_dsub, STR_TESTING_WORK_RAM_OE
	dc.l	auto_work_ram_we_tests_dsub, STR_TESTING_WORK_RAM_WE
	dc.l	auto_work_ram_data_tests_dsub, STR_TESTING_WORK_RAM_DATA
	dc.l	auto_work_ram_address_tests_dsub, STR_TESTING_WORK_RAM_ADDRESS
AUTOMATIC_PSUB_TEST_STRUCT_END:


; runs automatic tests that are subroutine based;
automatic_function_tests:
	lea	AUTOMATIC_FUNC_TEST_STRUCT_START, a5
	moveq	#((AUTOMATIC_FUNC_TEST_STRUCT_END - AUTOMATIC_FUNC_TEST_STRUCT_START)/8 - 1), d6

.loop_next_test:
	movea.l	(a5)+, a4			; test function address
	movea.l	(a5)+, a0			; test name string address
	movea.l	a0, a0
	moveq	#4, d0
	moveq	#5, d1
	RSUB	print_xy_string_clear		; at 4,5 print test name

	move.l	a5, -(a7)
	move.w	d6, -(a7)
	jsr	(a4)				; run function
	move.w	(a7)+, d6
	movea.l	(a7)+, a5

	tst.b	d0				; check result
	beq	.test_passed

	move.w	d0, -(a7)
	RSUB	print_error
	move.w	(a7)+, d0

	tst.b	z80_test_flags			; if z80 test enabled, send error code to z80
	beq	.skip_error_to_z80
	move.b	d0, REG_SOUND

.skip_error_to_z80:
	tst.b	REG_STATUS_B
	bpl	.skip_error_to_credit_leds	; skip if aes
	RSUB	error_to_credit_leds

.skip_error_to_credit_leds
	bra	loop_reset_check

.test_passed:
	dbra	d6, .loop_next_test
	rts


AUTOMATIC_FUNC_TEST_STRUCT_START:
	dc.l	auto_backup_ram_tests, STR_TESTING_BACKUP_RAM
	dc.l	auto_palette_ram_tests, STR_TESTING_PALETTE_RAM
	dc.l	auto_video_ram_2k_tests, STR_TESTING_VIDEO_RAM_2K
	dc.l	auto_video_ram_32k_tests, STR_TESTING_VIDEO_RAM_32K
	dc.l	auto_mmio_tests, STR_TESTING_MMIO
AUTOMATIC_FUNC_TEST_STRUCT_END:




; prints headers
; NEO DIAGNOSTICS v0.19aXX - BY SMKDAN
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
	lea	STR_VERSION_HEADER, a0
	DSUB	print_xy_string_clear
	DSUB_RETURN

; Display the error code on player1/2 credit leds.  Player 1 led contains
; the upper 2 digits, and player 2 the lower 2 digits.  The neogeo
; doesn't seem to allow having the left digit as 0 and instead it
; will be empty
;
; Examples:
; EC_VRAM_2K_DEAD_OUTPUT_LOWER = 0x6a = 106
; Led: p1:  1, p2:  6
;
; EC_WRAM_UNWRITABLE_LOWER = 0x70 = 112
; Led: p1:  1, p2: 12
;
; EC_Z80_RAM_DATA_00 = 0x04 = 4
; Led: p1:  0, p2:  4
;
; params:
;  d0 = error code
error_to_credit_leds_dsub:
	moveq	#3, d2
	moveq	#0, d3
	moveq	#0, d4

; convert error code to bcd
.loop_next_digit:
	divu.w	#10, d0
	swap	d0
	move.b	d0, d3
	and.l	d3, d3
	or.w	d3, d4
	clr.w	d0
	swap	d0
	ror.w	#4, d4
	dbra	d2, .loop_next_digit

	not.w	d4				; inverted per dev wiki

	; player 2 led
	move.b	#LED_NO_LATCH, REG_LEDLATCHES
	move.w	#$10, d0
	DSUB	delay				; 40us

	move.b	d4, REG_LEDDATA

	move.b	#LED_P2_LATCH, REG_LEDLATCHES
	move.w	#$10, d0
	DSUB	delay

	move.b	#LED_NO_LATCH, REG_LEDLATCHES
	move.w	#$10, d0
	DSUB	delay

	; player 1 led
	lsr.w	#8, d4
	move.b	d4, REG_LEDDATA

	move.b	#LED_P1_LATCH, REG_LEDLATCHES
	move.w	#$10, d0
	DSUB	delay

	move.b	#LED_P1_LATCH, REG_LEDLATCHES

	DSUB_RETURN


manual_tests:
.loop_forever:
	bsr	main_menu_draw
	bsr	main_menu_loop
	bra	.loop_forever


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
	add.b	main_menu_cursor, d1
	moveq	#$11, d2
	RSUB	print_xy_char				; draw arrow

	move.b	main_menu_cursor, d1
	move.b	p1_input_edge, d0
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
	add.b	main_menu_cursor, d1
	move.b	(1,a7), main_menu_cursor
	moveq	#$20, d2
	RSUB	print_xy_char				; replace existing arrow with space

	moveq	#4, d0
	moveq	#5, d1
	add.w	(a7)+, d1
	moveq	#$11, d2
	RSUB	print_xy_char				; draw arrow at new location

.check_a_pressed:
	btst	#A_BUTTON, p1_input_edge		; 'a' pressed?
	bne	.a_pressed
	bsr	wait_frame
	bra	.loop_run_menu

.a_pressed:						; 'a' was pressed, do stuff
	clr.w	d0
	move.b	main_menu_cursor, d0
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
	MAIN_MENU_ITEM STR_CALENDAR_IO, manual_calendar_tests, 1
	MAIN_MENU_ITEM STR_COLOR_BARS_BASIC, manual_color_bars_basic_test, 0
	MAIN_MENU_ITEM STR_COLOR_BARS_SMPTE, manual_color_bars_smpte_test, 0
	MAIN_MENU_ITEM STR_VIDEO_DAC_TESTS, manual_video_dac_tests, 0
	MAIN_MENU_ITEM STR_CONTROLLER_TESTS, manual_controller_tests, 0
	MAIN_MENU_ITEM STR_WORK_RAM_TEST_LOOP, manual_work_ram_tests, 0
	MAIN_MENU_ITEM STR_BACKUP_RAM_TEST_LOOP, manual_backup_ram_tests, 1
	MAIN_MENU_ITEM STR_PAL_RAM_TEST_LOOP, manual_palette_ram_tests, 0
	MAIN_MENU_ITEM STR_VRAM_TEST_LOOP_32K, manual_video_ram_32k_tests, 0
	MAIN_MENU_ITEM STR_VRAM_TEST_LOOP_2K, manual_video_ram_2k_tests, 0
	MAIN_MENU_ITEM STR_MISC_INPUT_TEST, manual_misc_input_tests, 0
	MAIN_MENU_ITEM STR_MEMCARD_TESTS, manual_memcard_tests, 0
MAIN_MENU_ITEMS_END:


vblank_interrupt:
	WATCHDOG
	move.w	#$4, REG_IRQACK
	tst.b	$100000.l		; this seems like dead code since nothing
	beq	.exit_interrupt		; else touches $10000(0|2) as a variable..
	movem.l	d0-d7/a0-a6, -(a7)
	addq.w	#1, $100002.l
	movem.l	(a7)+, d0-d7/a0-a6
	clr.b	$100000.l
.exit_interrupt:
	rte

timer_interrupt:
	addq.w	#$1, timer_count
	move.w	#$2, ($a,a6)		; ack int
	rte

STR_ACTUAL:			STRING "ACTUAL:"
STR_EXPECTED:			STRING "EXPECTED:"
STR_ADDRESS:			STRING "ADDRESS:"
STR_COLON_SPACE:		STRING ": "
STR_HOLD_ABCD_TO_STOP:		STRING "HOLD ABCD TO STOP"
STR_VERSION_HEADER:		STRING "NEO DIAGNOSTICS v0.19a00 - BY SMKDAN"
XY_STR_D_MAIN_MENU:		XY_STRING  4, 27, "D: Return to menu"

XY_STR_PASSES:			XY_STRING  4, 14, "PASSES:"
XY_STR_Z80_WAITING:		XY_STRING  4,  5, "WAITING FOR Z80 TO FINISH TESTS..."
XY_STR_ALL_TESTS_PASSED:	XY_STRING  4,  5, "ALL TESTS PASSED"
XY_STR_ABCD_MAIN_MENU:		XY_STRING  4, 21, "PRESS ABCD FOR MAIN MENU"
XY_STR_Z80_TESTS_SKIPPED:	XY_STRING  4, 23, "NOTE: Z80 TESTING WAS SKIPPED. TO"
XY_STR_Z80_HOLD_D_AND_SOFT:	XY_STRING  4, 24, "TEST Z80, HOLD BUTTON D AND SOFT"
XY_STR_Z80_RESET_WITH_CART:	XY_STRING  4, 25, "RESET WITH TEST CART INSERTED."

STR_TESTING_BIOS_MIRROR:	STRING "TESTING BIOS MIRRORING..."
STR_TESTING_BIOS_CRC32:		STRING "TESTING BIOS CRC32..."
STR_TESTING_WORK_RAM_OE:	STRING "TESTING WORK RAM /OE..."
STR_TESTING_WORK_RAM_WE:	STRING "TESTING WORK RAM /WE..."
STR_TESTING_WORK_RAM_DATA:	STRING "TESTING WORK RAM DATA..."
STR_TESTING_WORK_RAM_ADDRESS:	STRING "TESTING WORK RAM ADDRESS..."
STR_TESTING_BACKUP_RAM:		STRING "TESTING BACKUP RAM..."
STR_TESTING_PALETTE_RAM:	STRING "TESTING PALETTE RAM..."
STR_TESTING_VIDEO_RAM_2K:	STRING "TESTING VIDEO RAM (2K)..."
STR_TESTING_VIDEO_RAM_32K:	STRING "TESTING VIDEO RAM (32K)..."
STR_TESTING_MMIO:		STRING "TESTING MMIO..."
