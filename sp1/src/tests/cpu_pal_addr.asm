	include "neogeo.inc"
	include "macros.inc"
	include "diag.inc"

	global manual_cpu_pal_addr_test

	section code

manual_cpu_pal_addr_test:

		lea	d_xys_cpu_pal_line1, a0
		RSUB	print_xys_string_clear
		lea	d_xys_cpu_pal_line2, a0
		RSUB	print_xys_string_clear
		lea	d_xys_cpu_pal_line3, a0
		RSUB	print_xys_string_clear
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

		btst	#D_BUTTON, REG_P1CNT
		bne	.loop_run_test

		rts

	section data

d_xys_cpu_pal_line1:		XY_STRING  4, 13, "THIS SCREEN SHOULD REMAIN WHITE"
d_xys_cpu_pal_line2:		XY_STRING  4, 15, "TEXT ON BLACK BACKGROUND, WITH"
d_xys_cpu_pal_line3:		XY_STRING  4, 17, "COLORED SCROLLING DOTS"
