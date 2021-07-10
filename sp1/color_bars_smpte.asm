	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"

        global manual_color_bars_smpte_test
        global STR_COLOR_BARS_SMPTE

        section text

manual_color_bars_smpte_test:
		bsr	setup_palettes
		bsr	draw_sections

	.loop_run_test:
		WATCHDOG
		bsr	p1p2_input_update
		btst	#D_BUTTON, p1_input_edge	; D pressed?
		beq	.loop_run_test
		rts

; We will be using tile #$00 for writing the smpte bars, which is a solid
; color using color index 1.  Setup palettes 3 to 15 with the 13 needed
; colors
setup_palettes:
		moveq	#((SMPTE_COLORS_END - SMPTE_COLORS) / 2 - 1), d2
		lea	SMPTE_COLORS, a0
		lea	PALETTE_RAM_START+PALETTE_SIZE+PALETTE_SIZE+2, a1

	.loop_next_color:
		move.w	(a0)+, d0
		move.w	d0, (a1)
		adda.l	#PALETTE_SIZE, a1
		dbra	d2, .loop_next_color
		rts


draw_sections:
		move.w	#FIXMAP + 2, d1		; start 2nd row down
		move.w	#$20, (2,a6)		; draw tiles left to right

		lea	TOP_SECTION, a0
		moveq	#((TOP_SECTION_END - TOP_SECTION) / 2), d0
		moveq	#$14, d2
		bsr	draw_section

		lea	MIDDLE_SECTION, a0
		moveq	#((MIDDLE_SECTION_END - MIDDLE_SECTION) / 2), d0
		moveq	#$2, d2
		bsr	draw_section

		lea	BOTTOM_SECTION, a0
		moveq	#((BOTTOM_SECTION_END - BOTTOM_SECTION) / 2), d0
		moveq	#$7, d2
		bsr	draw_section
		rts

; a0 = address of smpte_color struct array
; d0 = number of items in the array
; d1 = fix address
; d2 = height of the section
draw_section:
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


STR_COLOR_BARS_SMPTE:	  STRING "COLOR BARS SMPTE"

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

; struct {
;	byte palette;
;	byte width;
; } smpte_color[]
TOP_SECTION:
	dc.b	SMPTE_PAL_BLACK, 2
	dc.b	SMPTE_PAL_GRAY, 5
	dc.b	SMPTE_PAL_YELLOW, 5
	dc.b	SMPTE_PAL_CYAN, 5
	dc.b	SMPTE_PAL_GREEN, 5
	dc.b	SMPTE_PAL_MAGENTA, 5
	dc.b	SMPTE_PAL_RED, 6
	dc.b	SMPTE_PAL_BLUE, 5
TOP_SECTION_END:

MIDDLE_SECTION:
	dc.b	SMPTE_PAL_BLACK, 2
	dc.b	SMPTE_PAL_BLUE, 5
	dc.b	SMPTE_PAL_BLACK16, 5
	dc.b	SMPTE_PAL_MAGENTA, 5
	dc.b	SMPTE_PAL_BLACK16, 5
	dc.b	SMPTE_PAL_CYAN, 5
	dc.b	SMPTE_PAL_BLACK16, 6
	dc.b	SMPTE_PAL_GRAY, 5
MIDDLE_SECTION_END:

BOTTOM_SECTION:
	dc.b	SMPTE_PAL_BLACK, 2
	dc.b	SMPTE_PAL_DARK_BLUE, 6
	dc.b	SMPTE_PAL_WHITE, 6
	dc.b	SMPTE_PAL_PURPLE, 6
	dc.b	SMPTE_PAL_BLACK16, 7
	dc.b	SMPTE_PAL_BLACK8, 2
	dc.b	SMPTE_PAL_BLACK16, 2
	dc.b	SMPTE_PAL_BLACK24, 2
	dc.b	SMPTE_PAL_BLACK16, 5
BOTTOM_SECTION_END:
