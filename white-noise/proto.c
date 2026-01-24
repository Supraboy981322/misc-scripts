#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

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
  float buf[10000000];
  uint num = 10000000;
  float lvl = 1.0;
  gen_noise(buf, num, lvl);
  char cmd[512];
  snprintf(
    cmd, sizeof(cmd),
    "ffmpeg %s %s %s -i - %s foo.wav",
      "-f f32le",
      "-ar 44100",
      "-ac 1",
      "-af \"rubberband=pitch=0.075,volume=0.05\"");
  FILE *pipe = popen(cmd, "w");
  if (!pipe) {
    perror("failed to open cmd");
    return 1;
  }

  fwrite(buf, 1, num, pipe);
  pclose(pipe);
}
