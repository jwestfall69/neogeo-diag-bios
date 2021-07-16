	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"

	global manual_video_dac_tests
	global STR_VIDEO_DAC_TESTS

	section text

; A button = enter full screen mode
; B button = toggle darker bit
; C button = toggle shadow register
; D button = return to main menu
manual_video_dac_tests:

		moveq	#0, d6			; will use d6 to track shadow toggle
		move.b	d0, REG_NOSHADOW

		bsr	setup_palettes
		bsr	draw_main_screen

	.loop_run_test:
		WATCHDOG
		bsr	p1p2_input_update
		bsr	wait_frame

		btst	#A_BUTTON, p1_input_edge
		beq	.a_not_pressed
		bsr	draw_fullscreen
		bra	manual_video_dac_tests		; jump to the top so we clear shadow/darker bit
	.a_not_pressed:

		btst	#B_BUTTON, p1_input_edge
		beq	.b_not_pressed
		bsr	toggle_darker_bit
	.b_not_pressed:

		btst	#C_BUTTON, p1_input_edge
		beq	.c_not_pressed
		bsr	toggle_reg_shadow
	.c_not_pressed:

		btst	#D_BUTTON, p1_input_edge	; D pressed?
		beq	.loop_run_test

		; we dont need to worry about cleaning up palettes, but
		; we should make sure show is off.
		move.b	d0, REG_NOSHADOW
		rts

; fill the entire screen with the single tile
; Left/Right = cycle through color bits / all
; UP/Down = cycle through red/green/blue/combined
; B button = toggle darker bit
; C button = toggle shadow register
; D button = return to main video screen
draw_fullscreen:

		; clear shadow/darker bit that might have been enabled on main screen
		moveq	#0, d6
		move.b	d0, REG_NOSHADOW
		bsr	setup_palettes

		move.w	#FS_TILE_BASE_PAL_MIN, d0
		SSA3	fix_fill				; fills the screen red/color bit 0

		move.w	#FS_TILE_BASE_PAL_MIN, d3		; start tile base pal
		lea	FS_TILE_OFFSETS, a0
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
		cmp.w	#FS_TILE_BASE_PAL_MAX + $1000, d3
		bmi	.redraw_fullscreen
		move.w	#FS_TILE_BASE_PAL_MIN, d3
		bra	.redraw_fullscreen
	.right_not_pressed:

		btst	#LEFT, p1_input_edge
		beq	.left_not_pressed
		sub.w	#$1000, d3
		cmp.w	#FS_TILE_BASE_PAL_MIN, d3
		bpl	.redraw_fullscreen
		move.w	#FS_TILE_BASE_PAL_MAX, d3

	.redraw_fullscreen:
		moveq	#0, d0
		move.w	(a0,d4), d0
		add.w	d3, d0			; tile base pal + tile offset = what to fill with
		SSA3	fix_fill

	.left_not_pressed:
		btst	#B_BUTTON, p1_input_edge
		beq	.b_not_pressed
		movem.l d0-d1/a0, -(a7)
		bsr	toggle_darker_bit
		movem.l (a7)+, d0-d1/a0
	.b_not_pressed:

		btst	#C_BUTTON, p1_input_edge
		beq	.c_not_pressed
		bsr	toggle_reg_shadow
	.c_not_pressed:

		btst	#D_BUTTON, p1_input_edge
		beq	.loop_input
		rts

; enabling/disabling this bit in the palette doesn't make
; any visual difference on screen, but you can hear it on the
; 8.2k resistors on the dac
toggle_darker_bit:

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
toggle_reg_shadow:

		eor.b	#1, d6
		beq	.disable_reg_shadow
		move.b	d0, REG_SHADOW
		rts

	.disable_reg_shadow:
		move.b	d0, REG_NOSHADOW
		rts

; palettes  5 to  9 are used by red  and green
; palettes 10 to 14 are used by blue and combined
setup_palettes:

		lea	PALETTE_RAM_START+(PALETTE_SIZE*4)+$2, a0	; goto palette5 color1
		move.l	#$40002000, d0					; lsb redgreen
		move.l	#$01000010, d1					; red/green
		move.l	#$4f0020f0, d2					; full red/green
		bsr	setup_palette_group

		lea     PALETTE_RAM_START+(PALETTE_SIZE*10)+$2, a0	; goto palette10 color1
		move.l	#$10007000, d0					; lsb blue/combined
		move.l	#$00010111, d1					; blue/combined
		move.l	#$100f7fff, d2					; full blue/white
		bsr	setup_palette_group

		rts

; setup an individual palette group
; a0 = palette start address
; d0 = lsb color
; d1 = start normal color
; d2 = all bits
setup_palette_group:
		; lsb bits
		move.l	d0, (a0)
		adda.l	#PALETTE_SIZE, a0

		moveq	#3, d0						; 4 rol palettes

	.loop_next_palette:
		move.l	d1, (a0)
		rol.l	#1, d1
		adda.l	#PALETTE_SIZE, a0				; next palette/color1
		dbra	d0, .loop_next_palette

		move.l	d2, (a0)					; all bits
		rts

; draw the main screen
draw_main_screen:
		SSA3	fix_clear

		lea	STR_VIDEO_DAC_TESTS, a0
		moveq	#13, d0
		moveq	#3, d1
		RSUB	print_xy_string

		lea	XY_STR_A_FULL_SCREEN, a0
		RSUB	print_xy_string_struct_clear

		lea	XY_STR_B_TOGGLE_DB, a0
		RSUB	print_xy_string_struct_clear

		lea	XY_STR_C_TOGGLE_SHADOW, a0
		RSUB	print_xy_string_struct_clear

		lea	XY_STR_D_MAIN_MENU, a0
		RSUB	print_xy_string_struct_clear

		lea	XY_STR_ALL, a0
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
		bsr	draw_color_pair

		; draw the blue/combined rows
		moveq	#8, d0
		moveq	#15, d1
		SSA3	fix_seek_xy

		move.w	#$a000, d1
		bsr	draw_color_pair

		rts

; d0 = column start
; d1 = start palette
draw_color_pair:
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


STR_VIDEO_DAC_TESTS:		STRING "VIDEO DAC TESTS"

XY_STR_A_FULL_SCREEN:		XY_STRING  4, 24, "A: Toggle Full Screen"
XY_STR_B_TOGGLE_DB:		XY_STRING  4, 25, "B: Toggle Darker Bit"
XY_STR_C_TOGGLE_SHADOW:		XY_STRING  4, 26, "C: Toggle Shadow Register"
XY_STR_D_MAIN_MENU:		XY_STRING  4, 27, "D: Return to menu"
XY_STR_ALL:			XY_STRING 29,  6, "ALL"

; full screen stuff
FS_TILE_BASE_PAL_MIN		equ $4000
FS_TILE_BASE_PAL_MAX		equ $9000
FS_TILE_OFFSETS:		dc.w $0000, $0020, $6000, $6020


