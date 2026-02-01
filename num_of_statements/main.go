package main

import (_"os";"fmt")

var (
	in = `#include <stdio.h>
int main(void) {
	for (int i = 0; i < 10; i++) {
		printf("foo;\n");
	}
}
`
)

func main() {
	var count int
	esc := struct {
		on bool
		typ rune
	}{}
	for _, b := range in {
		switch b {
		 case ';': if !esc.on { count++ }
		 case '"', '\'': if esc.typ == b {
			esc.on = false ; esc.typ = 0
			} else if !esc.on {
				esc.on = true ; esc.typ = b
			}
		 case '}': if !esc.on { count++ } 
		}
	}
	fmt.Printf("%d\n", count)
}
