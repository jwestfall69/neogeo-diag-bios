	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"
	include "../common/comm.inc"
	include "../common/error_codes.inc"

	global sm1_tests

	section code

; sm1 tests flow is
;  - copy code to ram
;  - jump to that code
;  - have the 68k to switch to sm1
;  - run sm1 tests
;  - have the 68k switch back to the diag m1 rom
;  - jump back to diag m1 rom code
sm1_tests:
		; copy the sm1 test code into ram
		ld	de, SM1_TESTS_RAM_START
		ld	hl, sm1_tests_start
		ld	bc, sm1_tests_end - sm1_tests_start
		ldir

		; copy crc32 code into ram after the sm1 test code
		; couple notes:
		;  - de will already be the correct address from
		;    the previous ldir, so no need to set it up
		;  - bc requires manual calculation because vasm
		;    doesn't seem to do compile time size calculations
		;    if labels aren't in the current source file. ie
		;    this isn't possible
		;      ld bc, crc32_psub_end - crc32_psub
		ld	hl, crc32_psub_end
		ld	bc, crc32_psub
		sbc	hl, bc
		ld	b, h
		ld	c, l
		ld	hl, crc32_psub
		ldir

		; crc32 code ends with a PSUB_RETURN/rst $10 (opcode $d7),
		; which won't work when running from ram.  We need to change
		; it to be a normal ret ($c9).  The above ldir will leave
		; de pointing at the memory address right after that PSUB_RETURN,
		; so we just need to backup 1 address and write the ret opcode.
		dec	de
		ex	de, hl
		ld	(hl), $c9

		jp	SM1_TESTS_RAM_START

sm1_tests_start:
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
		ld	hl, SM1_TESTS_RAM_START + (sm1_tests_end - sm1_tests_start)
		jp	(hl)
sm1_tests_end:
