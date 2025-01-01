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

OBJS = $(OBJ_DIR)/m1.o

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
	$(MKDIR) -p $(WORK_DIR) $(OBJ_DIR)

clean:
	rm -rf $(BUILD_DIR)

