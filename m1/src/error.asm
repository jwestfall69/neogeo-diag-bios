	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"
	include "../common/error_codes.inc"

	global handle_68k_error_code
	global handle_z80_error_code

	section code

; z80 errors play 6 bits/tones
handle_z80_error_code:
		ld	b, $06
		jr	handle_error_code

; 68k errors play 7 bits/tones
handle_68k_error_code:
		ld	b, $07
		jr	handle_error_code

; params:
;  a = error code
;  b = number of bits to play
handle_error_code:
		di			; disable ints
		out	($18), a	; disable nmi

		ld	c, a
		or	$40		; flag to indicate z80 error
		out	($00), a
		out	($0c), a	; send the error code to 68k


		ld	a, $08
		sub	b

	.loop_bitshift:			; shift over so bit 8 is the
		sla	c		; start of the error code
		dec	a
		jr	nz, .loop_bitshift

	.loop_next_bit:
		sla	c
		ld	a, $02		; bit is 0
		jr	nc, .play_sound
		ld	a, $01		; bit is 1

	.play_sound:
		exx
		ld	c, $01		; course tune register (cha)
		ld	b, a
		PSUB	ym2610_write_port0

		ld	bc, $0000	; fine tune register (cha)
		PSUB_YMWP0

		ld	bc, $0f08	; volume (cha)
		PSUB_YMWP0

		ld	bc, $fe07	; enable tone A? (cha)
		PSUB_YMWP0

		ld	bc, $c000	; 319488us / 319ms
		PSUB	delay

		ld	bc, $ff07	; disable tone A? (cha)
		PSUB_YMWP0

		ld	bc, $4000	; 106496us / 106ms
		PSUB	delay

		exx
		djnz 	.loop_next_bit

	.loop_wait_68k_input:
		in	a, ($00)
		or	a
		jr	z, .loop_wait_68k_input

		cpl
		out	($0c), a

	.stall:
		jr	.stall
