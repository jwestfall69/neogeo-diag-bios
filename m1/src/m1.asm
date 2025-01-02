	include "diag.inc"
	include "neogeo.inc"
	include "../common/error_codes.inc"
	include "../common/comm.inc"
	include "macros.inc"

	global _start

	section code

_start:
		di
		im	1
		out	($18), a

		PSUB	ym2610_make_noise

		PSUB	rom_mirror_test
		jr	z, .test_passed_rom_mirror
		rst	RST_HANDLE_Z80_ERROR_CODE

	.test_passed_rom_mirror:
		PSUB	rom_crc32_test
		jr	z, .test_passed_rom_crc32
		rst	RST_HANDLE_Z80_ERROR_CODE

	.test_passed_rom_crc32:
		PSUB	ram_oe_test
		jr	z, .test_passed_ram_oe
		rst	RST_HANDLE_Z80_ERROR_CODE

	.test_passed_ram_oe:
		PSUB	ram_we_test
		jr	z, .test_passed_ram_we
		rst	RST_HANDLE_Z80_ERROR_CODE

	.test_passed_ram_we:
		PSUB	ram_data_tests
		jr	z, .test_passed_ram_data
		rst	RST_HANDLE_Z80_ERROR_CODE

	.test_passed_ram_data:
		PSUB	ram_address_tests
		jr	z, .test_passed_ram_address
		rst	RST_HANDLE_Z80_ERROR_CODE

	.test_passed_ram_address:
		PSUB	ym2610_io_tests
		jr	z, .test_passed_ym2610_io
		rst	RST_HANDLE_Z80_ERROR_CODE

	.test_passed_ym2610_io:
		PSUB	comm_test
		jr	z, .test_passed_comm_test
		rst	RST_HANDLE_Z80_ERROR_CODE

	.test_passed_comm_test:
	; onto normal function based tests

		ld	sp, $fffd	; init stack pointer
		call	ym2610_stuck_irq_test

		call	ym2610_timer_flag_test
		jr	z, .test_passed_ym2610_timer_flag_test
		rst	RST_HANDLE_Z80_ERROR_CODE

	.test_passed_ym2610_timer_flag_test:
		call 	ym2610_timer_irq_test
		jr	z, .test_passed_ym2610_timer_irq_test
		rst	RST_HANDLE_Z80_ERROR_CODE

	.test_passed_ym2610_timer_irq_test:
		call	rom_bank_tests			; will call play_z80_error_code_stall itself
		call	sm1_tests
		jr	z, .test_passed_sm1_tests
		rst	RST_HANDLE_Z80_ERROR_CODE

	.test_passed_sm1_tests:
		PSUB	ym2610_make_noise

		ld	a, COMM_Z80_TESTS_COMPLETE	; tell 68k we are done with tests
		out	($0c), a

	.loop_wait_68k_error_code:
		in	a, ($00)
		and	a
		jr	z, .loop_wait_68k_error_code
		ld	c, a
		in	a, ($00)
		cp	c
		jr	nz, .loop_wait_68k_error_code
		jp	handle_68k_error_code
