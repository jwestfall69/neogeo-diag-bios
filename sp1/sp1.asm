	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"
	include "../common/error_codes.inc"
	include "../common/comm.inc"

	global _start
	global fix_backup
	global fix_restore
	global p1_input_update
	global loop_reset_check
	global loop_reset_check_dsub
	global manual_tests
	global p1p2_input_update
	global palette_ram_backup
	global palette_ram_restore
	global send_p1p2_controller
	global timer_interrupt
	global vblank_interrupt
	global wait_frame
	global wait_scanline
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


;




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
		bne	skip_z80_test		; skip Z80 tests if "D" not pressed
 	endif

.z80_test_enabled:

	bset.b	#Z80_TEST_FLAG_ENABLED, z80_test_flags

	cmp.b	REG_SOUND, d1
	beq	skip_slot_switch		; skip slot switch if auto-detected m1

	tst.b	REG_STATUS_B
	bpl	skip_slot_switch		; skip slot switch if AES

	btst	#5, REG_P1CNT
	beq	skip_slot_switch		; skip slot switch if P1 "B" is pressed

	bsr	z80_slot_switch

skip_slot_switch:

	bsr	z80_comm_test
	lea	XY_STR_Z80_WAITING, a0
	RSUB	print_xy_string_struct_clear

.loop_try_again:
	WATCHDOG
	bsr	z80_check_error
	bsr	z80_check_sm1_test
	bsr	z80_check_done
	bne	.loop_try_again

skip_z80_test:

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

watchdog_stuck_test_dsub:
	lea	XY_STR_WATCHDOG_DELAY, a0
	DSUB	print_xy_string_struct_clear
	lea	XY_STR_WATCHDOG_TEXT_REMAINS, a0
	DSUB	print_xy_string_struct_clear
	lea	XY_STR_WATCHDOG_STUCK, a0
	DSUB	print_xy_string_struct_clear

	move.l	#$c930, d0		; 128760us / 128.76ms
	DSUB	delay

	moveq	#8, d0
	SSA3	fix_clear_line
	moveq	#10, d0
	SSA3	fix_clear_line
	DSUB_RETURN

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



; swiches to cart M1/S1 roms;
z80_slot_switch:

	bset.b	#Z80_TEST_FLAG_SLOT_SWITCH, z80_test_flags

	lea	XY_STR_Z80_SWITCHING_M1, a0
	RSUB	print_xy_string_struct_clear

	move.b	#$01, REG_SOUND				; tell z80 to prep for m1 switch

	move.l	#$1388, d0				; 12500us / 12.5ms
	RSUB	delay

	cmpi.b	#$01, REG_SOUND
	beq	.z80_slot_switch_ready
	bsr	z80_slot_switch_ignored

.z80_slot_switch_ready:

	move.b	REG_P1CNT, d0
	moveq	#$f, d1
	and.b	d1, d0
	eor.b	d1, d0

	moveq	#((Z80_SLOT_SELECT_END - Z80_SLOT_SELECT_START)/2 - 1), d1
	lea	(Z80_SLOT_SELECT_START - 1), a0

.loop_next_entry:
	addq.l	#1, a0
	cmp.b	(a0)+, d0
	dbeq	d1, .loop_next_entry		; loop through struct looking for p1 input match
	beq	.z80_do_slot_switch

	addq.l	#2, a0				; nothing matched, use the last entry (slot 1)

.z80_do_slot_switch:

	move.b	(a0), d3
	lea	(XY_STR_Z80_SLOT_SWITCH_NUM), a0	; "[SS ]"
	RSUB	print_xy_string_struct

	move.b	#32, d0
	moveq	#4, d1
	moveq	#0, d2
	move.b	d3, d2
	RSUB	print_digit			; print the slot number

	subq	#1, d3				; convert to what REG_SLOT expects, 0 to 5
	move.b	d3, REG_SLOT			; set slot
	move.b	d0, REG_CRTFIX			; switch to carts m1/s1
	move.b	#$3, REG_SOUND			; tell z80 to reset
	rts


; struct {
; 	byte buttons_pressed; 	(up/down/left/right)
;  	byte slot;
; }
Z80_SLOT_SELECT_START:
	dc.b	$01, $02			; up = slot 2
	dc.b	$09, $03			; up+right = slot 3
	dc.b	$08, $04			; right = slot 4
	dc.b	$0a, $05			; down+right = slot 5
	dc.b	$02, $06			; down = slot 6
Z80_SLOT_SELECT_END:
	dc.b	$00, $01			; no match = slot 1


z80_slot_switch_ignored:
	lea	XY_STR_Z80_IGNORED_SM1, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_Z80_SM1_UNRESPONSIVE, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_Z80_MV1BC_HOLD_B, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_Z80_PRESS_START, a0
	RSUB	print_xy_string_struct_clear

	bsr	print_hold_ss_to_reset

.loop_start_not_pressed:
	WATCHDOG
	bsr	check_reset_request
	btst	#0, REG_STATUS_B
	bne	.loop_start_not_pressed		; loop waiting for user to press start or do a reboot request

.loop_start_pressed:
	WATCHDOG
	bsr	check_reset_request
	btst	#0, REG_STATUS_B
	beq	.loop_start_pressed		; loop waiting for user to release start or do a reboot request

	moveq	#27, d0
	SSA3	fix_clear_line
	moveq	#7, d0
	SSA3	fix_clear_line
	moveq	#10, d0
	SSA3	fix_clear_line
	moveq	#12, d0
	SSA3	fix_clear_line
	rts

; params:
;  d0 * 2.5us = how long to delay
delay_dsub:
	move.b	d0, REG_WATCHDOG	; 16 cycles
	subq.l	#1, d0			; 4 cycles
	bne	delay_dsub		; 10 cycles
	DSUB_RETURN

; see if the z80 sent us an error
z80_check_error:
	moveq	#-$40, d0
	and.b	REG_SOUND, d0
	cmp.b	#$40, d0		; 0x40 = flag indicating a z80 error code
	bne	.no_error

	move.b	REG_SOUND, d0		; get the error (again?)
	move.b	d0, d2
	move.l	#$100000, d1
	bsr	z80_ack_error		; ack the error by sending it back, and wait for z80 to ack our ack
	bne	loop_reset_check

	move.b	d2, d0
	and.b	#$3f, d0		; drop the error flag to get the actual error code

	; bypassing the normal print_error call here since the
	; z80 might have sent a corrupt error code which we
	; still want to print with print_error_z80
	move.w	d0, -(a7)
	DSUB	error_code_lookup
	bsr	print_error_z80
	move.w	(a7)+, d0

	tst.b	REG_STATUS_B
	bpl	.skip_error_to_credit_leds	; skip if aes
	RSUB	error_to_credit_leds

.skip_error_to_credit_leds

	bra	loop_reset_check

.no_error:
	rts

z80_check_sm1_test:

	; diag m1 is asking us to swap m1 -> sm1
	move.b	REG_SOUND, d0
	cmp.b	#COMM_SM1_TEST_SWITCH_SM1, d0
	bne	.check_swap_to_m1

	btst	#Z80_TEST_FLAG_SLOT_SWITCH, z80_test_flags		; only allow if we did a slot switch
	bne	.switch_sm1_allow

	move.b  #COMM_SM1_TEST_SWITCH_SM1_DENY, REG_SOUND
	bsr	z80_wait_clear
	rts

.switch_sm1_allow:
	move.b	d0, REG_BRDFIX
	move.b	#COMM_SM1_TEST_SWITCH_SM1_DONE, REG_SOUND

	lea	(XY_STR_Z80_SM1_TESTS), a0		; "[SM1]" to indicate m1 is running sm1 tests
	RSUB	print_xy_string_struct

	bsr	z80_wait_clear
	rts

.check_swap_to_m1:
	; diag m1 asking us to swap sm1 -> m1
	cmp.b	#COMM_SM1_TEST_SWITCH_M1, d0
	bne	.no_swaps

	move.b	d0, REG_CRTFIX
	move.b	#COMM_SM1_TEST_SWITCH_M1_DONE, REG_SOUND

	bsr	z80_wait_clear

.no_swaps:
	rts

; d0 = loop until we stop getting this byte from z80
z80_wait_clear:
	WATCHDOG
	cmp.b	REG_SOUND, d0
	beq	z80_wait_clear
	rts

; see if z80 says its done testing (with no issues)
z80_check_done:
	move.b	#COMM_Z80_TESTS_COMPLETE, d0
	cmp.b	REG_SOUND, d0
	rts

z80_comm_test:

	lea	XY_STR_Z80_M1_ENABLED, a0
	RSUB	print_xy_string_struct

	lea	XY_STR_Z80_TESTING_COMM_PORT, a0
	RSUB	print_xy_string_struct_clear

	move.b	#COMM_TEST_HELLO, d1
	move.w  #500, d2
	bra	.loop_start_wait_hello

; wait up to 5 seconds for hello (10ms * 500 loops)
.loop_wait_hello
	move.w	#4000, d0
	RSUB	delay
.loop_start_wait_hello
	cmp.b	REG_SOUND, d1
	dbeq	d2, .loop_wait_hello
	bne	.z80_hello_timeout

	move.b	#COMM_TEST_HANDSHAKE, REG_SOUND

	moveq	#COMM_TEST_ACK, d1
	move.w	#100, d2
	bra	.loop_start_wait_ack

; Wait up to 1 second for ack response (10ms delay * 100 loops)
; This is kinda long but the z80 has its own loop waiting for a
; Z80_SEND_HANDSHAKE request.  We need our loop to last longer
; so the z80 has a chance to timeout and give us an error,
; otherwise we will just get the last thing to wrote (Z80_RECV_HELLO).
.loop_wait_ack:
	move.w	#4000, d0
	RSUB	delay
.loop_start_wait_ack:
	cmp.b	REG_SOUND, d1
	dbeq	d2, .loop_wait_ack
	bne	.z80_ack_timeout
	rts

.z80_hello_timeout
	lea	XY_STR_Z80_COMM_NO_HELLO, a0
	bra	.print_comm_error

.z80_ack_timeout
	lea	XY_STR_Z80_COMM_NO_ACK, a0

.print_comm_error
	move.b	d1, d0
	bra	z80_print_comm_error



; loop forever checking for reset request;
loop_reset_check:
	bsr	print_hold_ss_to_reset
.loop_forever:
	WATCHDOG
	bsr	check_reset_request
	bra	.loop_forever


; loop forever checking for reset request
loop_reset_check_dsub:
	moveq	#4, d0
	moveq	#27, d1
	lea	STR_HOLD_SS_TO_RESET, a0
	DSUB	print_xy_string_clear

.loop_ss_not_pressed:
	WATCHDOG
	moveq	#3, d0
	and.b	REG_STATUS_B, d0
	bne	.loop_ss_not_pressed		; loop until P1 start+select both held down

	moveq	#4, d0
	moveq	#27, d1
	lea	STR_RELEASE_SS, a0
	DSUB	print_xy_string_clear

.loop_ss_pressed:
	WATCHDOG
	moveq	#3, d0
	and.b	REG_STATUS_B, d0
	cmp.b	#3, d0
	bne	.loop_ss_pressed		; loop until P1 start+select are released

	reset
	stop	#$2700

; check if P1 is pressing start+select, if they are loop until
; they release and reset, else just return
check_reset_request:
	move.w	d0, -(a7)
	moveq	#3, d0
	and.b	REG_STATUS_B, d0

	bne	.ss_not_pressed			; P1 start+select not pressed, exit out

	moveq	#4, d0
	moveq	#27, d1
	lea	STR_RELEASE_SS, a0
	RSUB	print_xy_string_clear

.loop_ss_pressed:
	WATCHDOG
	moveq	#3, d0
	and.b	REG_STATUS_B, d0
	cmp.b	#3, d0
	bne	.loop_ss_pressed		; wait for P1 start+select to be released, before reset

	reset
	stop	#$2700

.ss_not_pressed:
	move.w	(a7)+, d0
	rts

print_hold_ss_to_reset:
	moveq	#4, d0
	moveq	#27, d1
	lea	STR_HOLD_SS_TO_RESET, a0
	RSUB	print_xy_string_clear
	rts

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

; prints the z80 related communication error
; params:
;  d0 = expected response
;  a0 = xy_string_struct address for main error
z80_print_comm_error:
	move.w	d0, -(a7)

	RSUB	print_xy_string_struct_clear

	moveq	#4, d0
	moveq	#8, d1
	lea	STR_EXPECTED, a0
	RSUB	print_xy_string_clear

	moveq	#4, d0
	moveq	#10, d1
	lea	STR_ACTUAL, a0
	RSUB	print_xy_string_clear

	lea	XY_STR_Z80_SKIP_TEST, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_Z80_PRESS_D_RESET, a0
	RSUB	print_xy_string_struct_clear

	move.w	(a7)+, d2
	moveq	#14, d0
	moveq	#8, d1
	RSUB	print_hex_byte				; expected value

	move.b	REG_SOUND, d2
	moveq	#14, d0
	moveq	#10, d1
	RSUB	print_hex_byte				; actual value

	lea	XY_STR_Z80_MAKE_SURE, a0
	RSUB	print_xy_string_struct_clear

	lea	XY_STR_Z80_CART_CLEAN, a0
	RSUB	print_xy_string_struct_clear

	bsr	z80_check_error
	bra	loop_reset_check

; ack an error sent to us by the z80 by sending
; it back, and then waiting for the z80 to ack
; our ack.
; params:
;  d0 = error code z80 sent us
;  d1 = number of loops waiting for the response
z80_ack_error:
	move.b	d0, REG_SOUND
	not.b	d0			; z80's ack back should be !d0
.loop_try_again:
	WATCHDOG
	cmp.b	REG_SOUND, d0
	beq	.command_success
	subq.l	#1, d1
	bne	.loop_try_again
	moveq	#-1, d0
.command_success:
	rts

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

; backup palette ram to PALETTE_RAM_BACKUP_LOCATION (wram $10001c)
palette_ram_backup:
	movem.l	d0/a0-a1, -(a7)
	lea	PALETTE_RAM_START.l, a0
	lea	PALETTE_RAM_BACKUP_LOCATION.l, a1
	move.w	#$2000, d0
	bsr	copy_memory
	movem.l	(a7)+, d0/a0-a1
	rts

; restore palette ram from PALETTE_RAM_BACKUP_LOCATION (wram $10001c)
palette_ram_restore:
	movem.l	d0/a0-a1, -(a7)
	lea	PALETTE_RAM_BACKUP_LOCATION.l, a0
	lea	PALETTE_RAM_START.l, a1
	move.w	#$2000, d0
	bsr	copy_memory
	movem.l	(a7)+, d0/a0-a1
	rts

; params:
;  a0 = source address
;  a1 = dest address
;  d0 = length
copy_memory:
	swap	d0
	clr.w	d0
	swap	d0
	lea	(-$20,a0,d0.l), a0
	lea	(a1,d0.l), a1
	lsr.w	#5, d0
	subq.w	#1, d0
	movem.l	d1-d7/a2, -(a7)
.loop_next_address:
	movem.l	(a0), d1-d7/a2
	movem.l	d1-d7/a2, -(a1)
	lea	(-$20,a0), a0
	dbra	d0, .loop_next_address
	movem.l	(a7)+, d1-d7/a2

	WATCHDOG
	rts


; params:
;  d0 = inverse byte mask for player1 inputs we care about
wait_p1_input:
	WATCHDOG
	move.b	REG_P1CNT, d1
	and.b	d0, d1
	cmp.b	d0, d1
	bne	wait_p1_input
	bsr	wait_frame
	bsr	wait_frame
	rts

; wait for a full frame
wait_frame:
	move.w	d0, -(a7)

.loop_bottom_border:
	WATCHDOG
	move.w	(4,a6), d0
	and.w	#$ff80, d0
	cmp.w	#$f800, d0
	beq	.loop_bottom_border		; loop until we arent at bottom border

.loop_not_bottom_border:
	WATCHDOG
	move.w	(4,a6), d0
	and.w	#$ff80, d0
	cmp.w	#$f800, d0
	bne	.loop_not_bottom_border		; loop until we see the bottom border

	move.w	(a7)+, d0
	rts

; d0 = scanline to wait for
wait_scanline:
	WATCHDOG
	move.w	(4,a6), d1
	lsr.w	#$7, d1
	cmp.w	d0, d1
	bne	wait_scanline
	rts

p1p2_input_update:
	bsr	p1_input_update
	bra	p2_input_update

p1_input_update:
	move.b	REG_P1CNT, d0
	not.b	d0
	move.b	p1_input, d1
	eor.b	d0, d1
	and.b	d0, d1
	move.b	d1, p1_input_edge
	move.b	d0, p1_input
	move.b	REG_STATUS_B, d0
	not.b	d0
	move.b	p1_input_aux, d1
	eor.b	d0, d1
	and.b	d0, d1
	move.b	d1, p1_input_aux_edge
	move.b	d0, p1_input_aux
	rts

p2_input_update:
	move.b	REG_P2CNT, d0
	not.b	d0
	move.b	p2_input, d1
	eor.b	d0, d1
	and.b	d0, d1
	move.b	d1, p2_input_edge
	move.b	d0, p2_input
	move.b	REG_STATUS_B, d0
	lsr.b	#2, d0
	not.b	d0
	move.b	p2_input_aux, d1
	eor.b	d0, d1
	and.b	d0, d1
	move.b	d1, p2_input_aux_edge
	move.b	d0, p2_input_aux
	rts

; params:
;  d0 = send lower 3 bits to both p1/p2 ports
send_p1p2_controller:
	move.w	d1, -(a7)
	move.b	d0, d1
	lsl.b	#3, d1
	or.b	d1, d0
	move.b	d0, REG_POUTPUT
	move.l	#$1f4, d0		; 1250us / 1.25ms
	RSUB	delay
	move.w	(a7)+, d1
	rts

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

fix_backup:
	movem.l	d0/a0, -(a7)
	lea	FIXMAP_BACKUP_LOCATION.l, a0
	move.w	#FIXMAP, (-2,a6)
	move.w	#1, (2,a6)
	move.w	#$7ff, d0

.loop_next_address:
	nop
	nop
	move.w	(a6), (a0)+
	move.w	d0, (a6)
	dbra	d0, .loop_next_address
	movem.l	(a7)+, d0/a0
	rts

fix_restore:
	movem.l	d0/a0, -(a7)
	lea	FIXMAP_BACKUP_LOCATION.l, a0
	move.w	#FIXMAP, (-2,a6)
	move.w	#1, (2,a6)
	move.w	#$7ff, d0

.loop_next_address:
	move.w	(a0)+, (a6)
	dbra	d0, .loop_next_address
	movem.l	(a7)+, d0/a0
	rts

auto_mmio_tests:
	bsr	check_mmio_oe
	bne	.test_failed_abort
	bsr	check_mmio_reg_vramrw_oe

.test_failed_abort:
	rts

; does OE test against all the registers in the
; MMIO_ADDRESSES_TABLE_START table
check_mmio_oe:
	lea	MMIO_ADDRESSES_TABLE_START, a1
	moveq	#((MMIO_ADDRESSES_TABLE_END - MMIO_ADDRESSES_TABLE_START)/4 - 1), d6

.loop_next_test:
	movea.l	(a1)+, a0
	move.w	a0, d0

	lsr.b	#1, d0
	bcc	.system_both

	tst.b	REG_STATUS_B			; skip registers with bit 1 set on AES systems
	bpl	.system_aes

.system_both:
	bsr	check_mmio_oe_byte
	beq	.test_failed

.system_aes:
	dbra	d6, .loop_next_test

	moveq	#0, d0
	rts

.test_failed:
	moveq	#EC_MMIO_DEAD_OUTPUT, d0
	rts

MMIO_ADDRESSES_TABLE_START:
	dc.l REG_DIPSW
	dc.l REG_SYSTYPE
	dc.l REG_STATUS_A
	dc.l REG_P1CNT
	dc.l REG_SOUND
	dc.l REG_P2CNT
	dc.l REG_STATUS_B
MMIO_ADDRESSES_TABLE_END:

check_mmio_reg_vramrw_oe:
	movea.l	a6, a0
	bsr	check_mmio_oe_word
	beq	.test_failed

	moveq	#0, d0
	rts

.test_failed:
	moveq	#EC_MMIO_DEAD_OUTPUT, d0
	rts

; check for output enable of a byte at a0
; params:
;  a0 = address
check_mmio_oe_byte:
	moveq	#-1, d0
	move.w	a0, d0
	moveq	#$31, d2

.loop_test_again:
	move.b	(a0), d1
	cmp.b	*(PC,d0.w), d1
	bne	.test_passed

	move.b	(a0), d1
	nop
	cmp.b	*-2(PC,d0.w), d1
	bne	.test_passed

	move.b	(a0), d1
	add.w	#0, d0
	cmp.b	*-4(PC,d0.w), d1

.test_passed:
	dbeq	d2, .loop_test_again
	rts

; check for output enable of a word at a0
; params:
;  a0 = address
check_mmio_oe_word:
	moveq	#$31, d2

.loop_test_again:
	move.w	(a0), d1
	cmp.w	*(PC), d1
	bne	.test_passed

	move.w	(a0), d1
	nop
	cmp.w	*-2(PC), d1
	bne	.test_passed

	move.w	(a0), d1
	add.w	#0, d0
	cmp.w	*-4(PC), d1
.test_passed:
	dbeq	d2, .loop_test_again
	rts

STR_ACTUAL:			STRING "ACTUAL:"
STR_EXPECTED:			STRING "EXPECTED:"
STR_ADDRESS:			STRING "ADDRESS:"
STR_COLON_SPACE:		STRING ": "
STR_HOLD_SS_TO_RESET:		STRING "HOLD START/SELECT TO SOFT RESET"
STR_RELEASE_SS:			STRING "RELEASE START/SELECT"
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

XY_STR_WATCHDOG_DELAY:		XY_STRING  4,  5, "WATCHDOG DELAY..."
XY_STR_WATCHDOG_TEXT_REMAINS:	XY_STRING  4,  8, "IF THIS TEXT REMAINS HERE..."
XY_STR_WATCHDOG_STUCK:		XY_STRING  4, 10, "THEN SYSTEM IS STUCK IN WATCHDOG"

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

XY_STR_Z80_SWITCHING_M1:	XY_STRING  4,  5, "SWITCHING TO CART M1..."
XY_STR_Z80_IGNORED_SM1:		XY_STRING  4,  5, "Z80 SLOT SWITCH IGNORED (SM1)"
XY_STR_Z80_SM1_UNRESPONSIVE:	XY_STRING  4,  7, "SM1 OTHERWISE LOOKS UNRESPONSIVE"
XY_STR_Z80_MV1BC_HOLD_B:	XY_STRING  4, 10, "IF MV-1B/1C: SOFT RESET & HOLD B"
XY_STR_Z80_PRESS_START:		XY_STRING  4, 12, "PRESS START TO CONTINUE"
XY_STR_Z80_TESTING_COMM_PORT:	XY_STRING  4,  5, "TESTING Z80 COMM. PORT..."
XY_STR_Z80_COMM_NO_HELLO:	XY_STRING  4,  5, "Z80->68k COMM ISSUE (HELLO)"
XY_STR_Z80_COMM_NO_ACK:		XY_STRING  4,  5, "Z80->68k COMM ISSUE (ACK)"
XY_STR_Z80_SKIP_TEST:		XY_STRING  4, 24, "TO SKIP Z80 TESTING, RELEASE"
XY_STR_Z80_PRESS_D_RESET:	XY_STRING  4, 25, "D BUTTON AND SOFT RESET."
XY_STR_Z80_MAKE_SURE:		XY_STRING  4, 21, "FOR Z80 TESTING, MAKE SURE TEST"
XY_STR_Z80_CART_CLEAN:		XY_STRING  4, 22, "CART IS CLEAN AND FUNCTIONAL."
XY_STR_Z80_M1_ENABLED:		XY_STRING 34,  4, "[M1]"
XY_STR_Z80_SLOT_SWITCH_NUM:	XY_STRING 29,  4, "[SS ]"
XY_STR_Z80_SM1_TESTS:		XY_STRING 24,  4, "[SM1]"
