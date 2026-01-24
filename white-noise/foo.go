package main

import (
	"io"
	"os"
	"fmt"
	"bytes"
	"os/exec"
	"encoding/binary"
	"math/rand/v2"
)

func main() {
	buf_f := gen_noise(10000000, 1.0)
	buf_b := f_to_b_buf(buf_f)

	playback := exec.Command(
		"ffplay",
			"-f", "wav",
			"-i", "-")
	audio := exec.Command(
		"ffmpeg",
      "-f", "f32le",
      "-ar", "44100",
      "-ac", "1",
			"-i", "-",
      "-af", `rubberband=pitch=0.075,volume=0.05`,
			"-f", "wav", 
			"pipe:")

	r, w := io.Pipe()
	audio.Stdin, audio.Stdout, audio.Stderr = buf_b, w, os.Stderr
	playback.Stdin, playback.Stderr = r, os.Stderr
	
	if err1, err2 := audio.Start(), playback.Start(); err1 != nil || err2 != nil {
		fmt.Fprintf(
			os.Stderr,
			"failed to start:\n\taudio: %v\n\tplayback: %v\n",
			err1, err2)
		os.Exit(1)
	}

	if err1, err2 := audio.Wait(), playback.Wait(); err1 != nil || err2 != nil {
		fmt.Fprintf(
			os.Stderr,
			"Failed to run:\n\taudio: %v\n\tplayback: %v\n",
			err1, err2)
		os.Exit(1)
	}
}

func gen_noise(num uint, lvl float32) []float32 {
	buf := []float32{};
	var i uint;
	for i = 0; i < num; i++ {
		ran_f := rand.Float32()
    buf = append(buf, (2.0 * ran_f - 1.0) * lvl)
  }
	return buf
}

func f_to_b_buf(buf_f []float32) *bytes.Buffer {
	buf := new(bytes.Buffer)
	for _, f := range buf_f { binary.Write(buf, binary.LittleEndian, f) }
	return buf
}
