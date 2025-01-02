	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"
	include "../common/comm.inc"
	include "../common/error_codes.inc"

	global sm1_tests

	section code

sm1_tests:
		; copy the sm1 test code into ram
		ld	de, SM1_TESTS_RAM_START
		ld	hl, SM1_TEST_CODE_START
		ld	bc, SM1_TEST_CODE_END - SM1_TEST_CODE_START
		ldir

		; copy crc32 code into ram after the sm1 test code
		ld	de, SM1_TESTS_RAM_START + (SM1_TEST_CODE_END - SM1_TEST_CODE_START)
		ld	hl, CRC32_CODE_END
		ld	bc, crc32_psub
		sbc	hl, bc
		ld	b, h
		ld	c, l
		ld	hl, crc32_psub
		ldir

		; change the PSUB_RETURN at the end of crc32_psub to a ret ($c9) instruction
		; so we can use it as a normal function instead of a psub.
		ld	hl, SM1_TESTS_RAM_START + (SM1_TEST_CODE_END - SM1_TEST_CODE_START) - 1
		ld	bc, CRC32_CODE_END
		add	hl, bc
		ld	bc, crc32_psub
		sbc	hl, bc
		ld	(hl), $c9

		jp	SM1_TESTS_RAM_START

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

		RCALL	crc32_jump

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

; vlink/vasm dont seem to like setting up the dynamic call
; that RCALL is providing if the destination function isn't
; in the same source file.  So we are having RCALL call this
; function in ram, which will then calculate the location of
; the crc32 function in ram and jump to it.  When crc32 does
; its ret it will return to the location of the RCALL
crc32_jump:
		ld	hl, SM1_TESTS_RAM_START + (SM1_TEST_CODE_END - SM1_TEST_CODE_START)
		jp	(hl)


SM1_TEST_CODE_END:
