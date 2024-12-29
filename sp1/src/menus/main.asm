	include "diag.inc"
	include "macros.inc"
	include "menu.inc"

	global main_menu

	section code

main_menu:
		move.b	#0, r_menu_cursor

		moveq	#-$10, d0
		bsr	wait_p1_input
		bsr	wait_frame

	.loop_menu:
		SSA3	fix_clear

		lea	d_xys_menu_title, a0
		RSUB	print_xys_string

		lea	d_menu_list, a0
		jsr	menu

		cmp.b	#MENU_EXIT, d0
		beq	main_menu
		bra	.loop_menu

	section data
	align 1

d_menu_list:
	MENU_ENTRY manual_calendar_tests, d_str_calendar_io, 1
	MENU_ENTRY manual_color_bars_basic_test, d_str_color_bars_basic, 0
	MENU_ENTRY manual_color_bars_smpte_test, d_str_color_bars_smpte, 0
	MENU_ENTRY manual_video_dac_tests, d_str_video_dac_tests, 0
	MENU_ENTRY manual_controller_tests, d_str_controller_tests, 0
	MENU_ENTRY manual_work_ram_tests, d_str_work_ram_test_loop, 0
	MENU_ENTRY manual_backup_ram_tests, d_str_backup_ram_tests, 1
	MENU_ENTRY manual_palette_ram_tests, d_str_pal_ram_tests, 0
	MENU_ENTRY manual_video_ram_32k_tests, d_str_vram_32k_tests, 0
	MENU_ENTRY manual_video_ram_2k_tests, d_str_vram_2k_tests, 0
	MENU_ENTRY manual_misc_input_tests, d_str_misc_input_test, 0
	MENU_ENTRY manual_cpu_pal_addr_test, d_str_cpu_pal_addr_test, 0
	MENU_ENTRY manual_memcard_tests, d_str_memcard_tests, 0
	MENU_ENTRY manual_prog_rom_bus_tests, d_str_prog_rom_bus_tests, 0
	MENU_ENTRY memory_viewer_menu, d_str_memory_viewer, 0
	MENU_ENTRY fix_tile_viewer, d_str_fix_tile_viewer, 0
	MENU_LIST_END

d_xys_menu_title:		XY_STRING LEFT_MARGIN, 5, "MAIN MENU"

d_str_backup_ram_tests:		STRING "BACKUP RAM TESTS (MVS ONLY)"
d_str_calendar_io:		STRING "CALENDAR I/O (MVS ONLY)"
d_str_color_bars_basic:		STRING "COLOR BARS BASIC"
d_str_color_bars_smpte:		STRING "COLOR BARS SMPTE"
d_str_controller_tests:		STRING "CONTROLLER TESTS"
d_str_cpu_pal_addr_test:	STRING "CPU/PAL ADDR TEST"
d_str_fix_tile_viewer:		STRING "FIX TILE VIEWER"
d_str_memcard_tests:		STRING "MEMORY CARD TESTS"
d_str_memory_viewer:		STRING "MEMORY VIEWER"
d_str_misc_input_test:		STRING "MISC. INPUT TEST"
d_str_pal_ram_tests:		STRING "PALETTE RAM TESTS"
d_str_prog_rom_bus_tests:	STRING "PROG ROM BUS TESTS (CUSTOM CART)"
d_str_video_dac_tests:		STRING "VIDEO DAC TESTS"
d_str_vram_2k_tests:		STRING "VRAM 2K TESTS"
d_str_vram_32k_tests:		STRING "VRAM 32K TESTS"
d_str_work_ram_test_loop:	STRING "WORK RAM TEST LOOP"
