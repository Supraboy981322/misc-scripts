package main

import (
  "os"
	"fmt"
  "sync"
	"errors"
	"sync/atomic"
)

var stuff = struct {
	human_readable bool
	dir string
} {
	human_readable: false,
	dir: ".",
}

var (
	quiet bool
	c atomic.Int64
	wg sync.WaitGroup
	print_help bool
	spawned_early bool
	verbosity bool
	total_routines atomic.Int64
)

func main() {
	if !spawned_early {
		wg.Add(1)
		if (verbosity) { total_routines.Add(1) }
		go fork(&c, &wg, stuff.dir)
	}
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
	fmt.Printf("%s\n", final_size)

	if (verbosity) {
		fmt.Printf("total forks spawned %d\n", total_routines.Load());
	}
}

func fork(c *atomic.Int64, wg *sync.WaitGroup, path string) {
  defer wg.Done()
	files, e := os.ReadDir(path)
	if e != nil { err_out(e) ; return }
	loop: for _, file := range files {
		i, e := file.Info()
		if e != nil { err_out(e) ; continue loop }
		m := i.Mode()
		if m.IsDir() {
			wg.Add(1)
			if (verbosity) { total_routines.Add(1) }
			go fork(c, wg, path+"/"+file.Name())
		} else if m.IsRegular() {
			c.Add(i.Size())
		}
	}
}

func init() {
	args := os.Args[1:]
	loop: for _, a := range args {
		was_print_help := print_help
		was_human_readable := stuff.human_readable
		if len(a) > 1 {
			if Args.check(a) { goto spawn }
			continue loop
		}
		spawn: {
			print_help = was_print_help
			stuff.human_readable = was_human_readable
			spawned_early = true
			wg.Add(1)
			if (verbosity) { total_routines.Add(1) }
			go fork(&c, &wg, a)
			continue loop
		}
	}
	if print_help {
		help()
		os.Exit(0)
	}

	//happens, for some reason (despite being checked earlier)
	if (quiet && verbosity) {
		err_out(
			errors.New("conflicting arguments: quiet and verbose"),
		)
	}
}
