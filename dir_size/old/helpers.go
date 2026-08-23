package main

import (
	"os"
	"fmt"
	"io/fs"
	"errors"
)

type args struct{}
var Args args

func (args) set_or_err(opt *bool, flag_name string) {
	if *opt {
		msg := fmt.Errorf("attempted to set flag %s, but it was already set", flag_name)
		err_out(msg)
	}
	*opt = true
}

func (args) set_or_conflict(opt, conflict *bool, flag1, flag2 string) {
	if *conflict {
		msg := fmt.Errorf("conflicting args: %s and %s", flag1, flag2)
		err_out(msg)
	}
	Args.set_or_err(opt, flag1)
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

func help() {
	lines := []string{
		"\x1b[33m-h\x1b[0m, \x1b[33m--help\x1b[0m",
		"  prints this\x1b[0m",
		"\x1b[33m-H\x1b[0m, \x1b[33m--human\x1b[0m, \x1b[33m--human-readable\x1b[0m",
		"  print result in a human readable string \x1b[34m(eg: \x1b[35m2KB\x1b[34m instead of \x1b[35m2000\x1b[34m)\x1b[0m",
		"\x1b[33m-q\x1b[0m, \x1b[33m--quiet\x1b[0m",
		"  quiet, don't print any errors",
		"\x1b[33m-v\x1b[0m, \x1b[33m--verbose\x1b[0m",
		"  (ever-so-slightly) more verbose logging",
		"\x1b[33m-s\x1b[0m, \x1b[33m--stats\x1b[0m",
		"  print stats after result",
		"\x1b[33manything else\x1b[0m",
		"  assumed to be a directory name\x1b[0m",
	}
	for _, l := range lines { fmt.Println(l) }
}

func (args) check(a string) bool {
	if a[1] == '-' {
		old_arg := a
		if len(a) > 2 { a = a[2:] } else {
			a = old_arg ; return true
		}
		switch (a) {
		 case "help": Args.set_or_err(&print_help, "help")
		 case "verbose": Args.set_or_conflict(&verbosity, &quiet, "verbose", "quiet")
		 case "quiet":   Args.set_or_conflict(&quiet, &verbosity, "quiet", "verbose")
		 case "human-readable", "human": Args.set_or_err(&stuff.human_readable, "human-readable")
		 default: return true
		}
	} else {
		if a[0] == '-' {
			for _, ch := range a[1:] {
				switch ch {
				 case 'h': Args.set_or_err(&print_help, "help")
				 case 'v': Args.set_or_conflict(&verbosity, &quiet, "verbose", "quiet")
				 case 'H': Args.set_or_err(&stuff.human_readable, "human-readable")
				 case 'q': Args.set_or_conflict(&quiet, &verbosity, "quiet", "verbose")
				 default:  return true
				}
			}
		} else { return true }
	}
	return false
}
