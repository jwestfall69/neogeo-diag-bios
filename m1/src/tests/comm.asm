	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"
	include "../common/comm.inc"
	include "../common/error_codes.inc"

	global comm_test_psub

	section code

comm_test_psub:
		ld	a, COMM_TEST_HELLO
		out	($0c), a
		out	($00), a

		; Wait up to 5 seconds (500 * 10ms) for a response to our hello.
		; If we were started at boot (AES or MV-1B/C) we need to allow a bit
		; of time for the main bios to run its tests before it will respond
		; to us.
		; Using bc' for our loop, bc will be used for the delay psub call.
		; We can't use de/hl because they are used to when setting up the
		; PSUB delay call.
		exx
		ld	bc, 500
		exx

		jp	.loop_start

	.loop_again:
		ld	bc, 1540		; 1540 * 6.5us = ~10ms
		PSUB	delay

	.loop_start:
		in	a, ($00)
		cp	COMM_TEST_HANDSHAKE
		jr	z, .got_handshake

		exx
		dec	bc
		ld	a, c
		or	b
		exx
		jr	nz, .loop_again

		or	$ff
		ld	a, EC_Z80_68K_COMM_NO_HANDSHAKE
		or	a
		PSUB_RETURN

	.got_handshake:
		out	($00), a
		in	a, ($00)
		and	a
		jr	z, .test_passed
		ld	a, EC_Z80_68K_COMM_NO_CLEAR
		or	a
		PSUB_RETURN

	.test_passed:
		ld	a, COMM_TEST_ACK
		out	($0c), a

		; delay a little to avoid sending an error before the m68k has had
		; time to consume our ACK
		ld	bc, 1540
		PSUB	delay

		xor	a
		PSUB_RETURN

