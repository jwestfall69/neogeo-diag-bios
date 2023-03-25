	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"
	include "../common/error_codes.inc"

	global manual_p_rom_bus_tests
	global STR_P_ROM_BUS_TESTS

	section text

manual_p_rom_bus_tests:
		lea	XY_STR_SLOT_NUM, a0
		RSUB	print_xy_string_struct_clear

		lea	XY_STR_TESTS_REQUIRE, a0
		RSUB	print_xy_string_struct_clear
		lea	XY_STR_CUSTOM_CART, a0
		RSUB	print_xy_string_struct_clear

		lea	XY_STR_A_C_RUN_TEST, a0
		RSUB	print_xy_string_struct_clear
		lea	XY_STR_D_MAIN_MENU, a0
		RSUB	print_xy_string_struct_clear

		bsr	get_slot_count
		move.b	d0, d6			; max slots
		moveq	#1, d5			; selected slot

	.loop_wait_input_run_tests:
		moveq	#18, d0
		moveq	#8, d1
		move.b	d5, d2
		RSUB	print_digit

		bsr	wait_frame
		bsr	p1p2_input_update

		move.b	p1_input_edge, d0
		btst	#D_BUTTON, d0
		bne	.dont_run_tests

		btst	#LEFT, d0
		beq	.left_not_pressed
		subq.b	#1, d5
		cmp.b	#0, d5
		bne	.loop_wait_input_run_tests
		move.b	d6, d5

	.left_not_pressed:
		btst	#RIGHT, d0
		beq	.right_not_pressed
		addq.b	#1, d5
		cmp.b	d6, d5
		bls	.loop_wait_input_run_tests
		moveq	#1, d5

	.right_not_pressed:
		move.b	p1_input, d0
		and.b	#$50, d0
		cmp.b	#$50, d0		; if A+C pressed, run tests
		beq	.run_tests
		bra	.loop_wait_input_run_tests

	.dont_run_tests:
		rts

	.run_tests:
		; blindy tell SM1 to prepare for slot switch
		; so the cart M1 doesn't run.  This won't work
		; if the user ran the diag m1 rom on boot.
		move.b	#$01, REG_SOUND
		move.l	#$1388, d0
		RSUB	delay

		subq	#1, d5
		move.b	d5, REG_SLOT
		move.b  d5, REG_CRTFIX

	.skip_slot_switch:
		moveq	#8, d0
		SSA3	fix_clear_line
		moveq	#9, d0
		SSA3	fix_clear_line
		moveq	#20, d0
		SSA3	fix_clear_line
		moveq	#21, d0
		SSA3	fix_clear_line
		moveq	#26, d0
		SSA3	fix_clear_line

		lea	XY_STR_PASSES, a0
		RSUB	print_xy_string_struct_clear

		moveq	#0, d6	; passes

	.loop_run_test:
		WATCHDOG

		moveq	#$4, d0
		moveq 	#$e, d0
		moveq 	#$e, d1
		move.l	d6, d2
		bclr	#$1f, d2
		RSUB	print_hex_3_bytes


		bsr	p_rom_oe_tests
		bne	.test_failed_abort

		bsr	p_rom_to_245_oe_tests
		bne	.test_failed_abort

		bsr	p2_rom_we_tests
		bne	.test_failed_abort

		bsr	p2_rom_data_tests
		bne	.test_failed_abort

		bsr	p1_dummy_read

		bsr	p2_rom_address_tests
		bne	.test_failed_abort

		addq.l	#1, d6

		btst	#D_BUTTON, REG_P1CNT
		bne	.loop_run_test
		bra 	.test_exit

	.test_exit:
		move.b	d0, REG_BRDFIX
		SSA3	fix_clear
		rts

	.test_failed_abort:
		RSUB	print_error
		move.b	d0, REG_BRDFIX

	.loop_wait_input_return_menu:
		WATCHDOG
		btst	#D_BUTTON, REG_P1CNT
		bne	.loop_wait_input_return_menu
		rts

; Some 1 slot boards have their p roms directly connected
; to the CPU while others (and multislot boards) are
; connected via some ic (245/NEO-G0/NEO-BUF).  These test
; are checking for output from whatever is directly connect
; to the CPU
p_rom_oe_tests:
		lea	P1_ROM_START+$200, a0
		moveq	#1, d0
		RSUB	check_ram_oe
		tst.b	d0
		beq	.test_passed_p1_lower
		move.b	#EC_P1_245_DEAD_OUTPUT_UPPER, d0
		rts

	.test_passed_p1_lower:
		lea	P1_ROM_START+$200, a0
		moveq	#0, d0
		RSUB	check_ram_oe
		tst.b	d0
		beq	.test_passed_p1_upper
		move.b	#EC_P1_245_DEAD_OUTPUT_LOWER, d0
		rts

	.test_passed_p1_upper:
		lea	P2_ROM_START, a0
		moveq	#1, d0
		RSUB	check_ram_oe
		tst.b	d0
		beq	.test_passed_p2_lower
		move.b	#EC_P2_245_DEAD_OUTPUT_LOWER, d0
		rts

	.test_passed_p2_lower:
		lea	P2_ROM_START, a0
		moveq	#0, d0
		RSUB	check_ram_oe
		tst.b	d0
		beq	.test_passed_p2_upper
		move.b	#EC_P2_245_DEAD_OUTPUT_UPPER, d0
		rts

	.test_passed_p2_upper:
		moveq	#0, d0
		rts


; These tests are For boards that have an ic (245/NEO-G0/NEO-BUF)
; between the px roms and the CPU.  It attempts to detect when
; the px roms don't output anything to the ic
p_rom_to_245_oe_tests:
		lea	P1_ROM_START + $200, a0
		move.w	#$ff, d0
		RSUB	check_ram_to_245_oe
		tst.b	d0
		beq	.test_passed_p1_lower
		move.b	#EC_P1_DEAD_OUTPUT_LOWER, d0
		rts

	.test_passed_p1_lower:
		lea	P1_ROM_START + $200, a0
		move.w	#$ff00, d0
		RSUB	check_ram_to_245_oe
		tst.b	d0
		beq	.test_passed_p1_upper
		move.b	#EC_P1_DEAD_OUTPUT_UPPER, d0
		rts

	.test_passed_p1_upper:
		lea	P2_ROM_START, a0
		move.w	#$ff, d0
		RSUB	check_ram_to_245_oe
		tst.b	d0
		beq	.test_passed_p2_lower
		move.b	#EC_P1_DEAD_OUTPUT_LOWER, d0
		rts

	.test_passed_p2_lower:
		lea	P2_ROM_START, a0
		move.w	#$ff00, d0
		RSUB	check_ram_to_245_oe
		tst.b	d0
		beq	.test_passed_p2_upper
		move.b	#EC_P1_DEAD_OUTPUT_UPPER, d0
		rts

	.test_passed_p2_upper:
		moveq	#0, d0
		rts

; only p2 region is writable.  Games use writes to
; trigger bank switching
p2_rom_we_tests:
		lea	P2_ROM_START, a0
		bsr	check_p2_rom_we
		tst.b	d0
		beq	.test_passed_p2_lower
		move.b	#EC_P2_UNWRITABLE_LOWER, d0
		rts

	.test_passed_p2_lower:
		lea	P2_ROM_START+1, a0
		bsr	check_p2_rom_we
		tst.b	d0
		beq	.test_passed_p2_upper
		move.b	#EC_P2_UNWRITABLE_UPPER, d0
		rts

	.test_passed_p2_upper:
		moveq	#0, d0
		rts

; The bulk of the tests are just using the p2 address
; space so the ROMOE is barely getting enabled.  This
; function is just doing some dummy reads of p1 address
; space so that ROMOE is enabled enough that the ROMOE
; LED lights up on the custom prog board.
p1_dummy_read:
		lea	P1_ROM_START+$200, a0
		move.w	#$1fff, d0

	.loop_next_address:
		move.w	(a0)+, d1
		dbra	d0, .loop_next_address
		rts

; p1/p2 share the same data lines so we only need to test
; p2.  Additionally the goal here isnt to verify the sram
; chip on the custom cart is working, just that data lines
; are working.  So we just going to test the first 0x200 bytes
; for issues
p2_rom_data_tests:

		lea	P2_ROM_START, a0
		move.w	#$200, d0
		RSUB	check_ram_data
		tst.b	d0
		bne	.test_failed

		moveq	#0, d0
		rts

	.test_failed:
		move.b	#EC_P_DATA_BUS, d0
		rts

; p1/p2 share the same address lines so we only need to test
; p2.  Write an incrementing value at each data line, then
; read them back checking for any differences
p2_rom_address_tests:

		moveq	#19, d0		; address lines / loops
		moveq	#0, d2		; counter
		moveq	#1, d3		; address line offset

		lea	P2_ROM_START, a0

	.loop_write_next_address:
		add.w	#$101, d2
		move	d2, (a0)
		lsl.l	#1, d3
		lea	P2_ROM_START, a0
		adda.l	d3, a0
		dbra	d0, .loop_write_next_address


		moveq	#19, d0		; address lines / loops
		moveq	#0, d2		; counter
		moveq	#1, d3		; address line offset

		lea	P2_ROM_START, a0
	.loop_read_next_address:
		add.w	#$101, d2	; expected value
		move	(a0), d4	; actual value
		cmp.w	d2, d4
		bne	.test_failed

		lsl.l	#1, d3
		lea	P2_ROM_START, a0
		adda.l	d3, a0
		dbra	d0, .loop_read_next_address

		moveq	#0, d0
		rts

	.test_failed:
		move.w	d2, d1
		move.w	d4, d2
		move.b	#EC_P_ADDRESS_BUS, d0
		rts


; We cant use the normal check_ram_we because it writes data
; as words, but we need them written as bytes.  The PORTWEL
; and PORTWEU lines on cart slot dictate if the upper/lower
; byte should be written.  However the sram chip on the custom
; cart has a single WE pin, requiring that we use an AND gate
; on PORTWEL/PORTWEU.  Thus the only way to isolate
; PORTWE/PORTWEU to by doing byte writes.
check_p2_rom_we:
		move.b	(a0), d0		; read byte
		move.b	d0, d1
		eor.b	#-1, d1
		move.b	d1, (a0)		; write opposite back
		move.b	(a0), d1
		cmp.b	d0, d1			; compare with orginal read byte
		bne	.test_passed
		moveq	#-1, d0
		rts

	.test_passed:
		moveq	#0, d0
		rts

STR_P_ROM_BUS_TESTS:		STRING "P ROM BUS TESTS (CUSTOM CART)"

XY_STR_SLOT_NUM:		XY_STRING  4,  8, "SLOT NUMBER: "
XY_STR_TESTS_REQUIRE:		XY_STRING  4, 20, "THESE TESTS REQUIRE A"
XY_STR_CUSTOM_CART:		XY_STRING  5, 21, "CUSTOM CART TO WORK"
XY_STR_A_C_RUN_TEST:		XY_STRING  4, 26, "A+C: Run Test"
