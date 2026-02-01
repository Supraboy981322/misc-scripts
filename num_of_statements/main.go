package main

import ("os";"fmt";"bufio")

var (
	in []byte
	count = struct {
		semi bool
		lines bool
		endB bool
		N int
	} { semi: true, endB: true}
	file string
	silent bool
	test_input = `#include <stdio.h>
int main(void) {
	for (int i = 0; i < 10; i++) {
		printf("foo;\n");
	}
}
`
)

func init() {
	tak := []int{}
	for i, a := range os.Args[1:] {
		if contains_int(i, tak) { continue }
		switch a {
		 case "--test":
			if !silent { fmt.Println("in test mode, using built-in test file") }
			in = []byte(test_input)
			if !silent { fmt.Fprintln(os.Stderr, "\033[33m"+test_input+"\033[0m") }
			return
		 case "-s", "--silent": if !silent { silent = true } else {
				err_out("called arg %s but was already set", a) 
			}
		 case "-f", "--file":
			if contains_int(i+1, tak) {
				err_out("arg %s called but already taken (at %d)", a, idx_of_int(i+1, tak))
			}
			if len(os.Args[1:]) >= i+1 {
				tak = append(tak, i+1)
				file = os.Args[i+2] 
			} else { err_out("called %s but no value given", a) }
		 case "-l", "--lines": count.lines = true
		 case "--ignore-brace", "--no-brace", "-B": count.endB = false
		 case "--ignore-semi-colons", "--no-semi", "-C": count.semi = false
		 case "-h", "--help": print_help()
		 default: err_out("invalid arg: %s", a)
		}
		tak = append(tak, i)
	}
}

func main() {
	esc := struct {
		on bool
		typ byte
	}{}
	if file == "" && in == nil {
		if !silent { fmt.Fprintln(os.Stderr, "reading from stdin...") }
		scanr := bufio.NewScanner(os.Stdin)
		for scanr.Scan() { in = append(in, scanr.Bytes()...) }
		if e := scanr.Err(); e != nil { err_out("err reading stdin: %v", e) }
	}
	for _, b := range in {
		switch b {
		 case '\n': if !esc.on && count.lines { count.N++ }
		 case ';': if !esc.on && count.semi { count.N++ }
		 case '"', '\'': if esc.typ == b {
			esc.on = false ; esc.typ = 0
			} else if !esc.on {
				esc.on = true ; esc.typ = b
			}
		 case '}': if !esc.on && count.endB { count.N++ } 
		}
	}
	fmt.Printf("%d\n", count.N)
}

//I refuse to import slices and string
//  (manual string parsing is fun)
func contains_int(t int, s []int) bool {
	for _, i := range s {
		if i == t { return true }
	}
	return false
}

//I refuse to import slices and string
//  (manual string parsing is fun)
func idx_of_int(t int, s []int) int {
	for idx, i := range s {
		if i == t { return idx }
	}
	return -1
}

func err_out(s string, args ...any) {
	fmt.Printf(s+"\n", args...)
	os.Exit(1)
}

func print_help() {
	lines := []string{
		"'-f', '--file':",
		"\tinput file",
		"'--test':",
		"\tuse embeded test file (good for demonstration)",
		"'-s', '--silent':",
		"\tsilent mode (no output)",
		"'-f', '--file'",
		"\tinput file",
		"'-l', '--lines':",
		"\tinclude line numbers in count",
		"'-B', '--no-brace', '--ignore-brace':",
		"\tdon't count end braces",
		"'-C', '--no-semi', '--ignore-semi-colons':",
		"\tdon't count semi-colons", 
		"'-h', '--help':",
		"\tprints this",
	}
	for _, l := range lines { fmt.Println(l) }
	os.Exit(0)
}
