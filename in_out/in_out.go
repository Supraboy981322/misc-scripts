///usr/bin/env go run "$0" "$@" ; exit $?

package main

import (
	"os"
	"io"
)

func main() {
	_, e := io.Copy(os.Stdout, os.Stdin)
	if e != nil { print(e.Error()) }
}
