	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"
	include "../common/error_codes.inc"

	global ym2610_write_port0
	global ym2610_write_port0_psub
	global ym2610_write_port1
	global ym2610_write_port1_psub

	section code

; params:
;  de, d = data to write, e = ym2610 register
ym2610_write_port0:
		ld	a, e
		out	(IO_YM2610_PORT0_REGISTER), a

		ld	b, $ff
	.loop_busy_register_load:
		in	a, (IO_YM2610_PORT0_REGISTER)	; bit 8 will be 1 while ym is busy loading register
		rlca
		jr	nc, .register_loaded
		djnz	.loop_busy_register_load
		jr	.busy_timeout

	.register_loaded:
		ld	a, d
		out	(IO_YM2610_PORT0_DATA), a

		ld	b, $ff
	.loop_busy_data_load:
		in	a, (IO_YM2610_PORT0_REGISTER)
		rlca
		jr	nc, .register_data_loaded
		djnz	.loop_busy_data_load

	.busy_timeout:
		or	$ff
		ret

	.register_data_loaded:
		ret

; params:
;  de, d = data to write, e = ym2610 register
; never called
ym2610_write_port1:
		ld	a, e
		out	(IO_YM2610_PORT1_REGISTER), a
	.loop_busy_register_load:
		in	a, (IO_YM2610_PORT0_REGISTER)	; bit 8 will be 1 while ym is busy loading register
		rlca
		jr	c, .loop_busy_register_load

		ld	a, d
		out	(IO_YM2610_PORT1_DATA), a

	.loop_busy_data_load:
		in	a, (IO_YM2610_PORT0_REGISTER)
		rlca
		jr	c, .loop_busy_data_load
		ret

; params:
;  bc, b = data to write, c = ym2610 register
; assuming its doing the delay instead of the polling
; like the non-psub version because there could be
; a connectivity issue between the z80/ym2610 and
; we dont want to get stuck waiting for not-busy
ym2610_write_port0_psub:
		ld	a, c
		out	(IO_YM2610_PORT0_REGISTER), a
		add	hl, hl			; delay a bit before next write to ym
		add	hl, hl
		add	hl, hl
		add	hl, hl
		ld	a, b
		out	(IO_YM2610_PORT0_DATA), a
		PSUB_RETURN

; params:
;  bc, b = data to write, c = ym2610 register
; never called
ym2610_write_port1_psub:
		ld	a, c
		out	(IO_YM2610_PORT1_REGISTER), a
		add	hl, hl			; delay a bit before next write to ym
		add	hl, hl
		add	hl, hl
		add	hl, hl
		ld	a, b
		out	(IO_YM2610_PORT1_DATA), a
		PSUB_RETURN
