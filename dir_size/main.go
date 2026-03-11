package main

import (
  "os"
	"fmt"
  "sync"
	"io/fs"
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

func help() {
	lines := []string{
		"\x1b[33m-h\x1b[0m, \x1b[33m--help\x1b[0m",
		"  prints this\x1b[0m",
		"\x1b[33m-H\x1b[0m, \x1b[33m--human\x1b[0m, \x1b[33m--human-readable\x1b[0m",
		"  print result in a human readable string \x1b[34m(eg: \x1b[35m2KB\x1b[34m instead of \x1b[35m2000\x1b[34m)\x1b[0m",
		"\x1b[33manything else\x1b[0m",
		"  assumed to be a directory name\x1b[0m",
	}
	for _, l := range lines { fmt.Println(l) }
}

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

func err_out(e error) {
	if !quiet || (quiet && verbosity) {
		fmt.Fprintf(os.Stderr, "%v\n", e)
	}
	whitelist := []error{
		os.ErrNotExist,
		fs.ErrPermission,
	};
	for _, err := range whitelist {
		if errors.Is(e, err) { return }
	}
	os.Exit(1)
}

func init() {
	args := os.Args[1:]
	loop: for _, a := range args {
		was_print_help := print_help
		was_human_readable := stuff.human_readable
		do_spawn := true
		if len(a) > 1 {
			if a[1] == '-' {
				old_arg := a
				if len(a) > 2 { a = a[2:] } else {
					a = old_arg ; goto spawn
				}
				switch (a) {
				 case "help": print_help = true
				 case "verbose":
					if !(quiet && verbosity) {
						verbosity = true
					} else {
						err_out(errors.New("conflicting arguments: quiet and verbose"))
					}
				 case "quiet":
					if !(quiet && verbosity) {
						quiet = true;
					} else {
						err_out(errors.New("conflicting arguments: quiet and verbose"))
					}
				 case "human-readable", "human": stuff.human_readable = true
				 default: goto spawn
				}
			} else {
				if a[0] == '-' {
					for _, ch := range a[1:] {
						switch ch {
						 case 'h': print_help = true
						 case 'v':
							if !(quiet && verbosity) {
								verbosity = true
							} else {
								err_out(errors.New("conflicting arguments: quiet and verbose"))
							}
						 case 'H': stuff.human_readable = true
						 case 'q':
							if !(quiet && verbosity) {
								quiet = true
							} else {
								err_out(errors.New("conflicting arguments: quiet and verbose"))
							}
						 default:  goto spawn
						}
					}
				} else { goto spawn }
			}
			do_spawn = false
		}
		spawn: if !do_spawn { continue loop }
			print_help = was_print_help
			stuff.human_readable = was_human_readable
			spawned_early = true
			wg.Add(1)
			if (verbosity) { total_routines.Add(1) }
			go fork(&c, &wg, a)
			continue loop
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
