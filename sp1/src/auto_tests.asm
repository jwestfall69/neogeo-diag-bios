	include "auto_tests.inc"
	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"

	global auto_psub_tests_dsub
	global auto_func_tests

	section code

; runs automatic tests that are psub based
auto_psub_tests_dsub:

		; d6 will be the only thing that will survive doing auto psub tests
		; so we will use it to store the byte offset into our d_auto_psub_list
		; list
		moveq	#0, d6

	.loop_next_test:
		lea	d_auto_psub_list + s_ae_name_ptr, a0
		move.l	(a0, d6), a0

		cmp.l	#0, a0				; null terminated list
		beq	.all_tests_done

		moveq	#LEFT_MARGIN, d0
		moveq	#5, d1
		DSUB	print_xy_string_clear		; print the test description to screen

		lea	d_auto_psub_list, a2
		move.l	(a2, d6), a2			; test function
		lea	(.dsub_return), a3		; manually do dsub call since the DSUB macro wont
		bra	dsub_enter			; work in this case
	.dsub_return:

		tst.b	d0					; check result
		bne	.test_failed

		addq.w	#s_ae_struct_size, d6
		bra	.loop_next_test

	.test_failed:
		move.b	d0, d6
		DSUB	print_error
		moveq	#0, d0
		move.b	d6, d0

		tst.b	REG_STATUS_B
		bpl	.skip_error_to_credit_leds	; skip if aes
		DSUB	error_to_credit_leds

	.skip_error_to_credit_leds:
		btst	#INPUT_A_BIT, REG_P1CNT		; if "A" held down, do error address
		bne	.skip_error_address
		move.b	d6, d0
		DSUB	error_address

	.skip_error_address:
		bra	loop_reset_check_dsub

	.all_tests_done:
		DSUB_RETURN


; runs automatic tests that are subroutine based
auto_func_tests:

		lea	(d_auto_func_list), a1

	.loop_next_test:
		tst.l	s_ae_function_ptr(a1)		; null terminated
		beq	.all_tests_done

		move.l	s_ae_name_ptr(a1), a0
		moveq	#LEFT_MARGIN, d0
		moveq	#5, d1
		RSUB	print_xy_string_clear		; at 4,5 print test name

		move.l	s_ae_function_ptr(a1), a0

		move.l	a1, -(a7)
		jsr	(a0)
		move.l	(a7)+, a1

		tst.b	d0				; check result
		bne	.test_failed

		addq.l	#s_ae_struct_size, a1
		bra	.loop_next_test

	.test_failed:
		move.w	d0, -(a7)
		RSUB	print_error
		move.w	(a7)+, d0
		move.b	d0, d6

		tst.b	r_z80_test_flags		; if z80 test enabled, send error code to z80
		beq	.skip_error_to_z80
		move.b	d0, REG_SOUND

	.skip_error_to_z80:
		tst.b	REG_STATUS_B
		bpl	.skip_error_to_credit_leds	; skip if aes
		RSUB	error_to_credit_leds

	.skip_error_to_credit_leds:
		btst	#INPUT_A_BIT, REG_P1CNT		; if "A" held down, do error address
		bne	.skip_error_address
		move.b	d6, d0
		DSUB	error_address

	.skip_error_address:
		bra	loop_reset_check

	.all_tests_done:
		rts

	section data
	align 1

d_auto_psub_list:
	AUTO_ENTRY auto_bios_mirror_test_dsub, d_str_testing_bios_mirror
	AUTO_ENTRY auto_bios_crc32_test_dsub, d_str_testing_bios_crc32
	AUTO_ENTRY auto_work_ram_oe_tests_dsub, d_str_testing_work_ram_oe
	AUTO_ENTRY auto_work_ram_we_tests_dsub, d_str_testing_work_ram_we
	AUTO_ENTRY auto_work_ram_data_tests_dsub, d_str_testing_work_ram_data
	AUTO_ENTRY auto_work_ram_address_tests_dsub, d_str_testing_work_ram_address
	AUTO_LIST_END

d_auto_func_list:
	AUTO_ENTRY auto_backup_ram_tests, d_str_testing_backup_ram
	AUTO_ENTRY auto_palette_ram_tests, d_str_testing_palette_ram
	AUTO_ENTRY auto_video_ram_2k_tests, d_str_testing_video_ram_2k
	AUTO_ENTRY auto_video_ram_32k_tests, d_str_testing_video_ram_32k
	AUTO_ENTRY auto_mmio_tests, d_str_testing_mmio
	AUTO_LIST_END

d_str_testing_backup_ram:	STRING "TESTING BACKUP RAM..."
d_str_testing_bios_mirror:	STRING "TESTING BIOS MIRRORING..."
d_str_testing_bios_crc32:	STRING "TESTING BIOS CRC32..."
d_str_testing_mmio:		STRING "TESTING MMIO..."
d_str_testing_palette_ram:	STRING "TESTING PALETTE RAM..."
d_str_testing_video_ram_2k:	STRING "TESTING VIDEO RAM (2K)..."
d_str_testing_video_ram_32k:	STRING "TESTING VIDEO RAM (32K)..."
d_str_testing_work_ram_address:	STRING "TESTING WORK RAM ADDRESS..."
d_str_testing_work_ram_data:	STRING "TESTING WORK RAM DATA..."
d_str_testing_work_ram_oe:	STRING "TESTING WORK RAM /OE..."
d_str_testing_work_ram_we:	STRING "TESTING WORK RAM /WE..."
