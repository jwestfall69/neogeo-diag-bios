HOST_CC = cc
VASM = vasmm68k_mot
VASM_FLAGS = -Fvobj -m68000 -spaces -chklabels -Iinclude -quiet
VLINK = vlink
VLINK_FLAGS = -brawbin1 -Tsp1.ld
BUILD_DIR=build
OBJ_DIR=$(BUILD_DIR)/obj
WORK_DIR=$(BUILD_DIR)/work
MKDIR = mkdir
DD = dd

OBJS = $(OBJ_DIR)/auto_tests.o \
       $(OBJ_DIR)/dsub.o \
       $(OBJ_DIR)/error_address.o \
       $(OBJ_DIR)/fix_tile_viewer.o \
       $(OBJ_DIR)/fix_util.o \
       $(OBJ_DIR)/footer.o \
       $(OBJ_DIR)/menu.o \
       $(OBJ_DIR)/memory_viewer.o \
       $(OBJ_DIR)/print_error.o \
       $(OBJ_DIR)/sp1.o \
       $(OBJ_DIR)/util.o \
       $(OBJ_DIR)/vector_table.o \
       $(OBJ_DIR)/version.o \
       $(OBJ_DIR)/menus/main.o \
       $(OBJ_DIR)/menus/memory_viewer.o \
       $(OBJ_DIR)/tests/backup_ram.o \
       $(OBJ_DIR)/tests/bios_crc32.o \
       $(OBJ_DIR)/tests/bios_mirror.o \
       $(OBJ_DIR)/tests/calendar.o \
       $(OBJ_DIR)/tests/color_bars_basic.o \
       $(OBJ_DIR)/tests/color_bars_smpte.o \
       $(OBJ_DIR)/tests/controller.o \
       $(OBJ_DIR)/tests/cpu_pal_addr.o \
       $(OBJ_DIR)/tests/memory_card.o \
       $(OBJ_DIR)/tests/memory_common.o \
       $(OBJ_DIR)/tests/misc_input.o \
       $(OBJ_DIR)/tests/mmio.o \
       $(OBJ_DIR)/tests/palette_ram.o \
       $(OBJ_DIR)/tests/prog_rom_bus.o \
       $(OBJ_DIR)/tests/video_dac.o \
       $(OBJ_DIR)/tests/video_ram_2k.o \
       $(OBJ_DIR)/tests/video_ram_32k.o \
       $(OBJ_DIR)/tests/watchdog.o \
       $(OBJ_DIR)/tests/work_ram.o \
       $(OBJ_DIR)/tests/z80.o

INCS = $(wildcard include/*.inc) \
       $(wildcard ../common/include/*.inc)

ifdef _DEBUG_BUILD_
VASM_FLAGS += -D_DEBUG_BUILD_
OBJS += $(OBJ_DIR)/debug/ec_dupe_check.o \
        $(OBJ_DIR)/debug/git_hash.o \
        $(OBJ_DIR)/menus/debug.o
endif

$(BUILD_DIR)/sp1.bin: $(WORK_DIR)/sp1.raw
	$(WORK_DIR)/gen-crc-mirror $(WORK_DIR)/sp1.raw
	$(DD) if=$(WORK_DIR)/sp1.raw of=$(BUILD_DIR)/sp1.bin conv=swab

$(WORK_DIR)/sp1.raw: $(WORK_DIR)/gen-crc-mirror $(WORK_DIR) $(OBJS)
	$(VLINK) $(VLINK_FLAGS) -o $(WORK_DIR)/sp1.raw $(OBJS)

$(OBJ_DIR)/%.o: src/%.asm $(INCS)
	 $(VASM) $(VASM_FLAGS) -o $@ $<

src/version.asm:
	../common/util/gen-version-asm-file -i ../common/src/version.asm.in -o src/version.asm

$(WORK_DIR)/gen-crc-mirror: util/gen-crc-mirror.c $(WORK_DIR)
	$(HOST_CC) util/gen-crc-mirror.c -o $(WORK_DIR)/gen-crc-mirror

$(WORK_DIR):
	$(MKDIR) -p $(WORK_DIR) $(OBJ_DIR)/debug $(OBJ_DIR)/menus $(OBJ_DIR)/tests

.PHONY: src/version.asm

clean:
	rm -rf $(BUILD_DIR)
