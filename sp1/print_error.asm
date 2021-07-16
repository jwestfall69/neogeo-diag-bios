	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"
	include "../common/error_codes.inc"

	global error_code_lookup_dsub
	global print_error_dsub
	global print_error_z80

	section text

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
		lea	(EC_LOOKUP_TABLE), a1
		moveq	#((EC_LOOKUP_TABLE_END - EC_LOOKUP_TABLE)/6 - 1), d3
		bra	.loop_ec_lookup_start

	.loop_ec_lookup_next_entry:
		addq.l	#6, a1
	.loop_ec_lookup_start:
		cmp.b 	(a1), d0
		dbeq	d3, .loop_ec_lookup_next_entry
		beq	.ec_found

		; error code not found
		lea	print_error_invalid_dsub, a2
		lea	STR_INVALID_ERROR_CODE, a1
		move.b	#PRINT_ERROR_INVALID, d1
		bra	.not_found

	.ec_found:
		move.b	(1, a1), d4	; print error dsub id
		and.w	#$ff, d4
		movea.l (2, a1), a1	; error description string

		lea	(PRINT_ERROR_TABLE), a2
		moveq	#((PRINT_ERROR_TABLE_END - PRINT_ERROR_TABLE)/6), d3
		bra	.loop_print_error_start

	.loop_print_error_next_entry:
		addq.l	#6, a2
	.loop_print_error_start:
		cmp.w	(a2), d4
		dbeq	d3, .loop_print_error_next_entry
		beq	.function_found

		; no function was found
		lea	print_error_invalid_dsub, a2
		move.b	d4, d1
		bra	.not_found

	.function_found:
		movea.l	(2, a2), a2

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

		lea	STR_EXPECTED.l, a0
		moveq	#4, d0
		moveq	#12, d1
		DSUB	print_xy_string

		lea	STR_ACTUAL.l, a0
		moveq	#4, d0
		moveq	#10, d1
		DSUB	print_xy_string

		movea.l	a1, a0
		moveq	#4, d0
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

		lea	STR_EXPECTED.l, a0
		moveq	#4, d0
		moveq	#12, d1
		DSUB	print_xy_string

		lea	STR_ACTUAL.l, a0
		moveq	#4, d0
		moveq	#10, d1
		DSUB	print_xy_string

		movea.l	a1, a0
		moveq	#4, d0
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

		lea	STR_ADDRESS, a0
		moveq	#4, d0
		moveq	#8, d1
		DSUB	print_xy_string

		lea	STR_EXPECTED, a0
		moveq	#4, d0
		moveq	#12, d1
		DSUB	print_xy_string

		lea	STR_ACTUAL, a0
		moveq	#4, d0
		moveq	#10, d1
		DSUB	print_xy_string

		movea.l	a1, a0
		moveq	#4, d0
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

		lea	STR_ADDRESS, a0
		moveq	#4, d0
		moveq	#8, d1
		DSUB	print_xy_string

		lea	(MMIO_ERROR_LOOKUP_TABLE_START - 4), a0

	.loop_next_entry:
		addq.l	#4, a0
		cmp.l	(a0)+, d3
		bne	.loop_next_entry
		movea.l	(a0), a0

	.loop_next_xy_string_struct:
		DSUB	print_xy_string_struct
		tst.b	(a0)
		bne	.loop_next_xy_string_struct

		movea.l	a1, a0
		moveq	#4, d0
		moveq	#5, d1
		jmp	print_xy_string_clear_dsub

MMIO_ERROR_LOOKUP_TABLE_START:
	dc.l REG_DIPSW, XY_MMIO_ERROR_C1_1_TO_F0_47
	dc.l REG_SYSTYPE, XY_MMIO_ERROR_C1_1_TO_F0_47
	dc.l REG_STATUS_A, XY_MMIO_ERROR_REG_STATUS_A
	dc.l REG_P1CNT, XY_MMIO_ERROR_GENERIC_C1
	dc.l REG_SOUND, XY_MMIO_ERROR_GENERIC_C1
	dc.l REG_P2CNT, XY_MMIO_ERROR_GENERIC_C1
	dc.l REG_STATUS_B, XY_MMIO_ERROR_GENERIC_C1
	dc.l REG_VRAMRW, XY_MMIO_ERROR_REG_VRAMRW

XY_MMIO_ERROR_C1_1_TO_F0_47:
	XY_STRING_MULTI 4, 10, "1st gen: (no info)"
	XY_STRING_MULTI 4, 11, "2nd gen: NEO-C1(1) <-> NEO-F0(47)"
	XY_STRING_MULTI_END
XY_MMIO_ERROR_REG_STATUS_A:
	XY_STRING_MULTI 4, 10, "1st gen: (no info)"
	XY_STRING_MULTI 4, 11, "2nd gen: NEO-C1(2) <-> NEO-F0(34)"
	XY_STRING_MULTI_END
XY_MMIO_ERROR_GENERIC_C1:
	XY_STRING_MULTI 4, 10, "1st gen: (no info)"
	XY_STRING_MULTI 4, 11, "2nd gen: NEO-C1"
	XY_STRING_MULTI_END
XY_MMIO_ERROR_REG_VRAMRW:
	XY_STRING_MULTI 4, 10, "1st gen: ? <-> LSPC-A0(?)"
	XY_STRING_MULTI 4, 11, "2nd gen: NEO-C1 <-> LSPC2-A2(172)"
	XY_STRING_MULTI_END
	align 2

; prints just the error description
; params:
;  a1 = error description
print_error_string_dsub:
		movea.l	a1, a0
		moveq	#4, d0
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
		lea	STR_INVALID_ERROR, a0
		DSUB	print_xy_string_clear

		moveq	#4, d0
		moveq	#6, d1
		lea	STR_ERROR_CODE, a0
		DSUB	print_xy_string_clear

		moveq	#4, d0
		move	#7, d1
		lea	STR_PRINT_FUNCTION, a0
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

		lea	XY_STR_Z80_ERROR_CODE, a0
		RSUB	print_xy_string_struct

		movea.l	a1, a0
		moveq	#4, d0
		moveq	#14, d1
		RSUB	print_xy_string

		moveq	#21, d0
		SSA3	fix_clear_line
		moveq	#22, d0
		SSA3	fix_clear_line
		rts

; struct ec_lookup {
;  byte error_code;
;  byte print_error_dsub_id;
;  long error_code_description_string;  // macro fills in for us
; }
EC_LOOKUP_TABLE:
	; The code for handling errors from the z80 does not use the print function
	; provided by ec_lookup, but will instead directly call print_error_z80.
	; This allows handling a bad error code from the z80 differently then the 68k.
	; If the 68k somehow ended up with a z80 error code it will cause the
	; print_error_invalid function to be called
	EC_LOOKUP_STRUCT Z80_M1_CRC, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_M1_UPPER_ADDRESS, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_RAM_DATA_00, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_RAM_DATA_55, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_RAM_DATA_AA, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_RAM_DATA_FF, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_RAM_ADDRESS_A0_A7, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_RAM_ADDRESS_A8_A10, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_RAM_OE, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_RAM_WE, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_68K_COMM_NO_HANDSHAKE, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_68K_COMM_NO_CLEAR, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_SM1_OE, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_SM1_CRC, PRINT_ERROR_INVALID

	EC_LOOKUP_STRUCT YM2610_IO_ERROR, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT YM2610_TIMER_TIMING_FLAG, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT YM2610_TIMER_TIMING_IRQ, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT YM2610_IRQ_UNEXPECTED, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT YM2610_TIMER_INIT_FLAG, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT YM2610_TIMER_INIT_IRQ, PRINT_ERROR_INVALID

	EC_LOOKUP_STRUCT Z80_M1_BANK_ERROR_16K, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_M1_BANK_ERROR_8K, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_M1_BANK_ERROR_4K, PRINT_ERROR_INVALID
	EC_LOOKUP_STRUCT Z80_M1_BANK_ERROR_2K, PRINT_ERROR_INVALID

	EC_LOOKUP_STRUCT BIOS_MIRROR, PRINT_ERROR_HEX_BYTE
	EC_LOOKUP_STRUCT BIOS_CRC32, PRINT_ERROR_BIOS_CRC32

	EC_LOOKUP_STRUCT WRAM_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT WRAM_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING

	EC_LOOKUP_STRUCT BRAM_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT BRAM_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING

	EC_LOOKUP_STRUCT WRAM_UNWRITABLE_LOWER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT WRAM_UNWRITABLE_UPPER, PRINT_ERROR_STRING

	EC_LOOKUP_STRUCT BRAM_UNWRITABLE_LOWER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT BRAM_UNWRITABLE_UPPER, PRINT_ERROR_STRING

	EC_LOOKUP_STRUCT WRAM_DATA_LOWER, PRINT_ERROR_MEMORY
	EC_LOOKUP_STRUCT WRAM_DATA_UPPER, PRINT_ERROR_MEMORY
	EC_LOOKUP_STRUCT WRAM_DATA_BOTH, PRINT_ERROR_MEMORY

	EC_LOOKUP_STRUCT BRAM_DATA_LOWER, PRINT_ERROR_MEMORY
	EC_LOOKUP_STRUCT BRAM_DATA_UPPER, PRINT_ERROR_MEMORY
	EC_LOOKUP_STRUCT BRAM_DATA_BOTH, PRINT_ERROR_MEMORY

	EC_LOOKUP_STRUCT WRAM_ADDRESS_A0_A7, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT WRAM_ADDRESS_A8_A14, PRINT_ERROR_STRING

	EC_LOOKUP_STRUCT BRAM_ADDRESS_A0_A7, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT BRAM_ADDRESS_A8_A14, PRINT_ERROR_STRING

	EC_LOOKUP_STRUCT PAL_245_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT PAL_245_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT PAL_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT PAL_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING

	EC_LOOKUP_STRUCT PAL_UNWRITABLE_LOWER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT PAL_UNWRITABLE_UPPER, PRINT_ERROR_STRING

	EC_LOOKUP_STRUCT PAL_BANK0_DATA_LOWER, PRINT_ERROR_MEMORY
	EC_LOOKUP_STRUCT PAL_BANK0_DATA_UPPER, PRINT_ERROR_MEMORY
	EC_LOOKUP_STRUCT PAL_BANK0_DATA_BOTH, PRINT_ERROR_MEMORY

	EC_LOOKUP_STRUCT PAL_BANK1_DATA_LOWER, PRINT_ERROR_MEMORY
	EC_LOOKUP_STRUCT PAL_BANK1_DATA_UPPER, PRINT_ERROR_MEMORY
	EC_LOOKUP_STRUCT PAL_BANK1_DATA_BOTH, PRINT_ERROR_MEMORY

	EC_LOOKUP_STRUCT PAL_ADDRESS_A0_A7, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT PAL_ADDRESS_A0_A12, PRINT_ERROR_STRING

	EC_LOOKUP_STRUCT VRAM_32K_DATA_LOWER, PRINT_ERROR_MEMORY
	EC_LOOKUP_STRUCT VRAM_32K_DATA_UPPER, PRINT_ERROR_MEMORY
	EC_LOOKUP_STRUCT VRAM_32K_DATA_BOTH, PRINT_ERROR_MEMORY

	EC_LOOKUP_STRUCT VRAM_2K_DATA_LOWER, PRINT_ERROR_MEMORY
	EC_LOOKUP_STRUCT VRAM_2K_DATA_UPPER, PRINT_ERROR_MEMORY
	EC_LOOKUP_STRUCT VRAM_2K_DATA_BOTH, PRINT_ERROR_MEMORY

	EC_LOOKUP_STRUCT VRAM_32K_ADDRESS_A0_A7, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT VRAM_32K_ADDRESS_A8_A14, PRINT_ERROR_STRING

	EC_LOOKUP_STRUCT VRAM_2K_ADDRESS_A0_A7, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT VRAM_2K_ADDRESS_A8_A10, PRINT_ERROR_STRING

	EC_LOOKUP_STRUCT VRAM_32K_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT VRAM_32K_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT VRAM_2K_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT VRAM_2K_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING

	EC_LOOKUP_STRUCT VRAM_32K_UNWRITABLE_LOWER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT VRAM_32K_UNWRITABLE_UPPER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT VRAM_2K_UNWRITABLE_LOWER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT VRAM_2K_UNWRITABLE_UPPER, PRINT_ERROR_STRING

	EC_LOOKUP_STRUCT MMIO_DEAD_OUTPUT, PRINT_ERROR_MMIO

	EC_LOOKUP_STRUCT MC_245_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT MC_245_DEAD_OUTPUT_UPPER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT MC_DEAD_OUTPUT_LOWER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT MC_UNWRITABLE_LOWER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT MC_UNWRITABLE_UPPER, PRINT_ERROR_STRING
	EC_LOOKUP_STRUCT MC_DATA, PRINT_ERROR_MEMORY
	EC_LOOKUP_STRUCT MC_ADDRESS, PRINT_ERROR_MEMORY
EC_LOOKUP_TABLE_END:

; struct print_error {
;  byte padding; 0x00;
;  byte dsub_id;
;  long dsub_address;
;}
PRINT_ERROR_TABLE:
	PRINT_ERROR_STRUCT PRINT_ERROR_BIOS_CRC32, print_error_bios_crc32_dsub
	PRINT_ERROR_STRUCT PRINT_ERROR_HEX_BYTE, print_error_hex_byte_dsub
	PRINT_ERROR_STRUCT PRINT_ERROR_MEMORY, print_error_memory_dsub
	PRINT_ERROR_STRUCT PRINT_ERROR_MMIO, print_error_mmio_dsub
	PRINT_ERROR_STRUCT PRINT_ERROR_STRING, print_error_string_dsub
PRINT_ERROR_TABLE_END:

STR_INVALID_ERROR_CODE:		STRING "INVALID ERROR CODE"
STR_INVALID_ERROR:		STRING "INVALID ERROR"
STR_ERROR_CODE:			STRING "ERROR CODE:"
STR_PRINT_FUNCTION:		STRING "PRINT FUNCTION: "

STR_Z80_M1_CRC:			STRING "M1 CRC ERROR (fixed region)"
STR_Z80_M1_UPPER_ADDRESS:	STRING "M1 UPPER ADDRESS (fixed region)"
STR_Z80_RAM_DATA_00:		STRING "RAM DATA (00)"
STR_Z80_RAM_DATA_55:		STRING "RAM DATA (55)"
STR_Z80_RAM_DATA_AA:		STRING "RAM DATA (AA)"
STR_Z80_RAM_DATA_FF:		STRING "RAM DATA (FF)"
STR_Z80_RAM_ADDRESS_A0_A7:	STRING "RAM ADDRESS (A0-A7)"
STR_Z80_RAM_ADDRESS_A8_A10:	STRING "RAM ADDRESS (A8-A10)"
STR_Z80_RAM_OE:			STRING "RAM DEAD OUTPUT"
STR_Z80_RAM_WE:			STRING "RAM UNWRITABLE"
STR_Z80_68K_COMM_NO_HANDSHAKE:	STRING "68k->Z80 COMM ISSUE (HANDSHAKE)"
STR_Z80_68K_COMM_NO_CLEAR:	STRING "68k->Z80 COMM ISSUE (CLEAR)"
STR_Z80_SM1_OE:			STRING "SM1 DEAD OUTPUT"
STR_Z80_SM1_CRC:		STRING "SM1 CRC ERROR"

XY_STR_Z80_ERROR_CODE:		XY_STRING 4, 12, "Z80 REPORTED ERROR CODE: "

STR_YM2610_IO_ERROR:		STRING "YM2610 I/O ERROR"
STR_YM2610_TIMER_TIMING_FLAG:	STRING "YM2610 TIMER TIMING (FLAG)"
STR_YM2610_TIMER_TIMING_IRQ:	STRING "YM2610 TIMER TIMING (IRQ)"
STR_YM2610_IRQ_UNEXPECTED:	STRING "YM2610 UNEXPECTED IRQ"
STR_YM2610_TIMER_INIT_FLAG:	STRING "YM2610 TIMER INIT (FLAG)"
STR_YM2610_TIMER_INIT_IRQ:	STRING "YM2610 TIMER INIT (IRQ)"

STR_Z80_M1_BANK_ERROR_16K:	STRING "M1 BANK ERROR (16K)"
STR_Z80_M1_BANK_ERROR_8K:	STRING "M1 BANK ERROR (8K)"
STR_Z80_M1_BANK_ERROR_4K:	STRING "M1 BANK ERROR (4K)"
STR_Z80_M1_BANK_ERROR_2K:	STRING "M1 BANK ERROR (2K)"

STR_BIOS_MIRROR:		STRING "BIOS ADDRESS (A14-A15)"
STR_BIOS_CRC32:			STRING "BIOS CRC ERROR"

STR_WRAM_DEAD_OUTPUT_LOWER:	STRING "WRAM DEAD OUTPUT (LOWER)"
STR_WRAM_DEAD_OUTPUT_UPPER:	STRING "WRAM DEAD OUTPUT (UPPER)"
STR_BRAM_DEAD_OUTPUT_LOWER:	STRING "BRAM DEAD OUTPUT (LOWER)"
STR_BRAM_DEAD_OUTPUT_UPPER:	STRING "BRAM DEAD OUTPUT (UPPER)"

STR_WRAM_UNWRITABLE_LOWER:	STRING "WRAM UNWRITABLE (LOWER)"
STR_WRAM_UNWRITABLE_UPPER:	STRING "WRAM UNWRITABLE (UPPER)"
STR_BRAM_UNWRITABLE_LOWER:	STRING "BRAM UNWRITABLE (LOWER)"
STR_BRAM_UNWRITABLE_UPPER:	STRING "BRAM UNWRITABLE (UPPER)"

STR_WRAM_DATA_LOWER:		STRING "WRAM DATA (LOWER)"
STR_WRAM_DATA_UPPER:		STRING "WRAM DATA (UPPER)"
STR_WRAM_DATA_BOTH:		STRING "WRAM DATA (BOTH)"

STR_BRAM_DATA_LOWER:		STRING "BRAM DATA (LOWER)"
STR_BRAM_DATA_UPPER:		STRING "BRAM DATA (UPPER)"
STR_BRAM_DATA_BOTH:		STRING "BRAM DATA (BOTH)"

STR_WRAM_ADDRESS_A0_A7:		STRING "WRAM ADDRESS (A0-A7)"
STR_WRAM_ADDRESS_A8_A14:	STRING "WRAM ADDRESS (A8-A14)"
STR_BRAM_ADDRESS_A0_A7:		STRING "BRAM ADDRESS (A0-A7)"
STR_BRAM_ADDRESS_A8_A14:	STRING "BRAM ADDRESS (A8-A14)"

STR_PAL_245_DEAD_OUTPUT_LOWER:	STRING "PALETTE 74245 DEAD OUTPUT (LOWER)"
STR_PAL_245_DEAD_OUTPUT_UPPER:	STRING "PALETTE 74245 DEAD OUTPUT (UPPER)"
STR_PAL_DEAD_OUTPUT_LOWER:	STRING "PALETTE RAM DEAD OUTPUT (LOWER)"
STR_PAL_DEAD_OUTPUT_UPPER:	STRING "PALETTE RAM DEAD OUTPUT (UPPER)"

STR_PAL_UNWRITABLE_LOWER:	STRING "PALETTE RAM UNWRITABLE (LOWER)"
STR_PAL_UNWRITABLE_UPPER:	STRING "PALETTE RAM UNWRITABLE (UPPER)"

STR_PAL_BANK0_DATA_LOWER:	STRING "PALETTE BANK0 DATA (LOWER)"
STR_PAL_BANK0_DATA_UPPER:	STRING "PALETTE BANK0 DATA (UPPER)"
STR_PAL_BANK0_DATA_BOTH:	STRING "PALETTE BANK0 DATA (BOTH)"

STR_PAL_BANK1_DATA_LOWER:	STRING "PALETTE BANK1 DATA (LOWER)"
STR_PAL_BANK1_DATA_UPPER:	STRING "PALETTE BANK1 DATA (UPPER)"
STR_PAL_BANK1_DATA_BOTH:	STRING "PALETTE BANK1 DATA (BOTH)"

STR_PAL_ADDRESS_A0_A7:		STRING "PALETTE ADDRESS (A0-A7)"
STR_PAL_ADDRESS_A0_A12:		STRING "PALETTE ADDRESS (A8-A12)"

STR_VRAM_32K_DATA_LOWER:	STRING "VRAM 32K DATA (LOWER)"
STR_VRAM_32K_DATA_UPPER:	STRING "VRAM 32K DATA (UPPER)"
STR_VRAM_32K_DATA_BOTH:		STRING "VRAM 32K DATA (BOTH)"

STR_VRAM_2K_DATA_LOWER:		STRING "VRAM 2K DATA (LOWER)"
STR_VRAM_2K_DATA_UPPER:		STRING "VRAM 2K DATA (UPPER)"
STR_VRAM_2K_DATA_BOTH:		STRING "VRAM 2K DATA (BOTH)"

STR_VRAM_32K_ADDRESS_A0_A7:	STRING "VRAM 32K ADDRESS (A0-A7)"
STR_VRAM_32K_ADDRESS_A8_A14:	STRING "VRAM 32K ADDRESS (A8-A14)"

STR_VRAM_2K_ADDRESS_A0_A7:	STRING "VRAM 2K ADDRESS (A0-A7)"
STR_VRAM_2K_ADDRESS_A8_A10:	STRING "VRAM 2K ADDRESS (A8-A10)"

STR_VRAM_32K_DEAD_OUTPUT_LOWER:	STRING "VRAM 32K DEAD OUTPUT (LOWER)"
STR_VRAM_32K_DEAD_OUTPUT_UPPER:	STRING "VRAM 32K DEAD OUTPUT (UPPER)"
STR_VRAM_2K_DEAD_OUTPUT_LOWER:	STRING "VRAM 2K DEAD OUTPUT (LOWER)"
STR_VRAM_2K_DEAD_OUTPUT_UPPER:	STRING "VRAM 2K DEAD OUTPUT (UPPER)"

STR_VRAM_32K_UNWRITABLE_LOWER:	STRING "VRAM 32K UNWRITABLE (LOWER)"
STR_VRAM_32K_UNWRITABLE_UPPER:	STRING "VRAM 32K UNWRITABLE (UPPER)"
STR_VRAM_2K_UNWRITABLE_LOWER:	STRING "VRAM 2K UNWRITABLE (LOWER)"
STR_VRAM_2K_UNWRITABLE_UPPER:	STRING "VRAM 2K UNWRITABLE (UPPER)"

STR_MMIO_DEAD_OUTPUT:		STRING "MMIO DEAD OUTPUT"

STR_MC_245_DEAD_OUTPUT_LOWER:	STRING "MEMCARD 245/G0 DEAD OUTPUT (LOWER)"
STR_MC_245_DEAD_OUTPUT_UPPER:	STRING "MEMCARD 245/G0 DEAD OUTPUT (UPPER)"
STR_MC_DEAD_OUTPUT_LOWER:	STRING "MEMCARD DEAD OUTPUT (LOWER)"
STR_MC_UNWRITABLE_LOWER:	STRING "MEMCARD UNWRITABLE (LOWER)"
STR_MC_UNWRITABLE_UPPER:	STRING "MEMCARD UNWRITABLE (UPPER)"
STR_MC_DATA:			STRING "MEMCARD DATA"
STR_MC_ADDRESS:			STRING "MEMCARD ADDRESS"
