	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"
	include "../common/include/error_codes.inc"

	global rom_bank_tests

	section code

; The first 32k of the m1 rom are used by the compiled code + mirrors.
; The remaining 96k of space is use for bank switching testing.  The
; last 4 bytes of every 2k are filled in with counter data.
; bank3 (16k) counter is at $fff and starts with $02
; bank2 (8k) counter is at $ffe and starts with $04
; bank1 (4k) counter is at $ffd and starts with $08
; bank0 (2k) counter is at $ffc and starts with $10
; In the rom file a banks counter is only increased for each new bank
; of its size,  meaning bank0's counter will increase for every 2k
; chunk, while bank3's counter would only increase every 8 2k chunks.
; The code below checks each possible bank location a bank can have
; within the 96k and makes sure those counters are correct.
rom_bank_tests:
		ld	b, $02			; starting counter number
		ld	c, IO_BANK_16K
		ld	hl, $bfff		; offset within each bank with the counter
		ld	e, $06			; number of banks in the 96k
		call	test_rom_bank
		jr	z, .test_passed_bank_16k
		ld	a, EC_Z80_M1_BANK_ERROR_16K
		rst	RST_HANDLE_Z80_ERROR_CODE

	.test_passed_bank_16k:
		ld	b, $04
		ld	c, IO_BANK_8K
		ld	hl, $dffe
		ld	e, $0c
		call	test_rom_bank
		jr	z, .test_passed_bank_8k
		ld	a, EC_Z80_M1_BANK_ERROR_8K
		rst	RST_HANDLE_Z80_ERROR_CODE

	.test_passed_bank_8k:
		ld	b, $08
		ld	c, IO_BANK_4K
		ld	hl, $effd
		ld	e, $18
		call	test_rom_bank
		jr	z, .test_passed_bank_4k
		ld	a, EC_Z80_M1_BANK_ERROR_4K
		rst	RST_HANDLE_Z80_ERROR_CODE

	.test_passed_bank_4k:
		ld	b, $10
		ld	c, IO_BANK_2K
		ld	hl, $f7fc
		ld	e, $30
		call	test_rom_bank
		jr	z, .test_passed_bank_2k
		ld	a, EC_Z80_M1_BANK_ERROR_2K
		rst	RST_HANDLE_Z80_ERROR_CODE

	.test_passed_bank_2k:
		ret

; tests an individual bank
; params
;  b = start
;  c = bank
;  hl = offset to test against
;  e = number of banks to test
test_rom_bank:
		in	a, (c)
		ld	a, b
		cp	(hl)
		jr	nz, .test_failed_abort
		inc	b
		dec	e
		jr	nz, test_rom_bank
		xor	a
		ret

	.test_failed_abort:
		xor	a
		inc	a
		ret
