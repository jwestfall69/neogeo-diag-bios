HOST_CC = cc
VASM = vasmz80_mot
VASM_FLAGS = -Fbin -spaces -L debug/m1.asm.txt -chklabels
ODIR = output

${ODIR}/m1.bin: gen-crc-mirror-bank m1.asm m1.inc macros.inc neogeo.inc
	$(VASM) $(VASM_FLAGS) -o ${ODIR}/m1.bin m1.asm
	./gen-crc-mirror-bank ${ODIR}/m1.bin

gen-crc-mirror-bank: gen-crc-mirror-bank.c
	$(HOST_CC) gen-crc-mirror-bank.c -o gen-crc-mirror-bank

clean:
	rm -f gen-crc-mirror-bank ${ODIR}/m1.bin debug/m1.asm.txt

