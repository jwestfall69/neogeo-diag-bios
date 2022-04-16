	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"

	global fix_backup
	global fix_clear_ssa3
	global fix_clear_line_ssa3
	global fix_fill_ssa3
	global fix_restore
	global fix_seek_xy_ssa3
	global print_bit_dsub
	global print_char_repeat_dsub
	global print_digit_dsub
	global print_digits_dsub
	global print_3_digits_dsub
	global print_5_digits_dsub
	global print_hex_nibble_dsub
	global print_hex_byte_dsub
	global print_hex_word_dsub
	global print_hex_3_bytes_dsub
	global print_hex_long_dsub
	global print_xy_char_dsub
	global print_xy_string_dsub
	global print_xy_string_clear_dsub
	global print_xy_string_struct_dsub
	global print_xy_string_struct_clear_dsub
	global print_xyp_string

	section text

; set vram addr so its at location x,y of fix layer
; params:
;  d0 = x
;  d1 = y
fix_seek_xy_ssa3:
		ext.w	d0
		ext.w	d1
		lsl.w	#5, d0
		or.w	d1, d0
		or.w	#FIXMAP, d0
		move.w	d0, (-2,a6)
		SSA3_RETURN

; clears a line of the fix layer
; params:
;  d0 = line to clear
fix_clear_line_ssa3:
		ext.w	d0
		add.w	#FIXMAP, d0
		move.w	d0, (-2,a6)
		move.w	#$20, (2,a6)
		moveq	#$20, d0
		moveq	#$27, d1
	.loop_next_tile:
		move.w	d0, (a6)
		dbra	d1, .loop_next_tile
		SSA3_RETURN

; clears the fix layer
fix_clear_ssa3:
		move.w	#$20, d0

; fills the entire fix layer with a tile
; d0 = tile
fix_fill_ssa3:
		move.w	#FIXMAP, (-2,a6)
		move.w	#1, (2,a6)
		move.w	#$4ff, d1
	.loop_next_tile:
		move.w	d0, (a6)
		dbra	d1, .loop_next_tile
		WATCHDOG
		SSA3_RETURN

; prints a char at x,y of fix layer
; parms:
; d0 = x
; d1 = y
; d2 = char
print_xy_char_dsub:
		SSA3	fix_seek_xy
		and.w	#$ff, d2
		move.w	d2, (a6)
		DSUB_RETURN


; clears the line the string will be printed on, then falls through to print_xy_string_dsub
; params:
;  d0 = x
;  d1 = y
;  a0 = string location
print_xy_string_clear_dsub:
		move.b	d0, d2			; fix_clear_line expects d0 to be y
		swap	d2			; backup d0.b and d1.b into d2
		move.b	d1, d2			; then make d0.b be y
		move.b	d1, d0
		SSA3	fix_clear_line
		move.b	d2, d1			; restore d0.b and d1.b
		swap	d2
		move.b	d2, d0

; print string to x,y
; params:
;  d0 = x
;  d1 = y
;  a0 = string location
print_xy_string_dsub:
		SSA3	fix_seek_xy
		move.w	#$20, (2,a6)
		moveq	#0, d2
		move.b	(a0)+, d2
	.loop_next_char:
		move.w	d2, (a6)
		move.b	(a0)+, d2
		bne	.loop_next_char
		DSUB_RETURN

; prints string at starting at x,y using d2 as the upper byte of the fix map entry
; params:
;  d0 = x
;  d1 = y
;  d2 = upper byte of fix map entry
;  a0 = address of string
print_xyp_string:
		SSA3	fix_seek_xy
		move.w	#$20, (2,a6)
		move.b	d2, -(a7)		; these 3 instructions cause the d2.b to be moved to
		move.w	(a7)+, d2		; the upper byte of d2.w.  The lower d2.w will be garbage,
		move.b	(a0)+, d2		; but we replace it with current char from string
	.loop_next_char:
		move.w	d2, (a6)
		move.b	(a0)+, d2
		bne	.loop_next_char
		rts

; clears the line that an xy string will be on, then falls through to print_xy_string_struct_dsub
; params:
;  a0 = start of xy string struct
print_xy_string_struct_clear_dsub:
		move.b	(1, a0), d0
		SSA3	fix_clear_line

; prints xy string at x,y
; params:
;  a0 - start of xy string struct
print_xy_string_struct_dsub:
		move.b	(a0)+, d0
		move.b	(a0)+, d1
		SSA3	fix_seek_xy
		move.w	#$20, (2,a6)
		moveq	#0, d2
		move.b	(a0)+, d2
	.loop_next_char:
		move.w	d2, (a6)
		move.b	(a0)+, d2
		bne	.loop_next_char
		DSUB_RETURN

; prints the char n times starting at x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = upper byte of fix map entry
;  d3 = char
;  d4 = number of times to print
print_char_repeat_dsub:
		SSA3	fix_seek_xy
		move.w	#$20, (2,a6)
		lsl.w	#8, d2
		move.b	d3, d2
		subq.w	#1, d4
	.loop_next_tile:
		move.w	d2, (a6)
		dbra	d4, .loop_next_tile
		DSUB_RETURN

; prints a nibble in hex starting at location x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_hex_nibble_dsub:
		SSA3	fix_seek_xy
		moveq	#0, d1
		bra	print_hex_dsub			; handles DSUB_RETURN for us

; prints 1 byte in hex starting at location x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_hex_byte_dsub:
		addq.w	#1, d0
		SSA3	fix_seek_xy
		moveq	#1, d1
		bra	print_hex_dsub			; handles DSUB_RETURN for us

; prints 2 bytes in hex starting at location x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_hex_word_dsub:
		addq.w	#3, d0
		SSA3	fix_seek_xy
		moveq	#3, d1
		bra	print_hex_dsub			; handles DSUB_RETURN for us


; prints 3 bytes in hex starting at location x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_hex_3_bytes_dsub:
		addq.w	#5, d0
		SSA3	fix_seek_xy
		moveq	#5, d1
		bra	print_hex_dsub			; handles DSUB_RETURN for us


; prints 4 bytes in hex starting at location x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_hex_long_dsub:
		addq.w	#7, d0
		SSA3	fix_seek_xy
		moveq	#7, d1				; falls through to print_hex_dsub

; prints N hex chars, caller must already be at end x,y location as this function prints backwards
; params:
;  d1 = number of chars to print - 1
;  d2 = data
print_hex_dsub:
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
		DSUB_RETURN

HEX_LOOKUP:
	dc.b	"0123456789ABCDEF"


; prints bit 0/1 at location x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data (bit 0)
print_bit_dsub:
		SSA3	fix_seek_xy
		and.w	#1, d2
		add.b	#$30, d2
		move.w	d2, (a6)
		DSUB_RETURN


; prints a digit start at x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = digit
print_digit_dsub:
		SSA3	fix_seek_xy
		moveq	#0, d1
		bra	print_digits_dsub

; prints 3 digits starting at x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data
print_3_digits_dsub:
		addq.w	#2, d0
		SSA3	fix_seek_xy
		moveq	#2, d1
		bra	print_digits_dsub

; prints 5 digits starting at x,y
; params:
;  d0 = x
;  d1 = y
;  d2 = data
; unused code?
print_5_digits_dsub:
		addq.w	#4, d0
		SSA3	fix_seek_xy
		moveq	#4, d1
		nop				; falls through to print_digits_dsub

; prints digits
; params:
;  d1 = number of digits - 1
;  d2 = data
; prints backwards so caller must have x,y at the end location you want
print_digits_dsub:
		move.w	#$ffe0, (2,a6)			; write backwards
		moveq	#$30, d0
	.loop_next_digit:
		divu.w	#10, d2				; divide by 10 and print the remainder
		swap	d2
		add.b	d0, d2
		move.w	d2, (a6)
		clr.w	d2
		swap	d2
		dbeq	d1, .loop_next_digit

		; any remaining digit slots pad with spaces
		bra	.loop_pad_space_start
	.loop_pad_space:
		move.w	#$20, (a6)
	.loop_pad_space_start:
		dbra	d1, .loop_pad_space
		DSUB_RETURN

fix_backup:
		movem.l	d0/a0, -(a7)
		lea	FIXMAP_BACKUP_LOCATION, a0
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
		lea	FIXMAP_BACKUP_LOCATION, a0
		move.w	#FIXMAP, (-2,a6)
		move.w	#1, (2,a6)
		move.w	#$7ff, d0

	.loop_next_address:
		move.w	(a0)+, (a6)
		dbra	d0, .loop_next_address
		movem.l	(a7)+, d0/a0
		rts
