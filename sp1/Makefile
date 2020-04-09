HOST_CC = cc
VASM = vasmm68k_mot
VASM_FLAGS = -Fbin -m68000 -spaces -L debug/sp1.asm.txt -chklabels
ODIR = output
DD = dd

${ODIR}/sp1.bin: gen-crc-mirror sp1.asm sp1.inc macros.inc neogeo.inc
	$(VASM) $(VASM_FLAGS) -o ${ODIR}/sp1.raw sp1.asm
	./gen-crc-mirror ${ODIR}/sp1.raw
	$(DD) if=${ODIR}/sp1.raw of=${ODIR}/sp1.bin conv=swab

gen-crc-mirror: gen-crc-mirror.c
	$(HOST_CC) gen-crc-mirror.c -o gen-crc-mirror

clean:
	rm -f gen-crc-mirror ${ODIR}/sp1.raw ${ODIR}/sp1.bin debug/sp1.asm.txt

