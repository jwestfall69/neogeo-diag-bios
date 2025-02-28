	include "diag.inc"
	include "macros.inc"
	include "neogeo.inc"
	include "print_error.inc"

	global git_hash

	section code

git_hash:

		RSUB	print_header

		lea	d_xys_d_main_menu, a0
		RSUB	print_xys_string_clear

		lea	d_str_git_hash, a0
		moveq	#LEFT_MARGIN, d0
		moveq	#$7, d1
		RSUB	print_xy_string

	.loop_input:
		WATCHDOG
		btst	#INPUT_D_BIT, REG_P1CNT
		bne	.loop_input
		rts
