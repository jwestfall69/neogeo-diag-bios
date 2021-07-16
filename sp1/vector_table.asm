	include "sp1.inc"

	section vectors,data

		dc.l	SP_INIT_ADDR
		dc.l	_start

		rorg	$64, $ff
		dc.l	vblank_interrupt
		dc.l	timer_interrupt
