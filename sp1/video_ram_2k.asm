	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"
	include "../common/error_codes.inc"

	global auto_video_ram_2k_tests
	global manual_video_ram_2k_tests
	global STR_VRAM_TEST_LOOP_2K

	section text

auto_video_ram_2k_tests:
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

manual_video_ram_2k_tests:
		lea	STR_HOLD_ABCD_TO_STOP, a0
		moveq	#$4, d0
		moveq	#$1b, d1
		RSUB	print_xy_string_clear

		lea	XY_STR_PASSES.l, a0
		RSUB	print_xy_string_struct

		moveq	#$0, d6
		bra	.loop_start_run_test

	.loop_run_test:
		WATCHDOG
		bsr	vram_data_tests
		bne	.test_failed_abort

		bsr	vram_address_tests
		bne	.test_failed_abort

		moveq	#$e, d0
		moveq	#$e, d1
		move.l	d6, d2
		RSUB	print_hex_3_bytes

		addq.l	#1, d6

	.loop_start_run_test:
		moveq	#-$10, d0
		and.b	REG_P1CNT, d0
		beq	.test_exit			; if a+b+c+d pressed, exit test
		bra	.loop_run_test

	.test_failed_abort:
		RSUB	print_error

		moveq	#$19, d0
		SSA3	fix_clear_line

		bra	loop_reset_check

	.test_exit:
		rts

vram_oe_tests:
		move.w	#$8000, d0
		move.w	#$ff, d1
		bsr	check_vram_oe
		beq	.test_passed_2k_lower
		moveq	#EC_VRAM_2K_DEAD_OUTPUT_LOWER, d0
		rts

	.test_passed_2k_lower:
		move.w	#$8000, d0
		move.w	#$ff00, d1
		bsr	check_vram_oe
		beq	.test_passed_2k_upper
		moveq	#EC_VRAM_2K_DEAD_OUTPUT_UPPER, d0
		rts

	.test_passed_2k_upper:
		moveq	#0, d0
		rts

vram_we_tests:
		move.w	#$8000, d0
		move.w	#$ff, d1
		bsr	check_vram_we
		beq	.test_passed_2k_lower
		moveq	#EC_VRAM_2K_UNWRITABLE_LOWER, d0
		rts

	.test_passed_2k_lower:
		move.w	#$8000, d0
		move.w	#$ff00, d1
		bsr	check_vram_we
		beq	.test_passed_2k_upper
		moveq	#EC_VRAM_2K_UNWRITABLE_UPPER, d0
		rts

	.test_passed_2k_upper:
		moveq	#0, d0
		rts

; 2k (words) vram tests (data and address) only look at the
; first 1536 (0x600) words, since the remaining 512 words
; are used by the LSPC for buffers per dev wiki
vram_data_tests:
		move.w	#$8000, d0
		move.w	#$600, d1
		bsr	check_vram_data
		tst.b	d0
		bne	.test_failed
		rts

	.test_failed:
		subq.b	#1, d0
		add.b	#EC_VRAM_2K_DATA_LOWER, d0
		rts

vram_address_tests:
		move.w	#$8000, d1
		move.w	#$100, d2
		moveq	#1, d0
		bsr	check_vram_address
		beq	.test_passed_a0_a7
		moveq	#EC_VRAM_2K_ADDRESS_A0_A7, d0
		rts

	.test_passed_a0_a7:
		move.w	#$8000, d1
		move.w	#$6, d2
		move.w	#$100, d0
		bsr	check_vram_address
		beq	.test_passed_a8_a14
		moveq	#EC_VRAM_2K_ADDRESS_A8_A10, d0
		rts

	.test_passed_a8_a14:
		rts

STR_VRAM_TEST_LOOP_2K:		STRING "VRAM TEST LOOP (2K)"
