	include "neogeo.inc"
	include "macros.inc"
	include "sp1.inc"

	global manual_cpu_pal_addr_test
	global STR_CPU_PAL_ADDR_TEST

	section text

manual_cpu_pal_addr_test:

		lea	XY_STR_CPU_PAL_LINE1, a0
		RSUB	print_xy_string_struct_clear
		lea	XY_STR_CPU_PAL_LINE2, a0
		RSUB	print_xy_string_struct_clear
		lea	XY_STR_CPU_PAL_LINE3, a0
		RSUB	print_xy_string_struct_clear
		lea	XY_STR_D_MAIN_MENU, a0
		RSUB	print_xy_string_struct_clear


		lea	PALETTE_RAM_START + $aa, a0
		moveq	#0, d1

	.loop_run_test:
		WATCHDOG

		move.l	#$ff4, d0
		RSUB	delay

		addq.w	#1, d1
		move.w  d1, (a0)

		btst	#D_BUTTON, REG_P1CNT
		bne	.loop_run_test

		rts


XY_STR_CPU_PAL_LINE1:		XY_STRING  4, 13, "THIS SCREEN SHOULD REMAIN WHITE"
XY_STR_CPU_PAL_LINE2:		XY_STRING  4, 15, "TEXT ON BLACK BACKGROUND, WITH"
XY_STR_CPU_PAL_LINE3:		XY_STRING  4, 17, "COLORED SCROLLING DOTS"

STR_CPU_PAL_ADDR_TEST:		STRING "CPU/PAL ADDR TEST"


