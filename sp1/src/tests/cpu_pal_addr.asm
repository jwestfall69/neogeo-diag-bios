	include "diag.inc"
	include "neogeo.inc"
	include "macros.inc"

	global cpu_pal_addr_test

	section code

cpu_pal_addr_test:

		lea	d_xys_screen_list, a0
		RSUB	print_xys_string_clear_list

		lea	d_xys_d_main_menu, a0
		RSUB	print_xys_string_clear

		lea	PALETTE_RAM_START + $aa, a0
		moveq	#0, d1

	.loop_run_test:
		WATCHDOG

		move.l	#$ff4, d0
		RSUB	delay

		addq.w	#1, d1
		move.w	d1, (a0)

		btst	#INPUT_D_BIT, REG_P1CNT
		bne	.loop_run_test

		rts

	section data

d_xys_screen_list:
	XY_STRING LEFT_MARGIN, 13, "THIS SCREEN SHOULD REMAIN WHITE"
	XY_STRING LEFT_MARGIN, 15, "TEXT ON BLACK BACKGROUND, WITH"
	XY_STRING LEFT_MARGIN, 17, "COLORED SCROLLING DOTS"
	XY_STRING_LIST_END
