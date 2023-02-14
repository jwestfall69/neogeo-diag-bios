	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"
	include "../common/error_codes.inc"

	global manual_memcard_tests
	global STR_MEMCARD_TESTS

	section text

; notes:
; - 68k a1 line to wired to a0 of memcard slot
; - neo geo has ce#1 and ce#2 wired together
;     On sram memcards ce#1 is for enabling d0-7 and ce#2 d8-15
; - 8 bit memcard
;     Official and repro neogeo memcards are this and have a single 8bit sram/fram chip
;     Generic sram cards of this type likely have multiple underlying chips
; - 16 bit memcard
;     2x 8bit wide sram chips (like neo geo work ram)
;     Not sure these exist, as they would violate the PC Card sram spec
; - 16 bit double wide memcard
;     Some of these cards also support 8bit mode, but requires making proper use of ce#1/2.
;     With the neogeo setting ce#1/2 both low, it signals to the memcard access will be via
;     16bit / word.  The memcard expects word aligned requests in this case and will ignore
;     its a0 line.  This causes a double wide effect when the neogeo is accessing the card
;     68k address   memcard address   data
;       800000         000000         1122
;       800002         000000         1122
;       800004         000002         3344
;       800006         000002         3344
manual_memcard_tests:

		lea	XY_STR_D_MAIN_MENU, a0
		RSUB	print_xy_string_struct_clear

		move.b	REG_STATUS_B, d0
		and.b	#$30, d0
		beq	.memcard_inserted

		lea	XY_STR_NOT_DETECTED, a0
		RSUB	print_xy_string_struct_clear
		bra	.loop_wait_input_return_menu

	.memcard_inserted:
		move.b	REG_STATUS_B, d0
		btst	#$6, d0
		beq	.memcard_not_write_protect

		lea	XY_STR_WRITE_PROTECT, a0
		RSUB	print_xy_string_struct_clear
		bra	.loop_wait_input_return_menu

	.memcard_not_write_protect:
		lea	XY_STR_WARNING1, a0
		RSUB	print_xy_string_struct_clear
		lea	XY_STR_WARNING2, a0
		RSUB	print_xy_string_struct_clear
		lea	XY_STR_A_C_RUN_TEST, a0
		RSUB	print_xy_string_struct_clear

	.loop_wait_input_run_test:

		bsr	p1p2_input_update
		bsr	wait_frame

		move.b	p1_input, d0
		btst	#D_BUTTON, d0
		bne	.dont_run_tests

		and.b	#$50, d0			; a+c pressed, run test
		cmp.b	#$50, d0
		beq	.run_tests
		bra	.loop_wait_input_run_test

	.dont_run_tests:
		rts

	.run_tests:
		moveq	#8, d0
		SSA3	fix_clear_line
		moveq	#26, d0
		SSA3	fix_clear_line
		moveq	#27, d0
		SSA3	fix_clear_line
		lea	XY_STR_RUNNING_TESTS, a0
		RSUB	print_xy_string_struct_clear

		moveq	#$0, d0
		move.b	d0, REG_CRDNORMAL
		move.b	d0, REG_CRDBANK
		move.b	d0, REG_CRDUNLOCK1
		move.b  d0, REG_CRDUNLOCK2
		clr.b	memcard_flags
		clr.l	memcard_size

		bsr	memcard_oe_tests
		bne	.test_failed_abort

		bsr	memcard_get_bit_width
		bsr	memcard_get_size

		lea	XY_STR_DETECT, a0
		RSUB	print_xy_string_struct_clear

		; add (BAD DATA) if we weren't able to detect
		btst	#MEMCARD_FLAG_BAD_DATA, memcard_flags
		beq	.skip_bad_data
		lea	XY_STR_BAD_DATA, a0
		RSUB	print_xy_string_struct

	.skip_bad_data:

		lea	XY_STR_DBUS_8BIT, a0
		btst	#MEMCARD_FLAG_DBUS_16BIT, memcard_flags
		beq	.print_dbus_size
		lea	XY_STR_DBUS_16BIT, a0

	.print_dbus_size:
		RSUB	print_xy_string_struct_clear

		; add (WIDE) if double wide bus
		btst	#MEMCARD_FLAG_DBUS_WIDE, memcard_flags
		beq	.print_size
		lea	XY_STR_DBUS_WIDE, a0
		RSUB	print_xy_string_struct

	.print_size:
		lea	XY_STR_SIZE, a0
		RSUB	print_xy_string_struct_clear

		moveq	#13, d0
		moveq	#25, d1
		move.l	memcard_size, d2

		cmp.l	#1024,d2
		blt	.print_size_bytes

		moveq	#10, d3			; print the size in KB
		lsr.l	d3, d2
		RSUB	print_5_digits
		bra	.print_size_done

	.print_size_bytes:
		RSUB	print_5_digits
		lea	XY_STR_SIZE_BYTES, a0
		RSUB	print_xy_string_struct

	.print_size_done:
		bsr	memcard_we_tests
		bne	.test_failed_abort

		bsr	memcard_data_tests
		bne	.test_failed_abort

		bsr	memcard_address_tests
		bne	.test_failed_abort

		lea	XY_STR_TESTS_PASSED, a0
		RSUB	print_xy_string_struct

		bra	.wait_input_return_menu

	.test_failed_abort:
		RSUB	print_error
		moveq	#9, d0
		SSA3	fix_clear_line

	.wait_input_return_menu:
		move.b	d0, REG_CRDLOCK1
		move.b  d0, REG_CRDLOCK2

		lea	XY_STR_D_MAIN_MENU, a0
		RSUB	print_xy_string_struct_clear

	.loop_wait_input_return_menu:

		bsr	p1p2_input_update
		bsr	wait_frame

		btst	#D_BUTTON, p1_input_edge
		beq	.loop_wait_input_return_menu		; if d pressed, exit test

		rts


; The memory card data lines have 2xHCT245 or NEO-G0 between
; them and the 68k's data lines.
;
; check_memcard_oe calls will attempt to identify output issues
; from those IC's to the 68k.  For this test is ok to check the
; upper byte for output on 8 bit cards.  If the ICs are working
; they will be outputting something on the upper byte which
; won't trigger an error
;
; check_memcard_to_245_output call will attempt to identify when the
; memory on memcard itself is having output issues.  We can only
; test the lower byte in this case since we don't know if the card
; is 16 bit.  Figuring out if the card is 16 bit requires the upper
; byte to be outputing data.
memcard_oe_tests:
		moveq	#1, d0				; lower byte
		lea	MEMCARD_START, a0
		RSUB	check_ram_oe
		tst.b	d0
		beq	.test_passed_memory_output_lower
		move.b	#EC_MC_245_DEAD_OUTPUT_LOWER, d0
		rts

	.test_passed_memory_output_lower:
		moveq	#0, d0				; high byte
		lea	MEMCARD_START, a0
		RSUB	check_ram_oe
		tst.b	d0
		beq	.test_passed_memory_output_upper
		move.b	#EC_MC_245_DEAD_OUTPUT_UPPER, d0
		rts

	.test_passed_memory_output_upper:
		move.w	#$ff, d0
		lea	MEMCARD_START, a0
		RSUB	check_ram_to_245_oe
		tst.b	d0
		beq	.test_passed_memcard_to_245_output_lower
		move.b	#EC_MC_DEAD_OUTPUT_LOWER, d0
		rts

	.test_passed_memcard_to_245_output_lower:
		moveq	#$0, d0
		rts

; figure out if the card has a 8 bit, 16 bit or 16 bit double wide data bus
memcard_get_bit_width:

		lea	MEMCARD_START, a0
		move.w	#$aaaa, (a0)

		; if 8 bit card, the upper 8 bits on the 16 bit data bus seems to be the
		; last written data.  Write some junk so we see that instead of our 0xaaaa
		move.w	#$5555, (4, a0)
		move.w	(a0), d0

		; got back bad data, assume 8bit
		cmp.b	#$aa, d0
		bne	.bad_data

		; upper byte doesn't match, assume 8bit, but could be corrupt too
		cmp.w	#$aaaa, d0
		bne	.is_8bit
		bset.b	#MEMCARD_FLAG_DBUS_16BIT, memcard_flags

		; check for double wide
		move.w	#$5555, (2, a0)
		cmp.w	#$5555, (a0)
		beq	.is_16bit_wide
		rts

	.is_16bit_wide:
		bset.b	#MEMCARD_FLAG_DBUS_WIDE, memcard_flags
		rts

	.bad_data:
		bset.b	#MEMCARD_FLAG_BAD_DATA, memcard_flags

	.is_8bit:
		rts

; The memory card is mapped into $800000 to $BFFFFF ($400000/4MB bytes)
; We have to deal with there being possible bad addresses lines, so we
; are checking each address line and use the last working one to
; figure out the memory card size.
;
; When checking a specific address line we test the first word and
; if it passes assume all addresses until the next address line are
; valid.  For example if $802000 passed testing, we assume up to
; $803fff are also valid too.
;
; This means we are assuming the memory card size is a power of 2.
; There are some (uncommon) generic sram cards that are not a power
; of 2.  If one of these are used it will be detected as being the
; next highest power of 2 and ultimately trigger an error when
; doing the address tests.
memcard_get_size:

		; bad data, assume stock neo geo card size (2k)
		btst	#MEMCARD_FLAG_BAD_DATA, memcard_flags
		bne	.bad_data

		moveq	#4, d1			; test offset
		moveq	#0, d2			; last valid test offset
		lea	MEMCARD_START, a0

	.loop_next_bit:
		movea.l	a0, a1
		adda.l	d1, a1

		move.w	#$aa, (a1)		; write test offset
		move.w	#$55, (a0)		; write memcard start
		move.w	(a1), d0		; read test offset

		cmp.b	#$aa, d0
		bne	.test_failed

		move.l	d1, d2			; save working test offset

	.test_failed:
		lsl.l	#1, d1			; next test offset

		cmp.l	#$400000, d1		; max test offset
		beq	.loop_exit
		bra	.loop_next_bit

	.loop_exit:

		; never got any valid address lines? assume stock neo geo card size (2k)
		cmp.l	#$0, d2
		beq	.bad_data

		; d2 contains the last working working test offset, but this is
		; the start of that range.  We need to double it up to get the
		; total address size.
		lsl.l	#1, d2

		; d2 contains the address size of the memory card.  In the case of 8bit or
		; 16bit wide cards only 1/2 of the address space contains actual memory
		; card data.  So we need to adjust to get the correct memory card data size.
		; For other cards, data size = address size.
		btst	#MEMCARD_FLAG_DBUS_16BIT, memcard_flags
		beq	.adjust_size
		btst	#MEMCARD_FLAG_DBUS_WIDE, memcard_flags
		bne	.adjust_size
		bra	.skip_adjust_size

	.adjust_size:
		lsr.l	#$1, d2

	.skip_adjust_size:
		move.l	d2, memcard_size
		rts

	.bad_data:
		move.l	#2048, memcard_size
		rts

memcard_we_tests:
		lea	MEMCARD_START, a0
		move.w	#$ff, d0
		bsr 	check_memcard_we
		beq	.test_passed_lower
		move.b	#EC_MC_UNWRITABLE_LOWER, d0
		rts

	.test_passed_lower:
		; only test upper if 16bit
		btst	#MEMCARD_FLAG_DBUS_16BIT, memcard_flags
		beq	.test_passed_upper

		move.w	#$ff00, d0
		bsr	check_memcard_we
		beq	.test_passed_upper
		move.b	#EC_MC_UNWRITABLE_UPPER, d0
		rts

	.test_passed_upper:
		moveq	#0, d0
		rts

; a0 = address to check
; d0 = mask
; returns:
;  d0 = 0 pass / -1 fail
check_memcard_we:

		move.w	(a0), d1		; read existing data at address

		move.w	d1, d2
		eor.w	#-1, d2			; flip the bits on the read data
		move.w	d2, (a0)		; write flipped data to address
		move.w	d1, (4, a0)		; put junk on the bus

		move.w	(a0), d2		; re-read data at address

		and.w	d0, d1
		and.w	d0, d2
		cmp.w	d1, d2			; if re-read data == original read data => error

		bne	.test_passed
		moveq	#-1, d0
		rts

	.test_passed:
		moveq	#$0, d0
		rts

memcard_data_tests:
		moveq	#$0, d0
		bsr	check_memcard_data
		beq	.test_passed_0000
		move.b	#EC_MC_DATA, d0
		rts

	.test_passed_0000:
		move.w	#$5555, d0
		bsr	check_memcard_data
		beq	.test_passed_5555
		move.b	#EC_MC_DATA, d0
		rts

	.test_passed_5555:
		move.w	#$aaaa, d0
		bsr	check_memcard_data
		beq	.test_passed_aaaa
		move.b	#EC_MC_DATA, d0
		rts

	.test_passed_aaaa:
		moveq	#-1, d0
		bsr	check_memcard_data
		beq	.test_passed_ffff
		move.b	#EC_MC_DATA, d0

	.test_passed_ffff:
		moveq	#$0, d0
		rts


; Does a full write/read test
; params:
;  d0 = value
; returns:
;  d0 = 0 (pass), $ff (fail)
;  a0 = failed address
;  d1 = wrote value
;  d2 = read (bad) value
; On memcard memory, if the there is no output on a data line it will take on
; the state of the last written state for it.  So we need to poison this by
; writing the opposite value at an alternative address before re-reading our
; test address.
check_memcard_data:

		lea	MEMCARD_START, a0
		move.l	memcard_size, d1

		move.w	#$ff, d3	; compare mask, default is lower byte only
		moveq	#2, d4		; address increment amount
		move.w	d0, d5
		eor.w	#-1, d5		; poison value

		btst	#MEMCARD_FLAG_DBUS_16BIT, memcard_flags
		beq	.finished_adjustments

		; 16 bit
		lsr.l	#$1, d1		; adjust length since we will be reading in words
		move.w	#$ffff, d3	; adjust mask to check upper byte

		btst	#MEMCARD_FLAG_DBUS_WIDE, memcard_flags
		beq	.finished_adjustments
		moveq	#4, d4		; wide is every other word

	.finished_adjustments:
		and.w	d3, d0

		; dont check the last byte/word in the loop, we will need to do this
		; manually to avoid overflowing our test range when poisoning
		subq.l	#1, d1

	.loop_next_address:
		WATCHDOG
		move.w	d0, (a0)
		move.w	d5, (a0, d4)	; use next test address as the poison location
		move.w	(a0), d2

		and.w 	d3, d2
		cmp.w	d0, d2
		bne	.test_failed

		adda.l	d4, a0
		subq.l	#1, d1
		bne	.loop_next_address

		; manually test the last byte/word
		move.w	d0, (a0)
		move.w	d5, (-4, a0)
		move.w	(a0), d2
		and.w	d3, d2
		cmp.w	d0, d2
		bne	.test_failed

		moveq	#0, d0
		rts

	.test_failed:
		move.w	d0, d1
		moveq	#-1, d0
		rts

memcard_address_tests:
		bsr	check_memcard_address
		beq	.test_passed
		move.b	#EC_MC_ADDRESS, d0
		rts

	.test_passed:
		moveq	#0, d0
		rts

; Write an incrementing value at each address line
; Read back those values and make sure they are correct.
check_memcard_address:
		move.l	memcard_size, d0

		move.w	#$ff, d1	; compare mask, default is lower byte only
		btst	#MEMCARD_FLAG_DBUS_16BIT, memcard_flags
		beq	.skip_adjust_mask
		move.w	#$ffff, d1

	.skip_adjust_mask:

		; need to adjust memcard_size to address size
		btst	#MEMCARD_FLAG_DBUS_16BIT, memcard_flags
		beq	.adjust_size
		btst	#MEMCARD_FLAG_DBUS_WIDE, memcard_flags
		bne	.adjust_size
		bra	.skip_adjust_size

	.adjust_size:
		lsl.l	#1, d0

	.skip_adjust_size:

		move.w	#$101, d2		; current read/write value
		moveq	#2, d3			; current read/write offset

		lea	MEMCARD_START, a0
		move.w	d2, (a0)

		; wide bus, skip 800002
		btst	#MEMCARD_FLAG_DBUS_WIDE, memcard_flags
		beq	.loop_write_next_address
		lsl.l	#1, d3
		add.w	#$101, d2

	.loop_write_next_address:
		lea	MEMCARD_START, a0
		adda.l	d3, a0

		add.w	#$101, d2
		move.w	d2, (a0)


		lsl.l	#1, d3
		cmp.l	d3, d0
		beq	.loop_write_end
		bra	.loop_write_next_address
	.loop_write_end:

		; reset to read back the data
		move.w	#$101, d2
		moveq	#2, d3

		lea	MEMCARD_START, a0
		move.w	(a0), d4
		move.w	d2, d5
		and.w	d1, d4
		and.w	d1, d5
		cmp.w	d4, d5
		bne	.test_failed

		; wide bus, skip 800002
		btst	#MEMCARD_FLAG_DBUS_WIDE, memcard_flags
		beq	.loop_read_next_address
		lsl.l	#1, d3
		add.w	#$101, d2

	.loop_read_next_address:
		lea	MEMCARD_START, a0
		adda.l	d3, a0

		add.w	#$101, d2
		move.w	(a0), d4
		move.w	d2, d5
		and.w	d1, d4
		and.w	d1, d5
		cmp.w	d4, d5
		bne	.test_failed

		lsl.l	#1, d3
		cmp.l	d3, d0
		beq	.loop_read_end
		bra	.loop_read_next_address
	.loop_read_end:
		moveq	#$0, d0
		rts

	.test_failed:
		move.w	d5, d1
		move.w	d4, d2
		moveq	#-1, d0
		rts

STR_MEMCARD_TESTS:		STRING "MEMORY CARD TESTS"

XY_STR_A_C_RUN_TEST:		XY_STRING  4, 26, "A+C: Run Test"
XY_STR_WARNING1:		XY_STRING  4,  8, "WARNING: ALL DATA ON THE MEMORY"
XY_STR_WARNING2:		XY_STRING  4,  9, "CARD WILL BE OVERWRITTEN!"
XY_STR_NOT_DETECTED:		XY_STRING  4,  8, "ERROR: MEMORY CARD NOT DETECTED"
XY_STR_WRITE_PROTECT:		XY_STRING  4,  8, "ERROR: MEMORY CARD WRITE PROTECTED"
XY_STR_DETECT:			XY_STRING  4, 22, "DETECTED"
XY_STR_BAD_DATA:		XY_STRING 13, 22, "(BAD DATA)"
XY_STR_DBUS_8BIT:		XY_STRING  4, 24, "DATA BUS: 8-BIT"
XY_STR_DBUS_16BIT:		XY_STRING  4, 24, "DATA BUS: 16-BIT"
XY_STR_DBUS_WIDE:		XY_STRING 21, 24, "(WIDE)"
XY_STR_SIZE:			XY_STRING  8, 25, "SIZE:      KB"
XY_STR_SIZE_BYTES:		XY_STRING 19, 25, "BYTES"
XY_STR_TESTS_PASSED:		XY_STRING  4,  9, "ALL TESTS PASSED"
XY_STR_RUNNING_TESTS:		XY_STRING  4,  9, "RUNNING TESTS..."
