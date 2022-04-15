	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"

	global manual_calendar_tests
	global STR_CALENDAR_IO

	section	text

manual_calendar_tests:
		lea	XY_STR_A_1HZ_PULSE, a0
		RSUB	print_xy_string_struct_clear
		lea	XY_STR_B_64HZ_PULSE, a0
		RSUB	print_xy_string_struct_clear
		lea	XY_STR_C_4096HZ_PULSE, a0
		RSUB	print_xy_string_struct_clear
		lea	XY_STR_D_MAIN_MENU, a0
		RSUB	print_xy_string_struct_clear

		lea	XY_STR_ACTUAL, a0
		RSUB	print_xy_string_struct_clear

		lea	XY_STR_EXPECTED, a0
		RSUB	print_xy_string_struct_clear

		lea	XY_STR_4990_TP, a0
		RSUB	print_xy_string_struct_clear

		bsr	rtc_set_1_hz

		bsr	p1_input_update

	.loop_run_test:
		WATCHDOG
		bsr	p1_input_update

		bsr	rtc_print_data
		move.b	p1_input_edge, d0
		add.b	d0, d0
		bcs	.test_exit			; d pressed, exit test

		add.b	d0, d0
		bcc	.c_not_pressed			; check for c pressed
		bsr	rtc_set_4096_hz
		bra	.loop_run_test
	.c_not_pressed:

		add.b	d0, d0
		bcc	.b_not_pressed
		bsr	rtc_set_64_hz
		bra	.loop_run_test
	.b_not_pressed:

		add.b	d0, d0
		bcc	.loop_run_test
		bsr	rtc_set_1_hz
		bra	.loop_run_test

	.test_exit:
		move	#$2700, sr			; disable interrupts
		move.w	#$0, ($4,a6)			; disable timer
		move.w	#$2, ($a,a6)			; ack timer interrupt
		rts

rtc_set_1_hz:
		moveq	#$8, d0
		move.l	#$5b8d80, d1
		bra	rtc_update_hz

rtc_set_64_hz:
		moveq	#$4, d0
		move.l	#$16e36, d1
		bra	rtc_update_hz

rtc_set_4096_hz:
		moveq	#$7, d0
		move.l	#$5b8, d1

rtc_update_hz:
		move.w	#$20, ($4,a6)		; Reload counter as soon as REG_TIMERLOW is written to
		clr.w	timer_count
		bsr	rtc_send_command

		move.l	d1, -(a7)
		lea	XY_STR_WAITING_PULSE, a0
		RSUB	print_xy_string_struct_clear

		bsr	rtc_wait_pulse

		moveq	#20, d0
		SSA3	fix_clear_line		; removes waiting for calendar pulse... line

		move.l	(a7)+, ($6,a6)		; timer high
		move.w	#$90, ($4,a6)		; lspcmode
		move	#$2100, sr		; enable interrupts
		moveq	#$0, d2			; zero out pulse counter
		rts

; d2 = number of pulses
rtc_print_data:
		moveq	#14, d0
		moveq	#10, d1
		move.w	d2, -(a7)
		RSUB	print_hex_word

		moveq	#14, d0
		moveq	#12, d1
		move.w	timer_count, d2
		RSUB	print_hex_word

		moveq	#14, d0
		moveq	#14, d1
		SSA3	fix_seek_xy

		moveq	#$18, d0
		move.b	REG_STATUS_A, d1
		add.b	d1, d1
		add.b	d1, d1
		addx.b	d0, d0
		move.w	d0, (a6)

		move.w	(a7)+, d2
		bsr	rtc_check_pulse
		beq	.no_rtc_pulse
		addq.w	#1, d2

	.no_rtc_pulse:
		rts

; d0 = data
; sends the 4 bit command to the rtc, which runs in
; serial mode (shift register)
rtc_send_command:
		move.l	d1, -(a7)
		lea	REG_RTCCTRL, a0
		moveq	#$3, d2
	.loop_next:
		moveq	#$1, d1
		and.b	d0, d1
		move.b	d1, (a0)  	; write bit 0 from d0
		addq.b	#2, d1
		nop
		move.b	d1, (a0)  	; rtc clock high
		subq.b	#2, d1
		lsr.b	#1, d0		; shift right d0 to prep for next bit to send (next loop)
		move.b	d1, (a0)  	; rtc clock low to tigger shift
		dbra	d2, .loop_next
		move.b	#$4, (a0)	; rtc stb high
		nop
		clr.b	(a0)		; rtc stb low (run command)
		move.l	(a7)+, d1
		rts

rtc_wait_pulse:
		WATCHDOG
		btst	#$6, REG_STATUS_A
		bne	rtc_wait_pulse

	.loop_rtc_pulse_low:
		WATCHDOG
		btst	#$6, REG_STATUS_A
		beq	.loop_rtc_pulse_low
		move.b	#$40, rtc_pulse_state
		rts

; if there is a new pulse, Z will be set
rtc_check_pulse:
		moveq	#$40, d0
		and.b	REG_STATUS_A, d0
		move.b	rtc_pulse_state, d1
		move.b	d0, rtc_pulse_state
		eor.b	d0, d1
		and.b	d0, d1
		rts

STR_CALENDAR_IO:		STRING "CALENDAR I/O (MVS ONLY)"

; strings for calender io screen
XY_STR_WAITING_PULSE:		XY_STRING  4, 20, "WAITING FOR CALENDAR PULSE..."
XY_STR_4990_TP:			XY_STRING  4, 14, "4990 TP:"

XY_STR_A_1HZ_PULSE:		XY_STRING  4, 24, "A: 1Hz pulse"
XY_STR_B_64HZ_PULSE:		XY_STRING  4, 25, "B: 64Hz pulse"
XY_STR_C_4096HZ_PULSE:		XY_STRING  4, 26, "C: 4096Hz pulse"

