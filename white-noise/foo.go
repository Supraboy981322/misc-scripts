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
	//gernerate a buffer
	buf_f := gen_noise(10000000, 1.0)
	buf_b := f_to_b_buf(buf_f)

	//ffplay
	playback := exec.Command(
		"ffplay",
			"-f", "wav",
			"-i", "-")
	//ffmpeg
	audio := exec.Command(
		"ffmpeg",
      "-f", "f32le",
      "-ar", "44100",
      "-ac", "1",
			"-i", "-",
      "-af", `rubberband=pitch=0.075,volume=0.05`,
			"-f", "wav", 
			"pipe:")

	//connect audio and playback pipes to each other and terminal
	r, w := io.Pipe()//reader and writer 
	audio.Stdin, audio.Stdout, audio.Stderr = buf_b, w, os.Stderr
	playback.Stdin, playback.Stderr = r, os.Stderr

	{ //run containerization and playback 
		err1, err2 := audio.Start(), playback.Start()
		if err1 != nil || err2 != nil {
			fmt.Fprintf(
				os.Stderr,
				"failed to start:\n\taudio: %v\n\tplayback: %v\n",
				err1, err2)
			os.Exit(1)
		}
	};{ //wait for cmds to finish
		err1, err2 := audio.Wait(), playback.Wait()
		if err1 != nil || err2 != nil {
			fmt.Fprintf(
				os.Stderr,
				"Failed to run:\n\taudio: %v\n\tplayback: %v\n",
				err1, err2)
			os.Exit(1)
		}
	}
}

func gen_noise(num uint, lvl float32) []float32 {
	//create a buffer
	buf := []float32{};
	var i uint;
	//fill buffer
	for i = 0; i < num; i++ {
		ran_f := rand.Float32()
    buf = append(buf, (2.0 * ran_f - 1.0) * lvl)
  }
	return buf
}

//helper to make a byte buffer from float buffer 
func f_to_b_buf(buf_f []float32) *bytes.Buffer {
	buf := new(bytes.Buffer)
	for _, f := range buf_f { binary.Write(buf, binary.LittleEndian, f) }
	return buf
}
