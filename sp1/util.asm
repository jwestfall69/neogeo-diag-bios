	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"

	global check_reset_request
	global delay_dsub
	global loop_reset_check
	global loop_reset_check_dsub
	global p1_input_update
	global p1p2_input_update
	global palette_ram_backup
	global palette_ram_restore
	global print_hold_ss_to_reset
	global send_p1p2_controller
	global wait_frame
	global wait_p1_input
	global wait_scanline

	section text

; params:
;  d0 * 2.5us = how long to delay
delay_dsub:
		move.b	d0, REG_WATCHDOG	; 16 cycles
		subq.l	#1, d0			; 4 cycles
		bne	delay_dsub		; 10 cycles
		DSUB_RETURN

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

print_hold_ss_to_reset:
		moveq	#4, d0
		moveq	#27, d1
		lea	STR_HOLD_SS_TO_RESET, a0
		RSUB	print_xy_string_clear
		rts

STR_HOLD_SS_TO_RESET:			STRING "HOLD START/SELECT TO SOFT RESET"
STR_RELEASE_SS:				STRING "RELEASE START/SELECT"
