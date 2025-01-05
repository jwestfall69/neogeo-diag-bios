	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"
	include "../common/error_codes.inc"

	global ym2610_io_tests_psub
	global ym2610_stuck_irq_test
	global ym2610_timer_flag_test
	global ym2610_timer_irq_test

	section code

ym2610_io_tests_psub:
		in	a, (IO_YM2610_PORT0_REGISTER)
		rlca
		jr	c, .test_failed			; ym2610 says its busy

		ld	a, $27
		out	(IO_YM2610_PORT0_REGISTER), a	; irq/timer related register
		add	hl, hl				; delay
		add	hl, hl
		add	hl, hl
		add	hl, hl

		ld	a, $30
		out	(IO_YM2610_PORT0_DATA), a	; disable irqs
		add	hl, hl				; delay
		add	hl, hl
		add	hl, hl
		add	hl, hl

		in	a, (IO_YM2610_PORT0_REGISTER)
		and	$30				; check we get back what we wrote
		jr	nz, .test_failed

		; this next chunk of code writes $00/$55/$aa/$ff to reg $0 or ym2610 and
		; re-reads it back to verify its the same
		ld	bc, $0000
		PSUB	ym2610_write_port0
		in	a, (IO_YM2610_PORT0_DATA)
		cp	$00
		jr	nz, .test_failed

		ld	bc, $5500
		PSUB	ym2610_write_port0
		in	a, (IO_YM2610_PORT0_DATA)
		cp	$55
		jr	nz, .test_failed

		ld	bc, $aa00
		PSUB	ym2610_write_port0
		in	a, (IO_YM2610_PORT0_DATA)
		cp	$aa
		jr	nz, .test_failed

		ld	bc, $ff00
		PSUB	ym2610_write_port0
		in	a, (IO_YM2610_PORT0_DATA)
		cp	$ff
		jr	nz, .test_failed
		xor	a
		PSUB_RETURN

	.test_failed:
		ld	a, EC_YM2610_IO_ERROR
		or	a
		PSUB_RETURN

; ym2610_io_tests disables the timer and interrupt generation
; on the ym2610.  Temp enable interrupts on the z80 to see
; if we get one.
ym2610_stuck_irq_test:
		ex	af, af'
		ld	a, YM2610_IRQ_UNEXPECTED
		ex	af, af'
		ei
		nop
		nop
		nop
		nop
		di
		ret

; setup the timer with irq's disabled, poll it
; and make sure it triggers within the expected range
ym2610_timer_flag_test:
		call	ym2610_timer_init
		ld	a, $ff
		jr	nz, .timer_init_failed:

		ld	bc, $0000
		ld	de, $4000

	.loop_wait_timer_flag:
		in	a, (IO_YM2610_PORT0_REGISTER)
		rrca
		jr	c, .timer_a_fired
		inc	bc
		dec	de
		ld	a, e
		or	d
		jr	nz, .loop_wait_timer_flag	; wait for the timer A flag to get set
		di					; indicating the timer fired

	.test_failed_abort:
		or	$ff
		ld	a, EC_YM2610_TIMER_TIMING_FLAG
		or	a
		ret

	.timer_init_failed:
		or	$ff
		ld	a, EC_YM2610_TIMER_INIT_FLAG
		or	a
		ret

	; The timer fired now make sure it was within the
	; range we were expecting
	.timer_a_fired:
		di
		ld	hl, $02a5
		cp	a
		sbc	hl, bc
		jr	z, .test_passed_greater
		jr	nc, .test_failed_abort

	.test_passed_greater:
		ld	hl, $02af
		cp	a
		sbc	hl, bc
		jr	c, .test_failed_abort
		xor	a
		ret

; Test the timer with irq's enabled
ym2610_timer_irq_test:
		call	ym2610_timer_init
		jr	nz, .timer_init_failed

		ex	af, af'
		ld	a, YM2610_IRQ_EXPECTED
		ex	af, af'

		ei

		ld	bc, $0000
		ld	l, $00
		ld	de, $4000

	.loop_wait_int:
		ld	a, l		; when an irq fires it will cause l to be $ff
		or	a
		jr	nz, .got_ym2610_int
		inc	bc
		dec	de
		ld	a, e
		or	d
		jr	nz, .loop_wait_int
		di

	.test_failed_abort:
		ld	a, EC_YM2610_TIMER_TIMING_IRQ
		or	a
		ret

	.timer_init_failed:
		ld	a, EC_YM2610_TIMER_INIT_IRQ
		or	a
		ret

	; make sure bc is between $30a and $314 for how long
	; it took for the irq to fire
	.got_ym2610_int:
		di
		ld	hl, $030a
		cp	a
		sbc	hl, bc
		jr	z, .test_passed_greater
		jr	nc, .test_failed_abort

	.test_passed_greater:
		ld	hl, $0314
		cp	a
		sbc	hl, bc
		jr	c, .test_failed_abort
		xor	a
		ret

ym2610_timer_init:
		ld	de, $3027		; reset TA/TB flags
		call	ym2610_write_port0
		jr	nz, .init_timeout

		ld	de, $0025		; clear TA counter LSBs
		call	ym2610_write_port0
		jr	nz, .init_timeout

		ld	de, $8024		; set TBA MSBs to $80
		call	ym2610_write_port0
		jr	nz, .init_timeout

		ld	de, $0527		; enable TA irq, load TA
		call	ym2610_write_port0
		jr	nz, .init_timeout
		ret

	.init_timeout:
		ret
