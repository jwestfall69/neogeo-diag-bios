	global psub_enter
	global psub_exit

	section code

; pseudo subroutines are blocks of code that are not dependent on the
; stack for figuring out where to return to.  Instead the return
; address is stored in ix or iy.  One level if nesting is supported.

; psub_enter requires 2 registers to be setup
;  de = return address
;  hl = psub being jumped to
; This should is all handled by using the PSUB <psub> macro.
;
; NOTE: the psub macro will do an exx before setting up the de and hl
; registers.  A psub code block will need to do a exx in order to access
; the original de, hl and bc register values
psub_enter:
		; We are using the unused high bit of the 'r' register
		; to determine if we are nested or not
		ld	a, r
		add	a, $80
		ld	r, a
		jp	p, .nested_call
		ld	ix, $0000
		add	ix, de
		jp	(hl)

	.nested_call:
		ld	iy, $0000
		add	iy, de
		jp	(hl)

; At the end of a psub the block of code it should call PSUB_RETURN. This
; will jump to the below code, which determines the register (ix or iy) to
; use to jump back code that called the psub
psub_exit:
		; make sure we dont clobber a or flags
		ex	af, af'
		ld	a, r
		add	a, $80
		ld	r, a
		jp	m, .nested_return
		ex	af, af'
		jp	(ix)

	.nested_return:
		ex	af, af'
		jp	(iy)
