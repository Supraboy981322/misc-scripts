#include <stdio.h>
#include <stdlib.h>
#include <time.h>

typedef unsigned int uint;

void gen_noise(float* buf, uint num, float lvl) {
  srand(time(NULL));
  for (uint i = 0; i < num; i++) {
    int ran_i = rand();
    float ran_f = (float)ran_i / (float)RAND_MAX;
    buf[i] = (2.0f * ran_f - 1.0f) * lvl;
  }
}

int main(void) {
  while (1) {
    float buf[44100];
    uint num = 44100;
    float lvl = 1.0;
    gen_noise(buf, num, lvl);
    char cmd[512];
    snprintf(
      cmd, sizeof(cmd),
      "ffmpeg -hide_banner %s %s %s -i - %s -",
        "-f f32le",
        "-ar 44100",
        "-ac 1",
        "-af \"rubberband=pitch=0.075,volume=0.05\"");
    FILE *fp = popen(cmd, "w");
    if (!fp) {
      perror("failed to open cmd");
      return 1;
    }

    size_t writ = fwrite(buf, sizeof(buf)[0], num, stdout);
    if (writ != num) { 
      perror("failed to write to stdout");
      return 1;
    }
    fflush(stdout);
  }
  return 0;
}
