        include "neogeo.inc"
        include "macros.inc"
        include "sp1.inc"

        global manual_color_bars_basic_test
        global STR_COLOR_BARS_BASIC

        section text

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
manual_color_bars_basic_test:
		lea	XY_STR_D_MAIN_MENU, a0
		RSUB	print_xy_string_struct_clear
		bsr	setup_palettes
		bsr	draw_tiles

	.loop_run_test:
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
setup_palettes:
		; bank1 may have never been initialized
		move.b	d0, REG_PALBANK1
		clr.w	PALETTE_REFERENCE
		clr.w	PALETTE_BACKDROP
		move.l  #$7fff0000, PALETTE_RAM_START+$2	; white on black for text

		move.l	#$00010111, d0				; bluewhite
		bsr	setup_palette_bank

		move.b	d0, REG_PALBANK0
		move.l	#$01000010, d0				; redgreen
		bsr	setup_palette_bank

		rts

; setup an individual palette bank
; d0 = start value and also increment amount for color1&2
setup_palette_bank:
		move.l	d0, d1					; save for increment amount
		moveq	#$e, d2					; 15 palettes to update
		lea	PALETTE_RAM_START+PALETTE_SIZE+$2, a0	; goto palette1 color1

	.loop_next_palette:
		move.l	d0, (a0)
		add.l	d1, d0
		adda.l	#PALETTE_SIZE, a0			; next palette/color1
		dbra	d2, .loop_next_palette
		rts


draw_tiles:
		moveq	#$4, d0
		moveq	#$7, d1
		SSA3	fix_seek_xy			; d0 on return will have current vram address
		move.w	#$1, (2,a6)			; increment vram writes one at a time

		moveq	#$e, d1				; 15 total shades in the gradients
		move.w	#$1000, d4			; palette1, tile 0x00
		move.w  #$1020, d5			; palette1, tile 0x20

	.loop_next_shade:
		moveq	#$1, d2				; each gradient shade is 2 tiles wide

	.loop_double_wide:
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

STR_COLOR_BARS_BASIC:		STRING "COLOR BARS BASIC"
