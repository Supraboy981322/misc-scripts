package main

import (
  "os"
	"fmt"
  "sync"
	"sync/atomic"
)

var stuff = struct {
	human_readable bool
	dir string
} {
	human_readable: true,
	dir: ".",
}

func main() {
	var c atomic.Int64
	var wg sync.WaitGroup
	wg.Add(1)
	go fork(&c, &wg, stuff.dir)
  wg.Wait()
	raw_size := c.Load()
	var final_size string
	if (stuff.human_readable) {
		si := float64(raw_size)
		exts := []string{ "B", "KB", "MB", "GB", "TB", "PB", "EB", "YB" }
		i := 0;
		for si > 1000.0 { si /= 1000.0 ; i++ }
		final_size = fmt.Sprintf("%.2f%s", si, exts[i])
	} else { final_size = fmt.Sprintf("%d", raw_size) }
	print(final_size)
}

func fork(c *atomic.Int64, wg *sync.WaitGroup, path string) {
  defer wg.Done()
	files, e := os.ReadDir(path)
	if e != nil { err_out(e) ; return }
	loop: for _, file := range files {
		if file.IsDir() {
			wg.Add(1)
			go fork(c, wg, path+"/"+file.Name())
		} else {
			i, e := file.Info()
			if e != nil { err_out(e) ; continue loop }
			c.Add(i.Size())
		}
	}
}

func err_out(e error) {
	print(e.Error()+"\n")
	os.Exit(1)
}
