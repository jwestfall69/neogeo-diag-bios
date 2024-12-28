	include "diag.inc"
	include "macros.inc"
	include "menu.inc"
	include "neogeo.inc"

	global memory_viewer_menu

	section code

memory_viewer_menu:

		move.b	#0, r_menu_cursor

		moveq	#-$10, d0
		bsr	wait_p1_input
		bsr	wait_frame

	.loop_menu:
		lea	d_xys_menu_title, a0
		RSUB	print_xys_string

		lea	d_menu_list, a0
		jsr	menu

		cmp.b	#MENU_CONTINUE, d0
		beq	.loop_menu
		rts

view_backup_ram:
		lea	BACKUP_RAM_START, a0
		bra	view_memory

view_bios:
		lea	BIOS_ROM_START, a0
		bra	view_memory

view_fixmap:
		lea	FIXMAP_START, a0
		bra	view_video_memory

view_memory_card:
		lea	MEMCARD_START, a0
		bra	view_memory

view_mmio_30:
		lea	$300000, a0
		bra	view_memory

view_mmio_38:
		lea	$380000, a0
		bra	view_memory

view_mmio_3a:
		lea	$3a0000, a0
		bra	view_memory

view_mmio_3c:
		lea	$3c0000, a0
		bra	view_memory

view_palette_ram:
		lea	PALETTE_RAM_START, a0
		bra	view_memory

view_prog_p1:
		lea	P1_ROM_START, a0
		bra	view_memory

view_prog_p2:
		lea	P2_ROM_START, a0
		bra	view_memory

view_vram_32k:
		lea	$0, a0
		bra	view_video_memory

view_vram_2k:
		lea	$8000, a0
		bra	view_video_memory

view_work_ram:
		lea	WORK_RAM_START, a0
		bra	view_memory

view_memory:
		moveq	#0, d0
		jsr	memory_viewer
		rts

view_video_memory:
		moveq	#1, d0
		jsr	memory_viewer
		rts

	section data
	align 1

d_menu_list:
	MENU_ENTRY view_backup_ram, d_str_backup_ram, 1
	MENU_ENTRY view_bios, d_str_bios, 0
	MENU_ENTRY view_fixmap, d_str_fixmap, 0
	MENU_ENTRY view_memory_card, d_str_memory_card, 0
	MENU_ENTRY view_mmio_30, d_str_mmio_30, 0
	MENU_ENTRY view_mmio_38, d_str_mmio_38, 0
	MENU_ENTRY view_mmio_3a, d_str_mmio_3a, 0
	MENU_ENTRY view_mmio_3c, d_str_mmio_3c, 0
	MENU_ENTRY view_palette_ram, d_str_palette_ram, 0
	MENU_ENTRY view_prog_p1, d_str_prog_p1, 0
	MENU_ENTRY view_prog_p2, d_str_prog_p2, 0
	MENU_ENTRY view_vram_2k, d_str_vram_2k, 0
	MENU_ENTRY view_vram_32k, d_str_vram_32k, 0
	MENU_ENTRY view_work_ram, d_str_work_ram, 0
	MENU_LIST_END

d_xys_menu_title:		XY_STRING LEFT_MARGIN, 5, "MEMORY VIEWER MENU"

d_str_backup_ram:		STRING "BACKUP RAM"
d_str_bios:			STRING "BIOS"
d_str_fixmap:			STRING "FIXMAP"
d_str_memory_card:		STRING "MEMORY CARD"
d_str_mmio_30:			STRING "MMIO 300000"
d_str_mmio_38:			STRING "MMIO 380000"
d_str_mmio_3a:			STRING "MMIO 3A0000"
d_str_mmio_3c:			STRING "MMIO 3C0000"
d_str_palette_ram:		STRING "PALETTE RAM"
d_str_prog_p1:			STRING "PROG P1 ROM"
d_str_prog_p2:			STRING "PROG P2 ROM"
d_str_vram_2k:			STRING "VRAM 2K"
d_str_vram_32k:			STRING "VRAM 32K"
d_str_work_ram:			STRING "WORK RAM"
