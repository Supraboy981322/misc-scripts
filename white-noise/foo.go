package main

import (
	"io"
	"os"
	"bytes"
//	"bufio"
	"os/exec"
	"encoding/binary"
	"math/rand/v2"
)

func main() {
	buf_f := gen_noise(10000000, 1.0)
	buf_b := f_to_b_buf(buf_f)
	playback := exec.Command("ffplay", "-f", "wav", "-i", "-")
	audio := exec.Command(
		"ffmpeg",
      "-f", "f32le",
      "-ar", "44100",
      "-ac", "1",
			"-i", "-",
      "-af", `rubberband=pitch=0.075,volume=0.05`,
			"-f", "wav", 
			"pipe:");
	audio.Stdin = buf_b
	r, w := io.Pipe()
	audio.Stdout = w
	playback.Stdin = r
	audio.Stderr = os.Stderr
	playback.Stderr = os.Stderr
	err := audio.Start()
	if err != nil { print(err.Error) ; os.Exit(1) }
	err = playback.Run()
	if err != nil { print(err.Error) ; os.Exit(1) }
	err = playback.Wait()
	if err != nil { print(err.Error) ; os.Exit(1) }
	err = audio.Wait()
	if err != nil { print(err.Error) ; os.Exit(1) }
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
