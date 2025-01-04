HOST_CC = cc
VASM = vasmz80_mot
VASM_FLAGS = -Fvobj -spaces -chklabels -Iinclude -quiet
VLINK = vlink
VLINK_FLAGS = -brawbin1 -Tm1.ld
BUILD_DIR=build
OBJ_DIR=$(BUILD_DIR)/obj
WORK_DIR=$(BUILD_DIR)/work
MKDIR = mkdir
DD = dd

OBJS = $(OBJ_DIR)/crc32.o \
       $(OBJ_DIR)/error.o \
       $(OBJ_DIR)/error_address.o \
       $(OBJ_DIR)/footer.o \
       $(OBJ_DIR)/m1.o \
       $(OBJ_DIR)/util.o \
       $(OBJ_DIR)/psub.o \
       $(OBJ_DIR)/vectors.o \
       $(OBJ_DIR)/ym2610.o \
       $(OBJ_DIR)/tests/comm.o \
       $(OBJ_DIR)/tests/ram.o \
       $(OBJ_DIR)/tests/rom_bank.o \
       $(OBJ_DIR)/tests/rom_crc32.o \
       $(OBJ_DIR)/tests/rom_mirror.o \
       $(OBJ_DIR)/tests/sm1.o \
       $(OBJ_DIR)/tests/ym2610.o

INCS = $(wildcard include/*.inc) \
       $(wildcard ../common/*.inc)

$(BUILD_DIR)/m1.bin: $(WORK_DIR)/gen-crc-mirror-bank $(WORK_DIR) $(OBJS)
	$(VLINK) $(VLINK_FLAGS) -o $(BUILD_DIR)/m1.bin $(OBJS)
	$(WORK_DIR)/gen-crc-mirror-bank $(BUILD_DIR)/m1.bin

$(OBJ_DIR)/%.o: src/%.asm $(INCS)
	 $(VASM) $(VASM_FLAGS) -o $@ $<

$(WORK_DIR)/gen-crc-mirror-bank: util/gen-crc-mirror-bank.c $(WORK_DIR)
	$(HOST_CC) util/gen-crc-mirror-bank.c -o $(WORK_DIR)/gen-crc-mirror-bank

$(WORK_DIR):
	$(MKDIR) -p $(WORK_DIR) $(OBJ_DIR)/tests

clean:
	rm -rf $(BUILD_DIR)

