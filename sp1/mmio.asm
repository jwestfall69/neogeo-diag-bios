	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"
	include "../common/error_codes.inc"

	global auto_mmio_tests

	section text

auto_mmio_tests:
		bsr	check_mmio_oe
		bne	.test_failed_abort
		bsr	check_mmio_reg_vramrw_oe

	.test_failed_abort:
		rts

; does OE test against all the registers in the
; MMIO_ADDRESSES_TABLE_START table
check_mmio_oe:
		lea	MMIO_ADDRESSES_TABLE_START, a1
		moveq	#((MMIO_ADDRESSES_TABLE_END - MMIO_ADDRESSES_TABLE_START)/4 - 1), d6

	.loop_next_test:
		movea.l	(a1)+, a0
		move.w	a0, d0

		lsr.b	#1, d0
		bcc	.system_both

		tst.b	REG_STATUS_B			; skip registers with bit 1 set on AES systems
		bpl	.system_aes

	.system_both:
		bsr	check_mmio_oe_byte
		beq	.test_failed

	.system_aes:
		dbra	d6, .loop_next_test

		moveq	#0, d0
		rts

	.test_failed:
		moveq	#EC_MMIO_DEAD_OUTPUT, d0
		rts


check_mmio_reg_vramrw_oe:
		movea.l	a6, a0
		bsr	check_mmio_oe_word
		beq	.test_failed

		moveq	#0, d0
		rts

	.test_failed:
		moveq	#EC_MMIO_DEAD_OUTPUT, d0
		rts

; check for output enable of a byte at a0
; params:
;  a0 = address
check_mmio_oe_byte:
		moveq	#-1, d0
		move.w	a0, d0
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
		rts

; check for output enable of a word at a0
; params:
;  a0 = address
check_mmio_oe_word:
		moveq	#$31, d2

	.loop_test_again:
		move.w	(a0), d1
		cmp.w	*(PC), d1
		bne	.test_passed

		move.w	(a0), d1
		nop
		cmp.w	*-2(PC), d1
		bne	.test_passed

		move.w	(a0), d1
		add.w	#0, d0
		cmp.w	*-4(PC), d1
	.test_passed:
		dbeq	d2, .loop_test_again
		rts

MMIO_ADDRESSES_TABLE_START:
	dc.l REG_DIPSW
	dc.l REG_SYSTYPE
	dc.l REG_STATUS_A
	dc.l REG_P1CNT
	dc.l REG_SOUND
	dc.l REG_P2CNT
	dc.l REG_STATUS_B
MMIO_ADDRESSES_TABLE_END:
