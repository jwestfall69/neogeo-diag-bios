	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"
	include "../common/error_codes.inc"

	global auto_work_ram_address_tests_dsub
	global auto_work_ram_data_tests_dsub
	global auto_work_ram_oe_tests_dsub
	global auto_work_ram_we_tests_dsub
	global manual_work_ram_tests
	global STR_WORK_RAM_TEST_LOOP

	section text

manual_work_ram_tests:
		lea	XY_STR_PASSES,a0
		RSUB	print_xy_string_struct_clear
		lea	XY_STR_D_MAIN_MENU, a0
		RSUB	print_xy_string_struct_clear

		moveq	#DSUB_INIT_PSEUDO, d7		; init dsub for pseudo subroutines
		moveq	#0, d6				; passes

	.loop_run_test:
		WATCHDOG

		moveq	#$e, d0
		moveq	#$e, d1
		move.l	d6, d2
		bclr	#$1f, d2
		PSUB	print_hex_3_bytes

		PSUB	auto_work_ram_data_tests
		tst.b	d0
		bne	.test_failed_abort

		PSUB	auto_work_ram_address_tests
		tst.b	d0
		bne	.test_failed_abort

		addq.l	#1, d6

		btst	#D_BUTTON, REG_P1CNT
		bne	.loop_run_test
		bra	.test_exit

	.test_failed_abort:
		PSUB	print_error

	.loop_d_pressed:
		WATCHDOG
		btst	#D_BUTTON, REG_P1CNT
		bne	.loop_d_pressed

	.test_exit:
		SSA3	fix_clear

		; re-init stuff and return to menu
		move.b	#5, main_menu_cursor
		movea.l	$0, a7				; re-init SP
		moveq	#DSUB_INIT_REAL, d7		; init dsub for real subroutines
		bra	manual_tests

auto_work_ram_oe_tests_dsub:
		lea	WORK_RAM_START, a0
		moveq	#0, d0
		DSUB	check_ram_oe
		tst.b	d0
		bne	.test_failed_upper

		moveq	#1, d0
		DSUB	check_ram_oe
		tst.b	d0
		bne	.test_failed_lower

		moveq	#0, d0
		DSUB_RETURN

	.test_failed_upper:
		moveq	#EC_WRAM_DEAD_OUTPUT_UPPER, d0
		DSUB_RETURN

	.test_failed_lower:
		moveq	#EC_WRAM_DEAD_OUTPUT_LOWER, d0
		DSUB_RETURN

auto_work_ram_we_tests_dsub:
		lea	WORK_RAM_START, a0
		move.w	#$ff, d0
		DSUB	check_ram_we
		tst.b	d0
		beq	.test_passed_lower
		moveq	#EC_WRAM_UNWRITABLE_LOWER, d0
		DSUB_RETURN

	.test_passed_lower:
		lea	WORK_RAM_START, a0
		move.w	#$ff00, d0
		DSUB	check_ram_we
		tst.b	d0
		beq	.test_passed_upper
		moveq	#EC_WRAM_UNWRITABLE_UPPER, d0
		DSUB_RETURN

	.test_passed_upper:
		moveq	#0, d0
		DSUB_RETURN

auto_work_ram_data_tests_dsub:
		lea	WORK_RAM_START, a0
		move.w	#$8000, d0
		DSUB	check_ram_data
		tst.b	d0
		bne	.test_failed
		DSUB_RETURN

	.test_failed:
		subq.b	#1, d0
		add.b	#EC_WRAM_DATA_LOWER, d0
		DSUB_RETURN

auto_work_ram_address_tests_dsub:
		lea	WORK_RAM_START, a0
		moveq	#2, d0
		move.w	#$100, d1
		DSUB	check_ram_address
		tst.b	d0
		beq	.test_passed_a0_a7
		moveq	#EC_WRAM_ADDRESS_A0_A7, d0
		DSUB_RETURN

	.test_passed_a0_a7:
		lea	WORK_RAM_START, a0
		move.w	#$200, d0
		move.w	#$80, d1
		DSUB	check_ram_address
		tst.b	d0
		beq	.test_passed_a8_a14
		moveq	#EC_WRAM_ADDRESS_A8_A14, d0
		DSUB_RETURN

	.test_passed_a8_a14:
		moveq	#0, d0
		DSUB_RETURN

STR_WORK_RAM_TEST_LOOP:		STRING "WORK RAM TEST LOOP"
