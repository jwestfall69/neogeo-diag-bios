	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"
	include "../common/error_codes.inc"

	global auto_video_ram_32k_tests
	global manual_video_ram_32k_tests
	global STR_VRAM_TEST_LOOP_32K

	section text

auto_video_ram_32k_tests:
		bsr	fix_backup

		bsr	vram_oe_tests
		bne	.test_failed_abort

		bsr	vram_we_tests
		bne	.test_failed_abort

		bsr	vram_data_tests
		bne	.test_failed_abort

		bsr	vram_address_tests

	.test_failed_abort:
		move.w	d0, -(a7)
		bsr	fix_restore
		move.w	(a7)+, d0
		rts

manual_video_ram_32k_tests:
		lea	XY_STR_PASSES, a0
		RSUB	print_xy_string_struct

		lea	XY_STR_A_TO_RESUME, a0
		RSUB	print_xy_string_struct_clear

		lea	XY_STR_D_MAIN_MENU, a0
		RSUB	print_xy_string_struct

		bsr	fix_backup

		moveq	#$0, d6

	.loop_run_test:
		WATCHDOG

		bsr	vram_data_tests
		bne	.test_failed_abort

		bsr	vram_address_tests
		bne	.test_failed_abort

		addq.l	#1, d6

		btst	#D_BUTTON, REG_P1CNT
		beq	.test_exit_restore

		btst	#A_BUTTON, REG_P1CNT
		bne	.loop_run_test			; 'a' not pressed, loop and do another test

		bsr	fix_restore


	.loop_wait_a_release:
		WATCHDOG

		moveq	#$e, d0
		moveq	#$e, d1
		move.l	d6, d2
		bclr	#$1f, d2			; make sure signed bit is 0
		RSUB	print_hex_3_bytes		; print pass number

		btst	#D_BUTTON, REG_P1CNT
		beq	.test_exit

		btst	#A_BUTTON, REG_P1CNT
		beq	.loop_wait_a_release		; loop until either 'a' not pressed or 'a+b+c+d' pressed

		bsr	fix_backup
		bra	.loop_run_test

	.test_failed_abort:
		bsr	fix_restore

		movem.l	d0-d2, -(a7)
		moveq	#$e, d0
		moveq	#$e, d1
		move.l	d6, d2
		bclr	#$1f, d2
		RSUB	print_hex_3_bytes		; print pass number
		movem.l	(a7)+, d0-d2

		RSUB	print_error

		moveq	#25, d0
		SSA3	fix_clear_line			; remove A TO RESUME line

		bra	loop_d_pressed

	.test_exit_restore:
		bsr	fix_restore

	.test_exit:
		rts

vram_oe_tests:
		moveq	#0, d0
		move.w	#$ff, d1
		bsr	check_vram_oe
		beq	.test_passed_32k_lower
		moveq	#EC_VRAM_32K_DEAD_OUTPUT_LOWER, d0
		rts

	.test_passed_32k_lower:
		moveq	#0, d0
		move.w	#$ff00, d1
		bsr	check_vram_oe
		beq	.test_passed_32k_upper
		moveq	#EC_VRAM_32K_DEAD_OUTPUT_UPPER, d0
		rts

	.test_passed_32k_upper:
		moveq	#0, d0
		rts

vram_we_tests:
		moveq	#0, d0
		move.w	#$ff, d1
		bsr	check_vram_we
		beq	.test_passed_32k_lower
		moveq	#EC_VRAM_32K_UNWRITABLE_LOWER, d0
		rts

	.test_passed_32k_lower:
		moveq	#$0, d0
		move.w	#$ff00, d1
		bsr	check_vram_we
		beq	.test_passed_32k_upper
		moveq	#EC_VRAM_32K_UNWRITABLE_UPPER, d0
		rts

	.test_passed_32k_upper:
		moveq	#0, d0
		rts

vram_data_tests:
		moveq	#0, d0
		move.w	#$8000, d1
		bsr	check_vram_data
		tst.b	d0
		bne	.test_failed
		rts

	.test_failed:
		subq.b	#1, d0
		add.b	#EC_VRAM_32K_DATA_LOWER, d0
		rts

vram_address_tests:
		clr.w	d1
		move.w	#$100, d2
		moveq	#1, d0
		bsr	check_vram_address
		beq	.test_passed_a0_a7
		moveq	#EC_VRAM_32K_ADDRESS_A0_A7, d0
		rts

	.test_passed_a0_a7:
		clr.w	d1
		move.w	#$80, d2
		move.w	#$100, d0
		bsr	check_vram_address
		beq	.test_passed_a8_a14
		moveq	#EC_VRAM_32K_ADDRESS_A8_A14, d0
		rts

	.test_passed_a8_a14:
		rts

STR_VRAM_TEST_LOOP_32K:		STRING "VRAM TEST LOOP (32K)"
