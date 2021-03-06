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

	rorg	$80, $ff

; Simple|Small Subroutine A3 (SSA3)
; One of the limitations with dsubs is only being able to nest 2 times.  This
; is mainly a problem with the print related dsubs as most will want to either
; seek to an x,y location in the fix layer and/or clearing a fix layer line.
; If print dsub were to dsub call fix_seek_xy|fix_clear_line it would often
; be one to many nests, so a bunch of the print dsub's had a copy of the code
; for fix_seek_xy|fix_clear_line in them.  SSA3 is meant to get around this by
; calling a simple|small subroutine that will always jmp (a3) to return.  This
; way we can get around having another dsub nest.
;
; ssa3 code blocks should be kept simple and should never call any other
; subroutines.  They should not touch a3/a4/a5/a7/d7 registers and/or use
; the stack.
;
; Two macros are setup to handle these
;  SSA3 <subroutine>
;   This will deal with setting up the return label and pushing it into a3,
;   then calling the subroutine. Note that the macro will automatically
;   append _ssa3 onto the supplied subroutine name.
;  SSA3_RETURN
;   When in a ssa3, SSA3_RETURN should be used to return from the subroutine.


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

; dsub_enter/dsub_return allows creating and using dynamic subroutines.
; There are 2 modes for calling dynamic subroutines.
;
;  psuedo mode:
;    In this mode jumping to and returning from a dsub isn't reliant
;    on the stack, and thus there is no dependency on ram.  In this
;    mode a4, a5, a7 are used to store the jump back locations. To
;    switch to this mode d7 must be initialized with
;    DSUB_INIT_PSEUDO ($0c) before making the first dsub call. This mode
;    is the exact same as 0.19's pseudo subroutines
;
;  real mode:
;    In this mode jumping to and returning from a dsub will mimic
;    a normal bsr/rts by pushing the return address onto the stack.
;    a4, a5 are free to use outside the dsub. To swith to this mode
;    d7 must be initialized with DSUB_INIT_REAL ($18) before making
;    the first dsub call.
;
; Up to 2 nested dsub calls are supported.  When I dsub calls another
; dsub, the nested call with follow the same mode its already in.
;
; dsub_enter requires 2 registers to be setup
; a2 = dsub that will be called
; a3 = address to jmp to when dsub is finished
;
; dsub code blocks should not touch a4/a5/a7/d7 registers and/or use
; the stack. When a dsub code block is done it should jmp/bra to
; dsub_return instead of calling rts or something else.
;
; Code blocks that are dsubs should have _dsub append onto their
; subroutine names.
;
; A couple macros are set to deal with calling/returning from dsubs
;  DSUB <subroutine>
;   This will deal with setting the return label, populating a2, a3
;   and then jumping dsub_enter.  Note that the macro will automatically
;   append _dsub onto the supplied subroutine name.  This macro should be used
;   when a dsub calling another dsub
;  PSUB <subrouting>
;   This is meant to be called when using dsub in pseudo mode.  Its the exact
;   same as the DSUB macro.  It just exists to make it easier to follow the
;   code, by making it clear the call is meant to be pseudo.
;  RSUB <subroutine>
;   This is meant to be called when using dsub in real mode.  It bypasses
;   using dsub_enter and will instead directly adjust d7 then do an actual
;   bsr to the dsub.  Note that the macro will automatically append
;   _dsub onto the supplied subroutine name.
;  DSUB_RETURN
;   When in a dsub, DSUB_RETURN should be used to return from the subroutine
dsub_enter:
	subq.w	#4, d7
	jmp	*+4(PC, d7.w)

	; pseudo mode (DSUB)
	movea.l	a3, a4
	jmp	(a2)
	movea.l	a3, a5
	jmp	(a2)
	movea.l	a3, a7
	jmp	(a2)

	; real mode (RSUB)
	move.l	a3, -(a7)
	jmp	(a2)
	move.l	a3, -(a7)
	jmp	(a2)
	move.l	a3, -(a7)
	jmp	(a2)

dsub_return:
	addq.w	#4, d7
	jmp	*(PC, d7.w)

	; pseudo mode (DSUB)
	jmp	(a4)
	nop
	jmp	(a5)
	nop
	jmp	(a7)

	; real modde (RSUB)
	nop
	rts
	nop
	rts
	nop
	rts

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
	nop					; falls through to print_digits_dsub

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
	moveq	#DSUB_INIT_PSEUDO, d7				; init dsub for pseudo subroutines
	move.l	#$7fff0000, PALETTE_RAM_START+$2		; white on black for text
	move.l	#$07770000, PALETTE_RAM_START+PALETTE_SIZE+$2	;  gray on black for text (disabled menu items)
	clr.w	PALETTE_REFERENCE
	clr.w	PALETTE_BACKDROP

	SSA3	fix_clear

	moveq	#-$10, d0
	and.b	REG_P1CNT, d0			; check for A+B+C+D being pressed, if not automatic_tests

	ifnd force_manual_tests
		bne	automatic_tests
	endif

	movea.l	$0, a7				; re-init SP
	moveq	#DSUB_INIT_REAL, d7		; init dsub for real subroutines
	clr.b	main_menu_cursor
	bra	manual_tests

automatic_tests:
	PSUB	print_header
	PSUB	watchdog_stuck_test
	PSUB	automatic_psub_tests

	movea.l	$0, a7				; re-init SP
	moveq	#DSUB_INIT_REAL, d7		; init dsub for real subroutines

	clr.b	z80_test_flags

	btst	#7, REG_P1CNT			; if P1 "D" was pressed at boot
	beq	.z80_test_enabled

	; auto-detect m1 by checking for the HELLO message (ie diag m1 + AES or MV-1B/C)
	move.b	#COMM_TEST_HELLO, d1
	cmp.b	REG_SOUND, d1
	beq	.z80_test_enabled

 	ifnd force_z80_tests
		bne	skip_z80_test		; skip Z80 tests if "D" not pressed
 	endif

.z80_test_enabled:

	bset.b	#Z80_TEST_FLAG_ENABLED, z80_test_flags

	cmp.b	REG_SOUND, d1
	beq	skip_slot_switch		; skip slot switch if auto-detected m1

	tst.b	REG_STATUS_B
	bpl	skip_slot_switch		; skip slot switch if AES

	btst	#5, REG_P1CNT
	beq	skip_slot_switch		; skip slot switch if P1 "B" is pressed

	bsr	z80_slot_switch

skip_slot_switch:

	bsr	z80_comm_test
	lea	XY_STR_Z80_WAITING, a0
	RSUB	print_xy_string_struct_clear

.loop_try_again:
	WATCHDOG
	bsr	z80_check_error
	bsr	z80_check_sm1_test
	bsr	z80_check_done
	bne	.loop_try_again

skip_z80_test:

	bsr	automatic_function_tests
	lea	XY_STR_ALL_TESTS_PASSED, a0
	RSUB	print_xy_string_struct_clear

	lea	XY_STR_ABCD_MAIN_MENU, a0
	RSUB	print_xy_string_struct_clear

	tst.b	z80_test_flags

	bne	.loop_user_input

	lea	XY_STR_Z80_TESTS_SKIPPED, a0
	RSUB	print_xy_string_struct_clear

	lea	XY_STR_Z80_HOLD_D_AND_SOFT, a0
	RSUB	print_xy_string_struct_clear

	lea	XY_STR_Z80_RESET_WITH_CART, a0
	RSUB	print_xy_string_struct_clear

.loop_user_input
	WATCHDOG
	bsr	check_reset_request

	moveq	#-$10, d0
	and.b	REG_P1CNT, d0		; ABCD pressed?
	bne	.loop_user_input

	movea.l	$0, a7			; re-init SP
	moveq	#DSUB_INIT_REAL, d7	; init dsub for real subroutines
	clr.b	main_menu_cursor
	SSA3	fix_clear
	bra	manual_tests

watchdog_stuck_test_dsub:
	lea	XY_STR_WATCHDOG_DELAY, a0
	DSUB	print_xy_string_struct_clear
	lea	XY_STR_WATCHDOG_TEXT_REMAINS, a0
	DSUB	print_xy_string_struct_clear
	lea	XY_STR_WATCHDOG_STUCK, a0
	DSUB	print_xy_string_struct_clear

	move.l	#$c930, d0		; 128760us / 128.76ms
	DSUB	delay

	moveq	#8, d0
	SSA3	fix_clear_line
	moveq	#10, d0
	SSA3	fix_clear_line
	DSUB_RETURN

; runs automatic tests that are psub based
automatic_psub_tests_dsub:
	moveq	#0, d6
.loop_next_test:
	movea.l	(AUTOMATIC_PSUB_TEST_STRUCT_START+4,pc,d6.w),a0
	moveq	#4, d0
	moveq	#5, d1
	DSUB	print_xy_string_clear			; print the test description to screen

	movea.l	(AUTOMATIC_PSUB_TEST_STRUCT_START,pc,d6.w), a2
	lea	(.dsub_return), a3			; manually do dsub call since the DSUB macro wont
	bra	dsub_enter				; work in this case
.dsub_return

	tst.b	d0					; check result
	beq	.test_passed

	move.b	d0, d6
	DSUB	print_error
	move.b	d6, d0

	tst.b	REG_STATUS_B
	bpl	.skip_error_to_credit_leds	; skip if aes
	move.b	d6, d0
	DSUB	error_to_credit_leds

.skip_error_to_credit_leds
	bra	loop_reset_check_dsub

.test_passed:
	addq.w	#8, d6
	cmp.w	#(AUTOMATIC_PSUB_TEST_STRUCT_END - AUTOMATIC_PSUB_TEST_STRUCT_START), d6
	bne	.loop_next_test
	DSUB_RETURN


AUTOMATIC_PSUB_TEST_STRUCT_START:
	dc.l	auto_bios_mirror_test_dsub, STR_TESTING_BIOS_MIRROR
	dc.l	auto_bios_crc32_test_dsub, STR_TESTING_BIOS_CRC32
	dc.l	auto_ram_oe_tests_dsub, STR_TESTING_RAM_OE
	dc.l	auto_ram_we_tests_dsub, STR_TESTING_RAM_WE
	dc.l	auto_wram_data_tests_dsub, STR_TESTING_WRAM_DATA
	dc.l	auto_wram_address_tests_dsub, STR_TESTING_WRAM_ADDRESS
AUTOMATIC_PSUB_TEST_STRUCT_END:


; runs automatic tests that are subroutine based;
automatic_function_tests:
	lea	AUTOMATIC_FUNC_TEST_STRUCT_START, a5
	moveq	#((AUTOMATIC_FUNC_TEST_STRUCT_END - AUTOMATIC_FUNC_TEST_STRUCT_START)/8 - 1), d6

.loop_next_test:
	movea.l	(a5)+, a4			; test function address
	movea.l	(a5)+, a0			; test name string address
	movea.l	a0, a0
	moveq	#4, d0
	moveq	#5, d1
	RSUB	print_xy_string_clear		; at 4,5 print test name

	move.l	a5, -(a7)
	move.w	d6, -(a7)
	jsr	(a4)				; run function
	move.w	(a7)+, d6
	movea.l	(a7)+, a5

	tst.b	d0				; check result
	beq	.test_passed

	move.w	d0, -(a7)
	RSUB	print_error
	move.w	(a7)+, d0

	tst.b	z80_test_flags			; if z80 test enabled, send error code to z80
	beq	.skip_error_to_z80
	move.b	d0, REG_SOUND

.skip_error_to_z80:
	tst.b	REG_STATUS_B
	bpl	.skip_error_to_credit_leds	; skip if aes
	RSUB	error_to_credit_leds

.skip_error_to_credit_leds
	bra	loop_reset_check

.test_passed:
	dbra	d6, .loop_next_test
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

	lea	XY_STR_Z80_SWITCHING_M1, a0
	RSUB	print_xy_string_struct_clear

	move.b	#$01, REG_SOUND				; tell z80 to prep for m1 switch

	move.l	#$1388, d0				; 12500us / 12.5ms
	RSUB	delay

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
	lea	(XY_STR_Z80_SLOT_SWITCH_NUM), a0	; "[SS ]"
	RSUB	print_xy_string_struct

	move.b	#32, d0
	moveq	#4, d1
	moveq	#0, d2
	move.b	d3, d2
	RSUB	print_digit			; print the slot number

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
	lea	XY_STR_Z80_IGNORED_SM1, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_Z80_SM1_UNRESPONSIVE, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_Z80_MV1BC_HOLD_B, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_Z80_PRESS_START, a0
	RSUB	print_xy_string_struct_clear

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

	moveq	#27, d0
	SSA3	fix_clear_line
	moveq	#7, d0
	SSA3	fix_clear_line
	moveq	#10, d0
	SSA3	fix_clear_line
	moveq	#12, d0
	SSA3	fix_clear_line
	rts

; params:
;  d0 * 2.5us = how long to delay
delay_dsub:
	move.b	d0, REG_WATCHDOG	; 16 cycles
	subq.l	#1, d0			; 4 cycles
	bne	delay_dsub		; 10 cycles
	DSUB_RETURN

; see if the z80 sent us an error
z80_check_error:
	moveq	#-$40, d0
	and.b	REG_SOUND, d0
	cmp.b	#$40, d0		; 0x40 = flag indicating a z80 error code
	bne	.no_error

	move.b	REG_SOUND, d0		; get the error (again?)
	move.b	d0, d2
	move.l	#$100000, d1
	bsr	z80_ack_error		; ack the error by sending it back, and wait for z80 to ack our ack
	bne	loop_reset_check

	move.b	d2, d0
	and.b	#$3f, d0		; drop the error flag to get the actual error code

	; bypassing the normal print_error call here since the
	; z80 might have sent a corrupt error code which we
	; still want to print with print_error_z80
	move.w	d0, -(a7)
	DSUB	error_code_lookup
	bsr	print_error_z80
	move.w	(a7)+, d0

	tst.b	REG_STATUS_B
	bpl	.skip_error_to_credit_leds	; skip if aes
	RSUB	error_to_credit_leds

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

	lea	(XY_STR_Z80_SM1_TESTS), a0		; "[SM1]" to indicate m1 is running sm1 tests
	RSUB	print_xy_string_struct

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

XY_STR_Z80_ERROR_CODE:		XY_STRING 4, 12, "Z80 REPORTED ERROR CODE: "


; see if z80 says its done testing (with no issues)
z80_check_done:
	move.b	#COMM_Z80_TESTS_COMPLETE, d0
	cmp.b	REG_SOUND, d0
	rts

z80_comm_test:

	lea	XY_STR_Z80_M1_ENABLED, a0
	RSUB	print_xy_string_struct

	lea	XY_STR_Z80_TESTING_COMM_PORT, a0
	RSUB	print_xy_string_struct_clear

	move.b	#COMM_TEST_HELLO, d1
	move.w  #500, d2
	bra	.loop_start_wait_hello

; wait up to 5 seconds for hello (10ms * 500 loops)
.loop_wait_hello
	move.w	#4000, d0
	RSUB	delay
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
	RSUB	delay
.loop_start_wait_ack:
	cmp.b	REG_SOUND, d1
	dbeq	d2, .loop_wait_ack
	bne	.z80_ack_timeout
	rts

.z80_hello_timeout
	lea	XY_STR_Z80_COMM_NO_HELLO, a0
	bra	.print_comm_error

.z80_ack_timeout
	lea	XY_STR_Z80_COMM_NO_ACK, a0

.print_comm_error
	move.b	d1, d0
	bra	z80_print_comm_error



; loop forever checking for reset request;
loop_reset_check:
	bsr	print_hold_ss_to_reset
.loop_forever:
	WATCHDOG
	bsr	check_reset_request
	bra	.loop_forever


; loop forever checking for reset request
loop_reset_check_dsub:
	moveq	#4, d0
	moveq	#27, d1
	lea	STR_HOLD_SS_TO_RESET, a0
	DSUB	print_xy_string_clear

.loop_ss_not_pressed:
	WATCHDOG
	moveq	#3, d0
	and.b	REG_STATUS_B, d0
	bne	.loop_ss_not_pressed		; loop until P1 start+select both held down

	moveq	#4, d0
	moveq	#27, d1
	lea	STR_RELEASE_SS, a0
	DSUB	print_xy_string_clear

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
	RSUB	print_xy_string_clear

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
	RSUB	print_xy_string_clear
	rts

; prints headers
; NEO DIAGNOSTICS v0.19aXX - BY SMKDAN
; ---------------------------------
print_header_dsub:
	moveq	#0, d0
	moveq	#4, d1
	moveq	#1, d2
	moveq	#$16, d3
	moveq	#40, d4
	DSUB	print_char_repeat			; $116 which is an overscore line

	moveq	#2, d0
	moveq	#3, d1
	lea	STR_VERSION_HEADER, a0
	DSUB	print_xy_string_clear
	DSUB_RETURN

; prints the z80 related communication error
; params:
;  d0 = expected response
;  a0 = xy_string_struct address for main error
z80_print_comm_error:
	move.w	d0, -(a7)

	RSUB	print_xy_string_struct_clear

	moveq	#4, d0
	moveq	#8, d1
	lea	STR_EXPECTED, a0
	RSUB	print_xy_string_clear

	moveq	#4, d0
	moveq	#10, d1
	lea	STR_ACTUAL, a0
	RSUB	print_xy_string_clear

	lea	XY_STR_Z80_SKIP_TEST, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_Z80_PRESS_D_RESET, a0
	RSUB	print_xy_string_struct_clear

	move.w	(a7)+, d2
	moveq	#14, d0
	moveq	#8, d1
	RSUB	print_hex_byte				; expected value

	move.b	REG_SOUND, d2
	moveq	#14, d0
	moveq	#10, d1
	RSUB	print_hex_byte				; actual value

	lea	XY_STR_Z80_MAKE_SURE, a0
	RSUB	print_xy_string_struct_clear

	lea	XY_STR_Z80_CART_CLEAN, a0
	RSUB	print_xy_string_struct_clear

	bsr	z80_check_error
	bra	loop_reset_check

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
.loop_print_error_start
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

	lea	STR_ADDRESS.l, a0
	moveq	#4, d0
	moveq	#8, d1
	DSUB	print_xy_string

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

	lea	STR_ADDRESS.l, a0
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


STR_INVALID_ERROR:	STRING "INVALID ERROR"
STR_ERROR_CODE:		STRING "ERROR CODE:"
STR_PRINT_FUNCTION:	STRING "PRINT FUNCTION: "


; print function for all error codes from z80
; params:
;  d0 = error code
;  a1 = error description
print_error_z80:
	move.b	d0, d2
	moveq	#29, d0
	moveq	#12, d1
	RSUB	print_hex_byte

	lea	XY_STR_Z80_ERROR_CODE.l, a0
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
error_to_credit_leds_dsub:
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
	DSUB	delay				; 40us

	move.b	d4, REG_LEDDATA

	move.b	#LED_P2_LATCH, REG_LEDLATCHES
	move.w	#$10, d0
	DSUB	delay

	move.b	#LED_NO_LATCH, REG_LEDLATCHES
	move.w	#$10, d0
	DSUB	delay

	; player 1 led
	lsr.w	#8, d4
	move.b	d4, REG_LEDDATA

	move.b	#LED_P1_LATCH, REG_LEDLATCHES
	move.w	#$10, d0
	DSUB	delay

	move.b	#LED_P1_LATCH, REG_LEDLATCHES

	DSUB_RETURN

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
	RSUB	delay
	move.w	(a7)+, d1
	rts

manual_tests:
.loop_forever:
	bsr	main_menu_draw
	bsr	main_menu_loop
	bra	.loop_forever


main_menu_draw:
	RSUB	print_header
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
	RSUB	print_xy_string
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
	RSUB	print_xy_char				; draw arrow

	move.b	main_menu_cursor, d1
	move.b	p1_input_edge, d0
	btst	#UP, d0					; see if p1 up pressed
	beq	.up_not_pressed

	subq.b	#1, d1
	bpl	.update_arrow
	moveq	#((MAIN_MENU_ITEMS_END - MAIN_MENU_ITEMS_START) / 10) - 1, d1
	bra	.update_arrow

.up_not_pressed:					; up wasnt pressed, see if down was
	btst	#DOWN, d0
	beq	.check_a_pressed			; down not pressed either, see if 'a' is pressed

	addq.b	#1, d1
	cmp.b	#((MAIN_MENU_ITEMS_END - MAIN_MENU_ITEMS_START) / 10), d1
	bne	.update_arrow
	moveq	#0, d1

.update_arrow:						; up or down was pressed, update the arrow location
	move.w	d1, -(a7)
	moveq	#4, d0
	moveq	#5, d1
	add.b	main_menu_cursor, d1
	move.b	(1,a7), main_menu_cursor
	moveq	#$20, d2
	RSUB	print_xy_char				; replace existing arrow with space

	moveq	#4, d0
	moveq	#5, d1
	add.w	(a7)+, d1
	moveq	#$11, d2
	RSUB	print_xy_char				; draw arrow at new location

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

	SSA3	fix_clear

	movea.l	(a1)+, a0
	moveq	#4, d0
	moveq	#5, d1
	RSUB	print_xy_string

	movea.l	(a1), a0
	jsr	(a0)					; call the test function
	SSA3	fix_clear
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
	MAIN_MENU_ITEM STR_MM_SMPTE_COLOR_BARS, manual_smpte_color_bars_test, 0
	MAIN_MENU_ITEM STR_MM_VIDEO_DAC_TEST, manual_video_dac_test, 0
	MAIN_MENU_ITEM STR_MM_CONTROLER_TEST, manual_controller_test, 0
	MAIN_MENU_ITEM STR_MM_WBRAM_TEST_LOOP, manual_wbram_test_loop, 0
	MAIN_MENU_ITEM STR_MM_PAL_RAM_TEST_LOOP, manual_palette_ram_test_loop, 0
	MAIN_MENU_ITEM STR_MM_VRAM_TEST_LOOP_32K, manual_vram_32k_test_loop, 0
	MAIN_MENU_ITEM STR_MM_VRAM_TEST_LOOP_2K, manual_vram_2k_test_loop, 0
	MAIN_MENU_ITEM STR_MM_MISC_INPUT_TEST, manual_misc_input_tests, 0
	MAIN_MENU_ITEM STR_MM_MEMCARD_TESTS, manual_memcard_tests, 0
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

; The bios code is only 32k ($8000).  3 copies/mirrors
; of it are used to fill the entire 128k of the bios rom.
; At offset $7ffb of each mirror is a byte that contains
; the mirror number.  The running bios is $00, first
; mirror is $01, 2nd mirror $02, and 3th mirror $03.
; This test checks each of these to verify they are correct.
; If they end up being wrong it will trigger the "BIOS ADDRESS (A14-A15)"
; error.
; on error:
;  d1 = actual value
;  d2 = expected value
auto_bios_mirror_test_dsub:
	lea	$bffffb, a0
	moveq	#3, d0
	moveq	#-1, d2
.loop_next_offset:
	addq.b	#1, d2
	adda.l	#$8000, a0
	move.b	(a0), d1
	cmp.b	d2, d1
	dbne	d0, .loop_next_offset
	bne	.test_failed

	moveq	#$0, d0
	DSUB_RETURN

.test_failed:
	moveq	#EC_BIOS_MIRROR, d0
	DSUB_RETURN

; verifies the bios crc is correct.  The expected crc32 value
; are the 4 bytes located at $7ffc ($c07ffc) of the bios.
; on error:
;  d1 = actual crc32
auto_bios_crc32_test_dsub:
	move.l	#$7ffb, d0			; length
	lea	$c00000.l, a0			; start address
	move.b	d0, REG_SWPROM			; use carts vector table?
	DSUB	calc_crc32

	move.b	d0, REG_SWPBIOS			; use bios vector table
	cmp.l	$c07ffc.l, d0
	beq	.test_passed

	move.l	d0, d1
	moveq	#EC_BIOS_CRC32, d0
	DSUB_RETURN

.test_passed:
	moveq	#0, d0
	DSUB_RETURN

; calculate the crc32 value
; params:
;  d0 = length
;  a0 = start address
; returns:
;  d0 = crc value
calc_crc32_dsub:
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
	DSUB_RETURN

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


auto_ram_oe_tests_dsub:
	lea	WORK_RAM_START.l, a0		; wram upper
	moveq	#0, d0
	DSUB	check_ram_oe
	tst.b	d0
	bne	.test_failed_wram_upper

	moveq	#1, d0				; wram lower
	DSUB	check_ram_oe
	tst.b	d0
	bne	.test_failed_wram_lower

	tst.b	REG_STATUS_B			; skip bram test on AES unless C is pressed
	bmi	.do_bram_test
	btst	#6, REG_P1CNT
	bne	.test_passed

.do_bram_test:
	lea	BACKUP_RAM_START.l, a0		; bram upper
	moveq	#0, d0
	DSUB	check_ram_oe
	tst.b	d0
	bne	.test_failed_bram_upper

	moveq	#1, d0				; bram lower
	DSUB	check_ram_oe
	tst.b	d0
	bne	.test_failed_bram_lower

.test_passed:
	moveq	#0, d0
	DSUB_RETURN

.test_failed_wram_upper:
	moveq	#EC_WRAM_DEAD_OUTPUT_UPPER, d0
	DSUB_RETURN
.test_failed_wram_lower:
	moveq	#EC_WRAM_DEAD_OUTPUT_LOWER, d0
	DSUB_RETURN
.test_failed_bram_upper:
	moveq	#EC_BRAM_DEAD_OUTPUT_UPPER, d0
	DSUB_RETURN
.test_failed_bram_lower:
	moveq	#EC_BRAM_DEAD_OUTPUT_LOWER, d0
	DSUB_RETURN

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
check_ram_oe_dsub:
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
	DSUB_RETURN

auto_bram_tests:
	tst.b	REG_STATUS_B			; do test if MVS
	bmi	.do_bram_tests
	btst	#$6, REG_P1CNT			; do test if AES and C pressed
	beq	.do_bram_tests
	moveq	#0, d0
	rts

.do_bram_tests:
	move.b	d0, REG_SRAMUNLOCK		; unlock bram
	RSUB	bram_data_tests
	tst.b	d0
	bne	.test_failed
	RSUB	bram_address_tests

.test_failed:
	move.b	d0, REG_SRAMLOCK		; lock bram
	rts

auto_palette_ram_tests:
	lea	PALETTE_RAM_START.l, a0
	lea	PALETTE_RAM_BACKUP_LOCATION.l, a1
	move.w	#$2000, d0
	bsr	copy_memory			; backup palette ram, unclean why palette_ram_backup function wasnt used

	bsr	palette_ram_output_tests
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
	RSUB	check_ram_we
	tst.b	d0
	beq	.test_passed_lower
	moveq	#EC_PAL_UNWRITABLE_LOWER, d0
	rts

.test_passed_lower:
	lea	PALETTE_RAM_START.l, a0
	move.w	#$ff00, d0
	RSUB	check_ram_we
	tst.b	d0
	beq	.test_passed_upper
	moveq	#EC_PAL_UNWRITABLE_UPPER, d0
	rts

.test_passed_upper:
	moveq	#0, d0
	rts

auto_ram_we_tests_dsub:
	lea	WORK_RAM_START.l, a0
	move.w	#$ff, d0
	DSUB	check_ram_we
	tst.b	d0
	beq	.test_passed_wram_lower
	moveq	#EC_WRAM_UNWRITABLE_LOWER, d0
	DSUB_RETURN

.test_passed_wram_lower:
	lea	WORK_RAM_START.l, a0
	move.w	#$ff00, d0
	DSUB	check_ram_we
	tst.b	d0
	beq	.test_passed_wram_upper
	moveq	#EC_WRAM_UNWRITABLE_UPPER, d0
	DSUB_RETURN

.test_passed_wram_upper:
	tst.b	REG_STATUS_B
	bmi	.do_bram_test				; if MVS jump to bram test
	btst	#6, REG_P1CNT				; dead code? checking if C is pressed, then nop
	nop						; maybe nop should be 'bne .do_bram_test' to allow forced bram test on aes?
	moveq	#0, d0
	DSUB_RETURN

.do_bram_test:
	move.b	d0, REG_SRAMUNLOCK			; unlock bram

	lea	BACKUP_RAM_START.l, a0
	move.w	#$ff, d0
	DSUB	check_ram_we
	tst.b	d0
	beq	.test_passed_bram_lower

	moveq	#EC_BRAM_UNWRITABLE_LOWER, d0
	DSUB_RETURN

.test_passed_bram_lower:
	lea	BACKUP_RAM_START.l, a0
	move.w	#$ff00, d0
	DSUB	check_ram_we
	tst.b	d0
	beq	.test_passed_bram_upper

	moveq	#EC_BRAM_UNWRITABLE_UPPER, d0
	DSUB_RETURN

.test_passed_bram_upper:
	move.b	d0, REG_SRAMLOCK			; lock bram
	moveq	#0, d0
	DSUB_RETURN

; params:
;  a0 = address
;  d0 = bitmask
check_ram_we_dsub:
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
	DSUB_RETURN

.test_failed:
	moveq	#-1, d0
	DSUB_RETURN

MEMORY_DATA_TEST_PATTERNS:
	dc.w	$0000, $5555, $aaaa, $ffff
MEMORY_DATA_TEST_PATTERNS_END:


auto_wram_data_tests_dsub:
	lea	MEMORY_DATA_TEST_PATTERNS, a1
	moveq	#((MEMORY_DATA_TEST_PATTERNS_END - MEMORY_DATA_TEST_PATTERNS)/2 - 1), d3

.loop_next_pattern:
	lea	WORK_RAM_START, a0
	move.w	#$8000, d1
	move.w	(a1)+, d0
	DSUB	check_ram_data
	tst.b	d0
	bne	.test_failed
	dbra	d3, .loop_next_pattern
	DSUB_RETURN

.test_failed:
	subq.b	#1, d0
	add.b	#EC_WRAM_DATA_LOWER, d0
	DSUB_RETURN


bram_data_tests_dsub:
	lea	MEMORY_DATA_TEST_PATTERNS, a1
	moveq	#((MEMORY_DATA_TEST_PATTERNS_END - MEMORY_DATA_TEST_PATTERNS)/2 - 1), d3

.loop_next_pattern:
	lea	BACKUP_RAM_START, a0
	move.w	#$8000, d1
	move.w	(a1)+, d0
	DSUB	check_ram_data
	tst.b	d0
	bne	.test_failed
	dbra	d3, .loop_next_pattern
	DSUB_RETURN

.test_failed:
	subq.b	#1, d0
	add.b	#EC_BRAM_DATA_LOWER, d0
	DSUB_RETURN


palette_ram_data_tests:
	lea	MEMORY_DATA_TEST_PATTERNS, a1
	moveq	#((MEMORY_DATA_TEST_PATTERNS_END - MEMORY_DATA_TEST_PATTERNS)/2 - 1), d3

.loop_next_pattern_bank0:
	lea	PALETTE_RAM_START, a0
	move.w	#$1000, d1
	move.w	(a1)+, d0
	DSUB	check_ram_data
	tst.b	d0
	bne	.test_failed_bank0
	dbra	d3, .loop_next_pattern_bank0
	bra	.test_passed_bank0

.test_passed_bank0:
	lea	MEMORY_DATA_TEST_PATTERNS, a1
	moveq	#((MEMORY_DATA_TEST_PATTERNS_END - MEMORY_DATA_TEST_PATTERNS)/2 - 1), d3

.loop_next_pattern_bank1:
	lea	PALETTE_RAM_START, a0
	move.w	#$1000, d1
	move.w	(a1)+, d0
	DSUB	check_ram_data
	tst.b	d0
	bne	.test_failed_bank1
	dbra	d3, .loop_next_pattern_bank1

	move.b	d0, REG_PALBANK0
	moveq	#0, d0
	rts

.test_failed_bank0:
	subq.b	#1, d0
	add.b	#EC_PAL_BANK0_DATA_LOWER, d0
	rts

.test_failed_bank1:
	subq.b	#1, d0
	add.b	#EC_PAL_BANK1_DATA_LOWER, d0
	rts

; Does a full write/read test
; params:
;  a0 = start address
;  d0 = value
;  d1 = length
; returns:
;  d0 = 0 (pass), 1 (lower bad), 2 (upper bad), 3 (both bad)
;  a0 = failed address
;  d1 = wrote value
;  d2 = read (bad) value
check_ram_data_dsub:
	subq.w	#1, d1

.loop_next_address:
	move.w	d0, (a0)
	move.w	(a0)+, d2
	cmp.w	d0, d2
	dbne	d1, .loop_next_address
	bne	.test_failed

	WATCHDOG
	moveq	#0, d0
	DSUB_RETURN

.test_failed:
	subq.l	#2, a0
	move.w	d0, d1
	WATCHDOG

	; set error code based on which byte(s) were bad
	moveq	#0, d0

	cmp.b	d1, d2
	beq	.check_upper
	or.b	#1, d0

.check_upper:
	ror.l	#8, d1
	ror.l	#8, d2
	cmp.b	d1, d2
	beq	.check_done
	or.b	#2, d0

.check_done:
	rol.l	#8, d1
	rol.l	#8, d2
	DSUB_RETURN


auto_wram_address_tests_dsub:
	lea	WORK_RAM_START.l, a0
	moveq	#2, d0
	move.w	#$100, d1
	DSUB	check_ram_address
	tst.b	d0
	beq	.test_passed_a0_a7
	moveq	#EC_WRAM_ADDRESS_A0_A7, d0
	DSUB_RETURN

.test_passed_a0_a7:
	lea	WORK_RAM_START.l, a0
	move.w	#$200, d0
	move.w	#$80, d1
	DSUB	check_ram_address
	tst.b	d0
	beq	.test_passed_a8_a14
	moveq	#EC_WRAM_ADDRESS_A8_A14, d0
	DSUB_RETURN

.test_passed_a8_a14:
	moveq	#0, d0
	DSUB_RETURN

bram_address_tests_dsub:
	lea	BACKUP_RAM_START.l, a0
	moveq	#$2, d0
	move.w	#$100, d1
	DSUB	check_ram_address

	tst.b	d0
	beq	.test_passed_a0_a7
	moveq	#EC_BRAM_ADDRESS_A0_A7, d0
	DSUB_RETURN

.test_passed_a0_a7:
	lea	BACKUP_RAM_START.l, a0
	move.w	#$200, d0
	move.w	#$80, d1
	DSUB	check_ram_address

	tst.b	d0
	beq	.test_passed_a8_a14
	moveq	#EC_BRAM_ADDRESS_A8_A14, d0
	DSUB_RETURN

.test_passed_a8_a14:
	moveq	#0, d0
	DSUB_RETURN

; params:
;  a0 = address start
;  d0 = increment
;  d1 = iterations
; returns:
; d0 = 0 (pass), $ff (fail)
; d1 = expected value
; d2 = actual value
check_ram_address_dsub:
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
	DSUB_RETURN

.test_failed:
	move.w	d3, d1
	WATCHDOG
	moveq	#-1, d0
	DSUB_RETURN


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

; Depending on motherboard model there will either be 2x245s or a NEO-G0
; sitting between the palette memory and the 68k data bus.
; The first 2 tests are checking for output from the IC's, while the last 2
; tests are checking for output on the palette memory chips
palette_ram_output_tests:
	moveq	#1, d0
	lea	PALETTE_RAM_START, a0
	RSUB	check_ram_oe
	tst.b	d0
	beq	.test_passed_memory_output_lower
	moveq	#EC_PAL_245_DEAD_OUTPUT_LOWER, d0
	rts

.test_passed_memory_output_lower:
	moveq	#0, d0
	lea	PALETTE_RAM_START, a0
	RSUB	check_ram_oe
	tst.b	d0
	beq	.test_passed_memory_output_upper
	moveq	#EC_PAL_245_DEAD_OUTPUT_UPPER, d0
	rts

.test_passed_memory_output_upper:
	move.w	#$ff, d0
	bsr	check_palette_ram_to_245_output
	beq	.test_passed_palette_ram_to_245_output_lower
	moveq	#EC_PAL_DEAD_OUTPUT_LOWER, d0
	rts

.test_passed_palette_ram_to_245_output_lower:
	move.w	#$ff00, d0
	bsr	check_palette_ram_to_245_output
	beq	.test_passed_palette_ram_to_245_output_upper
	moveq	#EC_PAL_DEAD_OUTPUT_UPPER, d0
	rts

.test_passed_palette_ram_to_245_output_upper:
	moveq	#0, d0
	rts

; palette ram and have 2x245s or a NEO-G0 between
; them and the 68k data bus.  This function attempts
; to check for dead output between the memory chip and
; the 245s/NEO-G0.
;
; params
;  d0 = compare mask
; return
;  d0 = 0 is passed, -1 = failed
check_palette_ram_to_245_output:
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

	; note this is comparing the mask with the read data,
	; dead output from the chip will cause $ff
	cmp.w	d0, d1
	dbne	d2, .loop_next_address

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

	lea	MEMORY_DATA_TEST_PATTERNS, a1
	moveq	#((MEMORY_DATA_TEST_PATTERNS_END - MEMORY_DATA_TEST_PATTERNS)/2 - 1), d5

.loop_next_pattern:
	move.w	(a1)+, d0
	moveq	#0, d1
	move.w	#$8000, d2
	bsr	check_vram_data
	tst.b	d0
	bne	.test_failed
	dbra	d5, .loop_next_pattern
	rts

.test_failed:
	subq.b	#1, d0
	add.b	#EC_VRAM_32K_DATA_LOWER, d0
	rts

; 2k (words) vram tests (data and address) only look at the
; first 1536 (0x600) words, since the remaining 512 words
; are used by the LSPC for buffers per dev wiki
vram_2k_data_tests:

	lea	MEMORY_DATA_TEST_PATTERNS, a1
	moveq	#((MEMORY_DATA_TEST_PATTERNS_END - MEMORY_DATA_TEST_PATTERNS)/2 - 1), d5

.loop_next_pattern:
	move.w	(a1)+, d0
	move.w	#$8000, d1
	move.w	#$600, d2
	bsr	check_vram_data
	tst.b	d0
	bne	.test_failed
	dbra	d5, .loop_next_pattern
	rts

.test_failed:
	subq.b	#1, d0
	add.b	#EC_VRAM_2K_DATA_LOWER, d0
	rts

; params:
;  d0 = pattern
;  d1 = vram start address
;  d2 = length in words
; returns:
;  d0 = 0 (pass), 1 (lower bad), 2 (upper bad), 3 (both bad)
;  a0 = fail address
;  d1 = expected value
;  d2 = actual value
check_vram_data:
	move.w	#1, (2,a6)
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

	; set error code based on which byte(s) were bad
	moveq	#0, d0

	cmp.b	d1, d2
	beq	.check_upper
	or.b	#1, d0

.check_upper:
	ror.l	#8, d1
	ror.l	#8, d2
	cmp.b	d1, d2
	beq	.check_done
	or.b	#2, d0

.check_done:
	rol.l	#8, d1
	rol.l	#8, d2
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
	moveq	#EC_VRAM_32K_ADDRESS_A0_A7, d0
	rts

.test_passed_a0_a7:
	clr.w	d1
	move.w	#$80, d2
	move.w	#$100, d0
	bsr	check_vram_address
	beq	.test_passed_a8_a14
	moveq	#EC_VRAM_32K_ADDRESS_A8_A14, d0
	rts

.test_passed_a8_a14:
	rts


vram_2k_address_tests:
	move.w	#$8000, d1
	move.w	#$100, d2
	moveq	#1, d0
	bsr	check_vram_address
	beq	.test_passed_a0_a7
	moveq	#EC_VRAM_2K_ADDRESS_A0_A7, d0
	rts

.test_passed_a0_a7:
	move.w	#$8000, d1
	move.w	#$6, d2
	move.w	#$100, d0
	bsr	check_vram_address
	beq	.test_passed_a8_a14
	moveq	#EC_VRAM_2K_ADDRESS_A8_A10, d0
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
	moveq	#((MMIO_ADDRESSES_TABLE_END - MMIO_ADDRESSES_TABLE_START)/4 - 1), d6

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
	dbra	d6, .loop_next_test

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
	lea	XY_STR_CAL_A_1HZ_PULSE, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_CAL_B_64HZ_PULSE, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_CAL_C_4096HZ_PULSE, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_CAL_D_MAIN_MENU, a0
	RSUB	print_xy_string_struct_clear

	moveq	#$4, d0
	moveq	#$11, d1
	lea	STR_ACTUAL, a0
	RSUB	print_xy_string_clear

	moveq	#$4, d0
	moveq	#$13, d1
	lea	STR_EXPECTED, a0
	RSUB	print_xy_string_clear

	lea	XY_STR_CAL_4990_TP, a0
	RSUB	print_xy_string_struct_clear

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
	lea	XY_STR_CAL_WAITING_PULSE, a0
	RSUB	print_xy_string_struct_clear

	bsr	rtc_wait_pulse

	moveq	#$1b, d0
	SSA3	fix_clear_line		; removes waiting for calendar pulse... line

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
	RSUB	print_hex_word

	moveq	#$e, d0
	moveq	#$13, d1
	move.w	timer_count, d2
	RSUB	print_hex_word

	moveq	#$e, d0
	moveq	#$15, d1
	SSA3	fix_seek_xy

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
	lea	XY_STR_CT_D_MAIN_MENU, a0
	RSUB	print_xy_string_struct_clear
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
	SSA3	fix_seek_xy			; d0 on return will have current vram address
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


manual_smpte_color_bars_test:
	bsr	smpte_color_bar_setup_palettes
	bsr	smpte_color_bar_draw_sections

.loop_run_test
	WATCHDOG
	bsr	p1p2_input_update
	btst	#D_BUTTON, p1_input_edge	; D pressed?
	beq	.loop_run_test
	rts

SMPTE_COLORS:
	dc.w	SMPTE_BLACK
	dc.w	SMPTE_BLACK8
	dc.w	SMPTE_BLACK16
	dc.w	SMPTE_BLACK24
	dc.w	SMPTE_BLUE
	dc.w	SMPTE_CYAN
	dc.w	SMPTE_DARK_BLUE
	dc.w	SMPTE_GRAY
	dc.w	SMPTE_GREEN
	dc.w	SMPTE_MAGENTA
	dc.w	SMPTE_PURPLE
	dc.w	SMPTE_RED
	dc.w	SMPTE_WHITE
	dc.w	SMPTE_YELLOW
SMPTE_COLORS_END:

; We will be using tile #$00 for writing the smpte bars, which is a solid
; color using color index 1.  Setup palettes 3 to 15 with the 13 needed
; colors
smpte_color_bar_setup_palettes:
	moveq	#((SMPTE_COLORS_END - SMPTE_COLORS) / 2 - 1), d2
	lea	SMPTE_COLORS, a0
	lea	PALETTE_RAM_START+PALETTE_SIZE+PALETTE_SIZE+2, a1

.loop_next_color
	move.w	(a0)+, d0
	move.w	d0, (a1)
	adda.l	#PALETTE_SIZE, a1
	dbra	d2, .loop_next_color
	rts


; struct {
;	byte palette;
;	byte width;
; } smpte_color[]
SMPTE_TOP_SECTION:
	dc.b	SMPTE_PAL_BLACK, 2
	dc.b	SMPTE_PAL_GRAY, 5
	dc.b	SMPTE_PAL_YELLOW, 5
	dc.b	SMPTE_PAL_CYAN, 5
	dc.b	SMPTE_PAL_GREEN, 5
	dc.b	SMPTE_PAL_MAGENTA, 5
	dc.b	SMPTE_PAL_RED, 6
	dc.b	SMPTE_PAL_BLUE, 5
SMPTE_TOP_SECTION_END:

SMPTE_MIDDLE_SECTION:
	dc.b	SMPTE_PAL_BLACK, 2
	dc.b	SMPTE_PAL_BLUE, 5
	dc.b	SMPTE_PAL_BLACK16, 5
	dc.b	SMPTE_PAL_MAGENTA, 5
	dc.b	SMPTE_PAL_BLACK16, 5
	dc.b	SMPTE_PAL_CYAN, 5
	dc.b	SMPTE_PAL_BLACK16, 6
	dc.b	SMPTE_PAL_GRAY, 5
SMPTE_MIDDLE_SECTION_END:

SMPTE_BOTTOM_SECTION:
	dc.b	SMPTE_PAL_BLACK, 2
	dc.b	SMPTE_PAL_DARK_BLUE, 6
	dc.b	SMPTE_PAL_WHITE, 6
	dc.b	SMPTE_PAL_PURPLE, 6
	dc.b	SMPTE_PAL_BLACK16, 7
	dc.b	SMPTE_PAL_BLACK8, 2
	dc.b	SMPTE_PAL_BLACK16, 2
	dc.b	SMPTE_PAL_BLACK24, 2
	dc.b	SMPTE_PAL_BLACK16, 5
SMPTE_BOTTOM_SECTION_END:

smpte_color_bar_draw_sections:

	move.w	#FIXMAP + 2, d1		; start 2nd row down
	move.w	#$20, (2,a6)		; draw tiles left to right

	lea	SMPTE_TOP_SECTION, a0
	moveq	#((SMPTE_TOP_SECTION_END - SMPTE_TOP_SECTION) / 2), d0
	moveq	#$14, d2
	bsr	smpte_color_bar_draw_section

	lea	SMPTE_MIDDLE_SECTION, a0
	moveq	#((SMPTE_MIDDLE_SECTION_END - SMPTE_MIDDLE_SECTION) / 2), d0
	moveq	#$2, d2
	bsr	smpte_color_bar_draw_section

	lea	SMPTE_BOTTOM_SECTION, a0
	moveq	#((SMPTE_BOTTOM_SECTION_END - SMPTE_BOTTOM_SECTION) / 2), d0
	moveq	#$7, d2
	bsr	smpte_color_bar_draw_section
	rts

; a0 = address of smpte_color struct array
; d0 = number of items in the array
; d1 = fix address
; d2 = height of the section
smpte_color_bar_draw_section:
	subq	#$1, d0
	subq	#$1, d2
	moveq	#$0, d3
	moveq	#$c, d6

.loop_next_row:
	move.w	d1, (-2,a6)
	moveq	#$0, d3
	move.b	d0, d3
	movea.l	a0, a1

.loop_next_color:
	moveq	#$0, d4
	move.b	(a1)+, d5		; palette
	move.b	(a1)+, d4		; width
	subq	#$1, d4
	lsl.w	d6, d5			; using tile #$00, so just shift pal over

.loop_next_char:
	move.w	d5, (a6)
	dbra	d4, .loop_next_char
	dbra	d3, .loop_next_color

	addq	#$1, d1
	dbra	d2, .loop_next_row
	rts

; main vdac screen
; A button = enter full screen mode
; B button = toggle darker bit
; C button = toggle shadow register
; D button = return to main menu
manual_video_dac_test:

	moveq	#0, d6			; will use d6 to track shadow toggle
	move.b	d0, REG_NOSHADOW

	bsr	video_dac_setup_palettes
	bsr	video_dac_draw_screen

.loop_run_test
	WATCHDOG
	bsr	p1p2_input_update
	bsr	wait_frame

.right_not_pressed:
	btst	#A_BUTTON, p1_input_edge
	beq	.a_not_pressed
	bsr	video_dac_draw_fullscreen

	bra	manual_video_dac_test		; jump to the top so we clear shadow/darker bit

.a_not_pressed:
	btst	#B_BUTTON, p1_input_edge
	beq	.b_not_pressed
	bsr	video_dac_toggle_darker_bit

.b_not_pressed:

	btst	#C_BUTTON, p1_input_edge
	beq	.c_not_pressed
	bsr	video_dac_toggle_reg_shadow

.c_not_pressed:
	btst	#D_BUTTON, p1_input_edge	; D pressed?
	beq	.loop_run_test

	; we dont need to worry about cleaning up palettes, but
	; we should make sure show is off.
	move.b	d0, REG_NOSHADOW
	rts

VDAC_FS_TILE_OFFSETS:
	dc.w	$0000, $0020, $6000, $6020

VDAC_FS_TILE_BASE_PAL_MIN	equ $4000
VDAC_FS_TILE_BASE_PAL_MAX 	equ $9000

; fill the entire screen with the single tile
; Left/Right = cycle through color bits / all
; UP/Down = cycle through red/green/blue/combined
; B button = toggle darker bit
; C button = toggle shadow register
; D button = return to main vdac screen
video_dac_draw_fullscreen:

	; clear shadow/darker bit that might have been enabled on main screen
	moveq	#0, d6
	move.b	d0, REG_NOSHADOW
	bsr	video_dac_setup_palettes

	move.w	#VDAC_FS_TILE_BASE_PAL_MIN, d0
	SSA3	fix_fill				; fills the screen red/color bit 0

	move.w	#VDAC_FS_TILE_BASE_PAL_MIN, d3		; start tile base pal
	lea	VDAC_FS_TILE_OFFSETS, a0
	moveq	#0, d4					; tile offset in array

.loop_input:
	WATCHDOG
	bsr	p1p2_input_update
	bsr	wait_frame

	btst	#UP, p1_input_edge
	beq	.up_not_pressed

	subq.b	#2, d4
	bpl	.redraw_fullscreen
	moveq	#6, d4
	bra	.redraw_fullscreen

.up_not_pressed:
	btst	#DOWN, p1_input_edge
	beq	.down_not_pressed

	addq.b	#2, d4
	cmp.b	#8, d4
	bne	.redraw_fullscreen
	moveq	#0, d4
	bra	.redraw_fullscreen

.down_not_pressed:
	btst	#RIGHT, p1_input_edge
	beq	.right_not_pressed

	add.w	#$1000, d3
	cmp.w	#VDAC_FS_TILE_BASE_PAL_MAX + $1000, d3
	bmi	.redraw_fullscreen
	move.w	#VDAC_FS_TILE_BASE_PAL_MIN, d3
	bra	.redraw_fullscreen

.right_not_pressed:
	btst	#LEFT, p1_input_edge
	beq	.left_not_pressed

	sub.w	#$1000, d3
	cmp.w	#VDAC_FS_TILE_BASE_PAL_MIN, d3
	bpl	.redraw_fullscreen
	move.w	#VDAC_FS_TILE_BASE_PAL_MAX, d3

.redraw_fullscreen:
	moveq	#0, d0
	move.w	(a0,d4), d0
	add.w	d3, d0			; tile base pal + tile offset = what to fill with
	SSA3	fix_fill

.left_not_pressed:
	btst	#B_BUTTON, p1_input_edge
	beq	.b_not_pressed
	movem.l d0-d1/a0, -(a7)
	bsr	video_dac_toggle_darker_bit
	movem.l (a7)+, d0-d1/a0

.b_not_pressed:
	btst	#C_BUTTON, p1_input_edge
	beq	.c_not_pressed
	bsr	video_dac_toggle_reg_shadow

.c_not_pressed
	btst	#D_BUTTON, p1_input_edge
	beq	.loop_input

	rts

; enabling/disabling this bit in the palette doesn't make
; any visual difference on screen, but you can hear it on the
; 8.2k resistors on the dac
video_dac_toggle_darker_bit:

	lea	PALETTE_RAM_START+(PALETTE_SIZE*5)+$2, a0
	moveq	#9, d0

.loop_next_pallete:
	move.l	(a0), d1
	eor.l	#$80008000, d1
	move.l	d1, (a0)
	adda.l	#PALETTE_SIZE, a0
	dbra	d0, .loop_next_pallete
	rts

; when shadow is enabled it should cause the 150ohm resister on
; the active color(s) to be low 100% of the time.  When shadow is
; disabled the resister will have a bit of a pulse to it on the active
; color(s)
video_dac_toggle_reg_shadow:

	eor.b	#1, d6
	beq	.disable_reg_shadow

	move.b	d0, REG_SHADOW
	rts

.disable_reg_shadow
	move.b	d0, REG_NOSHADOW
	rts

; palettes  5 to  9 are used by red  and green
; palettes 10 to 14 are used by blue and combined
video_dac_setup_palettes:

	lea	PALETTE_RAM_START+(PALETTE_SIZE*4)+$2, a0	; goto palette5 color1
	move.l	#$40002000, d0					; lsb redgreen
	move.l	#$01000010, d1					; red/green
	move.l	#$4f0020f0, d2					; full red/green
	bsr	video_dac_setup_palette_group

	lea     PALETTE_RAM_START+(PALETTE_SIZE*10)+$2, a0	; goto palette10 color1
	move.l	#$10007000, d0					; lsb blue/combined
	move.l	#$00010111, d1					; blue/combined
	move.l	#$100f7fff, d2					; full blue/white
	bsr	video_dac_setup_palette_group

	rts

; setup an individual palette group
; a0 = palette start address
; d0 = lsb color
; d1 = start normal color
; d2 = all bits
video_dac_setup_palette_group:
	; lsb bits
	move.l	d0, (a0)
	adda.l	#PALETTE_SIZE, a0

	moveq	#3, d0						; 4 rol palettes


.loop_next_palette
	move.l	d1, (a0)
	rol.l	#1, d1
	adda.l	#PALETTE_SIZE, a0				; next palette/color1
	dbra	d0, .loop_next_palette

	move.l	d2, (a0)					; all bits
	rts


; draw the main screen
video_dac_draw_screen:
	SSA3	fix_clear

	lea	STR_MM_VIDEO_DAC_TEST, a0
	moveq	#13, d0
	moveq	#3, d1
	RSUB	print_xy_string

	lea	XY_STR_VDAC_A_FULL_SCREEN, a0
	RSUB	print_xy_string_struct_clear

	lea	XY_STR_VDAC_B_TOGGLE_DB, a0
	RSUB	print_xy_string_struct_clear

	lea	XY_STR_VDAC_C_TOGGLE_SHADOW, a0
	RSUB	print_xy_string_struct_clear

	lea	XY_STR_VDAC_D_MAIN_MENU, a0
	RSUB	print_xy_string_struct_clear

	lea	XY_STR_VDAC_ALL, a0
	RSUB	print_xy_string_struct_clear

	; print the B0 B1 ... B4 header (backwards)
	moveq	#4, d5		; bits to print
	moveq	#26, d4		; start X offset
.loop_next_print_header_bit:

	move.b	d4, d0
	moveq	#6, d1
	SSA3	fix_seek_xy

	moveq	#0, d1
	move.l	d5, d2
	RSUB	print_digits

	move.w	#'B', (a6)
	sub.b	#4, d4
	dbra	d5, .loop_next_print_header_bit

	; draw the red/green rows
	moveq	#8, d0
	moveq	#7, d1
	SSA3	fix_seek_xy

	move.w	#$4000, d1
	bsr	video_dac_draw_color_pair

	; draw the blue/combined rows
	moveq	#8, d0
	moveq	#15, d1
	SSA3	fix_seek_xy

	move.w	#$a000, d1
	bsr	video_dac_draw_color_pair

	rts

; d0 = column start
; d1 = start palette
video_dac_draw_color_pair:
	move.w	#1, (2,a6)

	move.w	d1, d4			; 0x00 tile
	move.w	d1, d5			; 0x20 tile
	add.w	#$20, d5

	moveq	#5, d2			; total number of color bits

.loop_next_color_bit:

	moveq	#3, d3			; width of each color

.loop_color_bit_width:

	; tile 0x00 (color1)
	move.w	d4, (a6)
	nop
	move.w	d4, (a6)
	nop
	move.w	d4, (a6)
	nop
	move.w	#$20, (a6)
	nop

	; tile 0x20 (color2)
	move.w	d5, (a6)
	nop
	move.w	d5, (a6)
	nop
	move.w	d5, (a6)
	nop
	move.w	#$20, (a6)

	add.w	#$20, d0
	move.w	d0, (-2,a6)			; move over a column
	dbra	d3, .loop_color_bit_width

	add.w	#$1000, d4			; next palette
	add.w	#$1000, d5

	dbra	d2, .loop_next_color_bit
	rts


manual_controller_test:
	moveq	#$5, d0
	SSA3	fix_clear_line
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
	lea	XY_STR_CT_P1, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_CT_P2, a0
	RSUB	print_xy_string_struct_clear
	moveq	#$7, d3
	moveq	#$25, d4
.loop_next_header:
	move.b	d4, d0
	moveq	#$3, d1
	move.b	d3, d2
	RSUB	print_hex_nibble
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
	RSUB	print_xy_string
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
	moveq	#$0, d6

.loop_next_sample:
	move.b	d6, d0
	bsr	send_p1p2_controller
	bsr	p1p2_input_update

	clr.w	d0
	move.b	p1_input, d0
	move.b	p1_input_aux, d1
	lsl.w	#8, d1
	or.w	d1, d0			; merge input/input_aux into d0
	move.b	d3, d1
	moveq	#$4, d2
	movem.w	d3/d6, -(a7)
	bsr	controller_print_player_data
	movem.w	(a7)+, d3/d6

	clr.w	d0
	move.b	p2_input, d0
	move.b	p2_input_aux, d1
	lsl.w	#8, d1
	or.w	d1, d0
	move.b	d3, d1
	moveq	#$11, d2
	movem.w	d3/d6, -(a7)
	bsr	controller_print_player_data
	movem.w	(a7)+, d3/d6
	addq.b	#4, d3
	addq.b	#1, d6
	cmp.b	#$8, d6
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
	moveq	#$9, d3

.loop_next_bit:
	move.b	d5, d0
	move.b	d6, d1
	move.w	d4, d2
	RSUB	print_bit
	lsr.w	#1, d4
	addq.b	#1, d6
	dbra	d3, .loop_next_bit

	move.b	d5, d0
	move.b	d6, d1
	move.w	(a7), d2
	RSUB	print_hex_byte

	move.b	d5, d0
	move.b	d6, d1
	addq.b	#1, d1
	move.w	(a7)+, d2
	and.w	#$ff, d2
	RSUB	print_3_digits
	rts

manual_wbram_test_loop:
	lea	XY_STR_WBRAM_PASSES,a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_WBRAM_HOLD_ABCD, a0
	RSUB	print_xy_string_struct_clear

	moveq	#$0, d6
	tst.b	REG_STATUS_B
	bmi	.system_mvs
	bset	#$1f, d6
	lea	XY_STR_WBRAM_WRAM_AES_ONLY, a0
	RSUB	print_xy_string_struct_clear

.system_mvs:
	moveq	#DSUB_INIT_PSEUDO, d7		; init dsub for pseudo subroutines
	bra	.loop_start_run_test

.loop_run_test:
	WATCHDOG
	PSUB	auto_wram_data_tests
	tst.b	d0
	bne	.test_failed_abort

	PSUB	auto_wram_address_tests
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

	SSA3	fix_clear

	; re-init stuff and return to menu
	move.b	#4, main_menu_cursor
	movea.l	$0, a7				; re-init SP
	moveq	#DSUB_INIT_REAL, d7		; init dsub for real subroutines
	bra	manual_tests

.test_failed_abort:
	PSUB	print_error
	bra	loop_reset_check_dsub



manual_palette_ram_test_loop:
	lea	XY_STR_PAL_PASSES, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_PAL_A_TO_RESUME, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_PAL_HOLD_ABCD, a0
	RSUB	print_xy_string_struct_clear

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
	RSUB	print_hex_3_bytes			; print the number of passes in hex

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

	RSUB	print_error

	moveq	#$19, d0
	SSA3	fix_clear_line
	bra	loop_reset_check

.test_exit:
	rts


manual_vram_32k_test_loop:
	lea	XY_STR_VRAM_32K_A_TO_RESUME, a0
	RSUB	print_xy_string_struct_clear

	lea	XY_STR_PASSES.l, a0
	RSUB	print_xy_string_struct

	lea	STR_VRAM_HOLD_ABCD.l, a0
	moveq	#$4, d0
	moveq	#$19, d1
	RSUB	print_xy_string

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
	RSUB	print_hex_3_bytes		; print pass number

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
	RSUB	print_hex_3_bytes		; print pass number
	movem.l	(a7)+, d0-d2

	RSUB	print_error

	moveq	#$19, d0
	SSA3	fix_clear_line

	bra	loop_reset_check

.test_exit:
	rts


manual_vram_2k_test_loop:
	lea	STR_VRAM_HOLD_ABCD, a0
	moveq	#$4, d0
	moveq	#$1b, d1
	RSUB	print_xy_string_clear

	lea	XY_STR_PASSES.l, a0
	RSUB	print_xy_string_struct

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
	RSUB	print_hex_3_bytes

	addq.l	#1, d6

.loop_start_run_test:
	moveq	#-$10, d0
	and.b	REG_P1CNT, d0
	beq	.test_exit			; if a+b+c+d pressed, exit test
	bra	.loop_run_test

.test_failed_abort:
	RSUB	print_error

	moveq	#$19, d0
	SSA3	fix_clear_line

	bra	loop_reset_check

.test_exit:
	rts

manual_misc_input_tests:
	lea	XY_STR_MI_D_MAIN_MENU, a0
	RSUB	print_xy_string_struct_clear
	bsr	misc_input_print_static
.loop_run_test
	bsr	p1p2_input_update
	bsr	misc_input_update_dynamic
	bsr	wait_frame
	btst	#D_BUTTON, p1_input_edge
	beq	.loop_run_test			; if d pressed, exit test
	rts

misc_input_print_static:
	lea	XY_STR_MI_MEMORY_CARD, a0
	RSUB	print_xy_string_struct_clear

	lea	MI_ITEM_CD1, a0
	moveq	#$9, d0
	moveq	#$3, d1
	bsr	misc_input_print_static_items

	lea	XY_STR_MI_SYSTEM_TYPE, a0
	RSUB	print_xy_string_struct_clear

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
	RSUB	print_xy_string

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
	RSUB	print_xy_string
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
	moveq	#$7f, d6
	and.w	d1, d6
	subq.w	#1, d6

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
	RSUB	print_xy_char

	moveq	#$15, d0
	move.b	d5, d1
	moveq	#$0, d2
	moveq	#$20, d3
	moveq	#$13, d4
	RSUB	print_char_repeat		; empty out part of the line stuff

	moveq	#$15, d0
	move.b	d5, d1
	RSUB	print_xy_string

	lea	($10,a1), a1			; load up next struct
	addq.b	#1, d5
	dbra	d6, .loop_next_entry
	rts

; d0 = start row
; d1 = numer of misc_input structs to process
; a0 = address of first misc_input struct
misc_input_print_static_items:
	movea.l	a0, a1
	move.b	d0, d3
	moveq	#$7f, d6
	and.w	d1, d6
	subq.w	#1, d6

.loop_next_entry:
	move.l	(a1)+, d2			; load the test_bit and mmio_address
	moveq	#$4, d0
	move.b	d3, d1
	RSUB	print_hex_3_bytes		; print the mmio_address

	moveq	#$2e, d2
	moveq	#$a, d0
	move.b	d3, d1
	RSUB	print_xy_char

	move.b	(-$4,a1), d2			; reload test_bit
	moveq	#$b, d0
	move.b	d3, d1
	RSUB	print_hex_nibble

	moveq	#$3d, d2
	moveq	#$c, d0
	move.b	d3, d1
	RSUB	print_xy_char

	movea.l	(a1)+, a0			; load bit_name_string_address
	moveq	#$f, d0
	move.b	d3, d1
	RSUB	print_xy_string

	addq.l	#8, a1				; skip over bit_(disabled|enabled)_string_address
	addq.b	#1, d3
	dbra	d6, .loop_next_entry
	rts

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

	lea	XY_STR_MC_D_MAIN_MENU, a0
	RSUB	print_xy_string_struct_clear

	move.b	REG_STATUS_B, d0
	and.b	#$30, d0
	beq	.memcard_inserted

	lea	XY_STR_MC_NOT_DETECTED, a0
	RSUB	print_xy_string_struct_clear
	bra	.loop_wait_input_return_menu

.memcard_inserted:
	move.b	REG_STATUS_B, d0
	btst	#$6, d0
	beq	.memcard_not_write_protect

	lea	XY_STR_MC_WRITE_PROTECT, a0
	RSUB	print_xy_string_struct_clear
	bra	.loop_wait_input_return_menu

.memcard_not_write_protect:

	lea	XY_STR_MC_WARNING1, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_MC_WARNING2, a0
	RSUB	print_xy_string_struct_clear
	lea	XY_STR_MC_A_C_RUN_TEST, a0
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
	lea	XY_STR_MC_RUNNING_TESTS, a0
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

	lea	XY_STR_MC_DETECT, a0
	RSUB	print_xy_string_struct_clear

	; add (BAD DATA) if we weren't able to detect
	btst	#MEMCARD_FLAG_BAD_DATA, memcard_flags
	beq	.skip_bad_data
	lea	XY_STR_MC_BAD_DATA, a0
	RSUB	print_xy_string_struct

.skip_bad_data:

	lea	XY_STR_MC_DBUS_8BIT, a0
	btst	#MEMCARD_FLAG_DBUS_16BIT, memcard_flags
	beq	.print_dbus_size
	lea	XY_STR_MC_DBUS_16BIT, a0

.print_dbus_size:
	RSUB	print_xy_string_struct_clear

	; add (WIDE) if double wide bus
	btst	#MEMCARD_FLAG_DBUS_WIDE, memcard_flags
	beq	.print_size
	lea	XY_STR_MC_DBUS_WIDE, a0
	RSUB	print_xy_string_struct

.print_size:
	lea	XY_STR_MC_SIZE, a0
	RSUB	print_xy_string_struct_clear

	moveq	#13, d0
	moveq	#25, d1
	move.l	memcard_size, d2
	moveq	#10, d3			; print the size in KB
	lsr.l	d3, d2
	RSUB	print_5_digits

	bsr	memcard_we_tests
	bne	.test_failed_abort

	bsr	memcard_data_tests
	bne	.test_failed_abort

	bsr	memcard_address_tests
	bne	.test_failed_abort

	lea	XY_STR_MC_TESTS_PASSED, a0
	RSUB	print_xy_string_struct

	bra	.wait_input_return_menu

.test_failed_abort:
	RSUB	print_error
	moveq	#9, d0
	SSA3	fix_clear_line

.wait_input_return_menu:
	move.b	d0, REG_CRDLOCK1
	move.b  d0, REG_CRDLOCK2

	lea	XY_STR_MC_D_MAIN_MENU, a0
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
	bsr	check_memcard_to_245_output
	beq	.test_passed_memcard_to_245_output_lower
	move.b	#EC_MC_DEAD_OUTPUT_LOWER, d0
	rts

.test_passed_memcard_to_245_output_lower:
	moveq	#$0, d0
	rts

; Both palette ram and memcard memory exist behind 2x245s or a NEO-G0.  Howver
; we seem to get different results when the underly memory is not outputting
; anything.  For palette ram we always get $ff, while for the memcard we get
; the last written (imm) value to it.  Its unclear why this is (wait cycles?).
; Additionally the check_palette_ram_to_245_output function is writing a
; single memory address up to 255 times, which isn't a good idea as repro
; memcards usually are fram based and have ~10k write cycles.
check_memcard_to_245_output:
	move.w  #$5555, (4, a0)
	move.w  (a0), d1
	move.w  #$5555, d2

	and.w	d0, d1
	and.w	d0, d2
	cmp.w	d1, d2
	bne	.test_passed

	move.w	#$aaaa, (8, a0)
	move.w	(a0), d1
	move.w	#$aaaa, d2

	and.w	d0, d1
	and.w	d0, d2
	cmp.w	d1, d2
	bne	.test_passed

	moveq	#-1, d0
	rts

.test_passed:
	moveq	#0, d0
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

.test_passed
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

	lea	MEMCARD_START.l, a0
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

	rorg	$6000, $ff

STR_ACTUAL:			STRING "ACTUAL:"
STR_EXPECTED:			STRING "EXPECTED:"
STR_ADDRESS:			STRING "ADDRESS:"
STR_COLON_SPACE:		STRING ": "
STR_HOLD_SS_TO_RESET:		STRING "HOLD START/SELECT TO SOFT RESET"
STR_RELEASE_SS:			STRING "RELEASE START/SELECT"
STR_VERSION_HEADER:		STRING "NEO DIAGNOSTICS v0.19a00 - BY SMKDAN"

XY_STR_PASSES:			XY_STRING  4, 14, "PASSES:"
XY_STR_Z80_WAITING:		XY_STRING  4,  5, "WAITING FOR Z80 TO FINISH TESTS..."
XY_STR_ALL_TESTS_PASSED:	XY_STRING  4,  5, "ALL TESTS PASSED"
XY_STR_ABCD_MAIN_MENU:		XY_STRING  4, 21, "PRESS ABCD FOR MAIN MENU"
XY_STR_Z80_TESTS_SKIPPED:	XY_STRING  4, 23, "NOTE: Z80 TESTING WAS SKIPPED. TO"
XY_STR_Z80_HOLD_D_AND_SOFT:	XY_STRING  4, 24, "TEST Z80, HOLD BUTTON D AND SOFT"
XY_STR_Z80_RESET_WITH_CART:	XY_STRING  4, 25, "RESET WITH TEST CART INSERTED."

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

XY_STR_Z80_SWITCHING_M1:	XY_STRING  4,  5, "SWITCHING TO CART M1..."
XY_STR_Z80_IGNORED_SM1:		XY_STRING  4,  5, "Z80 SLOT SWITCH IGNORED (SM1)"
XY_STR_Z80_SM1_UNRESPONSIVE:	XY_STRING  4,  7, "SM1 OTHERWISE LOOKS UNRESPONSIVE"
XY_STR_Z80_MV1BC_HOLD_B:	XY_STRING  4, 10, "IF MV-1B/1C: SOFT RESET & HOLD B"
XY_STR_Z80_PRESS_START:		XY_STRING  4, 12, "PRESS START TO CONTINUE"
XY_STR_Z80_TESTING_COMM_PORT:	XY_STRING  4,  5, "TESTING Z80 COMM. PORT..."
XY_STR_Z80_COMM_NO_HELLO:	XY_STRING  4,  5, "Z80->68k COMM ISSUE (HELLO)"
XY_STR_Z80_COMM_NO_ACK:		XY_STRING  4,  5, "Z80->68k COMM ISSUE (ACK)"
XY_STR_Z80_SKIP_TEST:		XY_STRING  4, 24, "TO SKIP Z80 TESTING, RELEASE"
XY_STR_Z80_PRESS_D_RESET:	XY_STRING  4, 25, "D BUTTON AND SOFT RESET."
XY_STR_Z80_MAKE_SURE:		XY_STRING  4, 21, "FOR Z80 TESTING, MAKE SURE TEST"
XY_STR_Z80_CART_CLEAN:		XY_STRING  4, 22, "CART IS CLEAN AND FUNCTIONAL."
XY_STR_Z80_M1_ENABLED:		XY_STRING 34,  4, "[M1]"
XY_STR_Z80_SLOT_SWITCH_NUM:	XY_STRING 29,  4, "[SS ]"
XY_STR_Z80_SM1_TESTS:		XY_STRING 24,  4, "[SM1]"

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

; main menu items
STR_MM_CALENDAR_IO:		STRING "CALENDAR I/O (MVS ONLY)"
STR_MM_COLOR_BARS:		STRING "COLOR BARS"
STR_MM_SMPTE_COLOR_BARS:	STRING "SMPTE COLOR BARS"
STR_MM_VIDEO_DAC_TEST:		STRING "VIDEO DAC TEST"
STR_MM_CONTROLER_TEST:		STRING "CONTROLLER TEST"
STR_MM_WBRAM_TEST_LOOP:		STRING "WRAM/BRAM TEST LOOP"
STR_MM_PAL_RAM_TEST_LOOP:	STRING "PALETTE RAM TEST LOOP"
STR_MM_VRAM_TEST_LOOP_32K:	STRING "VRAM TEST LOOP (32K)"
STR_MM_VRAM_TEST_LOOP_2K:	STRING "VRAM TEST LOOP (2K)"
STR_MM_MISC_INPUT_TEST:		STRING "MISC. INPUT TEST"
STR_MM_MEMCARD_TESTS:		STRING "MEMORY CARD TESTS"

; strings for calender io screen
XY_STR_CAL_A_1HZ_PULSE:		XY_STRING  4,  8, "A: 1Hz pulse"
XY_STR_CAL_B_64HZ_PULSE:	XY_STRING  4, 10, "B: 64Hz pulse"
XY_STR_CAL_C_4096HZ_PULSE:	XY_STRING  4, 12, "C: 4096Hz pulse"
XY_STR_CAL_D_MAIN_MENU:		XY_STRING  4, 14, "D: Return to menu"
XY_STR_CAL_4990_TP:		XY_STRING  4, 21, "4990 TP:"
XY_STR_CAL_WAITING_PULSE:	XY_STRING  4, 27, "WAITING FOR CALENDAR PULSE..."

; strings for video dac test
XY_STR_VDAC_A_FULL_SCREEN:	XY_STRING  4, 24, "A: Toggle Full Screen"
XY_STR_VDAC_B_TOGGLE_DB:	XY_STRING  4, 25, "B: Toggle Darker Bit"
XY_STR_VDAC_C_TOGGLE_SHADOW:	XY_STRING  4, 26, "C: Toggle Shadow Register"
XY_STR_VDAC_D_MAIN_MENU:	XY_STRING  4, 27, "D: Return to menu"
XY_STR_VDAC_ALL:		XY_STRING 29,  6, "ALL"

; strings for controller test screen
XY_STR_CT_D_MAIN_MENU:		XY_STRING  4, 27, "D: Return to menu"
XY_STR_CT_P1:			XY_STRING  1,  4, "P1"
XY_STR_CT_P2:			XY_STRING  1, 17, "P2"

; strings wram/bram test screens
XY_STR_WBRAM_PASSES:		XY_STRING  4, 14, "PASSES:"
XY_STR_WBRAM_HOLD_ABCD:		XY_STRING  4, 27, "HOLD ABCD TO STOP"
XY_STR_WBRAM_WRAM_AES_ONLY:	XY_STRING  4, 16, "WRAM TEST ONLY (AES)"

; strings for palette test screen
XY_STR_PAL_PASSES:		XY_STRING  4, 14, "PASSES:"
XY_STR_PAL_A_TO_RESUME:		XY_STRING  4, 27, "RELEASE A TO RESUME"
XY_STR_PAL_HOLD_ABCD:		XY_STRING  4, 25, "HOLD ABCD TO STOP"

; strings for vram test screens
XY_STR_VRAM_32K_A_TO_RESUME:	XY_STRING  4, 27, "RELEASE A TO RESUME"
STR_VRAM_HOLD_ABCD:		STRING "HOLD ABCD TO STOP"

; strings for misc input screen
XY_STR_MI_D_MAIN_MENU:		XY_STRING  4, 27, "D: Return to menu"
XY_STR_MI_MEMORY_CARD:		XY_STRING  4,  8, "MEMORY CARD:"
XY_STR_MI_SYSTEM_TYPE:		XY_STRING  4, 13, "SYSTEM TYPE:"
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

; strings for memory card screen
XY_STR_MC_A_C_RUN_TEST:		XY_STRING  4, 26, "A+C: Run Test"
XY_STR_MC_D_MAIN_MENU:		XY_STRING  4, 27, "D: Return to menu"
XY_STR_MC_WARNING1:		XY_STRING  4,  8, "WARNING: ALL DATA ON THE MEMORY"
XY_STR_MC_WARNING2:		XY_STRING  4,  9, "CARD WILL BE OVERWRITTEN!"
XY_STR_MC_NOT_DETECTED:		XY_STRING  4,  8, "ERROR: MEMORY CARD NOT DETECTED"
XY_STR_MC_WRITE_PROTECT:	XY_STRING  4,  8, "ERROR: MEMORY CARD WRITE PROTECTED"
XY_STR_MC_DETECT:		XY_STRING  4, 22, "DETECTED"
XY_STR_MC_BAD_DATA:		XY_STRING 13, 22, "(BAD DATA)"
XY_STR_MC_DBUS_8BIT:		XY_STRING  4, 24, "DATA BUS: 8-BIT"
XY_STR_MC_DBUS_16BIT:		XY_STRING  4, 24, "DATA BUS: 16-BIT"
XY_STR_MC_DBUS_WIDE:		XY_STRING 21, 24, "(WIDE)"
XY_STR_MC_SIZE:			XY_STRING  8, 25, "SIZE:      KB"
XY_STR_MC_TESTS_PASSED:		XY_STRING  4,  9, "ALL TESTS PASSED"
XY_STR_MC_RUNNING_TESTS:	XY_STRING  4,  9, "RUNNING TESTS..."


	rorg	$7ffb, $ff
; these get filled in by gen-crc-mirror
	dc.b 	$00			; bios mirror, $00 is running copy, $01 1st copy, $02 2nd, $03 3rd
	dc.b 	$00,$00,$00,$00		; bios crc32 value calculated from bios_start to $c07ffb
