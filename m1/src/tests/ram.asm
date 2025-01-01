	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"
	include "../common/error_codes.inc"

	global ram_address_tests_psub
	global ram_data_tests_psub
	global ram_oe_test_psub
	global ram_we_test_psub

	section code

; returns:
;  Z = 0 (error), 1 = (pass)
;  a = error code or 0 if passed
ram_oe_test_psub:
		ld	hl, Z80_RAM_START
		ld	de, Z80_RAM_START

	; When ram doesn't output anything on a read it usually results in the target
	; register, 'a' for us, containing the opcode of the ld.  Its not 100% and
	; will sometimes have $ff or other garbage, so we loop $64 times trying to
	; catch 2 in a row with different ld opcodes
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
		PSUB_RETURN

	.test_failed:
		ld	a, EC_Z80_RAM_OE
		or	a
		PSUB_RETURN

; returns:
;  Z = 0 (error), 1 = (pass)
;  a = error code or 0 if passed
ram_we_test_psub:
		ld	hl, Z80_RAM_START

	; read/save a byte from ram, write !byte back to the location,
	; re-read the location and error if it still the original byte
		ld	a, (hl)
		ld	b, a
		xor	$ff
		ld	(hl), a
		ld	a, (hl)
		cp	b
		jr	z, .test_failed

		xor	a
		PSUB_RETURN

	.test_failed:
		ld	a, EC_Z80_RAM_WE
		or	a
		PSUB_RETURN

; returns:
;  Z = 0 (error), 1 = (pass)
;  a = error code or 0 if passed
ram_data_tests_psub:
		ld	c, $00
		PSUB	test_ram_data
		jr	z, .test_passed_00
		ld	a, EC_Z80_RAM_DATA_00
		or	a
		PSUB_RETURN

	.test_passed_00:
		ld	c, $55
		PSUB	test_ram_data
		jr	z, .test_passed_55:
		ld	a, EC_Z80_RAM_DATA_55
		or	a
		PSUB_RETURN

	.test_passed_55:
		ld	c, $aa
		PSUB	test_ram_data
		jr	z, .test_passed_aa:
		ld	a, EC_Z80_RAM_DATA_AA
		or	a
		PSUB_RETURN

	.test_passed_aa:
		ld	c, $ff
		PSUB	test_ram_data
		jr	z, .test_passed_ff
		ld	a, EC_Z80_RAM_DATA_FF
		or	a
		PSUB_RETURN

	.test_passed_ff:
		PSUB_RETURN

; returns:
;  Z = 0 (error), 1 = (pass)
;  a = error code or 0 if passed
ram_address_tests_psub:
		ld	bc, $0001
		PSUB	test_ram_address
		jr	z, .test_passed_a0_a7:
		ld	a, EC_Z80_RAM_ADDRESS_A0_A7
		or	a
		PSUB_RETURN

	.test_passed_a0_a7:
		ld	bc, $0100
		PSUB	test_ram_address
		jr	z, .test_passed_a8_a10
		ld	a, EC_Z80_RAM_ADDRESS_A8_A10
		or	a
		PSUB_RETURN

	.test_passed_a8_a10:
		PSUB_RETURN

; params:
;  c = pattern
; returns:
;  a = 0 (pass), 1 (fail)
;  Z = 1 (pass), 0 (fail)
test_ram_data_psub:
		ld	hl, Z80_RAM_START	; ram start
		ld	a, c

	.loop_next_address:
		ld	(hl), a
		cp	(hl)
		jr	nz, .test_failed_abort
		inc	l
		jr	nz, .loop_next_address
		inc	h
		jr	nz, .loop_next_address
		xor	a
		PSUB_RETURN

	.test_failed_abort:
		xor	a
		inc	a
		PSUB_RETURN

; Write an incrementing data value at incrementing addresses, then
; read them back to verify the data matches
; params:
;  bc = incr address amount per loop
; returns:
;  a = 0 (pass), 1 (fail)
;  Z = 1 (pass), 0 (fail)
test_ram_address_psub:
		ld	d, b
		ld	e, c
		xor	a
		ld	b, a
		ld	hl, Z80_RAM_START

	.loop_next_write_address:
		ld	(hl), a
		inc	a
		add	hl, de
		jr	c, .loop_start_read_address	; loop exits if we hit top of ram
		djnz	.loop_next_write_address	; or 256 iterations

	.loop_start_read_address:
		xor	a
		ld	b, a
		ld	hl, Z80_RAM_START
	.loop_next_read_address:
		cp	(hl)
		jr	nz, .test_failed_abort
		inc	a
		add	hl, de
		jr	c, .test_passed_done
		djnz	.loop_next_read_address

	.test_passed_done:
		xor	a
		PSUB_RETURN

	.test_failed_abort:
		xor	a
		inc	a
		PSUB_RETURN
