///usr/bin/env go run "$0" "$@" ; exit $?

package main

import (
  "os"
  "io"
	"fmt"
	"bufio"
)

func main() {
	reader := bufio.NewReader(os.Stdin)

	var ign bool
	for {
		c, _, e := reader.ReadRune()
		if (e != nil) {
			if (e == io.EOF) { break } else { err(e) }
		}
		switch (c) {
		 case '\x1b': ign = true;
		 default:
			if (is_alpha(c) && ign) { ign = false } else if (!ign) {
				fmt.Printf("%c", c)
			}
		}
	}
}

func is_alpha(c rune) bool {
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

func err(e error) {
		print(e.Error())
		os.Exit(1)
}
