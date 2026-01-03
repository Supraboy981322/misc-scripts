package main

import (
	"os"
	"fmt"
	"slices"
)

type (
	Colors struct {
		R string
		G string
		B string
		Hex string
		OldMan string
	}
	Format struct {
		Bold bool
		Italic bool
		Underline bool
		Blink bool
		Strikethrough bool
		Which string
	}
)

var (
	typ string
	args = os.Args[1:]
	colors Colors
	format Format 
)

func init() {
	if len(args) == 0 {
		eror("not enough args", "see -h for help")
	}
	var tak []int
	for i, a := range args {
		if !slices.Contains(tak, i) {
			if a[0] == '-' && len(a) >= 2 {
				if a[1] == '-' { tak = wordArg(a, i, tak) }
				if a[1] != '-' { tak = charArg(a, i, tak) }
				continue
			} else if a[0] == '#' { colors.Hex = a ; continue }
			eror("invalid arg", a)	
		}
	}
	if typ == "" {
		typ = "hex"
		if len(args) <= len(tak) {
			eror("missing arg", "no color provided")
		}
		for i, a := range args {
			if !slices.Contains(tak, i) {
				colors.Hex = a
				break
			}
		}
	}	
	if format.Which == "" { format.Which = "3" }
}

func main() {
	var code string
	switch typ {
	 case "hex": code = hexToAnsi(colors.Hex)
	 case "rgb": code = rgbToAnsi(colors)
	}; code = format.Which+code
	if format.Bold { code = "1;"+code }
	if format.Italic { code = "3;"+code }
	if format.Underline { code = "4;"+code }
	if format.Blink { code = "5;"+code }
	if format.Strikethrough { code = "9;"+code }
	fmt.Printf("\033[%sm", code)
}
