package main

import (
	"os"
	"fmt"
	"io/fs"
	"os/exec"
	"math/rand/v2"
)

func main() {
	var dir string
	if len(os.Args) > 1 {
		os.Stdout.WriteString("assuming " + os.Args[1] + " is a directory\n")
		dir = os.Args[1]
	} else {
		var err error
		dir, err = os.Getwd()
		if err != nil {
			fmt.Fprintf(os.Stderr, "%v\n", err)
			os.Exit(1)
		}
	}

	fmt.Printf("\n\n\n")
	defer fmt.Printf("\n\n\n")
	current := pick_item(dir)
	for {
		upnext := pick_item(dir) 
		fmt.Printf(
			"\x1b[3A\x1b[2K\r\x1b[33mplaying: " +
				"\x1b[34m%s\x1b[0m\n\x1b[2K\t\x1b[35mupnext: " +
					"\x1b[36m%s\x1b[0m\n\x1b[2K",
			current,
			upnext,
		)

		cmd := exec.Command(
			"ffplay",
			append(
				[]string{
					"-nodisp",
					"-autoexit",
					"-hide_banner",
					"-loglevel", "quiet",
					"-stats",
				},
				current,
			)...,
		)

		current = upnext
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			fmt.Fprintf(os.Stderr, "%v\n", err)
			os.Exit(1)
		}
	}
}

func pick_item(dir string) string {
	var list []string
	fs.WalkDir(os.DirFS(dir), ".", func(p string, d fs.DirEntry, e error) error {
		if !d.IsDir() {
			list = append(list, p)
		}
		return nil
	})
	return list[rand.Int() % len(list)]
}
