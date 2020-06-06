	include "neogeo.inc"
	include "../common/error_codes.inc"
	include "../common/comm.inc"
	include "macros.inc"
	include "sp1.inc"

	; This stops vasm from doing a few optimizations
	; which cause the resulting rom to not match
	; the original (ie: cmp #0, d0 -> tst.b d0)
	opt og-

	; These are options to force the bios to do
	; z80 or goto manual tests since its not
	; practical to be holding down buttons on boot
	; with mame.

;force_z80_tests 	equ 1
;force_manual_tests 	equ 1

	org	BIOS_ROM_START

VECTORS:
	dc.l	SP_INIT_ADDR
	dc.l	_start

	rorg	$64, $ff
	dc.l	vblank_interrupt
	dc.l	timer_interrupt

; psub_enter/psub_exit allows creating and using pseudo subroutines.  The
; purpose of which is to mimic jsr/bsr with out the need for touching
; the stack/work ram, which maybe faultly.  Up to 2 nested psub calls
; are supported.
;
; psub_enter requires 2 registers to be setup
; a2 = psub that will be called
; a3 = address to jmp to when psub is finished
;
; d7 is used to keep track of nesting and must be initialized to $0c
; before using psub_enter for the first time
;
; When a psub is done, it should jmp/bra to psub_exit instead of rts.
;
; The initial psub call will store the return address in a7, first nest
; in a5, and 2nd nest in a4.  This will also mean that a7 will be
; clobbered and must be re-initialized before doing anything with the
; stack.
;
; A psub should not touch a4, a5, a7, d7.  This will mean you can't
; call normal subroutines within a psub as the stack (a7) will
; will not contain a valid stack location.  Ideally you should also
; avoid using wram within a psub.
;
; Its common for there to be 2 versions of a given function, one thats
; a normal subroutine and another that is the psub.  Because of this
; all psub routine labels a appended with _psub.
;
; Macros are set to deal with calling psubs
;  PSUB <function>
;   This will deal with setting the return label, populating a2, a3
;   and then calling psub_enter.  Note that the macro will automatically
;   append _psub onto the supplied function name.
; PSUB_RETURN
;   When in a psub, PSUB_RETURN should be used to return from the function
	rorg	$80, $ff
psub_enter:
	subq.w	#4,d7
	jmp	*+4(PC,d7.w)
	movea.l	a3,a4
	jmp	(a2)
	movea.l	a3,a5
	jmp	(a2)
	movea.l	a3, a7
	jmp	(a2)

psub_exit:
	addq.w	#4, d7
	jmp	*(PC,d7.w)
	jmp	(a4)
	nop
	jmp	(a5)
	nop
	jmp	(a7)

; set vram addr so its at location x,y of fix layer
; params:
;  d0 = x
;  d1 = y
fix_seek_xy:
	ext.w	d0
	ext.w	d1
	lsl.w	#5, d0
	or.w	d1, d0
	or.w	#FIXMAP, d0
	move.w	d0, (-2,a6)
	rts

; clears the fix layer by setting all tiles to space/empty
fix_clear:
	move.w	#FIXMAP, (-2,a6)
	move.w	#1, (2,a6)
	move.w	#$20, d0
	move.w	#$4ff, d1
.loop_next_tile:
	move.w	d0, (a6)
	dbra	d1, .loop_next_tile
	WATCHDOG
	rts

; clears the fix layer - psub version;
fix_clear_psub:
	move.w	#FIXMAP, (-2,a6)
	move.w	#1, (2,a6)
	move.w	#$20, d0
	move.w	#$4ff, d1
.loop_next_tile:
	move.w	d0, (a6)
	dbra	d1, .loop_next_tile
	WATCHDOG
	PSUB_RETURN


; clears a line of the fix layer
; params:
;  d0 = line to clear
fix_clear_line:
	move.w	d7, -(a7)
	ext.w	d0
	add.w	#FIXMAP, d0
	move.w	d0, (-2,a6)
	move.w	#$20, (2,a6)
	moveq	#$20, d0
	move.w	#$27, d7
.loop_next_tile:
	move.w	d0, (a6)
	dbra	d7, .loop_next_tile
	move.w	(a7)+, d7
	rts

; clears a line of the fix layer - psub version
; params:
;  d0 = line to clear
fix_clear_line_psub:
	ext.w	d0
	add.w	#FIXMAP, d0
	move.w	d0, (-2,a6)
	move.w	#$20, (2,a6)
	moveq	#$20, d0
	moveq	#$27, d1
.loop_next_tile:
	move.w	d0, (a6)
	dbra	d1, .loop_next_tile
	PSUB_RETURN


; prints a char at x,y of fix layer
; parms:
; d0 = x
; d1 = y
; d2 = char
print_xy_char:
	bsr	fix_seek_xy
	and.w	#$ff, d2
	move.w	d2, (a6)
	rts

; prints an array of xyp string structs until $00 is encountered
; params:
; a0 = start of array of xyp string structs
print_xyp_string_struct_multi:
	bsr	print_xyp_string_struct
	tst.b	(a0)
	bne	print_xyp_string_struct_multi
	rts

; clears the line that an xyp string will be on, then falls through to print_xyp_string_struct
; params:
; a0 = start of xyp string struct
print_xyp_string_struct_clear:
	move.b	(1,a0), d0
	bsr	fix_clear_line

; converts an xyp string struct into the format that print_xyp_string expects, then falls through to it
; params:
;  a0 = start of xyp string struct
print_xyp_string_struct:
	move.b	(a0)+, d0
	move.b	(a0)+, d1
	move.b	(a0)+, d2

; prints string at starting at x,y using d2 as the upper byte of the fix map entry
; params:
;  d0 = x
;  d1 = y
;  d2 = upper byte of fix map entry
;  a0 = address of string
print_xyp_string:
	bsr	fix_seek_xy
	move.w	#$20, (2,a6)
	move.b	d2, -(a7)		; these 3 instructions cause the d2.b to be moved to
	move.w	(a7)+, d2		; the upper byte of d2.w.  The lower d2.w will be garbage,
	move.b	(a0)+, d2		; but we replace it with current char from string
.loop_next_char:
	move.w	d2, (a6)
	move.b	(a0)+, d2
	bne	.loop_next_char
	rts


; prints string struct as double height letters at x,y using d2 as the upper byte of the fix map entry
; params:
;  a0 = start of xyp string struct
; this appears to be an unused subroutine
print16_xyp_string_struct:
	move.b	(a0)+, d0
	move.b	(a0)+, d1
	move.b	(a0)+, d2
	move.l	a1, -(a7)
	addq.b	#1, d2
	bsr	fix_seek_xy

	move.w	#$20, (2,a6)		; top half of chars
	move.b	d2, -(a7)
	move.w	(a7)+, d2
	movea.l	a0, a1
	move.b	(a0)+, d2
.loop_next_char_top:
	move.w	d2, (a6)
	move.b	(a0)+, d2
	bne	.loop_next_char_top

	addq.w	#1, d1			; bottom half of chars on the next line
	move.w	d1, (-2,a6)
	add.w	#$100, d2
	move.b	(a1)+, d2
.loop_next_char_bottom:
	move.w	d2, (a6)
	move.b	(a1)+, d2
	bne	.loop_next_char_bottom

	movea.l	(a7)+, a1
	rts


; clears the line that an string will be on, then falls through to print_xy_string
; params:
;  d0 = x
;  d1 = y
;  a0 = string location
print_xy_string_clear:
	move.w	d0, -(a7)
	move.b	d1, d0
	bsr	fix_clear_line
	move.w	(a7)+, d0

; print string to x,y
; params:
;  d0 = x
;  d1 = y
;  a0 = string location
print_xy_string:
	bsr	fix_seek_xy
	move.w	#$20, (2,a6)
	moveq	#$0, d0
	move.b	(a0)+, d0
.loop_next_char:
	move.w	d0, (a6)
	move.b	(a0)+, d0
	bne	.loop_next_char
	rts

; prints string as double height letters at x,y
; params:
;  d0 = x
;  d1 = y
;  a0 = string location
; this appears to be an unused subroutine
print16_xy_string:
	move.l	a1, -(a7)
	bsr	fix_seek_xy
	move.w	#$20, (2,a6)
	movea.l	a0, a1
	move.w	#$100, d0		; top half of letter
	move.b	(a0)+, d0
.loop_next_char_top:
	move.w	d0, (a6)
	move.b	(a0)+, d0
	bne	.loop_next_char_top

	addq.w	#1, d1
	move.w	d1, (-2,a6)
	move.w	#$200, d0		; bottom half of letter on the next line
	move.b	(a1)+, d0
.loop_next_char_bottom:
	move.w	d0, (a6)
	move.b	(a1)+, d0
	bne	.loop_next_char_bottom
	movea.l	(a7)+, a1
	rts

; clears the line the string will be printed on, then falls through to print_xy_string_psub - psub version
; params:
;  d0 = x
;  d1 = y
;  a0 = string location
print_xy_string_clear_psub:
	move.b	d0, d2			; fix_clear_line expect d0 to be y
	swap	d2			; backup d0.b and d1.b into d2
	move.b	d1, d2			; then make d0.b be y
	move.b	d1, d0
	PSUB	fix_clear_line
	move.b	d2, d1			; restore d0.b and d1.b
	swap	d2
	move.b	d2, d0

; print string to x,y - psub version
; params:
;  d0 = x
;  d1 = y
;  a0 = string location
print_xy_string_psub:
	ext.w	d0
	ext.w	d1
	lsl.w	#5, d0
	or.w	d0, d1
	or.w	#FIXMAP, d1
	move.w	d1, (-2,a6)		; seek to xy
	move.w	#$20, (2,a6)
	moveq	#0, d2
	move.b	(a0)+, d2
.loop_next_char:
	move.w	d2, (a6)
	move.b	(a0)+, d2
	bne	.loop_next_char
	PSUB_RETURN

; clears the line that an xyp string will be on, then falls through to print_xyp_string_struct_psub - psub version
; params:
;  a0 = start of xyp string struct
print_xy_string_struct_clear_psub:
	move.b	(1,a0), d0
	PSUB	fix_clear_line

; prints xyp string at x,y - psub version
; params:
;  a0 - start of xyp string struct
print_xy_string_struct_psub:
	move.b	(a0)+, d0
	move.b	(a0)+, d1
	ext.w	d0
	ext.w	d1
	lsl.w	#5, d0
	or.w	d0, d1
	or.w	#FIXMAP, d1		; seek to xy
	move.w	d1, (-2,a6)
	move.w	#$20, (2,a6)
	moveq	#0, d2
	move.b	(a0)+, d2
.loop_next_char:
	move.w	d2, (a6)
	move.b	(a0)+, d2
	bne	.loop_next_char
	PSUB_RETURN

; prints the char n times starting at x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = upper byte of fix map entry
;  d3 = char
;  d4 = number of times to print
print_char_repeat:
	bsr	fix_seek_xy
	move.w	#$20, (2,a6)
	lsl.w	#8, d2
	move.b	d3, d2
	subq.w	#1, d4
.loop_next_tile:
	move.w	d2, (a6)
	dbra	d4, .loop_next_tile
	rts

; prints the char n times starting at x,y - psub version
; params:
;  d0 = x
;  d1 = y
;  d2 = upper byte of fix map entry
;  d3 = char
;  d4 = number of times to print
print_char_repeat_psub:
	ext.w	d0
	ext.w	d1
	lsl.w	#5, d0
	or.w	d0, d1
	or.w	#FIXMAP, d1
	move.w	d1, (-2,a6)		; seek to x,y
	move.w	#$20, (2,a6)
	lsl.w	#8, d2
	move.b	d3, d2
	subq.w	#1, d4
.loop_next_tile:
	move.w	d2, (a6)
	dbra	d4, .loop_next_tile
	PSUB_RETURN

; prints 1 byte in hex starting at location x,y - psub version
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_hex_byte_psub:
	addq.w	#1, d0
	ext.w	d0
	ext.w	d1
	lsl.w	#5, d0
	or.w	d0, d1
	or.w	#FIXMAP, d1			; seek to x + 1, y
	move.w	d1, (-2,a6)
	moveq	#1, d1
	bra	print_hex_psub			; handles PSUB_RETURN for us

; prints 2 bytes in hex starting at location x,y - psub version
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_hex_word_psub:
	addq.w	#3, d0
	ext.w	d0
	ext.w	d1
	lsl.w	#5, d0
	or.w	d0, d1
	or.w	#FIXMAP, d1			; seek to x + 3, y
	move.w	d1, (-2,a6)
	moveq	#3, d1
	bra	print_hex_psub			; handles PSUB_RETURN for us


; prints 3 bytes in hex starting at location x,y - psub version
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_hex_3_bytes_psub:
	addq.w	#5, d0
	ext.w	d0
	ext.w	d1
	lsl.w	#5, d0
	or.w	d0, d1
	or.w	#FIXMAP, d1			; seek to x + 5, y
	move.w	d1, (-2,a6)
	moveq	#5, d1
	bra	print_hex_psub			; handles PSUB_RETURN for us


; prints 4 bytes in hex starting at location x,y - psub version
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_hex_long_psub:
	addq.w	#7, d0
	ext.w	d0
	ext.w	d1
	lsl.w	#5, d0
	or.w	d0, d1
	or.w	#FIXMAP, d1			; seek to x + 7, y
	move.w	d1, (-2,a6)
	moveq	#7, d1				; falls through to print_hex_psub

; prints N hex chars, caller must already be at end x,y location as this function prints backwards - psub version
; params:
;  d1 = number of chars to print - 1
;  d2 = data
print_hex_psub:
	move.w	#$ffe0, (2,a6)			; write backwards
	bra	.loop_start

.loop_next_hex:
	lsr.l	#4, d2
.loop_start:
	moveq	#$f, d0
	and.b	d2, d0
	move.b	(HEX_LOOKUP,PC,d0.w), d0
	move.w	d0, (a6)
	dbra	d1, .loop_next_hex
	PSUB_RETURN

HEX_LOOKUP:
	dc.b	"0123456789ABCDEF"


; prints N hex chars, caller must already be at end x,y location as this function prints backwards
; params:
;  d1 = number of chars to print - 1
;  d2 = data
print_hex:
	move.w	#$ffe0, (2,a6)			; write backwards
	bra	.loop_start

.loop_next_hex:
	lsr.l	#4, d2
.loop_start:
	moveq	#$f, d0
	and.b	d2, d0
	move.b	(HEX_LOOKUP,PC,d0.w), d0
	move.w	d0, (a6)
	dbra	d1, .loop_next_hex
	rts


; prints 1 nibble in hex starting at location x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_hex_nibble:
	bsr	fix_seek_xy
	moveq	#0, d1
	bra	print_hex			; will rts for us


; prints 1 byte in hex starting at location x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_hex_byte:
	addq.w	#1, d0
	bsr	fix_seek_xy			; seek to x + 1, y
	moveq	#1, d1
	bra	print_hex			; handles rts

; prints 2 bytes in hex starting at location x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_hex_word:
	addq.w	#3, d0
	bsr	fix_seek_xy			; seek to x + 3, y
	moveq	#3, d1
	bra	print_hex			; handles rts

; prints 3 bytes in hex starting at location x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_hex_3_bytes:
	addq.w	#5, d0
	bsr	fix_seek_xy			; seek x + 5, y
	moveq	#5, d1
	bra	print_hex			; handles rts


; prints 4 bytes in hex starting at location x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_hex_long:
	addq.w	#7, d0
	bsr	fix_seek_xy			; seek x + 7, y
	moveq	#7, d1
	bra	print_hex			; handles rts


; prints bit 0/1 at location x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data (bit 0)
print_bit:
	bsr	fix_seek_xy
	move.w	#$ffe0, (2,a6)			; write backwards, pointless instruction?
	and.w	#1, d2
	add.b	#$30, d2
	move.w	d2, (a6)
	rts


; prints a digit start at x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = digit
print_digit:
	bsr	fix_seek_xy
	moveq	#0, d1
	bra	print_digits			; handles rts

; prints 3 digits starting at x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_3_digits:
	addq.w	#2, d0
	bsr	fix_seek_xy			; seek to x + 2, y
	moveq	#2, d1
	bra	print_digits			; handles rts

; prints 5 digits starting at x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data
; unused code?
print_5_digits:
	addq.w	#4, d0
	bsr	fix_seek_xy			; seek to x + 4, y
	moveq	#4, d1
	nop					; falls through to print_digits

; prints digits
; params:
;  d1 = number of digits - 1
;  d2 = data
; prints backwards so caller must have x,y at the end location you want
print_digits:
	move.w	#$ffe0, (2,a6)			; write backwards
	moveq	#$30, d0
.loop_next_digit:
	divu.w	#10, d2				; divide by 10 and print the remainder
	swap	d2
	add.b	d0, d2
	move.w	d2, (a6)
	clr.w	d2
	swap	d2
	dbra	d1, .loop_next_digit
	rts

; prints 5 digits starting at x,y - psub version
; params:
;  d0 = x
;  d1 = y
;  d2 = data
; unused code?
print_5_digits_psub:
	addq.w	#4, d0
	ext.w	d0
	ext.w	d1
	lsl.w	#5, d0
	or.w	d0, d1
	or.w	#FIXMAP, d1
	move.w	d1, (-2,a6)			; seek to x + 4, y
	moveq	#4, d1
	nop
	move.w	#$ffe0, (2,a6)			; write backwards
	moveq	#$30, d0
.loop_next_digit:
	divu.w	#10, d2				; divide by 10 and print the remainder
	swap	d2
	add.b	d0, d2
	move.w	d2, (a6)
	clr.w	d2
	swap	d2
	dbra	d1, .loop_next_digit
	PSUB_RETURN

; moves fix memory from src to dst, src memory will be ovewritten with $20 tile
; params:
;  d0 = src addr
;  d1 = dst addr
;  d7 = length (words)
fix_move_memory:
	move.w	#1, (2,a6)
	move.w	d0, (-2,a6)
	lea	REG_WATCHDOG, a0
	move.w	#$20, d6
	subq.w	#1, d7
.loop_next_address:
	move.w	(a6), d2
	move.w	d6, (a6)			; clear src location
	move.w	d1, (-2,a6)
	addq.w	#1, d0
	move.w	d2, (a6)
	move.w	d0, (-2,a6)
	addq.w	#1, d1
	move.b	d0, (a0)			; WATCHDOG
	nop
	dbra	d7, .loop_next_address
	rts


; moves all of fix memory to ext
; unused code
fix_move_to_ext:
	move.w	#FIXMAP, d0
	move.w	#FIXMAP_EXT, d1
	move.w	#$500, d7
	bsr	fix_move_memory
	rts

; moves all ext memory to fix
; unused code
fix_move_from_ext:
	move.w	#FIXMAP_EXT, d0
	move.w	#FIXMAP, d1
	move.w	#$500, d7
	bsr	fix_move_memory
	rts


; start
_start:
	WATCHDOG
	clr.b	REG_POUTPUT
	clr.b	p1_input
	clr.b	p1_input_edge
	clr.b	p1_input_aux
	clr.b	p1_input_aux_edge
	move.w	#7, REG_IRQACK
	move.w	#$4000, REG_LSPCMODE
	lea	REG_VRAMRW, a6					; a6 will always be REG_VRAMRW
	moveq	#$c, d7						; init d7 for psub
	move.l	#$7fff0000, PALETTE_RAM_START+$2		; white on black for text
	move.l	#$07770000, PALETTE_RAM_START+PALETTE_SIZE+$2	;  gray on black for text (disabled menu items)
	clr.w	PALETTE_REFERENCE
	clr.w	PALETTE_BACKDROP

	PSUB	fix_clear

	moveq	#-$10, d0
	and.b	REG_P1CNT, d0			; check for A+B+C+D being pressed, if not automatic_tests

	ifnd force_manual_tests
		bne	automatic_tests
	endif

	movea.l	$0, a7				; re-init SP so we can call real subroutines
	clr.b	main_menu_cursor
	bra	manual_tests

automatic_tests:
	PSUB	print_header
	PSUB	watchdog_stuck_test
	PSUB	automatic_psub_tests

	movea.l	$0, a7				; re-init SP

	clr.b	z80_test_flags

	btst	#7, REG_P1CNT			; if P1 "D" was pressed at boot
	beq	.z80_user_enabled

	; auto-detect m1 by checking for the HELLO message (ie diag m1 + AES or MV-1B/C)
	move.b	#COMM_TEST_HELLO, d1
	cmp.b	REG_SOUND, d1
	beq	skip_slot_switch

 	ifnd force_z80_tests
		bne	skip_z80_test		; skip Z80 tests if "D" not pressed
 	endif

.z80_user_enabled:

	bset.b	#Z80_TEST_FLAG_ENABLED, z80_test_flags

	tst.b	REG_STATUS_B
	bpl	skip_slot_switch		; skip slot switch if AES

	btst	#5, REG_P1CNT
	beq	skip_slot_switch		; skip slot switch if P1 "B" is pressed

	bsr	z80_slot_switch

skip_slot_switch:

	bsr	z80_comm_test
	lea	XYP_STR_Z80_WAITING, a0
	bsr	print_xyp_string_struct_clear

.loop_try_again:
	WATCHDOG
	bsr	z80_check_error
	bsr	z80_check_sm1_test
	bsr	z80_check_done
	bne	.loop_try_again

skip_z80_test:

	bsr	automatic_function_tests
	lea	XYP_STR_ALL_TESTS_PASSED, a0
	bsr	print_xyp_string_struct_clear

	lea	XYP_STR_ABCD_MAIN_MENU, a0
	bsr	print_xyp_string_struct_clear

	tst.b	z80_test_flags

	bne	.loop_user_input

	lea	XYP_STR_Z80_TESTS_SKIPPED, a0
	bsr	print_xyp_string_struct_clear

	lea	XYP_STR_Z80_HOLD_D_AND_SOFT, a0
	bsr	print_xyp_string_struct_clear

	lea	XYP_STR_Z80_RESET_WITH_CART, a0
	bsr	print_xyp_string_struct_clear

.loop_user_input
	WATCHDOG
	bsr	check_reset_request

	moveq	#-$10, d0
	and.b	REG_P1CNT, d0		; ABCD pressed?
	bne	.loop_user_input

	movea.l	$0, a7
	clr.b	main_menu_cursor
	bsr	fix_clear
	bra	manual_tests

watchdog_stuck_test_psub:
	lea	XY_STR_WATCHDOG_DELAY, a0
	PSUB	print_xy_string_struct_clear
	lea	XY_STR_WATCHDOG_TEXT_REMAINS, a0
	PSUB	print_xy_string_struct_clear
	lea	XY_STR_WATCHDOG_STUCK, a0
	PSUB	print_xy_string_struct_clear

	move.l	#$c930, d0		; 128760us / 128.76ms
	PSUB	delay

	moveq	#8, d0
	PSUB	fix_clear_line
	moveq	#10, d0
	PSUB	fix_clear_line
	PSUB_RETURN

; runs automatic tests that are psub based;
automatic_psub_tests_psub:
	moveq	#0, d6
.loop_next_test:
	movea.l	(AUTOMATIC_PSUB_TEST_STRUCT_START+4,pc,d6.w),a0
	moveq	#4, d0
	moveq	#5, d1
	PSUB	print_xy_string_clear			; print the test description to screen

	movea.l	(AUTOMATIC_PSUB_TEST_STRUCT_START,pc,d6.w), a2
	lea	(.psub_return), a3			; manually do psub call since the PSUB macro wont
	bra	psub_enter				; work in this case
.psub_return

	tst.b	d0					; check result
	beq	.test_passed

	move.b	d0, d6
	PSUB	print_error_data

	move.b	d6, d0
	PSUB	get_error_description

	moveq	#4, d0
	moveq	#5, d1
	PSUB	print_xy_string_clear

	tst.b	REG_STATUS_B
	bpl	.skip_error_to_credit_leds	; skip if aes
	move.b	d6, d0
	PSUB	error_to_credit_leds

.skip_error_to_credit_leds
	bra	loop_reset_check_psub

.test_passed:
	addq.w	#8, d6
	cmp.w	#(AUTOMATIC_PSUB_TEST_STRUCT_END - AUTOMATIC_PSUB_TEST_STRUCT_START), d6
	bne	.loop_next_test
	PSUB_RETURN


AUTOMATIC_PSUB_TEST_STRUCT_START:
	dc.l	auto_bios_mirror_test_psub, STR_TESTING_BIOS_MIRROR
	dc.l	auto_bios_crc32_test_psub, STR_TESTING_BIOS_CRC32
	dc.l	auto_ram_oe_tests_psub, STR_TESTING_RAM_OE
	dc.l	auto_ram_we_tests_psub, STR_TESTING_RAM_WE
	dc.l	auto_wram_data_tests_psub, STR_TESTING_WRAM_DATA
	dc.l	auto_wram_addreess_tests_psub, STR_TESTING_WRAM_ADDRESS
AUTOMATIC_PSUB_TEST_STRUCT_END:


; runs automatic tests that are subroutine based;
automatic_function_tests:
	lea	AUTOMATIC_FUNC_TEST_STRUCT_START, a5
	moveq	#((AUTOMATIC_FUNC_TEST_STRUCT_END - AUTOMATIC_FUNC_TEST_STRUCT_START)/8 - 1), d7

.loop_next_test:
	movea.l	(a5)+, a4			; test function address
	movea.l	(a5)+, a0			; test name string address
	movea.l	a0, a0
	moveq	#4, d0
	moveq	#5, d1
	bsr	print_xy_string_clear		; at 4,5 print test name

	move.l	a5, -(a7)
	move.w	d7, -(a7)
	jsr	(a4)				; run function
	move.w	(a7)+, d7
	movea.l	(a7)+, a5

	tst.b	d0				; check result
	beq	.test_passed

	move.w	d0, -(a7)
	bsr	print_error_data

	move.w	(a7), d0
	bsr	get_error_description

	movea.l	a0, a0
	moveq	#4, d0
	moveq	#5, d1
	bsr	print_xy_string_clear

	move.w	(a7)+, d0
	tst.b	z80_test_flags			; if z80 test enabled, send error code to z80
	beq	.skip_error_to_z80
	move.b	d0, REG_SOUND

.skip_error_to_z80:
	tst.b	REG_STATUS_B
	bpl	.skip_error_to_credit_leds		; skip if aes
	bsr	error_to_credit_leds

.skip_error_to_credit_leds
	bra	loop_reset_check

.test_passed:
	dbra	d7, .loop_next_test
	rts


AUTOMATIC_FUNC_TEST_STRUCT_START:
	dc.l	auto_bram_tests, STR_TESTING_BRAM
	dc.l	auto_palette_ram_tests, STR_TESTING_PALETTE_RAM
	dc.l	auto_vram_tests, STR_TESTING_VRAM
	dc.l	auto_mmio_tests, STR_TESTING_MMIO
AUTOMATIC_FUNC_TEST_STRUCT_END:



; swiches to cart M1/S1 roms;
z80_slot_switch:

	bset.b	#Z80_TEST_FLAG_SLOT_SWITCH, z80_test_flags

	lea	XYP_STR_Z80_SWITCHING_M1, a0
	bsr	print_xyp_string_struct_clear

	move.b	#$01, REG_SOUND				; tell z80 to prep for m1 switch

	move.l	#$1388, d0				; 12500us / 12.5ms
	bsr	delay

	cmpi.b	#$01, REG_SOUND
	beq	.z80_slot_switch_ready
	bsr	z80_slot_switch_ignored

.z80_slot_switch_ready:

	move.b	REG_P1CNT, d0
	moveq	#$f, d1
	and.b	d1, d0
	eor.b	d1, d0

	moveq	#((Z80_SLOT_SELECT_END - Z80_SLOT_SELECT_START)/2 - 1), d1
	lea	(Z80_SLOT_SELECT_START - 1), a0

.loop_next_entry:
	addq.l	#1, a0
	cmp.b	(a0)+, d0
	dbeq	d1, .loop_next_entry		; loop through struct looking for p1 input match
	beq	.z80_do_slot_switch

	addq.l	#2, a0				; nothing matched, use the last entry (slot 1)

.z80_do_slot_switch:

	move.b	(a0), d3
	lea	(XYP_STR_Z80_SLOT_SWITCH_NUM), a0	; "[SS ]"
	bsr	print_xyp_string_struct

	move.b	#32, d0
	moveq	#4, d1
	move.b	d3, d2
	bsr	print_digit			; print the slot number

	subq	#1, d3				; convert to what REG_SLOT expects, 0 to 5
	move.b	d3, REG_SLOT			; set slot
	move.b	d0, REG_CRTFIX			; switch to carts m1/s1
	move.b	#$3, REG_SOUND			; tell z80 to reset
	rts


; struct {
; 	byte buttons_pressed; 	(up/down/left/right)
;  	byte slot;
; }
Z80_SLOT_SELECT_START:
	dc.b	$01, $02			; up = slot 2
	dc.b	$09, $03			; up+right = slot 3
	dc.b	$08, $04			; right = slot 4
	dc.b	$0a, $05			; down+right = slot 5
	dc.b	$02, $06			; down = slot 6
Z80_SLOT_SELECT_END:
	dc.b	$00, $01			; no match = slot 1


z80_slot_switch_ignored:
	lea	XYP_STR_Z80_IGNORED_SM1, a0
	bsr	print_xyp_string_struct_clear
	lea	XYP_STR_Z80_SM1_UNRESPONSIVE, a0
	bsr	print_xyp_string_struct_clear
	lea	XYP_STR_Z80_MV1BC_HOLD_B, a0
	bsr	print_xyp_string_struct_clear
	lea	XYP_STR_Z80_PRESS_START, a0
	bsr	print_xyp_string_struct_clear

	bsr	print_hold_ss_to_reset

.loop_start_not_pressed:
	WATCHDOG
	bsr	check_reset_request
	btst	#0, REG_STATUS_B
	bne	.loop_start_not_pressed		; loop waiting for user to press start or do a reboot request

.loop_start_pressed:
	WATCHDOG
	bsr	check_reset_request
	btst	#0, REG_STATUS_B
	beq	.loop_start_pressed		; loop waiting for user to release start or do a reboot request

	bsr	fix_clear_line_27		; unclear why this one has its own subroutine
	moveq	#7, d0
	bsr	fix_clear_line
	moveq	#10, d0
	bsr	fix_clear_line
	moveq	#12, d0
	bsr	fix_clear_line
	rts


; params:
;  d0 * 2.5us = how long to delay
delay:
	move.b	d0, REG_WATCHDOG	; 16 cycles
	subq.l	#1, d0			; 4 cycles
	bne	delay			; 10 cycles
	rts

; params:
;  d0 * 2.5us = how long to delay
; never called
delay_psub:
	move.b	d0, REG_WATCHDOG
	subq.l	#1, d0
	bne	delay_psub
	PSUB_RETURN

; see if the z80 sent us an error
z80_check_error:
	moveq	#-$40, d0
	and.b	REG_SOUND, d0
	cmp.b	#$40, d0		; 0x40 = flag indicating a z80 error
	bne	.no_error

	move.b	REG_SOUND, d0		; get the error (again?)
	move.b	d0, d2
	move.l	#$100000, d1
	bsr	z80_ack_error		; ack the error by sending it back, and wait for z80 to ack or ack
	bne	loop_reset_check

	moveq	#$1d, d0
	moveq	#$c, d1
	and.b	#$3f, d2		; drop the flag to get the actual error code
	move.w	d2, -(a7)
	bsr	print_hex_byte

	lea	XYP_STR_Z80_ERROR_CODE.l, a0
	bsr	print_xyp_string_struct

	move.w	(a7), d0

	bsr	get_error_description
	moveq	#$4, d0
	moveq	#$e, d1
	bsr	print_xyp_string

	moveq	#$15, d0
	bsr	fix_clear_line
	moveq	#$16, d0
	bsr	fix_clear_line

	move.w	(a7)+, d0

	tst.b	REG_STATUS_B
	bpl	.skip_error_to_credit_leds	; skip if aes
	bsr	error_to_credit_leds

.skip_error_to_credit_leds

	bra	loop_reset_check

.no_error:
	rts

z80_check_sm1_test:

	; diag m1 is asking us to swap m1 -> sm1
	move.b	REG_SOUND, d0
	cmp.b	#COMM_SM1_TEST_SWITCH_SM1, d0
	bne	.check_swap_to_m1

	btst	#Z80_TEST_FLAG_SLOT_SWITCH, z80_test_flags		; only allow if we did a slot switch
	bne	.switch_sm1_allow

	move.b  #COMM_SM1_TEST_SWITCH_SM1_DENY, REG_SOUND
	bsr	z80_wait_clear
	rts

.switch_sm1_allow:
	move.b	d0, REG_BRDFIX
	move.b	#COMM_SM1_TEST_SWITCH_SM1_DONE, REG_SOUND

	lea	(XYP_STR_Z80_SM1_TESTS), a0		; "[SM1]" to indicate m1 is running sm1 tests
	bsr	print_xyp_string_struct

	bsr	z80_wait_clear
	rts

.check_swap_to_m1:
	; diag m1 asking us to swap sm1 -> m1
	cmp.b	#COMM_SM1_TEST_SWITCH_M1, d0
	bne	.no_swaps

	move.b	d0, REG_CRTFIX
	move.b	#COMM_SM1_TEST_SWITCH_M1_DONE, REG_SOUND

	bsr	z80_wait_clear

.no_swaps:
	rts

; d0 = loop until we stop getting this byte from z80
z80_wait_clear:
	WATCHDOG
	cmp.b	REG_SOUND, d0
	beq	z80_wait_clear
	rts

XYP_STR_Z80_ERROR_CODE:		XYP_STRING 4, 12, 0, "Z80 REPORTED ERROR CODE: "


; see if z80 says its done testing (with no issues)
z80_check_done:
	move.b	#COMM_Z80_TESTS_COMPLETE, d0
	cmp.b	REG_SOUND, d0
	rts

z80_comm_test:

	lea	XYP_STR_Z80_M1_ENABLED, a0
	bsr	print_xyp_string_struct

	lea	XYP_STR_Z80_TESTING_COMM_PORT, a0
	bsr	print_xyp_string_struct_clear

	move.b	#COMM_TEST_HELLO, d1
	move.w  #500, d2
	bra	.loop_start_wait_hello

; wait up to 5 seconds for hello (10ms * 500 loops)
.loop_wait_hello
	move.w	#4000, d0
	bsr	delay
.loop_start_wait_hello
	cmp.b	REG_SOUND, d1
	dbeq	d2, .loop_wait_hello
	bne	.z80_hello_timeout

	move.b	#COMM_TEST_HANDSHAKE, REG_SOUND

	moveq	#COMM_TEST_ACK, d1
	move.w	#100, d2
	bra	.loop_start_wait_ack

; Wait up to 1 second for ack response (10ms delay * 100 loops)
; This is kinda long but the z80 has its own loop waiting for a
; Z80_SEND_HANDSHAKE request.  We need our loop to last longer
; so the z80 has a chance to timeout and give us an error,
; otherwise we will just get the last thing to wrote (Z80_RECV_HELLO).
.loop_wait_ack:
	move.w	#4000, d0
	bsr	delay
.loop_start_wait_ack:
	cmp.b	REG_SOUND, d1
	dbeq	d2, .loop_wait_ack
	bne	.z80_ack_timeout
	rts

.z80_hello_timeout
	lea	XYP_STR_Z80_COMM_NO_HELLO, a0
	bra	.print_error

.z80_ack_timeout
	lea	XYP_STR_Z80_COMM_NO_ACK, a0

.print_error
	move.b	d1, d0
	bra	z80_print_comm_error



; loop forever checking for reset request;
loop_reset_check:
	bsr	print_hold_ss_to_reset
.loop_forever:
	WATCHDOG
	bsr	check_reset_request
	bra	.loop_forever


; loop forever checking for reset request - psub version
loop_reset_check_psub:
	moveq	#27, d0
	PSUB	fix_clear_line

	moveq	#4, d0
	moveq	#27, d1
	lea	STR_HOLD_SS_TO_RESET, a0
	PSUB	print_xy_string

.loop_ss_not_pressed:
	WATCHDOG
	moveq	#3, d0
	and.b	REG_STATUS_B, d0
	bne	.loop_ss_not_pressed		; loop until P1 start+select both held down

	moveq	#27, d0
	PSUB	fix_clear_line

	moveq	#4, d0
	moveq	#27, d1
	lea	STR_RELEASE_SS, a0
	PSUB	print_xy_string

.loop_ss_pressed:
	WATCHDOG
	moveq	#3, d0
	and.b	REG_STATUS_B, d0
	cmp.b	#3, d0
	bne	.loop_ss_pressed		; loop until P1 start+select are released

	reset
	stop	#$2700

; check if P1 is pressing start+select, if they are loop until
; they release and reset, else just return
check_reset_request:
	move.w	d0, -(a7)
	moveq	#3, d0
	and.b	REG_STATUS_B, d0

	bne	.ss_not_pressed			; P1 start+select not pressed, exit out

	moveq	#4, d0
	moveq	#27, d1
	lea	STR_RELEASE_SS, a0
	bsr	print_xy_string_clear

.loop_ss_pressed:
	WATCHDOG
	moveq	#3, d0
	and.b	REG_STATUS_B, d0
	cmp.b	#3, d0
	bne	.loop_ss_pressed		; wait for P1 start+select to be released, before reset

	reset
	stop	#$2700

.ss_not_pressed:
	move.w	(a7)+, d0
	rts

print_hold_ss_to_reset:
	moveq	#4, d0
	moveq	#27, d1
	lea	STR_HOLD_SS_TO_RESET, a0
	bsr	print_xy_string_clear
	rts

; clears line 27 of fix layer, only seems to be called once;
fix_clear_line_27:
	moveq	#27, d0
	bsr	fix_clear_line
	rts



; prints headers
; NEO DIAGNOSTICS v0.19 - BY SMKDAN
; ---------------------------------
print_header:
	moveq	#0, d0
	moveq	#4, d1
	moveq	#1, d2
	moveq	#$16, d3
	moveq	#40, d4
	bsr	print_char_repeat			; $116 which is an overscore line

	moveq	#2, d0
	moveq	#3, d1
	lea	STR_VERSION_HEADER, a0
	bsr	print_xy_string_clear
	rts

; prints headers - psub version
; NEO DIAGNOSTICS v0.19 - BY SMKDAN
; ---------------------------------
print_header_psub:
	moveq	#0, d0
	moveq	#4, d1
	moveq	#1, d2
	moveq	#$16, d3
	moveq	#40, d4
	PSUB	print_char_repeat			; $116 which is an overscore line

	moveq	#3, d0
	PSUB	fix_clear_line

	moveq	#2, d0
	moveq	#3, d1
	lea	STR_VERSION_HEADER, a0
	PSUB	print_xy_string
	PSUB_RETURN

; prints the z80 related communication error
; params:
;  d0 = expected response
;  a0 = xyp_string_struct address for main error
z80_print_comm_error:
	move.w	d0, -(a7)

	bsr	print_xyp_string_struct_clear

	moveq	#4, d0
	moveq	#8, d1
	lea	STR_EXPECTED, a0
	bsr	print_xy_string_clear

	moveq	#4, d0
	moveq	#10, d1
	lea	STR_ACTUAL, a0
	bsr	print_xy_string_clear

	lea	XYP_STR_Z80_SKIP_TEST, a0
	bsr	print_xyp_string_struct_clear
	lea	XYP_STR_Z80_PRESS_D_RESET, a0
	bsr	print_xyp_string_struct_clear

	move.w	(a7)+, d2
	moveq	#14, d0
	moveq	#8, d1
	bsr	print_hex_byte				; expected value

	move.b	REG_SOUND, d2
	moveq	#14, d0
	moveq	#10, d1
	bsr	print_hex_byte				; actual value

	lea	XYP_STR_Z80_MAKE_SURE, a0
	bsr	print_xyp_string_struct_clear

	lea	XYP_STR_Z80_CART_CLEAN, a0
	bsr	print_xyp_string_struct_clear

	bsr	z80_check_error
	bra	loop_reset_check

; looks up the error code to find the corresponding description
; from the EC_LOOKUP_TABLE below
; params:
;  d0 = error code
; returns:
;  a0 = string address
get_error_description:
	lea	(EC_LOOKUP_TABLE - 4), a0
	moveq	#((EC_LOOKUP_TABLE_END - EC_LOOKUP_TABLE)/6 - 1), d1
	and.w	#$ff, d0
.loop_next_entry:
	addq.l	#4, a0
	cmp.w	(a0)+, d0
	dbeq	d1, .loop_next_entry
	beq	.match_found
	lea	STR_UNKNOWN_ERROR_CODE.l, a0
	rts
.match_found:
	movea.l	(a0), a0
	rts


STR_UNKNOWN_ERROR_CODE:		STRING "UNKNOWN ERROR CODE"

get_error_description_psub:
	lea	(EC_LOOKUP_TABLE - 4),a0
	moveq	#((EC_LOOKUP_TABLE_END - EC_LOOKUP_TABLE)/6 - 1), d1
	and.w	#$ff, d0
.loop_next_entry:
	addq.l	#4, a0
	cmp.w	(a0)+, d0
	dbeq	d1, .loop_next_entry
	beq	.match_found

	lea	STR_UNKNOWN_ERROR_CODE_NS.l, a0
	PSUB_RETURN

.match_found:
	movea.l	(a0), a0
	PSUB_RETURN


STR_UNKNOWN_ERROR_CODE_NS: 	STRING "UNKNOWN ERROR CODE (NS)"

EC_LOOKUP_TABLE:
	EC_LOOKUP_ITEM Z80_M1_CRC
	EC_LOOKUP_ITEM Z80_M1_UPPER_ADDRESS
	EC_LOOKUP_ITEM Z80_RAM_DATA_00
	EC_LOOKUP_ITEM Z80_RAM_DATA_55
	EC_LOOKUP_ITEM Z80_RAM_DATA_AA
	EC_LOOKUP_ITEM Z80_RAM_DATA_FF
	EC_LOOKUP_ITEM Z80_RAM_ADDRESS_A0_A7
	EC_LOOKUP_ITEM Z80_RAM_ADDRESS_A8_A10
	EC_LOOKUP_ITEM Z80_RAM_OE
	EC_LOOKUP_ITEM Z80_RAM_WE
	EC_LOOKUP_ITEM Z80_68K_COMM_NO_HANDSHAKE
	EC_LOOKUP_ITEM Z80_68K_COMM_NO_CLEAR
	EC_LOOKUP_ITEM Z80_SM1_OE
	EC_LOOKUP_ITEM Z80_SM1_CRC

	EC_LOOKUP_ITEM YM2610_IO_ERROR
	EC_LOOKUP_ITEM YM2610_TIMER_TIMING_FLAG
	EC_LOOKUP_ITEM YM2610_TIMER_TIMING_IRQ
	EC_LOOKUP_ITEM YM2610_IRQ_UNEXPECTED
	EC_LOOKUP_ITEM YM2610_TIMER_INIT_FLAG
	EC_LOOKUP_ITEM YM2610_TIMER_INIT_IRQ

	EC_LOOKUP_ITEM Z80_M1_BANK_ERROR_16K
	EC_LOOKUP_ITEM Z80_M1_BANK_ERROR_8K
	EC_LOOKUP_ITEM Z80_M1_BANK_ERROR_4K
	EC_LOOKUP_ITEM Z80_M1_BANK_ERROR_2K

	EC_LOOKUP_ITEM BIOS_MIRROR
	EC_LOOKUP_ITEM BIOS_CRC32

	EC_LOOKUP_ITEM WRAM_DEAD_OUTPUT_LOWER
	EC_LOOKUP_ITEM WRAM_DEAD_OUTPUT_UPPER

	EC_LOOKUP_ITEM BRAM_DEAD_OUTPUT_LOWER
	EC_LOOKUP_ITEM BRAM_DEAD_OUTPUT_UPPER

	EC_LOOKUP_ITEM WRAM_UNWRITABLE_LOWER
	EC_LOOKUP_ITEM WRAM_UNWRITABLE_UPPER

	EC_LOOKUP_ITEM BRAM_UNWRITABLE_LOWER
	EC_LOOKUP_ITEM BRAM_UNWRITABLE_UPPER

	EC_LOOKUP_ITEM WRAM_DATA_0000
	EC_LOOKUP_ITEM WRAM_DATA_5555
	EC_LOOKUP_ITEM WRAM_DATA_AAAA
	EC_LOOKUP_ITEM WRAM_DATA_FFFF

	EC_LOOKUP_ITEM BRAM_DATA_0000
	EC_LOOKUP_ITEM BRAM_DATA_5555
	EC_LOOKUP_ITEM BRAM_DATA_AAAA
	EC_LOOKUP_ITEM BRAM_DATA_FFFF

	EC_LOOKUP_ITEM WRAM_ADDRESS_A0_A7
	EC_LOOKUP_ITEM WRAM_ADDRESS_A8_A14

	EC_LOOKUP_ITEM BRAM_ADDRESS_A0_A7
	EC_LOOKUP_ITEM BRAM_ADDRESS_A8_A14

	EC_LOOKUP_ITEM PAL_245_DEAD_OUTPUT_LOWER
	EC_LOOKUP_ITEM PAL_245_DEAD_OUTPUT_UPPER
	EC_LOOKUP_ITEM PAL_DEAD_OUTPUT_LOWER
	EC_LOOKUP_ITEM PAL_DEAD_OUTPUT_UPPER

	EC_LOOKUP_ITEM PAL_UNWRITABLE_LOWER
	EC_LOOKUP_ITEM PAL_UNWRITABLE_UPPER

	EC_LOOKUP_ITEM PAL_BANK0_DATA_0000
	EC_LOOKUP_ITEM PAL_BANK0_DATA_5555
	EC_LOOKUP_ITEM PAL_BANK0_DATA_AAAA
	EC_LOOKUP_ITEM PAL_BANK0_DATA_FFFF

	EC_LOOKUP_ITEM PAL_BANK1_DATA_0000
	EC_LOOKUP_ITEM PAL_BANK1_DATA_5555
	EC_LOOKUP_ITEM PAL_BANK1_DATA_AAAA
	EC_LOOKUP_ITEM PAL_BANK1_DATA_FFFF

	EC_LOOKUP_ITEM PAL_ADDRESS_A0_A7
	EC_LOOKUP_ITEM PAL_ADDRESS_A0_A12

	EC_LOOKUP_ITEM VRAM_DATA_0000
	EC_LOOKUP_ITEM VRAM_DATA_5555
	EC_LOOKUP_ITEM VRAM_DATA_AAAA
	EC_LOOKUP_ITEM VRAM_DATA_FFFF

	EC_LOOKUP_ITEM VRAM_ADDRESS_A0_A7
	EC_LOOKUP_ITEM VRAM_ADDRESS_A8_A14

	EC_LOOKUP_ITEM VRAM_32K_DEAD_OUTPUT_LOWER
	EC_LOOKUP_ITEM VRAM_32K_DEAD_OUTPUT_UPPER
	EC_LOOKUP_ITEM VRAM_2K_DEAD_OUTPUT_LOWER
	EC_LOOKUP_ITEM VRAM_2K_DEAD_OUTPUT_UPPER

	EC_LOOKUP_ITEM VRAM_32K_UNWRITABLE_LOWER
	EC_LOOKUP_ITEM VRAM_32K_UNWRITABLE_UPPER
	EC_LOOKUP_ITEM VRAM_2K_UNWRITABLE_LOWER
	EC_LOOKUP_ITEM VRAM_2K_UNWRITABLE_UPPER

	EC_LOOKUP_ITEM MMIO_DEAD_OUTPUT
EC_LOOKUP_TABLE_END:

; ack an error sent to us by the z80 by sending
; it back, and then waiting for the z80 to ack
; our ack.
; params:
;  d0 = error code z80 sent us
;  d1 = number of loops waiting for the response
z80_ack_error:
	move.b	d0, REG_SOUND
	not.b	d0			; z80's ack back should be !d0
.loop_try_again:
	WATCHDOG
	cmp.b	REG_SOUND, d0
	beq	.command_success
	subq.l	#1, d1
	bne	.loop_try_again
	moveq	#-1, d0
.command_success:
	rts

; Display the error code on player1/2 credit leds.  Player 1 led contains
; the upper 2 digits, and player 2 the lower 2 digits.  The neogeo
; doesn't seem to allow having the left digit as 0 and instead it
; will be empty
;
; Examples:
; EC_VRAM_2K_DEAD_OUTPUT_LOWER = 0x6a = 106
; Led: p1:  1, p2:  6
;
; EC_WRAM_UNWRITABLE_LOWER = 0x70 = 112
; Led: p1:  1, p2: 12
;
; EC_Z80_RAM_DATA_00 = 0x04 = 4
; Led: p1:  0, p2:  4
;
; params:
;  d0 = error code
error_to_credit_leds:
	moveq	#3, d2
	moveq	#0, d3
	moveq	#0, d4

; convert error code to bcd
.loop_next_digit:
	divu.w	#10, d0
	swap	d0
	move.b	d0, d3
	and.l	d3, d3
	or.w	d3, d4
	clr.w	d0
	swap	d0
	ror.w	#4, d4
	dbra	d2, .loop_next_digit

	not.w	d4				; inverted per dev wiki

	; player 2 led
	move.b	#LED_NO_LATCH, REG_LEDLATCHES
	move.w	#$10, d0
	bsr	delay				; 40us

	move.b	d4, REG_LEDDATA

	move.b	#LED_P2_LATCH, REG_LEDLATCHES
	move.w	#$10, d0
	bsr	delay

	move.b	#LED_NO_LATCH, REG_LEDLATCHES
	move.w	#$10, d0
	bsr	delay

	; player 1 led
	lsr.w	#8, d4
	move.b	d4, REG_LEDDATA

	move.b	#LED_P1_LATCH, REG_LEDLATCHES
	move.w	#$10, d0
	bsr	delay

	move.b	#LED_P1_LATCH, REG_LEDLATCHES

	rts

error_to_credit_leds_psub:
	moveq	#3, d2
	moveq	#0, d3
	moveq	#0, d4

; convert error code to bcd
.loop_next_digit:
	divu.w	#10, d0
	swap	d0
	move.b	d0, d3
	and.l	d3, d3
	or.w	d3, d4
	clr.w	d0
	swap	d0
	ror.w	#4, d4
	dbra	d2, .loop_next_digit

	not.w	d4				; inverted per dev wiki

	; player 2 led
	move.b	#LED_NO_LATCH, REG_LEDLATCHES
	move.w	#$10, d0
	PSUB	delay				; 40us

	move.b	d4, REG_LEDDATA

	move.b	#LED_P2_LATCH, REG_LEDLATCHES
	move.w	#$10, d0
	PSUB	delay

	move.b	#LED_NO_LATCH, REG_LEDLATCHES
	move.w	#$10, d0
	PSUB	delay

	; player 1 led
	lsr.w	#8, d4
	move.b	d4, REG_LEDDATA

	move.b	#LED_P1_LATCH, REG_LEDLATCHES
	move.w	#$10, d0
	PSUB	delay

	move.b	#LED_P1_LATCH, REG_LEDLATCHES

	PSUB_RETURN

; backup palette ram to PALETTE_RAM_BACKUP_LOCATION (wram $10001c)
palette_ram_backup:
	movem.l	d0/a0-a1, -(a7)
	lea	PALETTE_RAM_START.l, a0
	lea	PALETTE_RAM_BACKUP_LOCATION.l, a1
	move.w	#$2000, d0
	bsr	copy_memory
	movem.l	(a7)+, d0/a0-a1
	rts

; restore palette ram from PALETTE_RAM_BACKUP_LOCATION (wram $10001c)
palette_ram_restore:
	movem.l	d0/a0-a1, -(a7)
	lea	PALETTE_RAM_BACKUP_LOCATION.l, a0
	lea	PALETTE_RAM_START.l, a1
	move.w	#$2000, d0
	bsr	copy_memory
	movem.l	(a7)+, d0/a0-a1
	rts

; params:
;  a0 = source address
;  a1 = dest address
;  d0 = length
copy_memory:
	swap	d0
	clr.w	d0
	swap	d0
	lea	(-$20,a0,d0.l), a0
	lea	(a1,d0.l), a1
	lsr.w	#5, d0
	subq.w	#1, d0
	movem.l	d1-d7/a2, -(a7)
.loop_next_address:
	movem.l	(a0), d1-d7/a2
	movem.l	d1-d7/a2, -(a1)
	lea	(-$20,a0), a0
	dbra	d0, .loop_next_address
	movem.l	(a7)+, d1-d7/a2

	WATCHDOG
	rts


; params:
;  d0 = inverse byte mask for player1 inputs we care about
wait_p1_input:
	WATCHDOG
	move.b	REG_P1CNT, d1
	and.b	d0, d1
	cmp.b	d0, d1
	bne	wait_p1_input
	bsr	wait_frame
	bsr	wait_frame
	rts

; wait for a full frame
wait_frame:
	move.w	d0, -(a7)

.loop_bottom_border:
	WATCHDOG
	move.w	(4,a6), d0
	and.w	#$ff80, d0
	cmp.w	#$f800, d0
	beq	.loop_bottom_border		; loop until we arent at bottom border

.loop_not_bottom_border:
	WATCHDOG
	move.w	(4,a6), d0
	and.w	#$ff80, d0
	cmp.w	#$f800, d0
	bne	.loop_not_bottom_border		; loop until we see the bottom border

	move.w	(a7)+, d0
	rts


; wait for a full frame, psub
; never called..
wait_frame_psub:
	WATCHDOG
	move.w	(4,a6), d0
	and.w	#$ff80, d0
	cmp.w	#$f800, d0
	beq	wait_frame_psub

.loop_not_bottom_border:
	WATCHDOG
	move.w	(4,a6), d0
	and.w	#$ff80, d0
	cmp.w	#$f800, d0
	bne	.loop_not_bottom_border
	PSUB_RETURN

; d0 = scanline to wait for
wait_scanline:
	WATCHDOG
	move.w	(4,a6), d1
	lsr.w	#$7, d1
	cmp.w	d0, d1
	bne	wait_scanline
	rts

p1p2_input_update:
	bsr	p1_input_update
	bra	p2_input_update

p1_input_update:
	move.b	REG_P1CNT, d0
	not.b	d0
	move.b	p1_input, d1
	eor.b	d0, d1
	and.b	d0, d1
	move.b	d1, p1_input_edge
	move.b	d0, p1_input
	move.b	REG_STATUS_B, d0
	not.b	d0
	move.b	p1_input_aux, d1
	eor.b	d0, d1
	and.b	d0, d1
	move.b	d1, p1_input_aux_edge
	move.b	d0, p1_input_aux
	rts

p2_input_update:
	move.b	REG_P2CNT, d0
	not.b	d0
	move.b	p2_input, d1
	eor.b	d0, d1
	and.b	d0, d1
	move.b	d1, p2_input_edge
	move.b	d0, p2_input
	move.b	REG_STATUS_B, d0
	lsr.b	#2, d0
	not.b	d0
	move.b	p2_input_aux, d1
	eor.b	d0, d1
	and.b	d0, d1
	move.b	d1, p2_input_aux_edge
	move.b	d0, p2_input_aux
	rts

; params:
;  d0 = send lower 3 bits to both p1/p2 ports
send_p1p2_controller:
	move.w	d1, -(a7)
	move.b	d0, d1
	lsl.b	#3, d1
	or.b	d1, d0
	move.b	d0, REG_POUTPUT
	move.l	#$1f4, d0		; 1250us / 1.25ms
	bsr	delay
	move.w	(a7)+, d1
	rts

manual_tests:
.loop_forever:
	bsr	main_menu_draw
	bsr	main_menu_loop
	bra	.loop_forever


main_menu_draw:
	bsr	print_header
	lea	MAIN_MENU_ITEMS_START, a1
	moveq	#((MAIN_MENU_ITEMS_END - MAIN_MENU_ITEMS_START) / 10 - 1), d4
	moveq	#5, d5					; row to start drawing menu items at

.loop_next_entry:
	movea.l	(a1)+, a0
	addq.l	#4, a1
	moveq	#0, d2
	move.w	(a1)+, d0
	cmp	#0, d0
	beq	.print_entry				; if flags == 0, print entry on both systems (mvs/aes)

	tst.b	REG_STATUS_B
	bpl	.system_aes

	cmp.w	#1, d0
	beq	.print_entry
	moveq	#$10, d2				; if flag is not 1, adjust palette
	bra	.print_entry

.system_aes:
	cmp.w	#2, d0
	beq	.print_entry
	moveq	#$10, d2					; if flag is not 2, adjust palette

.print_entry:
	moveq	#6, d0
	move.b	d5, d1
	bsr	print_xyp_string
	addq.b	#1, d3
	addq.b	#1, d5
	dbra	d4, .loop_next_entry
	bsr	print_hold_ss_to_reset
	rts


main_menu_loop:
	moveq	#-$10, d0
	bsr	wait_p1_input
	bsr	wait_frame

.loop_run_menu:

	bsr	check_reset_request
	bsr	p1p2_input_update

	moveq	#4, d0
	moveq	#5, d1
	add.b	main_menu_cursor, d1
	moveq	#$11, d2
	bsr	print_xy_char				; draw arrow

	move.b	main_menu_cursor, d1
	move.b	p1_input_edge, d0
	btst	#UP, d0					; see if p1 up pressed
	beq	.up_not_pressed

	subq.b	#1, d1
	bpl	.update_arrow
	clr.b	d1					; if went negative, force to 0

.up_not_pressed:					; up wasnt pressed, see if down was
	btst	#DOWN, d0
	beq	.check_a_pressed			; down not pressed either, see if 'a' is pressed

	addq.b	#1, d1
	cmp.b	#((MAIN_MENU_ITEMS_END - MAIN_MENU_ITEMS_START) / 10), d1
	bne	.update_arrow
	subq.b	#1, d1

.update_arrow:						; up or down was pressed, update the arrow location
	move.w	d1, -(a7)
	moveq	#4, d0
	moveq	#5, d1
	add.b	main_menu_cursor, d1
	move.b	(1,a7), main_menu_cursor
	moveq	#$20, d2
	bsr	print_xy_char				; replace existing arrow with space

	moveq	#4, d0
	moveq	#5, d1
	add.w	(a7)+, d1
	moveq	#$11, d2
	bsr	print_xy_char				; draw arrow at new location

.check_a_pressed:
	btst	#A_BUTTON, p1_input_edge		; 'a' pressed?
	bne	.a_pressed
	bsr	wait_frame
	bra	.loop_run_menu

.a_pressed:						; 'a' was pressed, do stuff
	clr.w	d0
	move.b	main_menu_cursor, d0
	mulu.w	#$a, d0					; find the offset within the main_menu_items array
	lea	(MAIN_MENU_ITEMS_START,PC,d0.w), a1

	moveq	#1, d0					; setup d0 to contain 1 for AES, 2 for MVS
	tst.b	REG_STATUS_B
	bpl	.system_aes
	moveq	#2, d0

.system_aes:
	cmp.w	($8,a1), d0
	beq	.loop_run_menu				; flags saw its not valid for this system, ignore and loop again

	bsr	fix_clear

	movea.l	(a1)+, a0
	moveq	#4, d0
	moveq	#5, d1
	bsr	print_xy_string

	movea.l	(a1), a0
	jsr	(a0)					; call the test function
	bsr	fix_clear
	rts


; array of main menu items
; struct {
;  long string_address,
;  long function_address,
;  word flags,  // 0 = valid for both, 1 = aes disabled, 2 = mvs disable
; }
MAIN_MENU_ITEMS_START:
	MAIN_MENU_ITEM STR_MM_CALENDAR_IO, manual_calendar_test, 1
	MAIN_MENU_ITEM STR_MM_COLOR_BARS, manual_color_bars_test, 0
	MAIN_MENU_ITEM STR_MM_CONTROLER_TEST, manual_controller_test, 0
	MAIN_MENU_ITEM STR_MM_WBRAM_TEST_LOOP, manual_wbram_test_loop, 0
	MAIN_MENU_ITEM STR_MM_PAL_RAM_TEST_LOOP, manual_palette_ram_test_loop, 0
	MAIN_MENU_ITEM STR_MM_VRAM_TEST_LOOP_32K, manual_vram_32k_test_loop, 0
	MAIN_MENU_ITEM STR_MM_VRAM_TEST_LOOP_2K, manual_vram_2k_test_loop, 0
	MAIN_MENU_ITEM STR_MM_MISC_INPUT_TEST, manual_misc_input_tests, 0
MAIN_MENU_ITEMS_END:


vblank_interrupt:
	WATCHDOG
	move.w	#$4, REG_IRQACK
	tst.b	$100000.l		; this seems like dead code since nothing
	beq	.exit_interrupt		; else touches $10000(0|2) as a variable..
	movem.l	d0-d7/a0-a6, -(a7)
	addq.w	#1, $100002.l
	movem.l	(a7)+, d0-d7/a0-a6
	clr.b	$100000.l
.exit_interrupt:
	rte

timer_interrupt:
	addq.w	#$1, timer_count
	move.w	#$2, ($a,a6)		; ack int
	rte

; parse through the array of error_code_print structs below
; and run the correct print error function
; params:
;  d0 = error code
;  d1 = error data
;  d2 = error data
;  a0 = error data
print_error_data:
	move.b	d0, d6
	and.w	#$3c, d0
	lsr.w	#2, d0
	lea	(ECT_DATA_FUNC_LOOKUP_TABLE_START - 4), a1
	moveq	#((ECT_DATA_FUNC_LOOKUP_TABLE_END - ECT_DATA_FUNC_LOOKUP_TABLE_START)/6), d5
.loop_next_entry:
	addq.l	#4, a1
	cmp.w	(a1)+, d0
	dbeq	d5, .loop_next_entry
	beq	.match_found
	rts

.match_found:
	movea.l	(a1), a2
	jsr	(a2)			; match found run the print function
	move.b	d6, d0
	rts



; struct error_code_print {
;  word error_code_type;
;  long function_address;
; }
ECT_DATA_FUNC_LOOKUP_TABLE_START:
	ECT_DATA_LOOKUP_ITEM $003, print_error_data_memory
	ECT_DATA_LOOKUP_ITEM $004, print_error_data_memory
	ECT_DATA_LOOKUP_ITEM $005, print_error_data_memory
	ECT_DATA_LOOKUP_ITEM $006, print_error_data_memory
	ECT_DATA_LOOKUP_ITEM $007, print_error_data_memory
	ECT_DATA_LOOKUP_ITEM $008, print_error_data_memory
	ECT_DATA_LOOKUP_ITEM $009, print_error_data_memory
	ECT_DATA_LOOKUP_ITEM $00f, print_error_data_mmio
ECT_DATA_FUNC_LOOKUP_TABLE_END:

	dc.b $4e,$75			; random rts opcode?

; jumps to the needed function to print error data
; that jump location is responsible for calling PSUB_RETURN
; params:
;  d0 = error code
print_error_data_psub:
	move.b	d0, d6
	and.w	#$3c, d0
	lsr.w	#2, d0
	lea	(ECT_DATA_PSUB_LOOKUP_TABLE_START - 4),a1
	moveq	#((ECT_DATA_PSUB_LOOKUP_TABLE_END - ECT_DATA_PSUB_LOOKUP_TABLE_START)/6), d5

.loop_next_entry:
	addq.l	#4, a1
	cmp.w	(a1)+, d0
	dbeq	d5, .loop_next_entry
	beq	.match_found
	PSUB_RETURN
.match_found:
	movea.l	(a1), a2
	move.b	d6, d0
	jmp	(a2)


; struct {
;  word error_code_type;
;  long jmp_address;       jmp location for how to print the data for the ec type
; };
ECT_DATA_PSUB_LOOKUP_TABLE_START:
	ECT_DATA_LOOKUP_ITEM $0000, print_error_hex_psub
	ECT_DATA_LOOKUP_ITEM $0001, print_error_data_bram_aes_psub
	ECT_DATA_LOOKUP_ITEM $0002, print_error_data_memory_psub
	ECT_DATA_LOOKUP_ITEM $0003, print_error_data_memory_psub
	ECT_DATA_LOOKUP_ITEM $0004, print_error_data_memory_psub
ECT_DATA_PSUB_LOOKUP_TABLE_END:

; prints error value and actual value as hex
; params:
;  d0 = error code
;  d1 = actual value
;  d2 = expected value
print_error_hex_psub:
	cmp.b	#EC_BIOS_CRC32, d0
	beq	.print_bios_crc32_data		; special case for bios crc values

	move.b	d2, d3
	move.b	d1, d2

	moveq	#14, d0
	moveq	#10, d1
	PSUB	print_hex_byte

	move.b	d3, d2
	moveq	#14, d0
	moveq	#12, d1
	PSUB	print_hex_byte

	bra	.print_error_strings

.print_bios_crc32_data:
	move.l	d1, d2
	moveq	#14, d0
	moveq	#10, d1
	PSUB	print_hex_long

	moveq	#14, d0
	moveq	#12, d1
	move.l	BIOS_CRC32_ADDR, d2
	PSUB	print_hex_long


.print_error_strings:
	lea	STR_EXPECTED.l, a0
	moveq	#4, d0
	moveq	#12, d1
	PSUB	print_xy_string

	lea	STR_ACTUAL.l, a0
	moveq	#4, d0
	moveq	#10, d1
	PSUB	print_xy_string
	PSUB_RETURN

; seems likely this is never called
print_error_data_bram_aes_psub:
	bra	.skip_aes_test

	tst.b	REG_STATUS_B			; next 4 lines seem to be dead code?
	bmi	.skip_print_error		; test for MVS
	cmp.b	#EC_BRAM_DEAD_OUTPUT_UPPER, d0	;
	bne	.skip_print_error		;

.skip_aes_test:

	lea	XY_STR_AES_BRAM_NOT_MOD, a0
	PSUB	print_xy_string_struct

	lea	XY_STR_AES_BRAM_C_RESET, a0
	PSUB	print_xy_string_struct
.skip_print_error:

	PSUB_RETURN

XY_STR_AES_BRAM_NOT_MOD:	XY_STRING 4, 24, "IF USING AES W/OUT BACKUP RAM MOD,"
XY_STR_AES_BRAM_C_RESET:	XY_STRING 4, 25, "RELEASE C BUTTON AND SOFT RESET."

; prints actual/expected data for a memory address
; params:
;  d0 = error code
;  d1 = expected data
;  d2 = actual data
;  a0 = address location
print_error_data_memory:
	move.w	d1, d3
	move.w	d2, d4
	moveq	#$e, d0
	moveq	#$8, d1
	move.l	a0, d2
	bsr	print_hex_3_bytes		; prints the address

	moveq	#$e, d0
	moveq	#$c, d1
	move.w	d3, d2
	bsr	print_hex_word			; prints expected value

	moveq	#$e, d0
	moveq	#$a, d1
	move.w	d4, d2
	bsr	print_hex_word			; prints actual value

	lea	STR_ADDRESS.l, a0
	moveq	#$4, d0
	moveq	#$8, d1
	bsr	print_xy_string

	lea	STR_EXPECTED.l, a0
	moveq	#$4, d0
	moveq	#$c, d1
	bsr	print_xy_string

	lea	STR_ACTUAL.l, a0
	moveq	#$4, d0
	moveq	#$a, d1
	bsr	print_xy_string
	rts


; prints actual/expected data for a memory address
; params:
;  d0 = error code
;  d1 = expected data
;  d2 = actual data
;  a0 = address location
print_error_data_memory_psub:
	move.w	d1, d3
	move.w	d2, d4

	moveq	#14, d0
	moveq	#8, d1
	move.l	a0, d2
	PSUB	print_hex_3_bytes

	moveq	#14, d0
	moveq	#12, d1
	move.w	d3, d2
	PSUB	print_hex_word

	moveq	#14, d0
	moveq	#10, d1
	move.w	d4, d2
	PSUB	print_hex_word

	lea	STR_ADDRESS.l, a0
	moveq	#4, d0
	moveq	#8, d1
	PSUB	print_xy_string

	lea	STR_EXPECTED.l, a0
	moveq	#4, d0
	moveq	#12, d1
	PSUB	print_xy_string

	lea	STR_ACTUAL.l, a0
	moveq	#4, d0
	moveq	#10, d1
	PSUB	print_xy_string

	PSUB_RETURN


; params:
;  a0 = mmio address
print_error_data_mmio:
	move.l	a0, d3
	moveq	#$d, d0
	moveq	#$8, d1
	move.l	a0, d2
	bsr	print_hex_3_bytes

	lea	STR_ADDRESS.l, a0
	moveq	#$4, d0
	moveq	#$8, d1
	bsr	print_xy_string

	lea	(MMIO_ERROR_LOOKUP_TABLE_START - 4), a0
.loop_next_entry:
	addq.l	#4, a0
	cmp.l	(a0)+, d3
	bne	.loop_next_entry
	movea.l	(a0), a0
	bsr	print_xyp_string_struct_multi
	rts




MMIO_ERROR_LOOKUP_TABLE_START:
	dc.l REG_DIPSW, XYP_MMIO_ERROR_C1_1_TO_F0_47
	dc.l REG_SYSTYPE, XYP_MMIO_ERROR_C1_1_TO_F0_47
	dc.l REG_STATUS_A, XYP_MMIO_ERROR_REG_STATUS_A
	dc.l REG_P1CNT, XYP_MMIO_ERROR_GENERIC_C1
	dc.l REG_SOUND, XYP_MMIO_ERROR_GENERIC_C1
	dc.l REG_P2CNT, XYP_MMIO_ERROR_GENERIC_C1
	dc.l REG_STATUS_B, XYP_MMIO_ERROR_GENERIC_C1
	dc.l REG_VRAMRW, XYP_MMIO_ERROR_REG_VRAMRW

XYP_MMIO_ERROR_C1_1_TO_F0_47:
	XYP_STRING_MULTI 4, 10, 0, "1st gen: (no info)"
	XYP_STRING_MULTI 4, 11, 0, "2nd gen: NEO-C1(1) <-> NEO-F0(47)"
	XYP_STRING_MULTI_END
XYP_MMIO_ERROR_REG_STATUS_A:
	XYP_STRING_MULTI 4, 10, 0, "1st gen: (no info)"
	XYP_STRING_MULTI 4, 11, 0, "2nd gen: NEO-C1(2) <-> NEO-F0(34)"
	XYP_STRING_MULTI_END
XYP_MMIO_ERROR_GENERIC_C1:
	XYP_STRING_MULTI 4, 10, 0, "1st gen: (no info)"
	XYP_STRING_MULTI 4, 11, 0, "2nd gen: NEO-C1"
	XYP_STRING_MULTI_END
XYP_MMIO_ERROR_REG_VRAMRW:
	XYP_STRING_MULTI 4, 10, 0, "1st gen: ? <-> LSPC-A0(?)"
	XYP_STRING_MULTI 4, 11, 0, "2nd gen: NEO-C1 <-> LSPC2-A2(172)"
	XYP_STRING_MULTI_END
	align 2


; The bios code is only 16k ($4000).  7 copies/mirrors
; of it are used to fill the entire 128k of the bios rom.
; At offset $.loop3fb of each mirror is a byte that contains
; the mirror number.  The running bios is $00, first
; mirror is $01, 2nd mirror $02, ... 7th mirror $07.
; This test checks each of these to verify they are correct.
; If they end up being wrong it will trigger the "BIOS ADDRESS (A13-A15)"
; error.
; on error:
;  d1 = actual value
;  d2 = expected value
auto_bios_mirror_test_psub:
	lea	$bffffb, a0
	moveq	#7, d0
	moveq	#-1, d2
.loop_next_offset:
	addq.b	#1, d2
	lea	($4000,a0), a0
	move.b	(a0), d1
	cmp.b	d2, d1
	dbne	d0, .loop_next_offset
	bne	.test_failed

	moveq	#$0, d0
	PSUB_RETURN

.test_failed:
	moveq	#EC_BIOS_MIRROR, d0
	PSUB_RETURN

; verifies the bios crc is correct.  The expected crc32 value
; are the 4 bytes located at $.loop3fc ($c03.loop3c) of the bios.
; on error:
;  d1 = actual crc32
auto_bios_crc32_test_psub:
	move.l	#$3ffb, d0			; length
	lea	$c00000.l, a0			; start address
	move.b	d0, REG_SWPROM			; use carts vector table?
	PSUB	calc_crc32

	move.b	d0, REG_SWPBIOS			; use bios vector table
	cmp.l	$c03ffc.l, d0
	beq	.test_passed

	move.l	d0, d1
	moveq	#EC_BIOS_CRC32, d0
	PSUB_RETURN

.test_passed:
	moveq	#0, d0
	PSUB_RETURN

; calculate the crc32 value
; params:
;  d0 = length
;  a0 = start address
; returns:
;  d0 = crc value
calc_crc32_psub:
	subq.l	#1, d0
	move.w	d0, d3
	swap	d0
	move.w	d0, d4
	lea	REG_WATCHDOG, a1
	move.l	#$edb88320, d5			; P
	moveq	#-1, d0
.loop_outter:
	move.b	d0, (a1)			; WATCHDOG
	moveq	#7, d2
	move.b	(a0)+, d1
	eor.b	d1, d0
.loop_inner:
	lsr.l	#1, d0
	bcc	.no_carry
	eor.l	d5, d0
.no_carry:
	dbra	d2, .loop_inner
	dbra	d3, .loop_outter
	dbra	d4, .loop_outter
	not.l	d0
	PSUB_RETURN

; d0 = data
; sends the 4 bit command to the rtc, which runs in
; serial mode (shift register)
rtc_send_command:
	move.l	d1, -(a7)
	lea	REG_RTCCTRL, a0
	moveq	#$3, d2
.loop_next:
	moveq	#$1, d1
	and.b	d0, d1
	move.b	d1, (a0)  	; write bit 0 from d0
	addq.b	#2, d1
	nop
	move.b	d1, (a0)  	; rtc clock high
	subq.b	#2, d1
	lsr.b	#1, d0		; shift right d0 to prep for next bit to send (next loop)
	move.b	d1, (a0)  	; rtc clock low to tigger shift
	dbra	d2, .loop_next
	move.b	#$4, (a0)	; rtc stb high
	nop
	clr.b	(a0)		; rtc stb low (run command)
	move.l	(a7)+, d1
	rts

rtc_wait_pulse:
	WATCHDOG
	btst	#$6, REG_STATUS_A
	bne	rtc_wait_pulse

.loop_rtc_pulse_low:
	WATCHDOG
	btst	#$6, REG_STATUS_A
	beq	.loop_rtc_pulse_low
	move.b	#$40, rtc_pulse_state
	rts


; if there is a new pulse, Z will be set
rtc_check_pulse:
	moveq	#$40, d0
	and.b	REG_STATUS_A, d0
	move.b	rtc_pulse_state, d1
	move.b	d0, rtc_pulse_state
	eor.b	d0, d1
	and.b	d0, d1
	rts


auto_ram_oe_tests_psub:
	lea	WORK_RAM_START.l, a0		; wram upper
	moveq	#0, d0
	PSUB	check_ram_oe
	tst.b	d0
	bne	.test_failed_wram_upper

	moveq	#1, d0				; wram lower
	PSUB	check_ram_oe
	tst.b	d0
	bne	.test_failed_wram_lower

	tst.b	REG_STATUS_B			; skip bram test on AES unless C is pressed
	bmi	.do_bram_test
	btst	#6, REG_P1CNT
	bne	.test_passed

.do_bram_test:
	lea	BACKUP_RAM_START.l, a0		; bram upper
	moveq	#0, d0
	PSUB	check_ram_oe
	tst.b	d0
	bne	.test_failed_bram_upper

	moveq	#1, d0				; bram lower
	PSUB	check_ram_oe
	tst.b	d0
	bne	.test_failed_bram_lower

.test_passed:
	moveq	#0, d0
	PSUB_RETURN

.test_failed_wram_upper:
	moveq	#EC_WRAM_DEAD_OUTPUT_UPPER, d0
	PSUB_RETURN
.test_failed_wram_lower:
	moveq	#EC_WRAM_DEAD_OUTPUT_LOWER, d0
	PSUB_RETURN
.test_failed_bram_upper:
	moveq	#EC_BRAM_DEAD_OUTPUT_UPPER, d0
	PSUB_RETURN
.test_failed_bram_lower:
	moveq	#EC_BRAM_DEAD_OUTPUT_LOWER, d0
	PSUB_RETURN

; Attempts to read from ram.  If the chip never gets enabled
; d1 will be filled with the last data on the data bus,
; which would be part of the preceding move.b instruction.
; The "move.b (a0), d1" instruction translates to $1210 in
; machine code.  When doing an upper ram test if d1 contains
; $12 its assumed the ram read didnt happen, likewise for
; lower if d1 contains $10 for lower.
; params:
;  a0 = address
;  d0 = 0 (upper chip) or 1 (lower chip)
; return:
;  d0 = $00 (pass) or $ff (fail)
check_ram_oe_psub:
	adda.w	d0, a0
	moveq	#$31, d2

.loop_test_again:
	move.b	(a0), d1
	cmp.b	*(PC,d0.w), d1
	bne	.test_passed

	move.b	(a0), d1
	nop
	cmp.b	*-2(PC,d0.w), d1
	bne	.test_passed

	move.b	(a0), d1
	add.w	#0, d0
	cmp.b	*-4(PC,d0.w), d1

.test_passed:
	dbeq	d2, .loop_test_again
	seq	d0
	PSUB_RETURN

auto_bram_tests:
	tst.b	REG_STATUS_B			; do test if MVS
	bmi	.do_bram_tests
	btst	#$6, REG_P1CNT			; do test if AES and C pressed
	beq	.do_bram_tests
	moveq	#0, d0
	rts

.do_bram_tests:
	move.b	d0, REG_SRAMUNLOCK		; unlock bram
	bsr	bram_data_tests
	bne	.test_failed
	bsr	bram_address_tests

.test_failed:
	move.b	d0, REG_SRAMLOCK		; lock bram
	rts


auto_palette_ram_tests:
	lea	PALETTE_RAM_START.l, a0
	lea	PALETTE_RAM_BACKUP_LOCATION.l, a1
	move.w	#$2000, d0
	bsr	copy_memory			; backup palette ram, unclean why palette_ram_backup function wasnt used

	bsr	palette_ram_oe_tests
	bne	.test_failed_abort

	bsr	palette_ram_we_tests
	bne	.test_failed_abort

	bsr	palette_ram_data_tests
	bne	.test_failed_abort

	bsr	palette_ram_address_tests

.test_failed_abort:
	move.b	d0, REG_PALBANK0

	movem.l	d0-d2/a0, -(a7)			; restore palette ram
	lea	PALETTE_RAM_BACKUP_LOCATION.l, a0
	lea	PALETTE_RAM_START.l, a1
	move.w	#$2000, d0
	bsr	copy_memory
	movem.l	(a7)+, d0-d2/a0
	rts


palette_ram_we_tests:
	lea	PALETTE_RAM_START.l, a0
	move.w	#$ff, d0
	jsr	check_ram_we.l
	beq	.test_passed_lower
	moveq	#EC_PAL_UNWRITABLE_LOWER, d0
	rts

.test_passed_lower:
	lea	PALETTE_RAM_START.l, a0
	move.w	#$ff00, d0
	jsr	check_ram_we.l
	beq	.test_passed_upper
	moveq	#EC_PAL_UNWRITABLE_UPPER, d0
	rts

.test_passed_upper:
	moveq	#0, d0
	rts

auto_ram_we_tests_psub:
	lea	WORK_RAM_START.l, a0
	move.w	#$ff, d0
	PSUB	check_ram_we
	tst.b	d0
	beq	.test_passed_wram_lower
	moveq	#EC_WRAM_UNWRITABLE_LOWER, d0
	PSUB_RETURN

.test_passed_wram_lower:
	lea	WORK_RAM_START.l, a0
	move.w	#$ff00, d0
	PSUB	check_ram_we
	tst.b	d0
	beq	.test_passed_wram_upper
	moveq	#EC_WRAM_UNWRITABLE_UPPER, d0
	PSUB_RETURN

.test_passed_wram_upper:
	tst.b	REG_STATUS_B
	bmi	.do_bram_test				; if MVS jump to bram test
	btst	#6, REG_P1CNT				; dead code? checking if C is pressed, then nop
	nop						; maybe nop should be 'bne .do_bram_test' to allow forced bram test on aes?
	moveq	#0, d0
	PSUB_RETURN

.do_bram_test:
	move.b	d0, REG_SRAMUNLOCK			; unlock bram

	lea	BACKUP_RAM_START.l, a0
	move.w	#$ff, d0
	PSUB	check_ram_we
	tst.b	d0
	beq	.test_passed_bram_lower

	moveq	#EC_BRAM_UNWRITABLE_LOWER, d0
	PSUB_RETURN

.test_passed_bram_lower:
	lea	BACKUP_RAM_START.l, a0
	move.w	#$ff00, d0
	PSUB	check_ram_we
	tst.b	d0
	beq	.test_passed_bram_upper

	moveq	#EC_BRAM_UNWRITABLE_UPPER, d0
	PSUB_RETURN

.test_passed_bram_upper:
	move.b	d0, REG_SRAMLOCK			; lock bram
	moveq	#0, d0
	PSUB_RETURN

; params:
;  a0 = address
;  d0 = bitmask
check_ram_we:
	move.w	(a0), d1
	and.w	d0, d1
	moveq	#0, d2
	move.w	#$101, d5		; incr amount for each loop
	move.w	#$ff, d3		; loop $ff times

.loop_next_address:
	move.w	d2, (a0)
	add.w	d5, d2
	move.w	(a0), d4
	and.w	d0, d4
	cmp.w	d1, d4			; check if write and re-read values match
	dbne	d3, .loop_next_address
	beq	.test_failed

	moveq	#0, d0
	rts

.test_failed:
	moveq	#-1, d0
	rts

; params:
;  a0 = address
;  d0 = bitmask
check_ram_we_psub:
	move.w	(a0), d1
	and.w	d0, d1
	moveq	#0, d2
	move.w	#$101, d5		; incr amount for each loop
	move.w	#$ff, d3		; loop $ff times

.loop_next_address
	move.w	d2, (a0)
	add.w	d5, d2
	move.w	(a0), d4
	and.w	d0, d4
	cmp.w	d1, d4			; check if write and re-read values match
	dbne	d3, .loop_next_address
	beq	.test_failed

	moveq	#0, d0
	PSUB_RETURN

.test_failed:
	moveq	#-1, d0
	PSUB_RETURN

auto_wram_data_tests_psub:
	lea	WORK_RAM_START.l, a0
	moveq	#0, d0
	move.w	#$8000, d1
	PSUB	check_ram_data
	tst.b	d0
	beq	.test_passed_0000
	moveq	#EC_WRAM_DATA_0000, d0
	PSUB_RETURN

.test_passed_0000:
	lea	WORK_RAM_START.l, a0
	move.w	#$5555, d0
	move.w	#$8000, d1
	PSUB	check_ram_data
	tst.b	d0
	beq	.test_passed_5555
	moveq	#EC_WRAM_DATA_5555, d0
	PSUB_RETURN

.test_passed_5555:
	lea	WORK_RAM_START.l, a0
	move.w	#$aaaa, d0
	move.w	#$8000, d1
	PSUB	check_ram_data
	tst.b	d0
	beq	.test_passed_aaaa
	moveq	#EC_WRAM_DATA_AAAA, d0
	PSUB_RETURN

.test_passed_aaaa:
	lea	WORK_RAM_START.l, a0
	moveq	#-1, d0
	move.w	#$8000, d1
	PSUB	check_ram_data
	tst.b	d0
	beq	.test_passed_ffff
	moveq	#EC_WRAM_DATA_FFFF, d0
	PSUB_RETURN

.test_passed_ffff:
	moveq	#0, d0
	PSUB_RETURN

bram_data_tests:
	lea	BACKUP_RAM_START.l, a0
	moveq	#0, d0
	move.w	#$8000, d1
	bsr	check_ram_data
	beq	.test_passed_0000
	moveq	#EC_BRAM_DATA_0000, d0
	rts

.test_passed_0000:
	lea	BACKUP_RAM_START.l, a0
	move.w	#$5555, d0
	move.w	#$8000, d1
	bsr	check_ram_data
	beq	.test_passed_5555
	moveq	#EC_BRAM_DATA_5555, d0
	rts

.test_passed_5555
	lea	BACKUP_RAM_START.l, a0
	move.w	#$aaaa, d0
	move.w	#$8000, d1
	bsr	check_ram_data
	beq	.test_passed_aaaa
	moveq	#EC_BRAM_DATA_AAAA, d0
	rts

.test_passed_aaaa:
	lea	BACKUP_RAM_START.l, a0
	moveq	#-1, d0
	move.w	#$8000, d1
	bsr	check_ram_data
	beq	.test_passed_ffff
	moveq	#EC_BRAM_DATA_FFFF, d0
	rts

.test_passed_ffff:
	moveq	#0, d0
	rts

bram_data_tests_psub:
	lea	BACKUP_RAM_START.l, a0
	moveq	#$0, d0
	move.w	#$8000, d1
	PSUB	check_ram_data
	tst.b	d0
	beq	.test_passed_0000
	moveq	#EC_BRAM_DATA_0000, d0
	PSUB_RETURN

.test_passed_0000:
	lea	BACKUP_RAM_START.l, a0
	move.w	#$5555, d0
	move.w	#$8000, d1
	PSUB	check_ram_data
	tst.b	d0
	beq	.test_passed_5555
	moveq	#EC_BRAM_DATA_5555, d0
	PSUB_RETURN

.test_passed_5555:
	lea	BACKUP_RAM_START.l, a0
	move.w	#$aaaa, d0
	move.w	#$8000, d1
	PSUB	check_ram_data
	tst.b	d0
	beq	.test_passed_aaaa
	moveq	#EC_BRAM_DATA_AAAA, d0
	PSUB_RETURN

.test_passed_aaaa:
	lea	BACKUP_RAM_START.l, a0
	moveq	#-$1, d0
	move.w	#$8000, d1
	PSUB	check_ram_data
	tst.b	d0
	beq	.test_passed_ffff
	moveq	#EC_BRAM_DATA_FFFF, d0
	PSUB_RETURN

.test_passed_ffff:
	moveq	#$0, d0
	PSUB_RETURN

palette_ram_data_tests:
	lea	PALETTE_RAM_START.l, a0
	moveq	#$0, d0
	move.w	#$1000, d1
	bsr	check_ram_data
	beq	.test_passed_bank0_0000

	moveq	#EC_PAL_BANK0_DATA_0000, d0
	rts

.test_passed_bank0_0000:
	lea	PALETTE_RAM_START.l, a0
	move.w	#$5555, d0
	move.w	#$1000, d1
	bsr	check_ram_data
	beq	.test_passed_bank0_5555

	moveq	#EC_PAL_BANK0_DATA_5555, d0
	rts

.test_passed_bank0_5555:
	lea	PALETTE_RAM_START.l, a0
	move.w	#$aaaa, d0
	move.w	#$1000, d1
	bsr	check_ram_data
	beq	.test_passed_bank0_aaaa

	moveq	#EC_PAL_BANK0_DATA_AAAA, d0
	rts

.test_passed_bank0_aaaa:
	lea	PALETTE_RAM_START.l, a0
	moveq	#-1, d0
	move.w	#$1000, d1
	bsr	check_ram_data
	beq	.test_passed_bank0_ffff

	moveq	#EC_PAL_BANK0_DATA_FFFF, d0
	rts

.test_passed_bank0_ffff:
	move.b	d0, REG_PALBANK1

	lea	PALETTE_RAM_START.l, a0
	moveq	#$0, d0
	move.w	#$1000, d1
	bsr	check_ram_data
	beq	.test_passed_bank1_0000

	moveq	#EC_PAL_BANK1_DATA_0000, d0
	rts

.test_passed_bank1_0000:
	lea	PALETTE_RAM_START.l, a0
	move.w	#$5555, d0
	move.w	#$1000, d1
	bsr	check_ram_data
	beq	.test_passed_bank1_5555

	moveq	#EC_PAL_BANK1_DATA_5555, d0
	rts

.test_passed_bank1_5555:
	lea	PALETTE_RAM_START.l, a0
	move.w	#$aaaa, d0
	move.w	#$1000, d1
	bsr	check_ram_data
	beq	.test_passed_bank1_aaaa

	moveq	#EC_PAL_BANK1_DATA_AAAA, d0
	rts

.test_passed_bank1_aaaa:
	lea	PALETTE_RAM_START.l, a0
	moveq	#-1, d0
	move.w	#$1000, d1
	bsr	check_ram_data
	beq	.test_passed_bank1_ffff

	moveq	#EC_PAL_BANK1_DATA_FFFF, d0
	rts

.test_passed_bank1_ffff:
	move.b	d0, REG_PALBANK0
	moveq	#0, d0
	rts

; Does a full write/read test
; params:
;  a0 = start address
;  d0 = value
;  d1 = length
; returns:
;  d0 = 0 (pass), $ff (fail)
;  a0 = failed address
;  d1 = wrote value
;  d2 = read (bad) value
check_ram_data:
	subq.w	#1, d1

.loop_next_address:
	move.w	d0, (a0)
	move.w	(a0)+, d2
	cmp.w	d0, d2
	dbne	d1, .loop_next_address
	bne	.test_failed
	WATCHDOG
	moveq	#0, d0
	rts

.test_failed:
	subq.l	#2, a0
	move.w	d0, d1
	WATCHDOG
	moveq	#-1, d0
	rts



; Does a full write/read test
; params:
;  a0 = start address
;  d0 = value
;  d1 = length
; returns:
;  d0 = 0 (pass), $ff (fail)
;  a0 = failed address
;  d1 = wrote value
;  d2 = read (bad) value
check_ram_data_psub:
	subq.w	#1, d1

.loop_next_address:
	move.w	d0, (a0)
	move.w	(a0)+, d2
	cmp.w	d0, d2
	dbne	d1, .loop_next_address
	bne	.test_failed

	WATCHDOG
	moveq	#0, d0
	PSUB_RETURN

.test_failed:
	subq.l	#2, a0
	move.w	d0, d1
	WATCHDOG
	moveq	#-1, d0
	PSUB_RETURN


auto_wram_addreess_tests_psub:
	lea	WORK_RAM_START.l, a0
	moveq	#2, d0
	move.w	#$100, d1
	PSUB	check_ram_address
	tst.b	d0
	beq	.test_passed_a0_a7
	moveq	#EC_WRAM_ADDRESS_A0_A7, d0
	PSUB_RETURN

.test_passed_a0_a7:
	lea	WORK_RAM_START.l, a0
	move.w	#$200, d0
	move.w	#$80, d1
	PSUB	check_ram_address
	tst.b	d0
	beq	.test_passed_a8_a14
	moveq	#EC_WRAM_ADDRESS_A8_A14, d0
	PSUB_RETURN

.test_passed_a8_a14:
	moveq	#0, d0
	PSUB_RETURN

bram_address_tests:
	lea	BACKUP_RAM_START.l, a0
	moveq	#$2, d0
	move.w	#$100, d1
	bsr	check_ram_address
	beq	.test_passed_a0_a7
	moveq	#EC_BRAM_ADDRESS_A0_A7, d0
	rts

.test_passed_a0_a7:
	lea	BACKUP_RAM_START.l, a0
	move.w	#$200, d0
	move.w	#$80, d1
	bsr	check_ram_address
	beq	.test_passed_a8_a14
	moveq	#EC_BRAM_ADDRESS_A8_A14, d0
	rts

.test_passed_a8_a14:
	moveq	#0, d0
	rts

; dont think this is ever called
bram_address_tests_psub:
	lea	BACKUP_RAM_START.l, a0
	moveq	#$2, d0
	move.w	#$100, d1
	PSUB	check_ram_address
	tst.b	d0

	beq	.test_passed_a0_a7
	moveq	#EC_BRAM_ADDRESS_A0_A7, d0
	PSUB_RETURN

.test_passed_a0_a7:
	lea	BACKUP_RAM_START.l, a0
	move.w	#$200, d0
	move.w	#$80, d1
	PSUB	check_ram_address

	tst.b	d0
	beq	.test_passed_a8_a14
	moveq	#EC_BRAM_ADDRESS_A8_A14, d0
	PSUB_RETURN

.test_passed_a8_a14:
	moveq	#0, d0
	PSUB_RETURN

; params:
;  a0 = address start
;  d0 = increment
;  d1 = iterations
; returns:
; d0 = 0 (pass), $ff (fail)
; d1 = expected value
; d2 = actual value
check_ram_address:
	subq.w	#1, d1
	move.w	d1, d2
	moveq	#0, d3
	move.w	#$101, d4

.loop_write_next_address:
	move.w	d3, (a0)
	add.w	d4, d3
	adda.w	d0, a0
	dbra	d2, .loop_write_next_address

	move.l	a0, d3
	and.l	#$f00000, d3
	movea.l	d3, a0
	moveq	#0, d3
	bra	.loop_start_address_read

.loop_read_next_address:
	add.w	d4, d3
	adda.w	d0, a0
.loop_start_address_read:
	move.w	(a0), d2
	cmp.w	d2, d3
	dbne	d1, .loop_read_next_address
	bne	.test_failed

	WATCHDOG
	moveq	#0, d0
	rts

.test_failed:
	move.w	d3, d1
	WATCHDOG
	moveq	#-1, d0
	rts


; params:
;  a0 = address start
;  d0 = increment
;  d1 = iterations
; returns:
; d0 = 0 (pass), $ff (fail)
; d1 = expected value
; d2 = actual value
check_ram_address_psub:
	subq.w	#1, d1
	move.w	d1, d2
	moveq	#0, d3

.loop_write_next_address:
	move.w	d3, (a0)			; write memory locations based on increment and iterations
	add.w	#$101, d3			; each location gets $0101 more then the previous
	adda.w	d0, a0
	dbra	d2, .loop_write_next_address

	move.l	a0, d3
	and.l	#$f00000, d3			; reset the $0101 counter
	movea.l	d3, a0

	moveq	#0, d3
	bra	.loop_start_address_read

.loop_read_next_address:
	add.w	#$101, d3
	adda.w	d0, a0
.loop_start_address_read:
	move.w	(a0), d2			; now re-read the same locations and make they match
	cmp.w	d2, d3
	dbne	d1, .loop_read_next_address
	bne	.test_failed
	WATCHDOG
	moveq	#0, d0
	PSUB_RETURN

.test_failed:
	move.w	d3, d1
	WATCHDOG
	moveq	#-1, d0
	PSUB_RETURN


palette_ram_address_tests:
	lea	PALETTE_RAM_START.l, a0
	moveq	#2, d0
	move.w	#$100, d1
	bsr	check_palette_ram_address
	beq	.test_passed_a0_a7
	moveq	#EC_PAL_ADDRESS_A0_A7, d0
	rts

.test_passed_a0_a7:
	lea	PALETTE_RAM_START.l, a0
	move.w	#$200, d0
	moveq	#$20, d1
	bsr	check_palette_ram_address
	beq	.test_passed_a8_a12
	moveq	#EC_PAL_ADDRESS_A0_A12, d0
	rts

.test_passed_a8_a12:
	moveq	#0, d0
	rts

; params:
;  d0 = increment amount
;  d1 = number of increments
check_palette_ram_address:
	lea	PALETTE_RAM_START.l, a0
	lea	PALETTE_RAM_MIRROR_START.l, a1
	subq.w	#1, d1
	move.w	d1, d2
	moveq	#0, d3

.loop_write_next_address:
	move.w	d3, (a0)
	add.w	#$101, d3
	adda.w	d0, a0				; write to palette ram
	cmpa.l	a0, a1				; continue until a0 == PALETTE_RAM_MIRROR
	bne	.skip_bank_switch_write

	move.b	d0, REG_PALBANK1
	lea	PALETTE_RAM_START.l, a0
.skip_bank_switch_write:
	dbra	d2, .loop_write_next_address

	move.b	d0, REG_PALBANK0
	lea	PALETTE_RAM_START.l, a0
	moveq	#0, d3
	bra	.loop_start_address_read


.loop_read_next_address:
	add.w	#$101, d3
	adda.w	d0, a0
	cmpa.l	a0, a1
	bne	.loop_start_address_read	; aka .skip_bank_switch_read

	move.b	d0, REG_PALBANK1
	lea	PALETTE_RAM_START.l, a0

.loop_start_address_read:
	move.w	(a0), d2
	cmp.w	d2, d3
	dbne	d1, .loop_read_next_address

	bne	.test_failed
	move.b	d0, REG_PALBANK0
	WATCHDOG
	moveq	#0, d0
	rts

.test_failed:
	move.w	d3, d1
	move.b	d0, REG_PALBANK0
	WATCHDOG
	moveq	#-1, d0
	rts

palette_ram_oe_tests:
	move.w	#$ff, d0
	bsr	check_palette_ram_74245_oe
	beq	.test_passed_74245_lower
	moveq	#EC_PAL_245_DEAD_OUTPUT_LOWER, d0
	rts

.test_passed_74245_lower:
	move.w	#$ff00, d0
	bsr	check_palette_ram_74245_oe
	beq	.test_passed_74245_upper
	moveq	#EC_PAL_245_DEAD_OUTPUT_UPPER, d0
	rts

.test_passed_74245_upper:
	move.w	#$ff, d0
	bsr	check_palette_ram_oe
	beq	.test_passed_lower
	moveq	#EC_PAL_DEAD_OUTPUT_LOWER, d0
	rts

.test_passed_lower:
	move.w	#$ff00, d0
	bsr	check_palette_ram_oe
	beq	.test_passed_upper
	moveq	#EC_PAL_DEAD_OUTPUT_UPPER, d0
	rts

.test_passed_upper:
	moveq	#0, d0
	rts


; params:
;  d0 = bitmask
; this seems to be doing the same thing as check_ram_we, with a delay before the re-read
check_palette_ram_oe:
	lea	PALETTE_RAM_START.l, a0
	move.w	#$ff, d2
	moveq	#0, d3
	move.w	#$101, d5

.loop_next_address
	move.w	d3, (a0)
	move.w	#$7fff, d4

.loop_delay:
	WATCHDOG
	dbra	d4, .loop_delay

	move.w	(a0), d1
	add.w	d5, d3
	and.w	d0, d1
	cmp.w	d0, d1
	dbne	d2, .loop_next_address

	beq	.test_failed
	moveq	#0, d0
	rts

.test_failed:
	moveq	#-1, d0
	rts


check_palette_ram_74245_oe:
	lea	PALETTE_RAM_START.l, a0
	moveq	#$31, d2

.loop_test_again:
	move.w	(a0), d1
	nop
	move.w	*-2(PC), d3
	and.w	d0, d1
	and.w	d0, d3
	cmp.w	d1, d3
	bne	.test_passed

	move.w	(a0), d1
	add.w	#0, d0
	move.w	*-4(PC), d3
	and.w	d0, d1
	and.w	d0, d3
	cmp.w	d1, d3
	bne	.test_passed

	move.w	(a0), d1
	seq	d3
	move.w	*-2(PC), d3
	and.w	d0, d1
	and.w	d0, d3
	cmp.w	d1, d3

.test_passed:
	dbeq	d2, .loop_test_again

	beq	.test_failed
	moveq	#0, d0
	rts

.test_failed:
	moveq	#-1, d0
	rts


auto_vram_tests:
	bsr	fix_backup

	bsr	vram_oe_tests
	bne	.test_failed_abort

	bsr	vram_we_tests
	bne	.test_failed_abort

	bsr	vram_data_tests
	bne	.test_failed_abort

	bsr	vram_address_tests

.test_failed_abort:
	move.w	d0, -(a7)
	bsr	fix_restore
	move.w	(a7)+, d0
	rts

vram_oe_tests:
	moveq	#0, d0
	move.w	#$ff, d1
	bsr	check_vram_oe
	beq	.test_passed_32k_lower
	moveq	#EC_VRAM_32K_DEAD_OUTPUT_LOWER, d0
	rts

.test_passed_32k_lower:
	moveq	#0, d0
	move.w	#$ff00, d1
	bsr	check_vram_oe
	beq	.test_passed_32k_upper
	moveq	#EC_VRAM_32K_DEAD_OUTPUT_UPPER, d0
	rts

.test_passed_32k_upper:
	move.w	#$8000, d0
	move.w	#$ff, d1
	bsr	check_vram_oe
	beq	.test_passed_2k_lower
	moveq	#EC_VRAM_2K_DEAD_OUTPUT_LOWER, d0
	rts

.test_passed_2k_lower:
	move.w	#$8000, d0
	move.w	#$ff00, d1
	bsr	check_vram_oe
	beq	.test_passed_2k_upper
	moveq	#EC_VRAM_2K_DEAD_OUTPUT_UPPER, d0
	rts

.test_passed_2k_upper:
	moveq	#0, d0
	rts

; params:
;  d0 = start vram address
;  d1 = mask
check_vram_oe:
	clr.w	(2,a6)
	move.w	d0, (-2,a6)
	move.w	#$ff, d2
	moveq	#0, d3
	move.w	#$101, d4

.loop_next_address:
	move.w	d3, (a6)
	nop
	nop
	nop
	nop
	move.w	(a6), d5
	add.w	d4, d3
	and.w	d1, d5
	cmp.w	d1, d5
	dbne	d2, .loop_next_address
	beq	.test_failed

	moveq	#0, d0
	rts

.test_failed:
	moveq	#-1, d0
	rts


vram_we_tests:
	moveq	#0, d0
	move.w	#$ff, d1
	bsr	check_vram_we
	beq	.test_passed_32k_lower
	moveq	#EC_VRAM_32K_UNWRITABLE_LOWER, d0
	rts

.test_passed_32k_lower:
	moveq	#$0, d0
	move.w	#$ff00, d1
	bsr	check_vram_we
	beq	.test_passed_32k_upper
	moveq	#EC_VRAM_32K_UNWRITABLE_UPPER, d0
	rts

.test_passed_32k_upper:
	move.w	#$8000, d0
	move.w	#$ff, d1
	bsr	check_vram_we
	beq	.test_passed_2k_lower
	moveq	#EC_VRAM_2K_UNWRITABLE_LOWER, d0
	rts

.test_passed_2k_lower:
	move.w	#$8000, d0
	move.w	#$ff00, d1
	bsr	check_vram_we
	beq	.test_passed_2k_upper
	moveq	#EC_VRAM_2K_UNWRITABLE_UPPER, d0
	rts

.test_passed_2k_upper:
	moveq	#0, d0
	rts


; params:
;  d0 = start vram address
;  d1 = mask
check_vram_we:
	move.w	d0, (-2,a6)
	clr.w	(2,a6)
	move.w	(a6), d0
	and.w	d1, d0
	moveq	#0, d2
	move.w	#$101, d5
	move.w	#$ff, d3
	lea	REG_WATCHDOG, a0

.loop_next_address:
	move.w	d2, (a6)
	move.b	d0, (a0)			; WATCHDOG
	add.w	d5, d2
	move.w	(a6), d4
	and.w	d1, d4
	cmp.w	d0, d4
	dbne	d3, .loop_next_address
	beq	.test_failed

	moveq	#0, d0
	rts

.test_failed:
	moveq	#-1, d0
	rts


vram_data_tests:
	bsr	vram_32k_data_tests
	bne	.test_failed_abort
	bsr	vram_2k_data_tests

.test_failed_abort:
	rts

vram_32k_data_tests:
	moveq	#0, d1
	moveq	#0, d0
	move.w	#$8000, d2
	bsr	check_vram_data
	beq	.test_passed_0000
	moveq	#EC_VRAM_DATA_0000, d0
	rts

.test_passed_0000:
	moveq	#0, d1
	moveq	#$55, d0
	move.w	#$8000, d2
	bsr	check_vram_data
	beq	.test_passed_5555
	moveq	#EC_VRAM_DATA_5555, d0
	rts

.test_passed_5555:
	moveq	#0, d1
	moveq	#-$56, d0
	move.w	#$8000, d2
	bsr	check_vram_data
	beq	.test_passed_aaaa
	moveq	#EC_VRAM_DATA_AAAA, d0
	rts

.test_passed_aaaa:
	moveq	#0, d1
	moveq	#-1, d0
	move.w	#$8000, d2
	bsr	check_vram_data
	beq	.test_passed_ffff
	moveq	#EC_VRAM_DATA_FFFF, d0
	rts

.test_passed_ffff				; check_vram_data will set d0 = 0 for us
	rts

; 2k (words) vram tests (data and address) only look at the
; first 1536 (0x600) words, since the remaining 512 words
; are used by the LSPC for buffers per dev wiki
vram_2k_data_tests:
	moveq	#-$80, d1
	moveq	#0, d0
	move.w	#$600, d2
	bsr	check_vram_data
	beq	.test_passed_0000
	moveq	#EC_VRAM_DATA_0000, d0
	rts

.test_passed_0000:
	moveq	#-$80, d1
	moveq	#$55, d0
	move.w	#$600, d2
	bsr	check_vram_data
	beq	.test_passed_5555
	moveq	#EC_VRAM_DATA_5555, d0
	rts

.test_passed_5555:
	moveq	#-$80, d1
	moveq	#-$56, d0
	move.w	#$600, d2
	bsr	check_vram_data
	beq	.test_passed_aaaa
	moveq	#EC_VRAM_DATA_AAAA, d0
	rts

.test_passed_aaaa
	moveq	#-$80, d1
	moveq	#-1, d0
	move.w	#$600, d2
	bsr	check_vram_data
	beq	.test_passed_ffff
	moveq	#EC_VRAM_DATA_FFFF, d0
	rts

.test_passed_ffff				; check_vram_data will set d0 = 0 for us
	rts

; params:
;  d0 = pattern (byte)
;  d1 = vram start address (byte) gets shifted left 8
;  d2 = length in words
; returns:
;  d0 = 0 (pass), $ff (fail)
;  a0 = fail address
;  d1 = expected value
;  d2 = actual value
; Its unclear why this functions params were made complex like this
; since all other ones just pass in the full pattern and full address
check_vram_data:
	move.b	d0, d3
	lsl.w	#8, d0
	move.b	d3, d0				; double up d0 so $YY becomes $YYYY for the pattern
	move.w	#1, (2,a6)
	lsl.w	#8, d1				; increase d1 (vram start address) by 256
	move.w	d1, (-2,a6)
	subq.w	#1, d2
	move.w	d2, d3

.loop_write_next_address:
	move.w	d0, (a6)			; write pattern
	dbra	d2, .loop_write_next_address

	move.w	d1, (-2,a6)
	lea	REG_WATCHDOG, a0
	move.w	d3, d2

.loop_read_next_address:
	move.b	d0, (a0)			; WATCHDOG
	move.w	(a6), d4			; read value
	move.w	d4, (a6)			; rewrite (to force address to increase)
	cmp.w	d0, d4
	dbne	d2, .loop_read_next_address
	bne	.test_failed

	moveq	#0, d0
	rts

.test_failed:
	add.w	d3, d1				; setup error data
	sub.w	d2, d1
	swap	d1
	clr.w	d1
	swap	d1
	movea.l	d1, a0
	move.w	d0, d1
	move.w	d4, d2
	moveq	#-1, d0
	rts


vram_address_tests:
	bsr	vram_32k_address_tests
	bne	.test_failed_abort
	bsr	vram_2k_address_tests

.test_failed_abort:
	rts

vram_32k_address_tests:
	clr.w	d1
	move.w	#$100, d2
	moveq	#1, d0
	bsr	check_vram_address
	beq	.test_passed_a0_a7
	moveq	#EC_VRAM_ADDRESS_A0_A7, d0
	rts

.test_passed_a0_a7:
	clr.w	d1
	move.w	#$80, d2
	move.w	#$100, d0
	bsr	check_vram_address
	beq	.test_passed_a8_a14
	moveq	#EC_VRAM_ADDRESS_A8_A14, d0
	rts

.test_passed_a8_a14:
	rts


vram_2k_address_tests:
	move.w	#$8000, d1
	move.w	#$100, d2
	moveq	#1, d0
	bsr	check_vram_address
	beq	.test_passed_a0_a7
	moveq	#EC_VRAM_ADDRESS_A0_A7, d0
	rts

.test_passed_a0_a7:
	move.w	#$8000, d1
	move.w	#$6, d2
	move.w	#$100, d0
	bsr	check_vram_address
	beq	.test_passed_a8_a14
	moveq	#EC_VRAM_ADDRESS_A8_A14, d0
	rts

.test_passed_a8_a14:
	rts

; params:
;  d0 = modulo/incr amount
;  d1 = start vram address
;  d2 = interation amount
; returns:
;  d0 = 0 (pass) / $ff (fail)
;  a0 = address (vram)
;  d1 = expected value
;  d2 = actual value
check_vram_address:
	move.w	d0, (2,a6)
	move.w	d1, (-2,a6)
	subq.w	#1, d2
	move.w	d2, d3
	moveq	#0, d0
	move.w	#$101, d5

.loop_write_next_address:
	move.w	d0, (a6)
	add.w	d5, d0
	dbra	d2, .loop_write_next_address

	move.w	d1, (-2,a6)
	moveq	#0, d0
	move.w	d3, d2
	lea	REG_WATCHDOG, a0
	bra	.loop_start_read_next_address

.loop_read_next_address:
	move.b	d0, (a0)			; WATCHDOG
	add.w	d5, d0

.loop_start_read_next_address:
	move.w	(a6), d4
	move.w	d4, (a6)
	cmp.w	d0, d4
	dbne	d2, .loop_read_next_address
	bne	.test_failed
	moveq	#0, d0
	rts

.test_failed:
	mulu.w	(2,a6), d3			; figure out the bad address based on
	add.w	d3, d1				; modulo and start address
	mulu.w	(2,a6), d2
	sub.w	d2, d1
	swap	d1
	clr.w	d1
	swap	d1
	movea.l	d1, a0
	move.w	d0, d1
	move.w	d4, d2
	moveq	#-1, d0
	rts


fix_backup:
	movem.l	d0/a0, -(a7)
	lea	FIXMAP_BACKUP_LOCATION.l, a0
	move.w	#FIXMAP, (-2,a6)
	move.w	#1, (2,a6)
	move.w	#$7ff, d0

.loop_next_address:
	nop
	nop
	move.w	(a6), (a0)+
	move.w	d0, (a6)
	dbra	d0, .loop_next_address
	movem.l	(a7)+, d0/a0
	rts

fix_restore:
	movem.l	d0/a0, -(a7)
	lea	FIXMAP_BACKUP_LOCATION.l, a0
	move.w	#FIXMAP, (-2,a6)
	move.w	#1, (2,a6)
	move.w	#$7ff, d0

.loop_next_address:
	move.w	(a0)+, (a6)
	dbra	d0, .loop_next_address
	movem.l	(a7)+, d0/a0
	rts


auto_mmio_tests:
	bsr	check_mmio_oe
	bne	.test_failed_abort
	bsr	check_mmio_reg_vramrw_oe

.test_failed_abort:
	rts


; does OE test against all the registers in the
; MMIO_ADDRESSES_TABLE_START table
check_mmio_oe:
	lea	MMIO_ADDRESSES_TABLE_START, a1
	moveq	#((MMIO_ADDRESSES_TABLE_END - MMIO_ADDRESSES_TABLE_START)/4 - 1), d7

.loop_next_test:
	movea.l	(a1)+, a0
	move.w	a0, d0

	lsr.b	#1, d0
	bcc	.system_both

	tst.b	REG_STATUS_B			; skip registers with bit 1 set on AES systems
	bpl	.system_aes

.system_both:
	bsr	check_mmio_oe_byte
	beq	.test_failed

.system_aes:
	dbra	d7, .loop_next_test

	moveq	#0, d0
	rts

.test_failed:
	moveq	#EC_MMIO_DEAD_OUTPUT, d0
	rts

MMIO_ADDRESSES_TABLE_START:
	dc.l REG_DIPSW
	dc.l REG_SYSTYPE
	dc.l REG_STATUS_A
	dc.l REG_P1CNT
	dc.l REG_SOUND
	dc.l REG_P2CNT
	dc.l REG_STATUS_B
MMIO_ADDRESSES_TABLE_END:

check_mmio_reg_vramrw_oe:
	movea.l	a6, a0
	bsr	check_mmio_oe_word
	beq	.test_failed

	moveq	#0, d0
	rts

.test_failed:
	moveq	#EC_MMIO_DEAD_OUTPUT, d0
	rts

; check for output enable of a byte at a0
; params:
;  a0 = address
check_mmio_oe_byte:
	moveq	#-1, d0
	move.w	a0, d0
	moveq	#$31, d2

.loop_test_again:
	move.b	(a0), d1
	cmp.b	*(PC,d0.w), d1
	bne	.test_passed

	move.b	(a0), d1
	nop
	cmp.b	*-2(PC,d0.w), d1
	bne	.test_passed

	move.b	(a0), d1
	add.w	#0, d0
	cmp.b	*-4(PC,d0.w), d1

.test_passed:
	dbeq	d2, .loop_test_again
	rts

; check for output enable of a word at a0
; params:
;  a0 = address
check_mmio_oe_word:
	moveq	#$31, d2

.loop_test_again:
	move.w	(a0), d1
	cmp.w	*(PC), d1
	bne	.test_passed

	move.w	(a0), d1
	nop
	cmp.w	*-2(PC), d1
	bne	.test_passed

	move.w	(a0), d1
	add.w	#0, d0
	cmp.w	*-4(PC), d1
.test_passed:
	dbeq	d2, .loop_test_again
	rts

manual_calendar_test:
	lea	XYP_STR_CAL_A_1HZ_PULSE, a0
	bsr	print_xyp_string_struct_clear
	lea	XYP_STR_CAL_B_64HZ_PULSE, a0
	bsr	print_xyp_string_struct_clear
	lea	XYP_STR_CAL_C_4096HZ_PULSE, a0
	bsr	print_xyp_string_struct_clear
	lea	XYP_STR_CAL_D_MAIN_MENU, a0
	bsr	print_xyp_string_struct_clear

	moveq	#$4, d0
	moveq	#$11, d1
	lea	STR_ACTUAL, a0
	bsr	print_xy_string_clear

	moveq	#$4, d0
	moveq	#$13, d1
	lea	STR_EXPECTED, a0
	bsr	print_xy_string_clear

	lea	XYP_STR_CAL_4990_TP, a0
	bsr	print_xyp_string_struct_clear

	bsr	rtc_set_1_hz

	bsr	p1_input_update

.loop_run_test:
	WATCHDOG
	bsr	p1_input_update

	bsr	rtc_print_data
	move.b	p1_input_edge, d0
	add.b	d0, d0
	bcs	.test_exit			; d pressed, exit test

	add.b	d0, d0
	bcc	.c_not_pressed			; check for c pressed
	bsr	rtc_set_4096_hz
	bra	.loop_run_test

.c_not_pressed:
	add.b	d0, d0
	bcc	.b_not_pressed
	bsr	rtc_set_64_hz
	bra	.loop_run_test

.b_not_pressed:
	add.b	d0, d0
	bcc	.loop_run_test
	bsr	rtc_set_1_hz
	bra	.loop_run_test

.test_exit:
	move	#$2700, sr			; disable interrupts
	move.w	#$0, ($4,a6)			; disable timer
	move.w	#$2, ($a,a6)			; ack timer interrupt
	rts

rtc_set_1_hz:
	moveq	#$8, d0
	move.l	#$5b8d80, d1
	bra	rtc_update_hz

rtc_set_64_hz:
	moveq	#$4, d0
	move.l	#$16e36, d1
	bra	rtc_update_hz


rtc_set_4096_hz:
	moveq	#$7, d0
	move.l	#$5b8, d1

rtc_update_hz:
	move.w	#$20, ($4,a6)		; Reload counter as soon as REG_TIMERLOW is written to
	clr.w	timer_count
	bsr	rtc_send_command

	move.l	d1, -(a7)
	lea	XYP_STR_CAL_WAITING_PULSE, a0
	bsr	print_xyp_string_struct_clear

	bsr	rtc_wait_pulse

	moveq	#$1b, d0
	bsr	fix_clear_line		; removes waiting for calendar pulse... line

	move.l	(a7)+, ($6,a6)		; timer high
	move.w	#$90, ($4,a6)		; lspcmode
	move	#$2100, sr		; enable interrupts
	moveq	#$0, d2			; zero out pulse counter
	rts


; d2 = number of pulses
rtc_print_data:
	moveq	#$e, d0
	moveq	#$11, d1
	move.w	d2, -(a7)
	bsr	print_hex_word

	moveq	#$e, d0
	moveq	#$13, d1
	move.w	timer_count, d2
	bsr	print_hex_word

	moveq	#$e, d0
	moveq	#$15, d1
	bsr	fix_seek_xy

	moveq	#$18, d0
	move.b	REG_STATUS_A, d1
	add.b	d1, d1
	add.b	d1, d1
	addx.b	d0, d0
	move.w	d0, (a6)

	move.w	(a7)+, d2
	bsr	rtc_check_pulse
	beq	.no_rtc_pulse
	addq.w	#1, d2

.no_rtc_pulse:
	rts


; Tiles 0x00 and 0x20 along with palette bank switching are used to
; generate the 4 color bars.
; tile 0x00 is a solid color1
; tile 0x20 is a solid color2
; color1 and color2 are also used for text foreground and background,
; so we need to leave palette0 untouched to allow for drawing text.
; This leaves palettes 1 to 15 for the color bars.
;
; red   = tile 0x00, palette bank0
; green = tile 0x20, palette bank0
; blue  = tile 0x00, palette bank1
; white = tile 0x20, palette bank1
manual_color_bars_test:
	lea	XYP_STR_CT_D_MAIN_MENU, a0
	bsr	print_xyp_string_struct_clear
	bsr	color_bar_setup_palettes
	bsr	color_bar_draw_tiles

.loop_run_test
	move.w	#$180, d0		; between green and blue, swap
	bsr	wait_scanline		; watchdog will happen in wait_scanline
	move.b	d0, REG_PALBANK1

	move.w	#$1e7, d0		; near bottom swap back
	bsr	wait_scanline
	move.b	d0, REG_PALBANK0

	bsr	p1p2_input_update
	btst	#D_BUTTON, p1_input_edge	; D pressed?
	beq	.loop_run_test

	; palette1 was clobbered, restore our gray on black
	move.l	#$07770000, PALETTE_RAM_START+PALETTE_SIZE+2
	rts


; setup color1&2 in palettes 1-15 for both banks.  Since the colors are
; adjacent we can update them both at the same time with long writes
color_bar_setup_palettes:

	; bank1 may have never been initialized
	move.b	d0, REG_PALBANK1
	clr.w	PALETTE_REFERENCE
	clr.w	PALETTE_BACKDROP
	move.l  #$7fff0000, PALETTE_RAM_START+$2	; white on black for text

	move.l	#$00010111, d0				; bluewhite
	bsr	color_bar_setup_palette_bank

	move.b	d0, REG_PALBANK0
	move.l	#$01000010, d0				; redgreen
	bsr	color_bar_setup_palette_bank

	rts

; setup an individual palette bank
; d0 = start value and also increment amount for color1&2
color_bar_setup_palette_bank:
	move.l	d0, d1					; save for increment amount
	moveq	#$e, d2					; 15 palettes to update
	lea	PALETTE_RAM_START+PALETTE_SIZE+$2, a0	; goto palette1 color1

.loop_next_palette
	move.l	d0, (a0)
	add.l	d1, d0
	adda.l	#PALETTE_SIZE, a0			; next palette/color1
	dbra	d2, .loop_next_palette
	rts


color_bar_draw_tiles:
	moveq	#$4, d0
	moveq	#$7, d1
	bsr	fix_seek_xy			; d0 on return will have current vram address
	move.w	#$1, (2,a6)			; increment vram writes one at a time

	moveq	#$e, d1				; 15 total shades in the gradients
	move.w	#$1000, d4			; palette1, tile 0x00
	move.w  #$1020, d5			; palette1, tile 0x20

.loop_next_shade

	moveq	#$1, d2				; each gradient shade is 2 tiles wide

.loop_double_wide

	; red
	move.w	d4, (a6)
	nop
	move.w	d4, (a6)
	nop
	move.w	d4, (a6)
	nop
	move.w	d4, (a6)
	nop
	move.w	#$20, (a6)
	nop

	; green
	move.w	d5, (a6)
	nop
	move.w	d5, (a6)
	nop
	move.w	d5, (a6)
	nop
	move.w	d5, (a6)
	nop
	move.w	#$20, (a6)
	nop

	; blue
	move.w	d4, (a6)
	nop
	move.w	d4, (a6)
	nop
	move.w	d4, (a6)
	nop
	move.w	d4, (a6)
	nop
	move.w	#$20, (a6)
	nop

	; white
	move.w	d5, (a6)
	nop
	move.w	d5, (a6)
	nop
	move.w	d5, (a6)
	nop
	move.w	d5, (a6)
	nop
	move.w	#$20, (a6)
	nop

	add.w	#$20, d0
	move.w	d0, (-2,a6)			; move over a column
	dbra	d2, .loop_double_wide

	add.w	#$1000, d4			; next palette
	add.w	#$1000, d5

	dbra	d1, .loop_next_shade

	rts


manual_controller_test:
	moveq	#$5, d0
	bsr	fix_clear_line
	bsr	controller_print_labels


.loop_update:
	WATCHDOG
	bsr	p1p2_input_update
	bsr	controller_update_player_data
	moveq	#$0, d0
	bsr	send_p1p2_controller
	moveq	#$3, d0
	and.b	REG_STATUS_B, d0
	bne	.loop_update				; loop until p1 start + select pressed

.loop_ss_still_pressed:
	WATCHDOG
	moveq	#$3, d0
	move.b	REG_STATUS_B, d1
	and.b	d0, d1
	cmp.b	d0, d1
	bne	.loop_ss_still_pressed			; wait for p1 start + select released
	rts


controller_print_labels:
	lea	XYP_STR_CT_P1, a0
	bsr	print_xyp_string_struct_clear
	lea	XYP_STR_CT_P2, a0
	bsr	print_xyp_string_struct_clear
	moveq	#$7, d3
	moveq	#$25, d4
.loop_next_header:
	move.b	d4, d0
	moveq	#$3, d1
	move.b	d3, d2
	bsr	print_hex_nibble
	subq.w	#4, d4
	dbra	d3, .loop_next_header

	moveq	#$4, d0
	bsr	controller_print_player_buttons
	moveq	#$11, d0
	bsr	controller_print_player_buttons
	rts


	dc.b "OUT", $0		; not used?

controller_print_player_buttons:
	move.b	d0, d3
	lea	CONTROLLER_BUTTONS_LIST, a0
.loop_next_buttom:
	moveq	#$4, d0
	move.b	d3, d1
	bsr	print_xy_string
	addq.b	#1, d3
	tst.b	(a0)
	bne	.loop_next_buttom
	rts


CONTROLLER_BUTTONS_LIST:
	dc.b "UP", $0
	dc.b "DN", $0
	dc.b "LF", $0
	dc.b "RT", $0
	dc.b "A", $0
	dc.b "B", $0
	dc.b "C", $0
	dc.b "D", $0
	dc.b "STA", $0
	dc.b "SEL", $0
	dc.b "HEX", $0
	dc.b "DEC", $0
	dc.b $0
	align 2

controller_update_player_data:
	moveq	#$0, d3
	moveq	#$0, d7

.loop_next_sample:
	move.b	d7, d0
	bsr	send_p1p2_controller
	bsr	p1p2_input_update

	clr.w	d0
	move.b	p1_input, d0
	move.b	p1_input_aux, d1
	lsl.w	#8, d1
	or.w	d1, d0			; merge input/input_aux into d0
	move.b	d3, d1
	moveq	#$4, d2
	movem.w	d3/d7, -(a7)
	bsr	controller_print_player_data
	movem.w	(a7)+, d3/d7

	clr.w	d0
	move.b	p2_input, d0
	move.b	p2_input_aux, d1
	lsl.w	#8, d1
	or.w	d1, d0
	move.b	d3, d1
	moveq	#$11, d2
	movem.w	d3/d7, -(a7)
	bsr	controller_print_player_data
	movem.w	(a7)+, d3/d7
	addq.b	#4, d3
	addq.b	#1, d7
	cmp.b	#$8, d7
	bne	.loop_next_sample
	rts


; params:
;  d0 = data
;  d1 = x offset?
;  d2 = y start
controller_print_player_data:
	move.w	d0, -(a7)
	move.w	d0, d4
	moveq	#$8, d5

	add.b	d1, d5
	move.b	d2, d6
	moveq	#$4, d3
	moveq	#$9, d7

.loop_next_bit:
	move.b	d5, d0
	move.b	d6, d1
	move.w	d4, d2
	bsr	print_bit
	lsr.w	#1, d4
	addq.b	#1, d6
	dbra	d7, .loop_next_bit

	move.b	d5, d0
	move.b	d6, d1
	move.w	(a7), d2
	bsr	print_hex_byte

	move.b	d5, d0
	move.b	d6, d1
	addq.b	#1, d1
	move.w	(a7)+, d2
	and.w	#$ff, d2
	bra	print_3_digits		; will rts for us


manual_wbram_test_loop:
	lea	XYP_STR_WBRAM_PASSES,a0
	bsr	print_xyp_string_struct_clear
	lea	XYP_STR_WBRAM_HOLD_ABCD, a0
	bsr	print_xyp_string_struct_clear

	moveq	#$0, d6
	tst.b	REG_STATUS_B
	bmi	.system_mvs
	bset	#$1f, d6
	lea	XYP_STR_WBRAM_WRAM_AES_ONLY, a0
	bsr	print_xyp_string_struct_clear

.system_mvs:
	moveq	#$c, d7				; re-setup d7 so we can do psub calls
	bra	.loop_start_run_test

.loop_run_test:
	WATCHDOG
	PSUB	auto_wram_data_tests
	tst.b	d0
	bne	.test_failed_abort

	PSUB	auto_wram_addreess_tests
	tst.b	d0
	bne	.test_failed_abort

	tst.l	d6
	bmi	.system_aes			; skip bram on aes
	move.b	d0, REG_SRAMUNLOCK

	PSUB	bram_data_tests
	tst.b	d0
	bne	.test_failed_abort

	PSUB	bram_address_tests
	move.b	d0, REG_SRAMLOCK
	tst.b	d0
	bne	.test_failed_abort

.system_aes:

	addq.l	#1, d6

.loop_start_run_test:

	moveq	#$e, d0
	moveq	#$e, d1
	move.l	d6, d2
	bclr	#$1f, d2
	PSUB	print_hex_3_bytes

	moveq	#-$10, d0
	and.b	REG_P1CNT, d0
	bne	.loop_run_test			; if a+b+c+d not pressed keep running test

	PSUB	fix_clear

	; re-init stuff and return to menu
	move.b	#3, main_menu_cursor
	movea.l	$0, a7
	moveq	#$c, d7
	bra	manual_tests

.test_failed_abort:
	move.b	d0, d6
	PSUB	print_error_data

	move.b	d6, d0
	PSUB	get_error_description

	moveq	#$4, d0
	moveq	#$5, d1
	PSUB	print_xy_string_clear
	bra	loop_reset_check_psub



manual_palette_ram_test_loop:
	lea	XYP_STR_PAL_PASSES, a0
	bsr	print_xyp_string_struct_clear
	lea	XYP_STR_PAL_A_TO_RESUME, a0
	bsr	print_xyp_string_struct_clear
	lea	XYP_STR_PAL_HOLD_ABCD, a0
	bsr	print_xyp_string_struct_clear

	bsr	palette_ram_backup

	moveq	#0, d6					; init pass count to 0
	bra	.loop_start_run_test

.loop_run_test:
	WATCHDOG

	bsr	palette_ram_data_tests
	bne	.test_failed_abort

	bsr	palette_ram_address_tests
	bne	.test_failed_abort

	addq.l	#1, d6

.loop_start_run_test:
	moveq	#$e, d0
	moveq	#$e, d1
	move.w	d6, d2
	bsr	print_hex_3_bytes			; print the number of passes in hex

	btst	#$4, REG_P1CNT				; check for 'a' being presses
	bne	.loop_run_test				; 'a' not pressed, loop and do another test

	bsr	palette_ram_restore

.loop_wait_a_release
	WATCHDOG
	moveq	#-$10, d0
	and.b	REG_P1CNT, d0				; a+b+c+d pressed? exit
	beq	.test_exit
	btst	#$4, REG_P1CNT				; only 'a' pressed
	beq	.loop_wait_a_release			; loop until either 'a' not pressed or 'a+b+c+d' pressed

	bsr	palette_ram_backup
	bra	.loop_run_test

.test_failed_abort					; error occured, print info
	move.b	d0, REG_PALBANK0
	bsr	palette_ram_restore

	move.w	d0, -(a7)
	bsr	print_error_data
	move.w	(a7)+, d0

	bsr	get_error_description
	movea.l	a0, a0					; bug? get_error_description already does this
	moveq	#$4, d0
	moveq	#$5, d1
	bsr	print_xy_string_clear

	moveq	#$19, d0
	bsr	fix_clear_line
	bra	loop_reset_check

.test_exit:
	rts


manual_vram_32k_test_loop:
	lea	XYP_STR_VRAM_32K_A_TO_RESUME, a0
	bsr	print_xyp_string_struct_clear

	lea	XYP_STR_PASSES.l, a0
	bsr	print_xyp_string_struct

	lea	STR_VRAM_HOLD_ABCD.l, a0
	moveq	#$4, d0
	moveq	#$19, d1
	bsr	print_xy_string

	bsr	fix_backup

	moveq	#$0, d6
	bra	.loop_start_run_test

.loop_run_test
	WATCHDOG
	bsr	vram_32k_data_tests
	bne	.test_failed_abort
	bsr	vram_32k_address_tests
	bne	.test_failed_abort
	addq.l	#1, d6

.loop_start_run_test:
	btst	#$4, REG_P1CNT
	bne	.loop_run_test			; loop until 'a' is pressed

	bsr	fix_restore

	moveq	#$e, d0
	moveq	#$e, d1
	move.l	d6, d2
	bclr	#$1f, d2			; make sure signed bit is 0
	bsr	print_hex_3_bytes		; print pass number

.loop_wait_a_release:
	WATCHDOG

	moveq	#-$10, d0
	and.b	REG_P1CNT, d0
	beq	.test_exit			; if a+b+c+d stop the test, return to main menu
	btst	#$4, REG_P1CNT
	beq	.loop_wait_a_release		; loop until either 'a' not pressed or 'a+b+c+d' pressed

	bsr	fix_backup
	bra	.loop_run_test

.test_failed_abort:
	bsr	fix_restore

	movem.l	d0-d2, -(a7)
	moveq	#$e, d0
	moveq	#$e, d1
	move.l	d6, d2
	bclr	#$1f, d2
	bsr	print_hex_3_bytes		; print pass number
	movem.l	(a7)+, d0-d2

	move.w	d0, -(a7)
	bsr	print_error_data
	move.w	(a7)+, d0
	bsr	get_error_description

	movea.l	a0, a0
	moveq	#$4, d0
	moveq	#$5, d1
	bsr	print_xy_string_clear

	moveq	#$19, d0
	bsr	fix_clear_line

	bra	loop_reset_check

.test_exit:
	rts


manual_vram_2k_test_loop:
	lea	STR_VRAM_HOLD_ABCD, a0
	moveq	#$4, d0
	moveq	#$1b, d1
	bsr	print_xy_string_clear

	lea	XYP_STR_PASSES.l, a0
	bsr	print_xyp_string_struct

	moveq	#$0, d6
	bra	.loop_start_run_test

.loop_run_test
	WATCHDOG
	bsr	vram_2k_data_tests
	bne	.test_failed_abort

	bsr	vram_2k_address_tests
	bne	.test_failed_abort

	moveq	#$e, d0
	moveq	#$e, d1
	move.l	d6, d2
	bsr	print_hex_3_bytes

	addq.l	#1, d6

.loop_start_run_test:
	moveq	#-$10, d0
	and.b	REG_P1CNT, d0
	beq	.test_exit			; if a+b+c+d pressed, exit test
	bra	.loop_run_test

.test_failed_abort:
	move.w	d0, -(a7)
	bsr	print_error_data
	move.w	(a7)+, d0

	bsr	get_error_description
	movea.l	a0, a0
	moveq	#$4, d0
	moveq	#$5, d1
	bsr	print_xy_string_clear

	moveq	#$19, d0
	bsr	fix_clear_line

	bra	loop_reset_check

.test_exit:
	rts

manual_misc_input_tests:
	lea	XYP_STR_MI_D_MAIN_MENU, a0
	bsr	print_xyp_string_struct_clear
	bsr	misc_input_print_static
.loop_run_test
	bsr	p1p2_input_update
	bsr	misc_input_update_dynamic
	bsr	wait_frame
	btst	#D_BUTTON, p1_input_edge
	beq	.loop_run_test			; if d pressed, exit test
	rts

misc_input_print_static:
	lea	XYP_STR_MI_MEMORY_CARD, a0
	bsr	print_xyp_string_struct_clear

	lea	MI_ITEM_CD1, a0
	moveq	#$9, d0
	moveq	#$3, d1
	bsr	misc_input_print_static_items

	lea	XYP_STR_MI_SYSTEM_TYPE, a0
	bsr	print_xyp_string_struct_clear

	lea	MI_ITEM_TYPE, a0
	moveq	#$e, d0
	moveq	#$1, d1
	bsr	misc_input_print_static_items

	tst.b	REG_STATUS_B
	bpl	.system_aes

	lea	MI_ITEM_CFG_A, a0
	moveq	#$f, d0
	moveq	#$2, d1
	bsr	misc_input_print_static_items

.system_aes:
	rts


misc_input_update_dynamic:
	lea	MI_ITEM_CD1,a0
	moveq	#$9, d0
	moveq	#$3, d1
	bsr	misc_input_print_dynamic_items

	lea	MI_ITEM_TYPE, a0
	moveq	#$e, d0
	moveq	#$1, d1
	bsr	misc_input_print_dynamic_items

	tst.b	REG_STATUS_B
	bpl	.system_aes

	lea	MI_ITEM_CFG_A, a0
	moveq	#$f, d0
	moveq	#$2, d1
	bsr	misc_input_print_dynamic_items

	lea	STR_SYSTEM_CONFIG_AS, a0
	moveq	#$4, d0
	moveq	#$12, d1
	bsr	print_xy_string

	btst	#$6, REG_SYSTYPE
	bne	.system_4_or_6_slots
	lea	STR_12SLOT, a0
	bra	.system_type_print

.system_4_or_6_slots:
	btst	#$5, REG_STATUS_A
	bne	.system_6_slot
	lea	STR_4SLOT, a0
	bra	.system_type_print

.system_6_slot:
	lea	STR_6SLOT, a0

.system_type_print:
	moveq	#$19, d0
	moveq	#$12, d1
	bsr	print_xy_string
.system_aes:
	rts


; struct misc_input {
;  byte test_bit;                ; bit to test on mmio address
;  byte mmio_address[3];         ; minus top byte
;  long bit_name_string_address;
;  long bit_disabled_string_address;
;  long bit_enabled_string_address;
;}
MI_ITEM_CD1:	MISC_INPUT_ITEM $04, $38, $00, $00, STR_MI_CD1, STR_MI_CARD1_DETECTED, STR_MI_CARD1_EMPTY
MI_ITEM_CD2:	MISC_INPUT_ITEM $05, $38, $00, $00, STR_MI_CD2, STR_MI_CARD2_DETECTED, STR_MI_CARD2_EMPTY
MI_ITEM_WP:	MISC_INPUT_ITEM $06, $38, $00, $00, STR_MI_WP, STR_MI_CARD_WP_OFF, STR_MI_CARD_WP_ON
MI_ITEM_TYPE:	MISC_INPUT_ITEM $07, $38, $00, $00, STR_MI_TYPE, STR_MI_TYPE_AES, STR_MI_TYPE_MVS
MI_ITEM_CFG_A:	MISC_INPUT_ITEM $05, $32, $00, $01, STR_MI_CFG_A, STR_MI_CFG_A_LOW, STR_MI_CFG_A_HIGH
MI_ITEM_CFG_B:	MISC_INPUT_ITEM $06, $30, $00, $81, STR_MI_CFG_B, STR_MI_CFG_B_LOW, STR_MI_CFG_B_HIGH

STR_SYSTEM_CONFIG_AS:	STRING "SYSTEM CONFIGURED AS "
STR_12SLOT:		STRING "1SLOT/2SLOT"
STR_4SLOT:		STRING "4SLOT      ";
STR_6SLOT:		STRING "6SLOT      ";


; d0 = start row
; d1 = numer of misc_input structs to process
; a0 = address of first misc_input struct
misc_input_print_dynamic_items:
	movea.l	a0, a1
	move.b	d0, d5
	moveq	#$7f, d7
	and.w	d1, d7
	subq.w	#1, d7

.loop_next_entry:
	movea.l	(a1), a2
	move.b	(a1), d0			; test_bit
	movea.l	($8,a1), a0			; bit_disabled_string_address
	moveq	#$30, d2
	btst	d0, (a2)
	beq	.print_description

	movea.l	($c,a1), a0			; bit_enabled_string_address
	moveq	#$31, d2

.print_description:
	moveq	#$d, d0
	move.b	d5, d1
	bsr	print_xy_char

	moveq	#$15, d0
	move.b	d5, d1
	moveq	#$0, d2
	moveq	#$20, d3
	moveq	#$13, d4
	bsr	print_char_repeat		; empty out part of the line stuff

	moveq	#$15, d0
	move.b	d5, d1
	bsr	print_xy_string

	lea	($10,a1), a1			; load up next struct
	addq.b	#1, d5
	dbra	d7, .loop_next_entry
	rts

; d0 = start row
; d1 = numer of misc_input structs to process
; a0 = address of first misc_input struct
misc_input_print_static_items:
	movea.l	a0, a1
	move.b	d0, d3
	moveq	#$7f, d7
	and.w	d1, d7
	subq.w	#1, d7

.loop_next_entry:
	move.l	(a1)+, d2			; load the test_bit and mmio_address
	moveq	#$4, d0
	move.b	d3, d1
	bsr	print_hex_3_bytes		; print the mmio_address

	moveq	#$2e, d2
	moveq	#$a, d0
	move.b	d3, d1
	bsr	print_xy_char

	move.b	(-$4,a1), d2			; reload test_bit
	moveq	#$b, d0
	move.b	d3, d1
	bsr	print_hex_nibble

	moveq	#$3d, d2
	moveq	#$c, d0
	move.b	d3, d1
	bsr	print_xy_char

	movea.l	(a1)+, a0			; load bit_name_string_address
	moveq	#$f, d0
	move.b	d3, d1
	bsr	print_xy_string

	addq.l	#8, a1				; skip over bit_(disabled|enabled)_string_address
	addq.b	#1, d3
	dbra	d7, .loop_next_entry
	rts

	rorg	$3000, $ff

STR_ACTUAL:			STRING "ACTUAL:"
STR_EXPECTED:			STRING "EXPECTED:"
STR_ADDRESS:			STRING "ADDRESS:"
STR_COLON_SPACE:		STRING ": "
STR_HOLD_SS_TO_RESET:		STRING "HOLD START/SELECT TO SOFT RESET"
STR_RELEASE_SS:			STRING "RELEASE START/SELECT"
STR_VERSION_HEADER:		STRING "NEO DIAGNOSTICS v0.19a00 - BY SMKDAN"

XYP_STR_PASSES:			XYP_STRING  4, 14,  0, "PASSES:"
XYP_STR_Z80_WAITING:		XYP_STRING  4,  5,  0, "WAITING FOR Z80 TO FINISH TESTS..."
XYP_STR_ALL_TESTS_PASSED:	XYP_STRING  4,  5,  0, "ALL TESTS PASSED"
XYP_STR_ABCD_MAIN_MENU:		XYP_STRING  4, 21,  0, "PRESS ABCD FOR MAIN MENU"
XYP_STR_Z80_TESTS_SKIPPED:	XYP_STRING  4, 23,  0, "NOTE: Z80 TESTING WAS SKIPPED. TO"
XYP_STR_Z80_HOLD_D_AND_SOFT:	XYP_STRING  4, 24,  0, "TEST Z80, HOLD BUTTON D AND SOFT"
XYP_STR_Z80_RESET_WITH_CART:	XYP_STRING  4, 25,  0, "RESET WITH TEST CART INSERTED."

XY_STR_WATCHDOG_DELAY:		XY_STRING  4,  5, "WATCHDOG DELAY..."
XY_STR_WATCHDOG_TEXT_REMAINS:	XY_STRING  4,  8, "IF THIS TEXT REMAINS HERE..."
XY_STR_WATCHDOG_STUCK:		XY_STRING  4, 10, "THEN SYSTEM IS STUCK IN WATCHDOG"

STR_TESTING_BIOS_MIRROR:	STRING "TESTING BIOS MIRRORING..."
STR_TESTING_BIOS_CRC32:		STRING "TESTING BIOS CRC32..."
STR_TESTING_RAM_OE:		STRING "TESTING RAM /OE..."
STR_TESTING_RAM_WE:		STRING "TESTING RAM /WE..."
STR_TESTING_WRAM_DATA:		STRING "TESTING WRAM DATA..."
STR_TESTING_WRAM_ADDRESS:	STRING "TESTING WRAM ADDRESS..."
STR_TESTING_BRAM:		STRING "TESTING BRAM..."
STR_TESTING_PALETTE_RAM:	STRING "TESTING PALETTE RAM..."
STR_TESTING_VRAM:		STRING "TESTING VRAM..."
STR_TESTING_MMIO:		STRING "TESTING MMIO..."

XYP_STR_Z80_SWITCHING_M1:	XYP_STRING  4,  5,  0, "SWITCHING TO CART M1..."
XYP_STR_Z80_IGNORED_SM1:	XYP_STRING  4,  5,  0, "Z80 SLOT SWITCH IGNORED (SM1)"
XYP_STR_Z80_SM1_UNRESPONSIVE:	XYP_STRING  4,  7,  0, "SM1 OTHERWISE LOOKS UNRESPONSIVE"
XYP_STR_Z80_MV1BC_HOLD_B:	XYP_STRING  4, 10,  0, "IF MV-1B/1C: SOFT RESET & HOLD B"
XYP_STR_Z80_PRESS_START:	XYP_STRING  4, 12,  0, "PRESS START TO CONTINUE"
XYP_STR_Z80_TESTING_COMM_PORT:	XYP_STRING  4,  5,  0, "TESTING Z80 COMM. PORT..."
XYP_STR_Z80_COMM_NO_HELLO:	XYP_STRING  4,  5,  0, "Z80->68k COMM ISSUE (HELLO)"
XYP_STR_Z80_COMM_NO_ACK:	XYP_STRING  4,  5,  0, "Z80->68k COMM ISSUE (ACK)"
XYP_STR_Z80_SKIP_TEST:		XYP_STRING  4, 24,  0, "TO SKIP Z80 TESTING, RELEASE"
XYP_STR_Z80_PRESS_D_RESET:	XYP_STRING  4, 25,  0, "D BUTTON AND SOFT RESET."
XYP_STR_Z80_MAKE_SURE:		XYP_STRING  4, 21,  0, "FOR Z80 TESTING, MAKE SURE TEST"
XYP_STR_Z80_CART_CLEAN:		XYP_STRING  4, 22,  0, "CART IS CLEAN AND FUNCTIONAL."
XYP_STR_Z80_M1_ENABLED:		XYP_STRING 34,  4,  0, "[M1]"
XYP_STR_Z80_SLOT_SWITCH_NUM:	XYP_STRING 29,  4,  0, "[SS ]"
XYP_STR_Z80_SM1_TESTS:		XYP_STRING 24,  4,  0, "[SM1]"

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

STR_BIOS_MIRROR:		STRING "BIOS ADDRESS (A13-A15)"
STR_BIOS_CRC32:			STRING "BIOS CRC ERROR"

STR_WRAM_DEAD_OUTPUT_LOWER:	STRING "WRAM DEAD OUTPUT (LOWER)"
STR_WRAM_DEAD_OUTPUT_UPPER:	STRING "WRAM DEAD OUTPUT (UPPER)"
STR_BRAM_DEAD_OUTPUT_LOWER:	STRING "BRAM DEAD OUTPUT (LOWER)"
STR_BRAM_DEAD_OUTPUT_UPPER:	STRING "BRAM DEAD OUTPUT (UPPER)"

STR_WRAM_UNWRITABLE_LOWER:	STRING "WRAM UNWRITABLE (LOWER)"
STR_WRAM_UNWRITABLE_UPPER:	STRING "WRAM UNWRITABLE (UPPER)"
STR_BRAM_UNWRITABLE_LOWER:	STRING "BRAM UNWRITABLE (LOWER)"
STR_BRAM_UNWRITABLE_UPPER:	STRING "BRAM UNWRITABLE (UPPER)"

STR_WRAM_DATA_0000:		STRING "WRAM DATA (0000)"
STR_WRAM_DATA_5555:		STRING "WRAM DATA (5555)"
STR_WRAM_DATA_AAAA:		STRING "WRAM DATA (AAAA)"
STR_WRAM_DATA_FFFF:		STRING "WRAM DATA (FFFF)"
STR_BRAM_DATA_0000:		STRING "BRAM DATA (0000)"
STR_BRAM_DATA_5555:		STRING "BRAM DATA (5555)"
STR_BRAM_DATA_AAAA:		STRING "BRAM DATA (AAAA)"
STR_BRAM_DATA_FFFF:		STRING "BRAM DATA (FFFF)"

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

STR_PAL_BANK0_DATA_0000:	STRING "PALETTE BANK0 DATA (0000)"
STR_PAL_BANK0_DATA_5555:	STRING "PALETTE BANK0 DATA (5555)"
STR_PAL_BANK0_DATA_AAAA:	STRING "PALETTE BANK0 DATA (AAAA)"
STR_PAL_BANK0_DATA_FFFF:	STRING "PALETTE BANK0 DATA (FFFF)"
STR_PAL_BANK1_DATA_0000:	STRING "PALETTE BANK1 DATA (0000)"
STR_PAL_BANK1_DATA_5555:	STRING "PALETTE BANK1 DATA (5555)"
STR_PAL_BANK1_DATA_AAAA:	STRING "PALETTE BANK1 DATA (AAAA)"
STR_PAL_BANK1_DATA_FFFF:	STRING "PALETTE BANK1 DATA (FFFF)"

STR_PAL_ADDRESS_A0_A7:		STRING "PALETTE ADDRESS (A0-A7)"
STR_PAL_ADDRESS_A0_A12:		STRING "PALETTE ADDRESS (A8-A12)"

STR_VRAM_DATA_0000:		STRING "VRAM DATA (0000)"
STR_VRAM_DATA_5555:		STRING "VRAM DATA (5555)"
STR_VRAM_DATA_AAAA:		STRING "VRAM DATA (AAAA)"
STR_VRAM_DATA_FFFF:		STRING "VRAM DATA (FFFF)"

STR_VRAM_ADDRESS_A0_A7:		STRING "VRAM ADDRESS (A0-A7)"
STR_VRAM_ADDRESS_A8_A14:	STRING "VRAM ADDRESS (A8-A10/A8-A14)"

STR_VRAM_32K_DEAD_OUTPUT_LOWER:	STRING "VRAM 32K DEAD OUTPUT (LOWER)"
STR_VRAM_32K_DEAD_OUTPUT_UPPER:	STRING "VRAM 32K DEAD OUTPUT (UPPER)"
STR_VRAM_2K_DEAD_OUTPUT_LOWER:	STRING "VRAM 2K DEAD OUTPUT (LOWER)"
STR_VRAM_2K_DEAD_OUTPUT_UPPER:	STRING "VRAM 2K DEAD OUTPUT (UPPER)"

STR_VRAM_32K_UNWRITABLE_LOWER:	STRING "VRAM 32K UNWRITABLE (LOWER)"
STR_VRAM_32K_UNWRITABLE_UPPER:	STRING "VRAM 32K UNWRITABLE (UPPER)"
STR_VRAM_2K_UNWRITABLE_LOWER:	STRING "VRAM 2K UNWRITABLE (LOWER)"
STR_VRAM_2K_UNWRITABLE_UPPER:	STRING "VRAM 2K UNWRITABLE (UPPER)"

STR_MMIO_DEAD_OUTPUT:		STRING "MMIO DEAD OUTPUT"

; main menu items;
STR_MM_CALENDAR_IO:		STRING "CALENDAR I/O (MVS ONLY)"
STR_MM_COLOR_BARS:		STRING "COLOR BARS"
STR_MM_CONTROLER_TEST:		STRING "CONTROLLER TEST"
STR_MM_WBRAM_TEST_LOOP:		STRING "WRAM/BRAM TEST LOOP"
STR_MM_PAL_RAM_TEST_LOOP:	STRING "PALETTE RAM TEST LOOP"
STR_MM_VRAM_TEST_LOOP_32K:	STRING "VRAM TEST LOOP (32K)"
STR_MM_VRAM_TEST_LOOP_2K:	STRING "VRAM TEST LOOP (2K)"
STR_MM_MISC_INPUT_TEST:		STRING "MISC. INPUT TEST"

; strings for calender io screen;
XYP_STR_CAL_A_1HZ_PULSE:	XYP_STRING  4,  8,  0, "A: 1Hz pulse"
XYP_STR_CAL_B_64HZ_PULSE:	XYP_STRING  4, 10,  0, "B: 64Hz pulse"
XYP_STR_CAL_C_4096HZ_PULSE:	XYP_STRING  4, 12,  0, "C: 4096Hz pulse"
XYP_STR_CAL_D_MAIN_MENU:	XYP_STRING  4, 14,  0, "D: Return to menu"
XYP_STR_CAL_4990_TP:		XYP_STRING  4, 21,  0, "4990 TP:"
XYP_STR_CAL_WAITING_PULSE:	XYP_STRING  4, 27,  0, "WAITING FOR CALENDAR PULSE..."

; strings for controller test screen;
XYP_STR_CT_D_MAIN_MENU:		XYP_STRING  4, 27,  0, "D: Return to menu"
XYP_STR_CT_P1:			XYP_STRING  1,  4,  0, "P1"
XYP_STR_CT_P2:			XYP_STRING  1, 17,  0, "P2"

; strings wram/bram test screens;
XYP_STR_WBRAM_PASSES:		XYP_STRING  4, 14,  0, "PASSES:"
XYP_STR_WBRAM_HOLD_ABCD:	XYP_STRING  4, 27,  0, "HOLD ABCD TO STOP"
XYP_STR_WBRAM_WRAM_AES_ONLY:	XYP_STRING  4, 16,  0, "WRAM TEST ONLY (AES)"

; strings for palette test screen;
XYP_STR_PAL_PASSES:		XYP_STRING  4, 14,  0, "PASSES:"
XYP_STR_PAL_A_TO_RESUME:	XYP_STRING  4, 27,  0, "RELEASE A TO RESUME"
XYP_STR_PAL_HOLD_ABCD:		XYP_STRING  4, 25,  0, "HOLD ABCD TO STOP"

; strings for vram test screens;
XYP_STR_VRAM_32K_A_TO_RESUME:	XYP_STRING  4, 27,  0, "RELEASE A TO RESUME"
STR_VRAM_HOLD_ABCD:		STRING "HOLD ABCD TO STOP"

; strings for misc input screen;
XYP_STR_MI_D_MAIN_MENU:		XYP_STRING  4, 27,  0, "D: Return to menu"
XYP_STR_MI_MEMORY_CARD:		XYP_STRING  4,  8,  0, "MEMORY CARD:"
XYP_STR_MI_SYSTEM_TYPE:		XYP_STRING  4, 13,  0, "SYSTEM TYPE:"
STR_MI_CD1:			STRING "/CD1"
STR_MI_CARD1_DETECTED:		STRING "(CARD DETECTED)"
STR_MI_CARD1_EMPTY:		STRING "(CARD SLOT EMPTY)"
STR_MI_CD2:			STRING "/CD2"
STR_MI_CARD2_DETECTED:		STRING "(CARD DETECTED)"
STR_MI_CARD2_EMPTY:		STRING "(CARD SLOT EMPTY)"
STR_MI_WP:			STRING "/WP"
STR_MI_CARD_WP_OFF:		STRING "(CARD WP OFF)"
STR_MI_CARD_WP_ON:		STRING "(CARD WP ON)"
STR_MI_TYPE:			STRING "TYPE"
STR_MI_TYPE_AES:		STRING "(SYSTEM IS AES)"
STR_MI_TYPE_MVS:		STRING "(SYSTEM IS MVS)"
STR_MI_CFG_A:			STRING "CFG-A"
STR_MI_CFG_A_LOW:		STRING "(CFG-A LOW)"
STR_MI_CFG_A_HIGH:		STRING "(CFG-A HIGH)"
STR_MI_CFG_B:			STRING "CFG-B"
STR_MI_CFG_B_LOW:		STRING "(CFG-B LOW)"
STR_MI_CFG_B_HIGH:		STRING "(CFG-B HIGH)"

	rorg	$3ffb, $ff
; these get filled in by gen-crc-mirror
	dc.b 	$00			; bios copy mirror.  mirror 1 (running copy) is $0, 2nd is $1, etc, up to $7
	dc.b 	$00,$00,$00,$00		; bios crc32 value calculated from bios_start to $c03ffb
