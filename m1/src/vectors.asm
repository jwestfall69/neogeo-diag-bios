	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"
	include "../common/error_codes.inc"

	section vectors

	rorg RST_ENTRY
		jp	_start

	rorg RST_PSUB_ENTER, $ff
		jp	psub_enter


	rorg RST_PSUB_EXIT, $ff
		jp	psub_exit


	rorg RST_HANDLE_Z80_ERROR_CODE, $ff
		jp	handle_z80_error_code


	rorg RST_PSUB_YM2610_WRITE_PORT0, $ff
		ld	hl, ym2610_write_port0_psub
		jp	psub_enter


	; interrupts from ym2610
	rorg RST_IRQ, $ff
		ex	af, af'
		cp	YM2610_IRQ_EXPECTED
		jr	z, .expected_interrupt
		cp	YM2610_IRQ_UNEXPECTED
		jr	z, .unexpected_interrupt

		; a' is in an unknown state, which implies we are not in our irq test
		; functions.  This shouldn't happen if the _start function was run,
		; since one of the first things it does is disable interrupts.  The
		; likely cause of this was a failed slot switch where we never got
		; the NMI reset command (0x03).
		;
		; It seems like there are 2 possibilities that can cause this:
		; 1. The sm1 had interrupts enabled and the ym2610 just triggered one.
		; 2. When the slot switch happened the PC was at a rom location that
		;    has our fill byte (0xff), which is instruction rst #$38 causing
		;    a jump to our irq code.
		;
		; Our best course of action in either case is to run the _start function
		; and attempt to recover.
		jp	_start


	.unexpected_interrupt:
		ld	a, EC_YM2610_IRQ_UNEXPECTED
		jp	handle_z80_error_code

	.expected_interrupt:
		ex	af, af'
		ld	l, $ff
		reti


	; NMIs from 68k
	rorg RST_NMI, $ff
		nop
		nop
		nop
		nop
		in	a, (IO_FROM_68K)
		out	(IO_FROM_68K_CLEAR), a
		out	(IO_TO_68K), a
		jp	_start
