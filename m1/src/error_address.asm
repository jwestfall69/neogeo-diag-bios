	include "diag.inc"
	include "macros.inc"

	global error_address

	section code

; params
;  a = error code
; The z80 uses A0 to A6 for memory refreshing so they will always
; be pulsing.  This leaves us with 6 useable address lines (A7 to A12)
; to communicate the error code to the user.
error_address:
		and	$3f		; error codes can only be 6 bits

		ld	hl, $0		; make the error code be bits 7 to 12 of hl
		ld	h, a
		srl	h
		rr	l

		ld	bc, ERROR_ADDRESS_BASE
		add	hl, bc

		; The top bit of the R register is used for PSUB nesting.  We need
		; to make sure its 0 or it will make address line a7 participate
		; in the z80's dram refresh logic. This would cause a conflict for
		; us since we use A7 for error address.
		ld	a, r
		and	a, $7f
		ld	r, a

		jp	(hl)

		; NOTE: the opcodes for error addresses are injected in the rom
		; at the proper locations by gen-crc-mirror-bank.
