	include "diag.inc"
	include "neogeo.inc"
	include "../common/error_codes.inc"
	include "../common/comm.inc"
	include "macros.inc"

	global _start
	global calc_crc32_psub

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
		jp	run_subroutine_tests


sm1_tests:
		; copy the sm1 related test code into ram
		ld	de, Z80_RAM_START
		ld	hl, SM1_TEST_CODE_START
		ld	bc, SM1_TEST_CODE_END - SM1_TEST_CODE_START
		ldir

		; change the PSUB_RETURN at the end of calc_crc32_psub to a ret ($c9) instruction
		; so we can use it as a normal function instead of a psub.
		ld	hl, Z80_RAM_START + (sm1_crc32_test - SM1_TEST_CODE_START) - 1
		ld	(hl), $c9

		jp	Z80_RAM_START

SM1_TEST_CODE_START:
		; request bios switch to sm1 rom
		ld	a, COMM_SM1_TEST_SWITCH_SM1
		out	($00), a
		out	($0c), a

		ld	bc, $3000
	.loop_wait_switch_sm1:
		in	a, ($00)
		cp	COMM_SM1_TEST_SWITCH_SM1_DENY
		jr	z, .switch_sm1_fail
		cp	COMM_SM1_TEST_SWITCH_SM1_DONE
		jr	z, .switch_sm1_done

		dec	bc
		ld	a, c
		or	b
		jr	nz, .loop_wait_switch_sm1

	; switch didn't happen, return no error
	.switch_sm1_fail:
		xor	a
		out	($00), a
		out	($0c), a
		ret

	.switch_sm1_done:
		ld	a, $0
		out	($00), a
		out	($0c), a

		RCALL	sm1_oe_test
		jr	nz, .tests_end
		RCALL	sm1_crc32_test

	.tests_end:
		; backup 'a' and have bios switch back to m1
		ld	b, a

		ld	a, COMM_SM1_TEST_SWITCH_M1
		out	($00), a
		out	($0c), a

	.loop_wait_switch_m1:
		in	a, ($00)
		cp	COMM_SM1_TEST_SWITCH_M1_DONE
		jr	z, .switch_m1_done
		jr	.loop_wait_switch_m1

	.switch_m1_done:
		ld	a, $0
		out	($00), a
		out	($0c), a
		ld	a, b
		and	a
		ret

; params:
;  bc  = start address
;  bc' = length
; returns:
;  bc = upper 16bits of crc32
;  de = lower 16bits of crc32
calc_crc32_psub:
		ld	a, c
		exx
		ld	l, a
		exx
		ld	a, b
		exx
		ld	h, a
		ld	d, b
		ld	e, c
		exx
		ld	de, $ffff
		ld	hl, $ffff

	.loop_outer:
		ld	b, $08
		ld	a, e
		exx
		xor	(hl)
		inc	hl
		exx
		ld	e, a

	.loop_inner:
		srl	h
		rr	l
		rr	d
		rr	e
		jr	nc, .next_loop_inner
		ld 	a, e
		xor	$20
		ld	e, a
		ld	a, d
		xor	$83
		ld	d, a
		ld	a, l
		xor	$b8
		ld	l, a
		ld	a, h
		xor	$ed
		ld	h, a

	.next_loop_inner:
		djnz	.loop_inner
		exx
		dec	de
		ld	a, e
		or	d
		exx
		jr	nz, .loop_outer
		ld	a, e
		cpl
		ld	c, a
		ld	a, d
		cpl
		ld	b, a
		ld	a, l
		cpl
		ld	e, a
		ld	a, h
		cpl
		ld	d, a
		PSUB_RETURN

; The sm1 rom code resides within the first ~$5400 bytes of the rom,
; so we are only doing a crc32 check against those bytes.  Doing the
; entire rom would take an unreasonable amount of time, plus it would
; require adding a bunch of needless complexity doing bank switching
; to access the entire 128KB of the rom.
sm1_crc32_test:
		ld	bc, $0000
		exx
		ld	bc, SM1_CRC32_SIZE
		exx

		RCALL	calc_crc32_psub

		ld	hl, SM1_CRC32_UPPER
		sbc	hl, de
		jr	nz, .test_failed


		ld	hl, SM1_CRC32_LOWER
		sbc	hl, bc
		jr	nz, .test_failed

		xor	a
		ret

	.test_failed:
		ld	a, EC_Z80_SM1_CRC
		or	a
		ret

; output enable test for sm1 rom, mimics ram_oe_test
sm1_oe_test:
		ld	hl, $0000
		ld	de, $0000

		ld	b, $64
	.loop_next:
		ld	a, (hl)
		cp	$7e		; ld a, (hl) opcode
		jr	nz, .loop_pass

		ld	a, (de)
		cp	$1a		; ld a, (de) opcode
		jr	z, .test_failed

	.loop_pass:
		djnz	.loop_next
		xor	a
		ret

	.test_failed:
		ld	a, EC_Z80_SM1_OE
		or	a
		ret

SM1_TEST_CODE_END:

run_subroutine_tests:
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
