#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define INPUT_SIZE        0x4000	// how large the resulting file from vasm should be

#define MIRROR_OFFSET     INPUT_SIZE - 5
#define CRC32_OFFSET      INPUT_SIZE - 4

#define NUM_MIRRORS       8

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
  int i;
  uint32_t crc = 0;

  if(argc != 2) {
    printf("gen-crc-mirror file.bin\n");
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

  crc32(buffer, INPUT_SIZE - 5, &crc);
  printf("Fill in CRC: 0x%x\n", crc);

  // write crc
  fseek(rom, CRC32_OFFSET, SEEK_SET);
  crc = htobe32(crc);
  fwrite(&crc, sizeof(uint32_t), 1, rom);

  // zero out the crc location, mirrors dont get it filled in
  bzero(buffer+CRC32_OFFSET, 4);

  for(i = 1; i < NUM_MIRRORS;i++) {
    buffer[MIRROR_OFFSET] = i;
    fwrite(buffer, sizeof(char), INPUT_SIZE, rom);
  }

  fclose(rom);
  return 0;
}