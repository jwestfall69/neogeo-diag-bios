	include "neogeo.inc"
	include "macros.inc"
	include "diag.inc"

	global check_reset_request
	global delay_dsub
	global error_to_credit_leds_dsub
	global get_slot_count
	global loop_d_pressed
	global loop_reset_check
	global loop_reset_check_dsub
	global p1_input_update
	global p1p2_input_update
	global palette_init_dsub
	global print_hold_ss_to_reset
	global send_p1p2_controller
	global wait_frame
	global wait_p1_input
	global wait_scanline

	global d_xys_hold_ss_to_reset

	global r_p1_input
	global r_p1_input_edge
	global r_p1_input_aux
	global r_p1_input_aux_edge

	global r_p2_input
	global r_p2_input_edge
	global r_p2_input_aux
	global r_p2_input_aux_edge

	section code

; params:
;  d0 * 2.5us = how long to delay
delay_dsub:
		move.b	d0, REG_WATCHDOG	; 16 cycles
		subq.l	#1, d0			; 4 cycles
		bne	delay_dsub		; 10 cycles
		DSUB_RETURN


; loop waiting for D to be pressed
loop_d_pressed:
		WATCHDOG
		btst	#INPUT_D_BIT, REG_P1CNT
		bne	loop_d_pressed
		rts

; loop forever checking for reset request;
loop_reset_check:
		bsr	print_hold_ss_to_reset
	.loop_forever:
		WATCHDOG
		bsr	check_reset_request
		bra	.loop_forever


; loop forever checking for reset request
loop_reset_check_dsub:
		lea	d_xys_hold_ss_to_reset, a0
		DSUB	print_xys_string_clear

	.loop_ss_not_pressed:
		WATCHDOG
		moveq	#3, d0
		and.b	REG_STATUS_B, d0
		bne	.loop_ss_not_pressed		; loop until P1 start+select both held down

		lea	d_xys_release_ss, a0
		DSUB	print_xys_string_clear

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

		lea	d_xys_release_ss, a0
		RSUB	print_xys_string_clear

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

palette_init_dsub:
		lea	PALETTE_RAM_START, a0
		move.l	#(PALETTE_RAM_SIZE / 2) - 1, d0

	.loop_next_address:
		move.w	#$0, (a0)+
		dbra	d0, .loop_next_address

		move.l	#$7fff0000, PALETTE_RAM_START + $2			; white on black for text
		move.l	#$07770000, PALETTE_RAM_START + PALETTE_SIZE + $2	; gray on black for text (disabled menu items)
		DSUB_RETURN

; params:
;  none
; returns:
;  d0 = number of slots the board has
; bit6 of REG_SYSTYPE | bit5 of REG_STATUS_A | slot count
;---------------------+----------------------+-----------
;         0           |         0            | 2 slot
;         0           |         1            | 1 slot
;         1           |         0            | 4 slot
;         1           |         1            | 6 slot
get_slot_count:
		tst.b	REG_STATUS_B
		bpl	.one_slot		; aes

		btst	#6, REG_SYSTYPE
		bne	.four_or_six_slot

		btst	#5, REG_STATUS_A
		bne	.one_slot
		moveq	#2, d0
		rts

	.four_or_six_slot:
		btst	#5, REG_STATUS_A
		bne	.six_slot
		moveq	#4, d0
		rts

	.six_slot:
		moveq	#6, d0
		rts

	.one_slot:
		moveq	#1, d0
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
		move.b	r_p1_input, d1
		eor.b	d0, d1
		and.b	d0, d1
		move.b	d1, r_p1_input_edge
		move.b	d0, r_p1_input
		move.b	REG_STATUS_B, d0
		not.b	d0
		move.b	r_p1_input_aux, d1
		eor.b	d0, d1
		and.b	d0, d1
		move.b	d1, r_p1_input_aux_edge
		move.b	d0, r_p1_input_aux
		rts

p2_input_update:
		move.b	REG_P2CNT, d0
		not.b	d0
		move.b	r_p2_input, d1
		eor.b	d0, d1
		and.b	d0, d1
		move.b	d1, r_p2_input_edge
		move.b	d0, r_p2_input
		move.b	REG_STATUS_B, d0
		lsr.b	#2, d0
		not.b	d0
		move.b	r_p2_input_aux, d1
		eor.b	d0, d1
		and.b	d0, d1
		move.b	d1, r_p2_input_aux_edge
		move.b	d0, r_p2_input_aux
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

print_hold_ss_to_reset:
		lea	d_xys_hold_ss_to_reset, a0
		RSUB	print_xys_string_clear
		rts

	section data
	align 1

d_xys_hold_ss_to_reset:		XY_STRING LEFT_MARGIN, 27, "HOLD START/SELECT TO SOFT RESET"
d_xys_release_ss:		XY_STRING LEFT_MARGIN, 27, "RELEASE START/SELECT"

	section bss
	align 1

r_p1_input:			dc.b $0
r_p1_input_edge:		dc.b $0
r_p1_input_aux:			dc.b $0
r_p1_input_aux_edge:		dc.b $0
r_p2_input:			dc.b $0
r_p2_input_edge:		dc.b $0
r_p2_input_aux:			dc.b $0
r_p2_input_aux_edge:		dc.b $0
