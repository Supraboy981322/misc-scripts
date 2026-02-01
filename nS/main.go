package main

import ("os";"fmt";"bufio")

var (
	in []byte
	count = struct {
		semi bool
		lines bool
		endB bool
		N int
		cust []byte
	} { semi: true, endB: true}
	file string
	esc_quot = true
	silent bool
	test_input = `#include <stdio.h>
int main(void) {
	for (int i = 0; i < 10; i++) {
		printf("foo;\n");
	}
}
`
)

func main() {
	if file == "" && in == nil {
		if !silent { fmt.Fprintln(os.Stderr, "reading from stdin...") }
		scanr := bufio.NewScanner(os.Stdin)
		for scanr.Scan() { in = append(in, scanr.Bytes()...) }
		if e := scanr.Err(); e != nil { err_out("err reading stdin: %v", e) }
	} else if in == nil {
		var e error
		in, e = os.ReadFile(file)
		if e != nil { err_out("failed to read file: %v", e) }
	}

	esc := struct {
		on bool
		typ byte
	}{}

	for _, b := range in {
		switch b {
		 case '\n': if !esc.on && count.lines { count.N++ }
		 case ';': if !esc.on && count.semi { count.N++ }
		 case '}': if !esc.on && count.endB { count.N++ } 
		 case '"', '\'', '`':
			if esc_quot {
				if esc.typ == b {
					esc.on = false ; esc.typ = 0
				} else if !esc.on {
					esc.on = true ; esc.typ = b
				}
				continue
			}; fallthrough //handle parsing quoted strings (if enabled)
		 default:
			if byte_contains(count.cust, b) && !esc.on { count.N++ }
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

//I refuse to import slices and string
//  (manual string parsing is fun)
func split_str(s string) []byte {
	var res []byte
	for i, _ := range s { res = append(res, s[i]) }
	fmt.Printf("\n%#v\n", res)
	return res
}

//I refuse to import slices and string
//  (manual string parsing is fun)
func byte_contains(b_s []byte, b_I byte) bool {
	for _, b := range b_s { if b == b_I { return true } }
	return false
}

//priint to stderr and exit
func err_out(s string, args ...any) {
	fmt.Fprintf(os.Stderr, s+"\n", args...)
	os.Exit(1)
}

//print help screen
func print_help() {
	lines := []string{
		"'-f', '--file':",
		"\tinput file",
		"'--test':",
		"\tuse embeded test file (good for demonstration)",
		"'-s', '--silent':",
		"\tsilent mode (no output)",
		"'-l', '--lines':",
		"\tinclude line numbers in count",
		"'-B', '--no-brace', '--ignore-brace':",
		"\tdon't count end braces",
		"'-C', '--no-semi', '--ignore-semi-colons':",
		"\tdon't count semi-colons", 
		"'-q', or '--parse-quotes'",
		"\tparse quoted strings",
		"'-c', '--custom'",
		"\tcount set of additional chars",
		"'-h', '--help':",
		"\tprints this",
	}
	for _, l := range lines { fmt.Println(l) }
	os.Exit(0)
}

//I put this at the end because it's ugly
//  it's just some crappy arg parsing
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
		 case "-q", "--parse-quotes": esc_quot = false
		 case "-c", "--custom": 
			if contains_int(i+1, tak) {
				err_out("arg %s called but already taken (at %d)", a, idx_of_int(i+1, tak))
			}
			if len(os.Args[1:]) >= i+1 {
				tak = append(tak, i+1)
				count.cust = append(count.cust, split_str(os.Args[i+2])...)
			} else { err_out("called %s but no value given", a) }
		 default: err_out("invalid arg: %s", a)
		}
		tak = append(tak, i)
	}
}
