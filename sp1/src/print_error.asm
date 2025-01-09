	include "neogeo.inc"
	include "macros.inc"
	include "print_error.inc"
	include "diag.inc"
	include "../common/error_codes.inc"

	global d_ec_list

	global error_code_lookup_dsub
	global print_error_dsub
	global print_error_z80

	section code

; figure out error description and print error dsub
; params:
;  d0 = error code
;  d1 = error data
;  d2 = error data
;  a0 = error data
; returns
;  a1 = error code description
;  a2 = print error dsub
;  d0-d2, a0 are unmodified
error_code_lookup_dsub:

		lea	(d_ec_list), a1
	.loop_ec_next_entry:
		cmp.b	s_ee_error_code(a1), d0
		beq	.ec_found

		addq.l	#s_ee_struct_size, a1
		tst.b	s_ee_error_code(a1)	; list is null terminated
		bne	.loop_ec_next_entry

		; error code not found
		lea	print_error_invalid_dsub, a2
		lea	d_str_invalid_error_code, a1
		move.b	#PRINT_ERROR_INVALID, d1
		bra	.not_found

	.ec_found:
		move.b	s_ee_print_error_id(a1), d4
		movea.l	s_ee_description_ptr(a1), a1
		and.w	#$ff, d4

		lea	(d_ec_print_list), a2
	.loop_pe_next_entry:
		cmp.w	s_pe_print_error_id(a2), d4
		beq	.pe_found

		addq.l	#s_pe_struct_size, a2
		tst.w	s_pe_print_error_id(a2)	; list is null terminated
		bne	.loop_pe_next_entry

		; no print function was found
		lea	print_error_invalid_dsub, a2
		move.b	d4, d1
		bra	.not_found

	.pe_found:
		movea.l	s_pe_function_ptr(a2), a2

	.not_found:
		DSUB_RETURN

; lookup/print error
print_error_dsub:
		DSUB	error_code_lookup
		jmp	(a2)

; prints error for bad bios crc32
; params:
;  d0 = error code
;  d1 = actual value
;  a1 = error description
print_error_bios_crc32_dsub:
		move.l	d1, d2
		moveq	#14, d0
		moveq	#10, d1
		DSUB	print_hex_long

		moveq	#14, d0
		moveq	#12, d1
		move.l	BIOS_CRC32_ADDR, d2
		DSUB	print_hex_long

		lea	d_xys_expected, a0
		DSUB	print_xys_string

		lea	d_xys_actual, a0
		DSUB	print_xys_string

		movea.l	a1, a0
		moveq	#LEFT_MARGIN, d0
		moveq	#5, d1
		jmp	print_xy_string_clear_dsub	; error description and DSUB_RETURN

; print error for generic hex byte
; params:
;  d0 = error code
;  d1 = actual value
;  d2 = expected value
;  a1 = error description
print_error_hex_byte_dsub:
		move.b	d2, d3
		move.b	d1, d2

		moveq	#14, d0
		moveq	#10, d1
		DSUB	print_hex_byte

		move.b	d3, d2
		moveq	#14, d0
		moveq	#12, d1
		DSUB	print_hex_byte

		lea	d_xys_expected, a0
		DSUB	print_xys_string

		lea	d_xys_actual, a0
		DSUB	print_xys_string

		movea.l	a1, a0
		moveq	#LEFT_MARGIN, d0
		moveq	#5, d1
		jmp	print_xy_string_clear_dsub	; error description and DSUB_RETURN

; prints actual/expected data for a memory address
; params:
;  d0 = error code
;  d1 = expected data
;  d2 = actual data
;  a0 = address location
;  a1 = error description
print_error_memory_dsub:
		move.w	d1, d3
		move.w	d2, d4

		moveq	#14, d0
		moveq	#8, d1
		move.l	a0, d2
		DSUB	print_hex_3_bytes		; address

		moveq	#14, d0
		moveq	#12, d1
		move.w	d3, d2
		DSUB	print_hex_word			; expected

		moveq	#14, d0
		moveq	#10, d1
		move.w	d4, d2
		DSUB	print_hex_word			; actual

		lea	d_xys_address, a0
		DSUB	print_xys_string

		lea	d_xys_expected, a0
		DSUB	print_xys_string

		lea	d_xys_actual, a0
		DSUB	print_xys_string

		movea.l	a1, a0
		moveq	#LEFT_MARGIN, d0
		moveq	#5, d1
		jmp	print_xy_string_clear_dsub	; error description and DSUB_RETURN

; print error for mmio
; params:
;  a0 = mmio address
;  a1 = error description
print_error_mmio_dsub:
		move.l	a0, d3
		moveq	#13, d0
		moveq	#8, d1
		move.l	a0, d2
		DSUB	print_hex_3_bytes

		lea	d_xys_address, a0
		DSUB	print_xys_string

		lea	d_ec_mmio_list, a0
	.loop_next_entry:
		cmp.l	s_em_register(a0), d3
		beq	.reg_found

		addq.l	#s_em_struct_size, a0
		tst.l	(a0)			; null terminated
		bne	.loop_next_entry

		; fall back on just printing the description
		bra	.not_found

	.reg_found:
		movea.l	s_em_description_xys_list_ptr(a0), a0
		DSUB	print_xys_string_clear_list

	.not_found:
		movea.l	a1, a0
		moveq	#LEFT_MARGIN, d0
		moveq	#5, d1
		jmp	print_xy_string_clear_dsub

; prints just the error description
; params:
;  a1 = error description
print_error_string_dsub:
		movea.l	a1, a0
		moveq	#LEFT_MARGIN, d0
		moveq	#5, d1
		jmp	print_xy_string_clear_dsub		; error description and DSUB_RETURN

; called if there was an error looking up the
; error code or its print function
; params:
;  d0 = error code
;  d1 = print dsub id
print_error_invalid_dsub:
		move.b	d0, d3				; print dsub id
		move.b	d1, d4				; error code

		moveq	#9, d0
		moveq	#5, d1
		lea	d_str_invalid_error, a0
		DSUB	print_xy_string_clear

		moveq	#LEFT_MARGIN, d0
		moveq	#6, d1
		lea	d_str_error_code, a0
		DSUB	print_xy_string_clear

		moveq	#LEFT_MARGIN, d0
		move	#7, d1
		lea	d_str_print_function, a0
		DSUB	print_xy_string_clear

		move.b	d3, d2
		moveq	#24, d0
		moveq	#6, d1
		DSUB	print_hex_byte				; error code

		move.b	d4, d2
		moveq	#24, d0
		moveq	#7, d1
		jmp	print_hex_byte_dsub			; print dsub id

; print function for all error codes from z80
; params:
;  d0 = error code
;  a1 = error description
print_error_z80:
		move.b	d0, d2
		moveq	#29, d0
		moveq	#12, d1
		RSUB	print_hex_byte

		lea	d_xys_z80_error_code, a0
		RSUB	print_xys_string

		movea.l	a1, a0
		moveq	#LEFT_MARGIN, d0
		moveq	#14, d1
		RSUB	print_xy_string

		moveq	#21, d0
		SSA3	fix_clear_line
		moveq	#22, d0
		SSA3	fix_clear_line
		rts

	section data
	align 1

d_ec_print_list:
	EC_PRINT_ENTRY PRINT_ERROR_BIOS_CRC32, print_error_bios_crc32_dsub
	EC_PRINT_ENTRY PRINT_ERROR_HEX_BYTE, print_error_hex_byte_dsub
	EC_PRINT_ENTRY PRINT_ERROR_MEMORY, print_error_memory_dsub
	EC_PRINT_ENTRY PRINT_ERROR_MMIO, print_error_mmio_dsub
	EC_PRINT_ENTRY PRINT_ERROR_STRING, print_error_string_dsub
	EC_PRINT_LIST_END

d_ec_list:
	; The code for handling errors from the z80 does not use the print function
	; provided by ec_lookup, but will instead directly call print_error_z80.
	; This allows handling a bad error code from the z80 differently then the 68k.
	; If the 68k somehow ended up with a z80 error code it will cause the
	; PRINT_ERROR_INVALID function to be called
	EC_ENTRY EC_Z80_M1_CRC, PRINT_ERROR_INVALID, d_str_z80_m1_crc
	EC_ENTRY EC_Z80_M1_UPPER_ADDRESS, PRINT_ERROR_INVALID, d_str_z80_m1_upper_address
	EC_ENTRY EC_Z80_RAM_DATA_00, PRINT_ERROR_INVALID, d_str_z80_ram_data_00
	EC_ENTRY EC_Z80_RAM_DATA_55, PRINT_ERROR_INVALID, d_str_z80_ram_data_55
	EC_ENTRY EC_Z80_RAM_DATA_AA, PRINT_ERROR_INVALID, d_str_z80_ram_data_aa
	EC_ENTRY EC_Z80_RAM_DATA_FF, PRINT_ERROR_INVALID, d_str_z80_ram_data_ff
	EC_ENTRY EC_Z80_RAM_ADDRESS_A0_A7, PRINT_ERROR_INVALID, d_str_z80_ram_address_a0_a7
	EC_ENTRY EC_Z80_RAM_ADDRESS_A8_A10, PRINT_ERROR_INVALID, d_str_z80_ram_address_a8_a10
	EC_ENTRY EC_Z80_RAM_OE, PRINT_ERROR_INVALID, d_str_z80_ram_oe
	EC_ENTRY EC_Z80_RAM_WE, PRINT_ERROR_INVALID, d_str_z80_ram_we
	EC_ENTRY EC_Z80_68K_COMM_NO_HANDSHAKE, PRINT_ERROR_INVALID, d_str_z80_68k_comm_no_handshake
	EC_ENTRY EC_Z80_68K_COMM_NO_CLEAR, PRINT_ERROR_INVALID, d_str_z80_68k_comm_no_clear
	EC_ENTRY EC_Z80_SM1_OE, PRINT_ERROR_INVALID, d_str_z80_sm1_oe
	EC_ENTRY EC_Z80_SM1_CRC, PRINT_ERROR_INVALID, d_str_z80_sm1_crc
	EC_ENTRY EC_YM2610_IO_ERROR, PRINT_ERROR_INVALID, d_str_ym2610_io_error
	EC_ENTRY EC_YM2610_TIMER_TIMING_FLAG, PRINT_ERROR_INVALID, d_str_ym2610_timer_timing_flag
	EC_ENTRY EC_YM2610_TIMER_TIMING_IRQ, PRINT_ERROR_INVALID, d_str_ym2610_timer_timing_irq
	EC_ENTRY EC_YM2610_IRQ_UNEXPECTED, PRINT_ERROR_INVALID, d_str_ym2610_irq_unexpected
	EC_ENTRY EC_YM2610_TIMER_INIT_FLAG, PRINT_ERROR_INVALID, d_str_ym2610_timer_init_flag
	EC_ENTRY EC_YM2610_TIMER_INIT_IRQ, PRINT_ERROR_INVALID, d_str_ym2610_timer_init_irq
	EC_ENTRY EC_Z80_M1_BANK_ERROR_16K, PRINT_ERROR_INVALID, d_str_z80_m1_bank_error_16k
	EC_ENTRY EC_Z80_M1_BANK_ERROR_8K, PRINT_ERROR_INVALID, d_str_z80_m1_bank_error_8k
	EC_ENTRY EC_Z80_M1_BANK_ERROR_4K, PRINT_ERROR_INVALID, d_str_z80_m1_bank_error_4k
	EC_ENTRY EC_Z80_M1_BANK_ERROR_2K, PRINT_ERROR_INVALID, d_str_z80_m1_bank_error_2k
	EC_ENTRY EC_BIOS_MIRROR, PRINT_ERROR_HEX_BYTE, d_str_bios_mirror
	EC_ENTRY EC_BIOS_CRC32, PRINT_ERROR_BIOS_CRC32, d_str_bios_crc32
	EC_ENTRY EC_WRAM_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING, d_str_wram_dead_output_lower
	EC_ENTRY EC_WRAM_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING, d_str_wram_dead_output_upper
	EC_ENTRY EC_BRAM_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING, d_str_bram_dead_output_lower
	EC_ENTRY EC_BRAM_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING, d_str_bram_dead_output_upper
	EC_ENTRY EC_WRAM_UNWRITABLE_LOWER, PRINT_ERROR_STRING, d_str_wram_unwritable_lower
	EC_ENTRY EC_WRAM_UNWRITABLE_UPPER, PRINT_ERROR_STRING, d_str_wram_unwritable_upper
	EC_ENTRY EC_BRAM_UNWRITABLE_LOWER, PRINT_ERROR_STRING, d_str_bram_unwritable_lower
	EC_ENTRY EC_BRAM_UNWRITABLE_UPPER, PRINT_ERROR_STRING, d_str_bram_unwritable_upper
	EC_ENTRY EC_WRAM_DATA_LOWER, PRINT_ERROR_MEMORY, d_str_wram_data_lower
	EC_ENTRY EC_WRAM_DATA_UPPER, PRINT_ERROR_MEMORY, d_str_wram_data_upper
	EC_ENTRY EC_WRAM_DATA_BOTH, PRINT_ERROR_MEMORY, d_str_wram_data_both
	EC_ENTRY EC_BRAM_DATA_LOWER, PRINT_ERROR_MEMORY, d_str_bram_data_lower
	EC_ENTRY EC_BRAM_DATA_UPPER, PRINT_ERROR_MEMORY, d_str_bram_data_upper
	EC_ENTRY EC_BRAM_DATA_BOTH, PRINT_ERROR_MEMORY, d_str_bram_data_both
	EC_ENTRY EC_WRAM_ADDRESS_A0_A7, PRINT_ERROR_MEMORY, d_str_wram_address_a0_a7
	EC_ENTRY EC_WRAM_ADDRESS_A8_A14, PRINT_ERROR_MEMORY, d_str_wram_address_a8_a14
	EC_ENTRY EC_BRAM_ADDRESS_A0_A7, PRINT_ERROR_MEMORY, d_str_bram_address_a0_a7
	EC_ENTRY EC_BRAM_ADDRESS_A8_A14, PRINT_ERROR_MEMORY, d_str_bram_address_a8_a14
	EC_ENTRY EC_PAL_245_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING, d_str_pal_245_dead_output_lower
	EC_ENTRY EC_PAL_245_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING, d_str_pal_245_dead_output_upper
	EC_ENTRY EC_PAL_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING, d_str_pal_dead_output_lower
	EC_ENTRY EC_PAL_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING, d_str_pal_dead_output_upper
	EC_ENTRY EC_PAL_UNWRITABLE_LOWER, PRINT_ERROR_STRING, d_str_pal_unwritable_lower
	EC_ENTRY EC_PAL_UNWRITABLE_UPPER, PRINT_ERROR_STRING, d_str_pal_unwritable_upper
	EC_ENTRY EC_PAL_BANK0_DATA_LOWER, PRINT_ERROR_MEMORY, d_str_pal_bank0_data_lower
	EC_ENTRY EC_PAL_BANK0_DATA_UPPER, PRINT_ERROR_MEMORY, d_str_pal_bank0_data_upper
	EC_ENTRY EC_PAL_BANK0_DATA_BOTH, PRINT_ERROR_MEMORY, d_str_pal_bank0_data_both
	EC_ENTRY EC_PAL_BANK1_DATA_LOWER, PRINT_ERROR_MEMORY, d_str_pal_bank1_data_lower
	EC_ENTRY EC_PAL_BANK1_DATA_UPPER, PRINT_ERROR_MEMORY, d_str_pal_bank1_data_upper
	EC_ENTRY EC_PAL_BANK1_DATA_BOTH, PRINT_ERROR_MEMORY, d_str_pal_bank1_data_both
	EC_ENTRY EC_PAL_ADDRESS_A0_A7, PRINT_ERROR_MEMORY, d_str_pal_address_a0_a7
	EC_ENTRY EC_PAL_ADDRESS_A0_A12, PRINT_ERROR_MEMORY, d_str_pal_address_a0_a12
	EC_ENTRY EC_VRAM_32K_DATA_LOWER, PRINT_ERROR_MEMORY, d_str_vram_32k_data_lower
	EC_ENTRY EC_VRAM_32K_DATA_UPPER, PRINT_ERROR_MEMORY, d_str_vram_32k_data_upper
	EC_ENTRY EC_VRAM_32K_DATA_BOTH, PRINT_ERROR_MEMORY, d_str_vram_32k_data_both
	EC_ENTRY EC_VRAM_2K_DATA_LOWER, PRINT_ERROR_MEMORY, d_str_vram_2k_data_lower
	EC_ENTRY EC_VRAM_2K_DATA_UPPER, PRINT_ERROR_MEMORY, d_str_vram_2k_data_upper
	EC_ENTRY EC_VRAM_2K_DATA_BOTH, PRINT_ERROR_MEMORY, d_str_vram_2k_data_both
	EC_ENTRY EC_VRAM_32K_ADDRESS_A0_A7, PRINT_ERROR_MEMORY, d_str_vram_32k_address_a0_a7
	EC_ENTRY EC_VRAM_32K_ADDRESS_A8_A14, PRINT_ERROR_MEMORY, d_str_vram_32k_address_a8_a14
	EC_ENTRY EC_VRAM_2K_ADDRESS_A0_A7, PRINT_ERROR_MEMORY, d_str_vram_2k_address_a0_a7
	EC_ENTRY EC_VRAM_2K_ADDRESS_A8_A10, PRINT_ERROR_MEMORY, d_str_vram_2k_address_a8_a10
	EC_ENTRY EC_VRAM_32K_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING, d_str_vram_32k_dead_output_lower
	EC_ENTRY EC_VRAM_32K_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING, d_str_vram_32k_dead_output_upper
	EC_ENTRY EC_VRAM_2K_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING, d_str_vram_2k_dead_output_lower
	EC_ENTRY EC_VRAM_2K_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING, d_str_vram_2k_dead_output_upper
	EC_ENTRY EC_VRAM_32K_UNWRITABLE_LOWER, PRINT_ERROR_STRING, d_str_vram_32k_unwritable_lower
	EC_ENTRY EC_VRAM_32K_UNWRITABLE_UPPER, PRINT_ERROR_STRING, d_str_vram_32k_unwritable_upper
	EC_ENTRY EC_VRAM_2K_UNWRITABLE_LOWER, PRINT_ERROR_STRING, d_str_vram_2k_unwritable_lower
	EC_ENTRY EC_VRAM_2K_UNWRITABLE_UPPER, PRINT_ERROR_STRING, d_str_vram_2k_unwritable_upper
	EC_ENTRY EC_MMIO_DEAD_OUTPUT, PRINT_ERROR_MMIO, d_str_mmio_dead_output
	EC_ENTRY EC_MC_245_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING, d_str_mc_245_dead_output_lower
	EC_ENTRY EC_MC_245_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING, d_str_mc_245_dead_output_upper
	EC_ENTRY EC_MC_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING, d_str_mc_dead_output_lower
	EC_ENTRY EC_MC_UNWRITABLE_LOWER, PRINT_ERROR_STRING, d_str_mc_unwritable_lower
	EC_ENTRY EC_MC_UNWRITABLE_UPPER, PRINT_ERROR_STRING, d_str_mc_unwritable_upper
	EC_ENTRY EC_MC_DATA, PRINT_ERROR_MEMORY, d_str_mc_data
	EC_ENTRY EC_MC_ADDRESS, PRINT_ERROR_MEMORY, d_str_mc_address
	EC_ENTRY EC_P1_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING, d_str_p1_dead_output_lower
	EC_ENTRY EC_P1_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING, d_str_p1_dead_output_upper
	EC_ENTRY EC_P2_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING, d_str_p2_dead_output_lower
	EC_ENTRY EC_P2_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING, d_str_p2_dead_output_upper
	EC_ENTRY EC_P1_245_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING, d_str_p1_245_dead_output_lower
	EC_ENTRY EC_P1_245_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING, d_str_p1_245_dead_output_upper
	EC_ENTRY EC_P2_245_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING, d_str_p2_245_dead_output_lower
	EC_ENTRY EC_P2_245_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING, d_str_p2_245_dead_output_upper
	EC_ENTRY EC_P2_UNWRITABLE_LOWER, PRINT_ERROR_STRING, d_str_p2_unwritable_lower
	EC_ENTRY EC_P2_UNWRITABLE_UPPER, PRINT_ERROR_STRING, d_str_p2_unwritable_upper
	EC_ENTRY EC_PROG_DATA_BUS, PRINT_ERROR_MEMORY, d_str_prog_data_bus
	EC_ENTRY EC_PROG_ADDRESS_BUS, PRINT_ERROR_MEMORY, d_str_prog_address_bus
	EC_LIST_END

d_str_invalid_error_code:		STRING "INVALID ERROR CODE"
d_str_invalid_error:			STRING "INVALID ERROR"
d_str_error_code:			STRING "ERROR CODE:"
d_str_print_function:			STRING "PRINT FUNCTION: "

d_str_z80_m1_crc:			STRING "M1 CRC ERROR (fixed region)"
d_str_z80_m1_upper_address:		STRING "M1 UPPER ADDRESS (fixed region)"
d_str_z80_ram_data_00:			STRING "RAM DATA (00)"
d_str_z80_ram_data_55:			STRING "RAM DATA (55)"
d_str_z80_ram_data_aa:			STRING "RAM DATA (AA)"
d_str_z80_ram_data_ff:			STRING "RAM DATA (FF)"
d_str_z80_ram_address_a0_a7:		STRING "RAM ADDRESS (A0-A7)"
d_str_z80_ram_address_a8_a10:		STRING "RAM ADDRESS (A8-A10)"
d_str_z80_ram_oe:			STRING "RAM DEAD OUTPUT"
d_str_z80_ram_we:			STRING "RAM UNWRITABLE"
d_str_z80_68k_comm_no_handshake:	STRING "68K->Z80 COMM ISSUE (HANDSHAKE)"
d_str_z80_68k_comm_no_clear:		STRING "68K->Z80 COMM ISSUE (CLEAR)"
d_str_z80_sm1_oe:			STRING "SM1 DEAD OUTPUT"
d_str_z80_sm1_crc:			STRING "SM1 CRC ERROR"

d_xys_z80_error_code:			XY_STRING LEFT_MARGIN, 12, "Z80 REPORTED ERROR CODE: "

d_str_ym2610_io_error:			STRING "YM2610 I/O ERROR"
d_str_ym2610_timer_timing_flag:		STRING "YM2610 TIMER TIMING (FLAG)"
d_str_ym2610_timer_timing_irq:		STRING "YM2610 TIMER TIMING (IRQ)"
d_str_ym2610_irq_unexpected:		STRING "YM2610 UNEXPECTED IRQ"
d_str_ym2610_timer_init_flag:		STRING "YM2610 TIMER INIT (FLAG)"
d_str_ym2610_timer_init_irq:		STRING "YM2610 TIMER INIT (IRQ)"

d_str_z80_m1_bank_error_16k:		STRING "M1 BANK ERROR (16K)"
d_str_z80_m1_bank_error_8k:		STRING "M1 BANK ERROR (8K)"
d_str_z80_m1_bank_error_4k:		STRING "M1 BANK ERROR (4K)"
d_str_z80_m1_bank_error_2k:		STRING "M1 BANK ERROR (2K)"

d_str_bios_mirror:			STRING "BIOS ADDRESS (A14-A15)"
d_str_bios_crc32:			STRING "BIOS CRC ERROR"

d_str_wram_dead_output_lower:		STRING "WRAM DEAD OUTPUT (LOWER)"
d_str_wram_dead_output_upper:		STRING "WRAM DEAD OUTPUT (UPPER)"
d_str_bram_dead_output_lower:		STRING "BRAM DEAD OUTPUT (LOWER)"
d_str_bram_dead_output_upper:		STRING "BRAM DEAD OUTPUT (UPPER)"

d_str_wram_unwritable_lower:		STRING "WRAM UNWRITABLE (LOWER)"
d_str_wram_unwritable_upper:		STRING "WRAM UNWRITABLE (UPPER)"
d_str_bram_unwritable_lower:		STRING "BRAM UNWRITABLE (LOWER)"
d_str_bram_unwritable_upper:		STRING "BRAM UNWRITABLE (UPPER)"

d_str_wram_data_lower:			STRING "WRAM DATA (LOWER)"
d_str_wram_data_upper:			STRING "WRAM DATA (UPPER)"
d_str_wram_data_both:			STRING "WRAM DATA (BOTH)"

d_str_bram_data_lower:			STRING "BRAM DATA (LOWER)"
d_str_bram_data_upper:			STRING "BRAM DATA (UPPER)"
d_str_bram_data_both:			STRING "BRAM DATA (BOTH)"

d_str_wram_address_a0_a7:		STRING "WRAM ADDRESS (A0-A7)"
d_str_wram_address_a8_a14:		STRING "WRAM ADDRESS (A8-A14)"
d_str_bram_address_a0_a7:		STRING "BRAM ADDRESS (A0-A7)"
d_str_bram_address_a8_a14:		STRING "BRAM ADDRESS (A8-A14)"

d_str_pal_245_dead_output_lower:	STRING "PALETTE 74245 DEAD OUTPUT (LOWER)"
d_str_pal_245_dead_output_upper:	STRING "PALETTE 74245 DEAD OUTPUT (UPPER)"
d_str_pal_dead_output_lower:		STRING "PALETTE RAM DEAD OUTPUT (LOWER)"
d_str_pal_dead_output_upper:		STRING "PALETTE RAM DEAD OUTPUT (UPPER)"

d_str_pal_unwritable_lower:		STRING "PALETTE RAM UNWRITABLE (LOWER)"
d_str_pal_unwritable_upper:		STRING "PALETTE RAM UNWRITABLE (UPPER)"

d_str_pal_bank0_data_lower:		STRING "PALETTE BANK0 DATA (LOWER)"
d_str_pal_bank0_data_upper:		STRING "PALETTE BANK0 DATA (UPPER)"
d_str_pal_bank0_data_both:		STRING "PALETTE BANK0 DATA (BOTH)"

d_str_pal_bank1_data_lower:		STRING "PALETTE BANK1 DATA (LOWER)"
d_str_pal_bank1_data_upper:		STRING "PALETTE BANK1 DATA (UPPER)"
d_str_pal_bank1_data_both:		STRING "PALETTE BANK1 DATA (BOTH)"

d_str_pal_address_a0_a7:		STRING "PALETTE ADDRESS (A0-A7)"
d_str_pal_address_a0_a12:		STRING "PALETTE ADDRESS (A8-A12)"

d_str_vram_32k_data_lower:		STRING "VRAM 32K DATA (LOWER)"
d_str_vram_32k_data_upper:		STRING "VRAM 32K DATA (UPPER)"
d_str_vram_32k_data_both:		STRING "VRAM 32K DATA (BOTH)"

d_str_vram_2k_data_lower:		STRING "VRAM 2K DATA (LOWER)"
d_str_vram_2k_data_upper:		STRING "VRAM 2K DATA (UPPER)"
d_str_vram_2k_data_both:		STRING "VRAM 2K DATA (BOTH)"

d_str_vram_32k_address_a0_a7:		STRING "VRAM 32K ADDRESS (A0-A7)"
d_str_vram_32k_address_a8_a14:		STRING "VRAM 32K ADDRESS (A8-A14)"

d_str_vram_2k_address_a0_a7:		STRING "VRAM 2K ADDRESS (A0-A7)"
d_str_vram_2k_address_a8_a10:		STRING "VRAM 2K ADDRESS (A8-A10)"

d_str_vram_32k_dead_output_lower:	STRING "VRAM 32K DEAD OUTPUT (LOWER)"
d_str_vram_32k_dead_output_upper:	STRING "VRAM 32K DEAD OUTPUT (UPPER)"
d_str_vram_2k_dead_output_lower:	STRING "VRAM 2K DEAD OUTPUT (LOWER)"
d_str_vram_2k_dead_output_upper:	STRING "VRAM 2K DEAD OUTPUT (UPPER)"

d_str_vram_32k_unwritable_lower:	STRING "VRAM 32K UNWRITABLE (LOWER)"
d_str_vram_32k_unwritable_upper:	STRING "VRAM 32K UNWRITABLE (UPPER)"
d_str_vram_2k_unwritable_lower:		STRING "VRAM 2K UNWRITABLE (LOWER)"
d_str_vram_2k_unwritable_upper:		STRING "VRAM 2K UNWRITABLE (UPPER)"

d_str_mmio_dead_output:			STRING "MMIO DEAD OUTPUT"

d_str_mc_245_dead_output_lower:		STRING "MEMCARD 245/G0 DEAD OUTPUT (LOWER)"
d_str_mc_245_dead_output_upper:		STRING "MEMCARD 245/G0 DEAD OUTPUT (UPPER)"
d_str_mc_dead_output_lower:		STRING "MEMCARD DEAD OUTPUT (LOWER)"
d_str_mc_unwritable_lower:		STRING "MEMCARD UNWRITABLE (LOWER)"
d_str_mc_unwritable_upper:		STRING "MEMCARD UNWRITABLE (UPPER)"
d_str_mc_data:				STRING "MEMCARD DATA"
d_str_mc_address:			STRING "MEMCARD ADDRESS"

d_str_p1_dead_output_lower:		STRING "P1 DEAD OUPUT (LOWER)"
d_str_p1_dead_output_upper:		STRING "P1 DEAD OUPUT (UPPER)"
d_str_p2_dead_output_lower:		STRING "P2 DEAD OUPUT (LOWER)"
d_str_p2_dead_output_upper:		STRING "P2 DEAD OUPUT (UPPER)"
d_str_p1_245_dead_output_lower:		STRING "P1 or 245/G0/BUF DEAD OUPUT (LOWER)"
d_str_p1_245_dead_output_upper:		STRING "P1 or 245/G0/BUF DEAD OUPUT (UPPER)"
d_str_p2_245_dead_output_lower:		STRING "P2 or 245/G0/BUF DEAD OUPUT (LOWER)"
d_str_p2_245_dead_output_upper:		STRING "P2 or 245/G0/BUF DEAD OUPUT (UPPER)"
d_str_p2_unwritable_lower:		STRING "P2 UNWRITABLE (LOWER)"
d_str_p2_unwritable_upper:		STRING "P2 UNWRITABLE (UPPER)"
d_str_prog_data_bus:			STRING "PROG DATA BUS"
d_str_prog_address_bus:			STRING "PROP ADDRESS BUS"

	align 1

d_ec_mmio_list:
	EC_MMIO_ENTRY REG_DIPSW, d_xys_mmio_error_c1_1_to_r0_47_list
	EC_MMIO_ENTRY REG_SYSTYPE, d_xys_mmio_error_c1_1_to_r0_47_list
	EC_MMIO_ENTRY REG_STATUS_A, d_xys_mmio_error_reg_status_a_list
	EC_MMIO_ENTRY REG_P1CNT, d_xys_mmio_error_generic_c1_list
	EC_MMIO_ENTRY REG_SOUND, d_xys_mmio_error_generic_c1_list
	EC_MMIO_ENTRY REG_P2CNT, d_xys_mmio_error_generic_c1_list
	EC_MMIO_ENTRY REG_STATUS_B, d_xys_mmio_error_generic_c1_list
	EC_MMIO_ENTRY REG_VRAMRW, d_xys_mmio_error_reg_vramrw_list
	EC_MMIO_LIST_END

d_xys_mmio_error_c1_1_to_r0_47_list:
	XY_STRING LEFT_MARGIN, 10, "1st gen: (no info)"
	XY_STRING LEFT_MARGIN, 11, "2nd gen: NEO-C1(1) <-> NEO-F0(47)"
	XY_STRING_LIST_END
d_xys_mmio_error_reg_status_a_list:
	XY_STRING LEFT_MARGIN, 10, "1st gen: (no info)"
	XY_STRING LEFT_MARGIN, 11, "2nd gen: NEO-C1(2) <-> NEO-F0(34)"
	XY_STRING_LIST_END

d_xys_mmio_error_generic_c1_list:
	XY_STRING LEFT_MARGIN, 10, "1st gen: (no info)"
	XY_STRING LEFT_MARGIN, 11, "2nd gen: NEO-C1"
	XY_STRING_LIST_END

d_xys_mmio_error_reg_vramrw_list:
	XY_STRING LEFT_MARGIN, 10, "1st gen: ? <-> LSPC-A0(?)"
	XY_STRING LEFT_MARGIN, 11, "2nd gen: NEO-C1 <-> LSPC2-A2(172)"
	XY_STRING_LIST_END
