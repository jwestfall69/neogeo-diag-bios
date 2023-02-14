	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"
	include "../common/error_codes.inc"

	global check_ram_address_dsub
	global check_ram_data_dsub
	global check_ram_oe_dsub
	global check_ram_to_245_oe_dsub
	global check_ram_we_dsub
	global check_vram_address
	global check_vram_data
	global check_vram_we
	global check_vram_oe

	section text

; Attempts to read from ram.  If the chip never gets enabled
; d1 will be filled with the next data on the data bus, which
; would be the next instruction because of prefetching.  We do
; the move.b 3 times with 3 different instructions after it. If
; the data loaded into d1 is the next instruction for all of
; them it will trigger an error
; params:
;  a0 = address
;  d0 = 0 (upper chip) or 1 (lower chip)
; return:
;  d0 = $00 (pass) or $ff (fail)
check_ram_oe_dsub:
		adda.w	d0, a0
		moveq	#$31, d2

	.loop_test_again:
		move.b	(a0), d1
		cmp.b	*(PC,d0.w), d1
		bne	.test_passed

		move.b	(a0), d1
		nop
		cmp.b	*-2(PC,d0.w), d1
		bne	.test_passed

		move.b	(a0), d1
		add.w	#0, d0
		cmp.b	*-4(PC,d0.w), d1

	.test_passed:
		dbeq	d2, .loop_test_again
		seq	d0
		DSUB_RETURN


; memcard and (on some boards) p rom there is a bus transceiver (74LS245,
; NEO-G0, NEO-BUF) between it and the CPU.  This test attempts to detect
; when the memcard or p rom has dead output.  When this happens the most
; common result is we will get the last writtn imm value to it.  Note for
; palette ram the result always seems to be $ff. I'm unclear why this is
; but palette ram has its own 245 check for this.
; params:
;  d0 = mask
;  a0 = start address
; return:
;  d0 = $00 (pass) or $ff (fail)
check_ram_to_245_oe_dsub:
		move.w	#$5555, (4, a0)
		move.w	(a0), d1
		move.w	#$5555, d2

		and.w	d0, d1
		and.w	d0, d2
		cmp.w	d1, d2
		bne	.test_passed

		move.w	#$aaaa, (8, a0)
		move.w	(a0), d1
		move.w	#$aaaa, d2

		and.w	d0, d1
		and.w	d0, d2
		cmp.w	d1, d2
		bne	.test_passed

		moveq	#-1, d0
		DSUB_RETURN

	.test_passed:
		moveq	#0, d0
		DSUB_RETURN

; params:
;  d0 = start video ram address
;  d1 = mask
check_vram_oe:
		clr.w	(2,a6)
		move.w	d0, (-2,a6)
		move.w	#$ff, d2
		moveq	#0, d3
		move.w	#$101, d4

	.loop_next_address:
		move.w	d3, (a6)
		nop
		nop
		nop
		nop
		move.w	(a6), d5
		add.w	d4, d3
		and.w	d1, d5
		cmp.w	d1, d5
		dbne	d2, .loop_next_address
		beq	.test_failed

		moveq	#0, d0
		rts

	.test_failed:
		moveq	#-1, d0
		rts

; params:
;  a0 = address
;  d0 = bitmask
check_ram_we_dsub:
		move.w	(a0), d1
		and.w	d0, d1
		moveq	#0, d2
		move.w	#$101, d5		; incr amount for each loop
		move.w	#$ff, d3		; loop $ff times

	.loop_next_address:
		move.w	d2, (a0)
		add.w	d5, d2
		move.w	(a0), d4
		and.w	d0, d4
		cmp.w	d1, d4			; check if write and re-read values match
		dbne	d3, .loop_next_address
		beq	.test_failed

		moveq	#0, d0
		DSUB_RETURN

	.test_failed:
		moveq	#-1, d0
		DSUB_RETURN

; params:
;  d0 = start vram address
;  d1 = mask
check_vram_we:
		move.w	d0, (-2,a6)
		clr.w	(2,a6)
		move.w	(a6), d0
		and.w	d1, d0
		moveq	#0, d2
		move.w	#$101, d5
		move.w	#$ff, d3
		lea	REG_WATCHDOG, a0

	.loop_next_address:
		move.w	d2, (a6)
		move.b	d0, (a0)			; WATCHDOG
		add.w	d5, d2
		move.w	(a6), d4
		and.w	d1, d4
		cmp.w	d0, d4
		dbne	d3, .loop_next_address
		beq	.test_failed

		moveq	#0, d0
		rts

	.test_failed:
		moveq	#-1, d0
		rts

; Does a full write/read test
; params:
;  a0 = start address
;  d0 = length
; returns:
;  d0 = 0 (pass), 1 (lower bad), 2 (upper bad), 3 (both bad)
;  a0 = failed address
;  d1 = wrote value
;  d2 = read (bad) value
check_ram_data_dsub:
		subq.w	#1, d0

		lea	MEMORY_DATA_TEST_PATTERNS, a1
		moveq	#((MEMORY_DATA_TEST_PATTERNS_END - MEMORY_DATA_TEST_PATTERNS)/2 - 1), d3
		move.l	d0, d4
		movea.l	a0, a2

	.loop_next_pattern:
		movea.l	a2, a0
		move.l	d4, d0

		move.w	(a1)+, d1

	.loop_next_address:
		move.w	d1, (a0)
		move.w	(a0)+, d2
		cmp.w	d1, d2
		dbne	d0, .loop_next_address
		bne	.test_failed

		WATCHDOG
		dbra	d3, .loop_next_pattern

		moveq	#0, d0
		DSUB_RETURN

	.test_failed:
		subq.l	#2, a0
		WATCHDOG

		; set error code based on which byte(s) were bad
		moveq	#0, d0

		cmp.b	d1, d2
		beq	.check_upper
		or.b	#1, d0

	.check_upper:
		ror.l	#8, d1
		ror.l	#8, d2
		cmp.b	d1, d2
		beq	.check_done
		or.b	#2, d0

	.check_done:
		rol.l	#8, d1
		rol.l	#8, d2
		DSUB_RETURN

; params:
;  d0 = vram start address
;  d1 = length in words
; returns:
;  d0 = 0 (pass), 1 (lower bad), 2 (upper bad), 3 (both bad)
;  a0 = fail address
;  d1 = expected value
;  d2 = actual value
check_vram_data:
		move.w	#1, (2,a6)

		subq.w	#1, d1
		move.w	d1, d5				; backup length

		lea	MEMORY_DATA_TEST_PATTERNS, a1
		moveq	#((MEMORY_DATA_TEST_PATTERNS_END - MEMORY_DATA_TEST_PATTERNS)/2 - 1), d3

	.loop_next_pattern:
		move.w	d5, d1
		move.w	d0, (-2,a6)

		move.w	(a1)+, d2

	.loop_write_next_address:
		move.w	d2, (a6)			; write pattern
		dbra	d1, .loop_write_next_address

		move.w	d0, (-2,a6)
		lea	REG_WATCHDOG, a0
		move.w	d5, d1

	.loop_read_next_address:
		move.b	d0, (a0)			; WATCHDOG
		move.w	(a6), d4			; read value
		move.w	d4, (a6)			; rewrite (to force address to increase)
		cmp.w	d2, d4
		dbne	d1, .loop_read_next_address
		bne	.test_failed

		dbra	d3, .loop_next_pattern

		moveq	#0, d0
		rts

	.test_failed:
		add.w	d5, d0				; setup error data
		sub.w	d1, d0
		swap	d0
		clr.w	d0
		swap	d0
		movea.l	d0, a0
		move.w	d2, d1
		move.w	d4, d2

		; set error code based on which byte(s) were bad
		moveq	#0, d0

		cmp.b	d1, d2
		beq	.check_upper
		or.b	#1, d0

	.check_upper:
		ror.l	#8, d1
		ror.l	#8, d2
		cmp.b	d1, d2
		beq	.check_done
		or.b	#2, d0

	.check_done:
		rol.l	#8, d1
		rol.l	#8, d2
		rts

; params:
;  a0 = address start
;  d0 = increment
;  d1 = iterations
; returns:
; d0 = 0 (pass), $ff (fail)
; d1 = expected value
; d2 = actual value
check_ram_address_dsub:
		subq.w	#1, d1
		move.w	d1, d2
		moveq	#0, d3

	.loop_write_next_address:
		move.w	d3, (a0)			; write memory locations based on increment and iterations
		add.w	#$101, d3			; each location gets $0101 more then the previous
		adda.w	d0, a0
		dbra	d2, .loop_write_next_address

		move.l	a0, d3
		and.l	#$f00000, d3			; reset the $0101 counter
		movea.l	d3, a0

		moveq	#0, d3
		bra	.loop_start_address_read

	.loop_read_next_address:
		add.w	#$101, d3
		adda.w	d0, a0
	.loop_start_address_read:
		move.w	(a0), d2			; now re-read the same locations and make they match
		cmp.w	d2, d3
		dbne	d1, .loop_read_next_address
		bne	.test_failed
		WATCHDOG
		moveq	#0, d0
		DSUB_RETURN

	.test_failed:
		move.w	d3, d1
		WATCHDOG
		moveq	#-1, d0
		DSUB_RETURN

; params:
;  d0 = modulo/incr amount
;  d1 = start vram address
;  d2 = interation amount
; returns:
;  d0 = 0 (pass) / $ff (fail)
;  a0 = address (vram)
;  d1 = expected value
;  d2 = actual value
check_vram_address:
		move.w	d0, (2,a6)
		move.w	d1, (-2,a6)
		subq.w	#1, d2
		move.w	d2, d3
		moveq	#0, d0
		move.w	#$101, d5

	.loop_write_next_address:
		move.w	d0, (a6)
		add.w	d5, d0
		dbra	d2, .loop_write_next_address

		move.w	d1, (-2,a6)
		moveq	#0, d0
		move.w	d3, d2
		lea	REG_WATCHDOG, a0
		bra	.loop_start_read_next_address

	.loop_read_next_address:
		move.b	d0, (a0)			; WATCHDOG
		add.w	d5, d0

	.loop_start_read_next_address:
		move.w	(a6), d4
		move.w	d4, (a6)
		cmp.w	d0, d4
		dbne	d2, .loop_read_next_address
		bne	.test_failed
		moveq	#0, d0
		rts

	.test_failed:
		mulu.w	(2,a6), d3			; figure out the bad address based on
		add.w	d3, d1				; modulo and start address
		mulu.w	(2,a6), d2
		sub.w	d2, d1
		swap	d1
		clr.w	d1
		swap	d1
		movea.l	d1, a0
		move.w	d0, d1
		move.w	d4, d2
		moveq	#-1, d0
		rts

MEMORY_DATA_TEST_PATTERNS:
	dc.w	$0000, $5555, $aaaa, $ffff
MEMORY_DATA_TEST_PATTERNS_END:
