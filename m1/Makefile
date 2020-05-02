HOST_CC = cc
VASM = vasmz80_mot
VASM_FLAGS = -Fbin -spaces -L debug/m1.asm.txt -chklabels
ODIR = output
MKDIR = mkdir
MD5SUM = md5sum
EXPECTED_MD5 = 65f3b01165ad1e9ee1b4fa5722a9df57

${ODIR}/m1.bin: gen-crc-mirror-bank m1.asm m1.inc macros.inc neogeo.inc ${ODIR}
	${VASM} ${VASM_FLAGS} -o ${ODIR}/m1.bin m1.asm
	./gen-crc-mirror-bank ${ODIR}/m1.bin
	@echo "Verifying MD5 (${EXPECTED_MD5})"
	@echo ${EXPECTED_MD5} ${ODIR}/m1.bin | ${MD5SUM} -c

gen-crc-mirror-bank: gen-crc-mirror-bank.c
	${HOST_CC} gen-crc-mirror-bank.c -o gen-crc-mirror-bank

${ODIR}:
	${MKDIR} ${ODIR} debug

clean:
	rm -f gen-crc-mirror-bank ${ODIR}/m1.bin debug/m1.asm.txt

