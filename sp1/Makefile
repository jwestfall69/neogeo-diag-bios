OBJS = obj/backup_ram.o \
       obj/bios_crc32.o \
       obj/bios_mirror.o \
       obj/calendar.o \
       obj/color_bars_basic.o \
       obj/color_bars_smpte.o \
       obj/controller.o \
       obj/dsub.o \
       obj/fix_util.o \
       obj/footer.o \
       obj/memory_card.o \
       obj/memory_common.o \
       obj/misc_input.o \
       obj/mmio.o \
       obj/palette_ram.o \
       obj/print_error.o \
       obj/sp1.o \
       obj/util.o \
       obj/vector_table.o \
       obj/video_dac.o \
       obj/video_ram_2k.o \
       obj/video_ram_32k.o \
       obj/work_ram.o \

INCS = include/macros.inc \
       include/neogeo.inc \
       include/sp1.inc \
       ../common/error_codes.inc \
       ../common/comm.inc

HOST_CC = cc
VASM = vasmm68k_mot
VASM_FLAGS = -Fvobj -m68000 -spaces -chklabels -Iinclude -quiet
VLINK = vlink
VLINK_FLAGS = -brawbin1 -Tsp1.ld
OUTPUT_DIR = output
OBJ_DIR = obj
MKDIR = mkdir
DD = dd

$(OUTPUT_DIR)/sp1.bin: $(OUTPUT_DIR)/sp1.raw
	./gen-crc-mirror $(OUTPUT_DIR)/sp1.raw
	$(DD) if=$(OUTPUT_DIR)/sp1.raw of=$(OUTPUT_DIR)/sp1.bin conv=swab

$(OUTPUT_DIR)/sp1.raw: gen-crc-mirror $(OUTPUT_DIR) $(OBJ_DIR) $(OBJS)
	$(VLINK) $(VLINK_FLAGS) -o $(OUTPUT_DIR)/sp1.raw $(OBJS)

$(OBJ_DIR)/%.o: %.asm $(INCS)
	 $(VASM) $(VASM_FLAGS) -o $@ $<

gen-crc-mirror: gen-crc-mirror.c
	$(HOST_CC) gen-crc-mirror.c -o gen-crc-mirror

$(OUTPUT_DIR):
	$(MKDIR) $(OUTPUT_DIR)

$(OBJ_DIR):
	$(MKDIR) $(OBJ_DIR)

clean:
	rm -f gen-crc-mirror $(OUTPUT_DIR)/sp1.raw $(OUTPUT_DIR)/sp1.bin obj/*.o

