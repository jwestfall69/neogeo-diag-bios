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
		moveq	#0, d3

	.loop_run_test:
		WATCHDOG
		addq	#1, d3
		and	#$ffff,d3
		move.w  d3, (a0)

		bsr	p1_input_update
		btst	#D_BUTTON, p1_input_edge
		beq	.loop_run_test

		rts


XY_STR_CPU_PAL_LINE1:		XY_STRING  4, 13, "THIS SCREEN SHOULD REMAIN WHITE"
XY_STR_CPU_PAL_LINE2:		XY_STRING  4, 15, "TEXT ON BLACK BACKGROUND, WITH"
XY_STR_CPU_PAL_LINE3:		XY_STRING  4, 17, "COLORED SCROLLING DOTS"

STR_CPU_PAL_ADDR_TEST:		STRING "CPU/PAL ADDR TEST"


