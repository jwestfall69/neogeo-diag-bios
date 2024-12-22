	include "neogeo.inc"
	include "macros.inc"
	include "diag.inc"

	global r_timer_count

	section vectors

		dc.l	SP_INIT_ADDR
		dc.l	_start

		rorg	$64, $ff
		dc.l	irq1_handler
		dc.l	irq2_handler

	section data

; vblank
irq1_handler:
		WATCHDOG
		addq.w	#$1, r_vblank_count
		move.w	#$4, REG_IRQACK
		rte

; timer
irq2_handler:
		addq.w	#$1, r_timer_count
		move.w	#$2, ($a,a6)	; ack int
		rte

	section bss
	align 2

r_vblank_count:		dc.w $0
r_timer_count:		dc.w $0
