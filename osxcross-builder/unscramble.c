//
//  main.c
//  pbzx
//
//  Created by PHPdev32 on 6/20/14.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#include <fcntl.h>
#include <lzma.h>
#include <math.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define err(m, e)                                                              \
  {                                                                            \
    fprintf(stderr, m "\n");                                                   \
    return e;                                                                  \
  }
#define read_f(dst, src, len)                                                  \
  memmove(&dst, src.file + src.offset, len);                                   \
  src.offset += len
#define fswap64(f, s)                                                          \
  read_f(s, f, 8);                                                             \
  s = __builtin_bswap64(s)
#define BSIZE 8192 // 8 * 1024

struct memfile {
  void *file;
  size_t offset;
};

int lzma_write(lzma_stream *lzma_stream, int out_fd) {
  lzma_ret ret = LZMA_OK;
  size_t len = 0;
  int status = 0;
  uint8_t *decoded = (uint8_t*)calloc(1048576, 1); // 1 MB
  lzma_stream->next_out = decoded;
  lzma_stream->avail_out = 1048576;
  ret = lzma_stream_decoder(lzma_stream, UINT64_MAX, 0);
  if (ret != LZMA_OK) {
    fprintf(stderr,
            "liblzma decoder returned error during initialization: %u\n", ret);
    status = -1;
    goto clean;
  }
  ret = lzma_code(lzma_stream, LZMA_FINISH);
  while (1) {
    if (ret != LZMA_OK) {
      if (ret == LZMA_STREAM_END) {
        len = 1048576 - lzma_stream->avail_out;
        write(out_fd, decoded, len);
        goto clean;
      }
      fprintf(stderr, "LZMA error: %u\n", ret);
      status = -1;
      goto clean;
    }
    write(out_fd, decoded, 1048576);
    memset(decoded, 0, 1048576);
    lzma_stream->next_out = decoded;
    lzma_stream->avail_out = 1048576;
    ret = lzma_code(lzma_stream, LZMA_FINISH);
  }
  // end of lzma_write

clean:
  if (decoded) {
    free(decoded);
  }
  return status;
}

int decode(void *input, int out_fd, size_t in_size, size_t in_offset) {
  uint64_t length = 0, flags = 0;
  struct memfile memfile = {.file = input, .offset = in_offset};
  int status = 0;
  // initialize lzma decoder
  lzma_stream lzma_stream = LZMA_STREAM_INIT;
  lzma_stream.next_in = NULL;
  lzma_stream.avail_in = 0;
  lzma_stream.next_out = NULL;
  lzma_stream.avail_out = 0;


  fswap64(memfile, flags);
  while (flags & (1 << 24)) {
    fswap64(memfile, flags);
    fswap64(memfile, length);
    printf("\r%lu...", memfile.offset * 100 / in_size);
    fflush(stdout);
    if (length == 0x1000000) {
      write(out_fd, input + memfile.offset, length);
    } else {
      if (memcmp(input + memfile.offset, "\xfd\x37\x7a\x58\x5a\x00", 6) == 0) {
        lzma_stream.next_in = input + memfile.offset;
        lzma_stream.avail_in = length;
        status = lzma_write(&lzma_stream, out_fd);
        if (status != 0) {
          fprintf(stderr, "LZMA error\n");
          goto cleanup;
        }
      } else {
        printf("Unknown section of data at %lu\n", memfile.offset);
        status = -1;
        goto cleanup;
      }
    }
    memfile.offset += length;
  }

  // end of decoder routine
cleanup:
  lzma_end(&lzma_stream);
  return status;
}

int main(int argc, char const *argv[]) {
  if (argc < 3) {
    fprintf(stderr,
            "Usage: %s <input file> <output file>\nNote: Only works with "
            "regular files, does not support pipes\n",
            argv[0]);
    return 1;
  }
  struct stat sb;
  void *input_file = NULL;
  size_t fsize, in_offset = 0;
  int status = 0;
  int in_fd = open(argv[1], O_RDONLY);
  int out_fd = -1;
  if (in_fd == -1) {
    perror("Unable to open input file");
    return 1;
  }
  if (fstat(in_fd, &sb) == -1) {
    perror("Unable to stat input file");
    return 1;
  }
  fsize = sb.st_size;
  input_file = mmap(0, sb.st_size, PROT_READ, MAP_SHARED, in_fd, 0);
  if (input_file == MAP_FAILED) {
    perror("Unable to map file into the memory");
    return 1;
  }

  if (memcmp(input_file, "pbzx", 4) != 0) {
    fprintf(stderr, "The file is not a pbzx file\n");
    status = 1;
    goto cleanup_and_exit;
  }
  out_fd = open(argv[2], O_RDWR | O_CREAT);
  if (out_fd == -1) {
    perror("Unable to open output file");
    return 1;
  }
  in_offset += 4;
  decode(input_file, out_fd, fsize, in_offset);
  // end of main
cleanup_and_exit:
  // input_file -= in_offset;
  munmap(input_file, fsize);
  close(in_fd);
  close(out_fd);
  chmod(argv[2], S_IRWXU|S_IRWXG|S_IROTH|S_IWOTH);
  return status;
}
