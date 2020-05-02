HOST_CC = cc
VASM = vasmm68k_mot
VASM_FLAGS = -Fbin -m68000 -spaces -L debug/sp1.asm.txt -chklabels
ODIR = output
MKDIR = mkdir
DD = dd
MD5SUM = md5sum
EXPECTED_MD5 = f1490183904e577d51a8f7489dcaea84

${ODIR}/sp1.bin: gen-crc-mirror sp1.asm sp1.inc macros.inc neogeo.inc ${ODIR}
	${VASM} ${VASM_FLAGS} -o ${ODIR}/sp1.raw sp1.asm
	./gen-crc-mirror ${ODIR}/sp1.raw
	${DD} if=${ODIR}/sp1.raw of=${ODIR}/sp1.bin conv=swab
	@echo "Verifying MD5 (${EXPECTED_MD5})"
	@echo ${EXPECTED_MD5} ${ODIR}/sp1.bin | ${MD5SUM} -c

gen-crc-mirror: gen-crc-mirror.c
	${HOST_CC} gen-crc-mirror.c -o gen-crc-mirror

${ODIR}:
	${MKDIR} ${ODIR} debug

clean:
	rm -f gen-crc-mirror ${ODIR}/sp1.raw ${ODIR}/sp1.bin debug/sp1.asm.txt

