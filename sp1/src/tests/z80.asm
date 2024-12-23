	include "neogeo.inc"
	include "macros.inc"
	include "diag.inc"
	include "../common/error_codes.inc"
	include "../common/comm.inc"

	global auto_z80_tests
	global z80_slot_switch

	global r_z80_test_flags

	section code

auto_z80_tests:
		lea	d_xys_z80_m1_enabled, a0
		RSUB	print_xys_string

		lea	d_xys_z80_testing_comm_port, a0
		RSUB	print_xys_string_clear

		lea	d_xys_z80_snd_reg, a0
		RSUB	print_xys_string_clear

		bsr	start_comm_test

	.loop_try_again:
		WATCHDOG
		bsr	check_error
		bsr	check_sm1_test
		bsr	check_done
		bne	.loop_try_again

		; clears out the SND REG: line
		moveq	#10, d0
		SSA3	fix_clear_line
		rts

; swiches to cart M1/S1 roms;
z80_slot_switch:

		bset.b	#Z80_TEST_FLAG_SLOT_SWITCH, r_z80_test_flags

		lea	d_xys_z80_switching_m1, a0
		RSUB	print_xys_string_clear

		move.b	#$01, REG_SOUND				; tell z80 to prep for m1 switch

		move.l	#$1388, d0				; 12500us / 12.5ms
		RSUB	delay

		move.b	REG_P1CNT, d3				; save users input

		move.b	REG_SOUND, d2
		cmpi.b	#$01, d2
		beq	.slot_switch_ready
		bsr	slot_switch_ignored

	.slot_switch_ready:

		move.b	d3, d0
		moveq	#$f, d1
		and.b	d1, d0
		eor.b	d1, d0

		moveq	#((d_slot_select_end - d_slot_select_start)/2 - 1), d1
		lea	(d_slot_select_start - 1), a0

	.loop_next_entry:
		addq.l	#1, a0
		cmp.b	(a0)+, d0
		dbeq	d1, .loop_next_entry		; loop through struct looking for p1 input match
		beq	.do_slot_switch

		addq.l	#2, a0				; nothing matched, use the last entry (slot 1)

	.do_slot_switch:

		move.b	(a0), d3
		lea	(d_xys_z80_slot_switch_num), a0	; "[SS ]"
		RSUB	print_xys_string

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


slot_switch_ignored:

		moveq	#14, d0
		moveq	#10, d1
		DSUB	print_hex_byte

		move.b	#1, d2
		moveq	#14, d0
		moveq	#12, d1
		DSUB	print_hex_byte

		lea	d_xys_actual, a0
		DSUB	print_xys_string

		lea	d_xys_expected, a0
		DSUB	print_xys_string

		lea	d_xys_z80_sm1_ignored, a0
		RSUB	print_xys_string_clear
		lea	d_xys_z80_sm1_responsive, a0
		RSUB	print_xys_string_clear
		lea	d_xys_z80_mv1bc_hold_b, a0
		RSUB	print_xys_string_clear
		lea	d_xys_z80_press_start, a0
		RSUB	print_xys_string_clear

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
		moveq	#16, d0
		SSA3	fix_clear_line
		moveq	#18, d0
		SSA3	fix_clear_line
		rts

; see if the z80 sent us an error
check_error:
		moveq	#-$40, d0
		and.b	REG_SOUND, d0
		cmp.b	#$40, d0		; 0x40 = flag indicating a z80 error code
		bne	.no_error

		move.b	REG_SOUND, d0		; get the error (again?)
		move.b	d0, d2
		move.l	#$100000, d1
		bsr	ack_error		; ack the error by sending it back, and wait for z80 to ack our ack
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

	.skip_error_to_credit_leds:

		bra	loop_reset_check

	.no_error:
		rts


check_sm1_test:

		; diag m1 is asking us to swap m1 -> sm1
		move.b	REG_SOUND, d0
		cmp.b	#COMM_SM1_TEST_SWITCH_SM1, d0
		bne	.check_swap_to_m1

		btst	#Z80_TEST_FLAG_SLOT_SWITCH, r_z80_test_flags		; deny, no sm1 because there was no slot switch
		beq	.deny_sm1_tests

		btst	#Z80_TEST_FLAG_SKIP_SM1_TESTS, r_z80_test_flags		; deny, user requests no sm1 tests
		bne	.deny_sm1_tests

		move.b	d0, REG_BRDFIX
		move.b	#COMM_SM1_TEST_SWITCH_SM1_DONE, REG_SOUND

		lea	(d_xys_z80_sm1_tests), a0		; "[SM1]" to indicate m1 is running sm1 tests
		RSUB	print_xys_string

		bsr	z80_wait_clear
		rts

	.deny_sm1_tests:
		move.b	#COMM_SM1_TEST_SWITCH_SM1_DENY, REG_SOUND
		bsr	z80_wait_clear
		rts

	.check_swap_to_m1:
		; diag m1 asking us to swap sm1 -> m1
		cmp.b	#COMM_SM1_TEST_SWITCH_M1, d0
		bne	.no_swap_back_requested

		move.b	d0, REG_CRTFIX
		move.b	#COMM_SM1_TEST_SWITCH_M1_DONE, REG_SOUND

		bsr	z80_wait_clear

	.no_swap_back_requested:
		rts

; d0 = loop until we stop getting this byte from z80
z80_wait_clear:
		WATCHDOG
		cmp.b	REG_SOUND, d0
		beq	z80_wait_clear
		rts

; see if z80 says its done testing (with no issues)
check_done:
		move.b	#COMM_Z80_TESTS_COMPLETE, d0
		cmp.b	REG_SOUND, d0
		rts


start_comm_test:
		move.b	#COMM_TEST_HELLO, d1
		move.w	#500, d2
		bra	.loop_start_wait_hello

	; wait up to 5 seconds for hello (10ms * 500 loops)
	.loop_wait_hello:
		move.w	#4000, d0
		RSUB	delay

		bsr	print_reg_sound

	.loop_start_wait_hello:
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

		bsr	print_reg_sound

	.loop_start_wait_ack:
		cmp.b	REG_SOUND, d1
		dbeq	d2, .loop_wait_ack
		bne	.z80_ack_timeout
		rts

	.z80_hello_timeout:
		lea	d_xys_z80_comm_no_hello, a0
		bra	.print_comm_error

	.z80_ack_timeout:
		lea	d_xys_z80_comm_no_ack, a0

	.print_comm_error:
		move.b	d1, d0
		bra	print_comm_error

print_reg_sound:
		movem.l	d0-d2, -(a7)
		move.b	REG_SOUND, d2
		moveq	#14, d0
		moveq	#10, d1
		RSUB	print_hex_byte
		movem.l	(a7)+, d0-d2
		rts

; prints the z80 related communication error
; params:
;  d0 = expected response
;  a0 = xy_string_struct address for main error
print_comm_error:
		move.w	d0, -(a7)

		RSUB	print_xys_string_clear

		lea	d_xys_expected, a0
		RSUB	print_xys_string_clear

		lea	d_xys_actual, a0
		RSUB	print_xys_string_clear

		lea	d_xys_z80_skip_test, a0
		RSUB	print_xys_string_clear
		lea	d_xys_z80_press_d_reset, a0
		RSUB	print_xys_string_clear

		move.w	(a7)+, d2
		moveq	#14, d0
		moveq	#12, d1
		RSUB	print_hex_byte				; expected value

		move.b	REG_SOUND, d2
		moveq	#14, d0
		moveq	#10, d1
		RSUB	print_hex_byte				; actual value

		lea	d_xys_z80_make_sure, a0
		RSUB	print_xys_string_clear

		lea	d_xys_z80_cart_clean, a0
		RSUB	print_xys_string_clear

		bsr	check_error
		bra	loop_reset_check

; ack an error sent to us by the z80 by sending
; it back, and then waiting for the z80 to ack
; our ack.
; params:
;  d0 = error code z80 sent us
;  d1 = number of loops waiting for the response
ack_error:
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

	section data
	align 1

; struct {
; 	byte buttons_pressed; 	(up/down/left/right)
;  	byte slot;
; }
d_slot_select_start:
	dc.b	$01, $02			; up = slot 2
	dc.b	$09, $03			; up+right = slot 3
	dc.b	$08, $04			; right = slot 4
	dc.b	$0a, $05			; down+right = slot 5
	dc.b	$02, $06			; down = slot 6
d_slot_select_end:
	dc.b	$00, $01			; no match = slot 1

d_xys_z80_switching_m1:		XY_STRING LEFT_MARGIN,  5, "SWITCHING TO CART M1..."
d_xys_z80_sm1_ignored:		XY_STRING (LEFT_MARGIN - 1),  5, "SM1/Z80 PREPARE SLOT SWITCH IGNORED"
d_xys_z80_sm1_responsive:	XY_STRING (LEFT_MARGIN - 1),  7, "SM1 RESPONSE"
d_xys_z80_press_start:		XY_STRING (LEFT_MARGIN - 1), 16, "PRESS START TO FORCE SLOT SWITCH"
d_xys_z80_mv1bc_hold_b:		XY_STRING (LEFT_MARGIN - 1), 18, "IF MV-1B/1C: SOFT RESET & HOLD B+D"
d_xys_z80_testing_comm_port:	XY_STRING LEFT_MARGIN,  5, "TESTING Z80 COMM. PORT..."
d_xys_z80_comm_no_hello:	XY_STRING LEFT_MARGIN,  5, "Z80->68k COMM ISSUE (HELLO)"
d_xys_z80_comm_no_ack:		XY_STRING LEFT_MARGIN,  5, "Z80->68k COMM ISSUE (ACK)"
d_xys_z80_skip_test:		XY_STRING LEFT_MARGIN, 24, "TO SKIP Z80 TESTING, RELEASE"
d_xys_z80_press_d_reset:	XY_STRING LEFT_MARGIN, 25, "D BUTTON AND SOFT RESET."
d_xys_z80_make_sure:		XY_STRING LEFT_MARGIN, 21, "FOR Z80 TESTING, MAKE SURE TEST"
d_xys_z80_cart_clean:		XY_STRING LEFT_MARGIN, 22, "CART IS CLEAN AND FUNCTIONAL."
d_xys_z80_m1_enabled:		XY_STRING 34,  4, "[M1]"
d_xys_z80_slot_switch_num:	XY_STRING 29,  4, "[SS ]"
d_xys_z80_sm1_tests:		XY_STRING 24,  4, "[SM1]"
d_xys_z80_snd_reg:		XY_STRING LEFT_MARGIN, 10, "SND REG: "

	section bss
	align 1

r_z80_test_flags:		dc.b $0
