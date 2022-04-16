	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"
	include "../common/error_codes.inc"

	global auto_palette_ram_tests
	global manual_palette_ram_tests
	global STR_PAL_RAM_TEST_LOOP

	section text

auto_palette_ram_tests:
		bsr	palette_ram_backup

		bsr	palette_ram_output_tests
		bne	.test_failed_abort

		bsr	palette_ram_we_tests
		bne	.test_failed_abort

		bsr	palette_ram_data_tests
		bne	.test_failed_abort

		bsr	palette_ram_address_tests

	.test_failed_abort:
		move.b	d0, REG_PALBANK0

		movem.l d0-d2/a0, -(a7)
		bsr	palette_ram_restore
		movem.l	(a7)+, d0-d2/a0

		rts

manual_palette_ram_tests:
		lea	XY_STR_PASSES, a0
		RSUB	print_xy_string_struct_clear
		lea	XY_STR_A_TO_RESUME, a0
		RSUB	print_xy_string_struct_clear
		lea	XY_STR_D_MAIN_MENU, a0
		RSUB	print_xy_string_struct_clear

		bsr	palette_ram_backup

		moveq	#0, d6					; init pass count to 0

	.loop_run_test:
		WATCHDOG
		moveq	#$e, d0
		moveq	#$e, d1
		move.w	d6, d2
		bclr	#$1f, d2
		RSUB	print_hex_3_bytes			; print the number of passes in hex

		bsr	palette_ram_data_tests
		bne	.test_failed_abort

		bsr	palette_ram_address_tests
		bne	.test_failed_abort

		addq.l	#1, d6

		btst	#D_BUTTON, REG_P1CNT
		beq	.test_exit_restore

		btst	#A_BUTTON, REG_P1CNT
		bne	.loop_run_test				; 'a' not pressed, loop and do another test

		bsr	palette_ram_restore

	.loop_wait_a_release:
		WATCHDOG
		btst	#D_BUTTON, REG_P1CNT
		beq	.test_exit

		btst	#A_BUTTON, REG_P1CNT
		beq	.loop_wait_a_release

		bsr	palette_ram_backup
		bra	.loop_run_test

	.test_failed_abort:					; error occured, print info
		move.b	d0, REG_PALBANK0
		bsr	palette_ram_restore

		RSUB	print_error

		moveq	#25, d0					; remove A TO RESUME line
		SSA3	fix_clear_line

		bra	loop_d_pressed

	.test_exit_restore:
		bsr	palette_ram_restore

	.test_exit:
		rts


palette_ram_we_tests:
		lea	PALETTE_RAM_START, a0
		move.w	#$ff, d0
		RSUB	check_ram_we
		tst.b	d0
		beq	.test_passed_lower
		moveq	#EC_PAL_UNWRITABLE_LOWER, d0
		rts

	.test_passed_lower:
		lea	PALETTE_RAM_START, a0
		move.w	#$ff00, d0
		RSUB	check_ram_we
		tst.b	d0
		beq	.test_passed_upper
		moveq	#EC_PAL_UNWRITABLE_UPPER, d0
		rts

	.test_passed_upper:
		moveq	#0, d0
		rts

palette_ram_data_tests:

		lea	PALETTE_RAM_START, a0
		move.w	#$1000, d0
		DSUB	check_ram_data
		tst.b	d0
		bne	.test_failed_bank0

		move.b	d0, REG_PALBANK1

		lea	PALETTE_RAM_START, a0
		move.w	#$1000, d0
		DSUB	check_ram_data
		tst.b	d0
		bne	.test_failed_bank1

		move.b	d0, REG_PALBANK0
		moveq	#0, d0
		rts

	.test_failed_bank0:
		subq.b	#1, d0
		add.b	#EC_PAL_BANK0_DATA_LOWER, d0
		rts

	.test_failed_bank1:
		move.b	d0, REG_PALBANK0
		subq.b	#1, d0
		add.b	#EC_PAL_BANK1_DATA_LOWER, d0
		rts

palette_ram_address_tests:
		lea	PALETTE_RAM_START, a0
		moveq	#2, d0
		move.w	#$100, d1
		bsr	check_palette_ram_address
		beq	.test_passed_a0_a7
		moveq	#EC_PAL_ADDRESS_A0_A7, d0
		rts

	.test_passed_a0_a7:
		lea	PALETTE_RAM_START, a0
		move.w	#$200, d0
		moveq	#$20, d1
		bsr	check_palette_ram_address
		beq	.test_passed_a8_a12
		moveq	#EC_PAL_ADDRESS_A0_A12, d0
		rts

	.test_passed_a8_a12:
		moveq	#0, d0
		rts

; params:
;  d0 = increment amount
;  d1 = number of increments
check_palette_ram_address:
		lea	PALETTE_RAM_START, a0
		lea	PALETTE_RAM_MIRROR_START, a1
		subq.w	#1, d1
		move.w	d1, d2
		moveq	#0, d3

	.loop_write_next_address:
		move.w	d3, (a0)
		add.w	#$101, d3
		adda.w	d0, a0				; write to palette ram
		cmpa.l	a0, a1				; continue until a0 == PALETTE_RAM_MIRROR
		bne	.skip_bank_switch_write

		move.b	d0, REG_PALBANK1
		lea	PALETTE_RAM_START, a0
	.skip_bank_switch_write:
		dbra	d2, .loop_write_next_address

		move.b	d0, REG_PALBANK0
		lea	PALETTE_RAM_START, a0
		moveq	#0, d3
		bra	.loop_start_address_read

	.loop_read_next_address:
		add.w	#$101, d3
		adda.w	d0, a0
		cmpa.l	a0, a1
		bne	.loop_start_address_read	; aka .skip_bank_switch_read

		move.b	d0, REG_PALBANK1
		lea	PALETTE_RAM_START, a0

	.loop_start_address_read:
		move.w	(a0), d2
		cmp.w	d2, d3
		dbne	d1, .loop_read_next_address

		bne	.test_failed
		move.b	d0, REG_PALBANK0
		WATCHDOG
		moveq	#0, d0
		rts

	.test_failed:
		move.w	d3, d1
		move.b	d0, REG_PALBANK0
		WATCHDOG
		moveq	#-1, d0
		rts

; Depending on motherboard model there will either be 2x245s or a NEO-G0
; sitting between the palette memory and the 68k data bus.
; The first 2 tests are checking for output from the IC's, while the last 2
; tests are checking for output on the palette memory chips
palette_ram_output_tests:
		moveq	#1, d0
		lea	PALETTE_RAM_START, a0
		RSUB	check_ram_oe
		tst.b	d0
		beq	.test_passed_memory_output_lower
		moveq	#EC_PAL_245_DEAD_OUTPUT_LOWER, d0
		rts

	.test_passed_memory_output_lower:
		moveq	#0, d0
		lea	PALETTE_RAM_START, a0
		RSUB	check_ram_oe
		tst.b	d0
		beq	.test_passed_memory_output_upper
		moveq	#EC_PAL_245_DEAD_OUTPUT_UPPER, d0
		rts

	.test_passed_memory_output_upper:
		move.w	#$ff, d0
		bsr	check_palette_ram_to_245_output
		beq	.test_passed_palette_ram_to_245_output_lower
		moveq	#EC_PAL_DEAD_OUTPUT_LOWER, d0
		rts

	.test_passed_palette_ram_to_245_output_lower:
		move.w	#$ff00, d0
		bsr	check_palette_ram_to_245_output
		beq	.test_passed_palette_ram_to_245_output_upper
		moveq	#EC_PAL_DEAD_OUTPUT_UPPER, d0
		rts

	.test_passed_palette_ram_to_245_output_upper:
		moveq	#0, d0
		rts

; palette ram and have 2x245s or a NEO-G0 between
; them and the 68k data bus.  This function attempts
; to check for dead output between the memory chip and
; the 245s/NEO-G0.
;
; params
;  d0 = compare mask
; return
;  d0 = 0 is passed, -1 = failed
check_palette_ram_to_245_output:
		lea	PALETTE_RAM_START, a0
		move.w	#$ff, d2
		moveq	#0, d3
		move.w	#$101, d5

	.loop_next_address:
		move.w	d3, (a0)
		move.w	#$7fff, d4

	.loop_delay:
		WATCHDOG
		dbra	d4, .loop_delay

		move.w	(a0), d1
		add.w	d5, d3
		and.w	d0, d1

		; note this is comparing the mask with the read data,
		; dead output from the chip will cause $ff
		cmp.w	d0, d1
		dbne	d2, .loop_next_address

		beq	.test_failed
		moveq	#0, d0
		rts

	.test_failed:
		moveq	#-1, d0
		rts

STR_PAL_RAM_TEST_LOOP:		STRING "PALETTE RAM TEST LOOP"
