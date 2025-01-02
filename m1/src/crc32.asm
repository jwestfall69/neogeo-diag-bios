	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"

	global crc32_psub
	global CRC32_CODE_END

	section code

; params:
;  bc  = start address
;  bc' = length
; returns:
;  bc = upper 16bits of crc32
;  de = lower 16bits of crc32
crc32_psub:
		ld	a, c
		exx
		ld	l, a
		exx
		ld	a, b
		exx
		ld	h, a
		ld	d, b
		ld	e, c
		exx
		ld	de, $ffff
		ld	hl, $ffff

	.loop_outer:
		ld	b, $08
		ld	a, e
		exx
		xor	(hl)
		inc	hl
		exx
		ld	e, a

	.loop_inner:
		srl	h
		rr	l
		rr	d
		rr	e
		jr	nc, .next_loop_inner
		ld 	a, e
		xor	$20
		ld	e, a
		ld	a, d
		xor	$83
		ld	d, a
		ld	a, l
		xor	$b8
		ld	l, a
		ld	a, h
		xor	$ed
		ld	h, a

	.next_loop_inner:
		djnz	.loop_inner
		exx
		dec	de
		ld	a, e
		or	d
		exx
		jr	nz, .loop_outer
		ld	a, e
		cpl
		ld	c, a
		ld	a, d
		cpl
		ld	b, a
		ld	a, l
		cpl
		ld	e, a
		ld	a, h
		cpl
		ld	d, a
		PSUB_RETURN
CRC32_CODE_END:
