	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"

	global delay_psub
	global ym2610_make_noise_psub

	section code
; params:
;  bc * 6.5us = how long to delay
delay_psub:
		dec	bc			; 6 cycles
		ld	a, c			; 4 cycles
		or	b			; 4 cycles
		jr	nz, delay_psub		; 12 cycles
		PSUB_RETURN

ym2610_make_noise_psub:
		ld	b, $04

	.loop_again:
		exx
		ld	bc, $0001		; course tune (cha)
		PSUB_YMWP0

		ld	bc, $8000		; fine tune (cha)
		PSUB_YMWP0

		ld	bc, $0f08		; volume (cha)
		PSUB_YMWP0

		ld	bc, $fe07		; tone enable? (cha)
		PSUB_YMWP0

		ld	bc, $1000		; 26624us / 26ms
		PSUB	delay

		ld	bc, $ff07		; tone disable? (cha)
		PSUB_YMWP0

		ld	bc, $1000		; 26624us / 26ms
		PSUB	delay

		exx
		djnz .loop_again
		PSUB_RETURN
