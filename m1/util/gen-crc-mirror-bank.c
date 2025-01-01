#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define INPUT_SIZE        0x800       // how large the resulting file from vasm should be

#define MIRROR_OFFSET     INPUT_SIZE - 5
#define CRC32_OFFSET      INPUT_SIZE - 4

#define NUM_MIRRORS       16

#define BANK0_INCREMENT   0x0800
#define BANK1_INCREMENT   0x1000
#define BANK2_INCREMENT   0x2000
#define BANK3_INCREMENT   0x4000


uint32_t crc32_for_byte(uint32_t r) {
  for(int j = 0; j < 8; ++j)
    r = (r & 1? 0: (uint32_t)0xEDB88320L) ^ r >> 1;
  return r ^ (uint32_t)0xFF000000L;
}

void crc32(const void *data, size_t n_bytes, uint32_t* crc) {
  static uint32_t table[0x100];
  if(!*table)
    for(size_t i = 0; i < 0x100; ++i)
      table[i] = crc32_for_byte(i);
  for(size_t i = 0; i < n_bytes; ++i)
    *crc = table[(uint8_t)*crc ^ ((uint8_t*)data)[i]] ^ *crc >> 8;
}

int main(int argc, char **argv) {

  FILE *rom;
  char buffer[INPUT_SIZE];
  int i, offset;
  int bank0, bank1, bank2, bank3;
  uint32_t crc = 0;

  if(argc != 2) {
    printf("gen-crc-mirror-bank-m1 file.bin\n");
    return 1;
  }

  rom = fopen(argv[1], "r+");
  if(!rom) {
    printf("failed to open %s\n", argv[1]);
    return 1;
  }

  if(fread(buffer, sizeof(char), INPUT_SIZE, rom) != INPUT_SIZE) {
    printf("wrong input size of %s, should be %d bytes\n", argv[1], INPUT_SIZE);
    fclose(rom);
    return 1;
  }

  crc32(buffer, INPUT_SIZE - 4, &crc);
  printf("Fill in CRC32: 0x%x\n", crc);

  // write crc
  fseek(rom, CRC32_OFFSET, SEEK_SET);
  crc = htole32(crc);
  fwrite(&crc, sizeof(uint32_t), 1, rom);

  // zero out the crc location, mirrors dont get it filled in
  bzero(buffer+CRC32_OFFSET, 4);

  for(i = 1; i < NUM_MIRRORS;i++) {
    buffer[MIRROR_OFFSET] = i;
    fwrite(buffer, sizeof(char), INPUT_SIZE, rom);
  }

  offset = 0x8000;

  // start counters for each bank
  bank0 = 0x10;
  bank1 = 0x08;
  bank2 = 0x04;
  bank3 = 0x02;

  memset(buffer, 0xff, INPUT_SIZE);

  while(offset < 0x20000) {

    buffer[INPUT_SIZE - 4] = bank0;
    buffer[INPUT_SIZE - 3] = bank1;
    buffer[INPUT_SIZE - 2] = bank2;
    buffer[INPUT_SIZE - 1] = bank3;
    fwrite(buffer, sizeof(char), INPUT_SIZE, rom);

    offset += 0x800;

    if(offset % BANK0_INCREMENT == 0) {
      bank0++;
    }

    if(offset % BANK1_INCREMENT == 0) {
      bank1++;
    }

    if(offset % BANK2_INCREMENT == 0) {
      bank2++;
    }

    if(offset % BANK3_INCREMENT == 0) {
      bank3++;
    }
  }

  fclose(rom);
  return 0;
}