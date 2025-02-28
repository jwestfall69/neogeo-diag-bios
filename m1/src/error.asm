	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"
	include "../common/include/error_codes.inc"

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
		di
		out	(IO_NMI_DISABLE), a

		ld	c, a
		or	$40		; flag to indicate z80 error
		out	(IO_FROM_68K_CLEAR), a
		out	(IO_TO_68K), a

		ld	a, $08
		sub	b

	.loop_bitshift:			; shift over so bit 8 is the
		rlc	c		; start of the error code
		dec	a
		jr	nz, .loop_bitshift

	.loop_next_bit:
		rlc	c
		ld	a, $02		; bit is 0
		jr	nc, .play_sound
		ld	a, $01		; bit is 1

	.play_sound:
		exx
		ld	c, $01		; course tune register (cha)
		ld	b, a
		PSUB_YMWP0

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

		; wait a reasonable amount of time for the 68k
		; to ack our sent error, then move on
		exx
		ld	l, $32
	.loop_wait_68k_input:
		in	a, (IO_FROM_68K)
		or	a
		jr	nz, .got_68k_input


		; doing a manual dely here because PSUB
		; uses hl/de and we need a counter for
		; the outer loop
		ld	bc, $4000
	.loop_delay:
		dec	bc
		ld	a, c
		or	b
		jr	nz, .loop_delay

		dec	l
		jr	nz, .loop_wait_68k_input
		jr	.input_timeout

	.got_68k_input:
		cpl
		out	(IO_TO_68K), a

	.input_timeout:
		exx

		; because of the exx/rlc's above, 'c' will contain
		; the original error code.  if its an error code
		; from the diag m1 (less then $20) do error_address
		ld	a, c
		cp	$20
		jr	c, error_address

		STALL
