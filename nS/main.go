package main

//all I need
import ("os";"fmt";"bufio")

var (
	in []byte //holds input
	file string //filename
	silent bool //silence messages 
	esc_quot = true //whether or not to ignore quoted strings

	//keeps track of counter
	count = struct {
		semi bool
		lines bool
		endB bool
		N int
		cust []byte
	} { semi: true, endB: true}

	//test input
	test_input = `#include <stdio.h>
int main(void) {
	for (int i = 0; i < 10; i++) {
		printf("foo;\n");
	}
}
`
)

func main() {
	//either read from stdin or a file
	if file == "" && in == nil {
		if !silent { fmt.Fprintln(os.Stderr, "no file specified\nreading from stdin...") }
		scanr := bufio.NewScanner(os.Stdin)
		for scanr.Scan() { in = append(in, scanr.Bytes()...) }
		if e := scanr.Err(); e != nil { err_out("err reading stdin: %v", e) }
	} else if in == nil {
		var e error
		in, e = os.ReadFile(file)
		if e != nil { err_out("failed to read file:\n\t%v", e) }
	}

	//keeps track of escaping
	esc := struct {
		on bool
		typ byte
	}{}

	//add line count before parsing (if enabled)
	if count.lines { count.N += len(split_lines(in)) }

	//range of input bytes
	for i, b := range in {
		switch b { //switch on byte
		 //semi-colon
		 case ';': if !esc.on && count.semi { count.N++ }
		 //end-brace
		 case '}': if !esc.on && count.endB { count.N++ } 
		 //quoted strings
		 case '"', '\'', '`':
			//fallthrough if string ignoring disabled
			if esc_quot {
				//ignore if previous character was backslash
				if i > 0 {
					if in[i-1] == '\\' { break }
				}
				//if string type matches, stop ignoring 
				if esc.typ == b {
					esc.on = false ; esc.typ = 0
				//if not a match, only start ignoring if not currently ignoring 
				} else if !esc.on && esc.typ == 0{
					esc.on = true ; esc.typ = b
				}
				continue //prevent fallthrough
			}; fallthrough //handle parsing quoted strings (if enabled)
		 default:
			//user-defined bytes
			if byte_contains(count.cust, b) && !esc.on { count.N++ }
		}
	}
	//print result
	fmt.Printf("%d\n", count.N)
}

//split lines into slice of byte slices
func split_lines(b_s []byte) [][]byte {
	var res [][]byte
	var mem []byte //holds current line
	//range over byte slice
	for _, b := range b_s {
		//on newline, add memory to result and clear memory
		if b == '\n' {
			res = append(res, mem) ; mem = nil
		//for anything else, add current byte to memory
		} else { mem = append(mem, b) }
	}
	//return result
	return res
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
	//print each line then exit
	for _, l := range lines { fmt.Println(l) }
	os.Exit(0)
}

//I put this at the end because it's ugly
//  it's just some crappy arg parsing
func init() {
	//keeps track of used args
	tak := []int{}
	//range over args
	for i, a := range os.Args[1:] {
		//if taken, skip
		if contains_int(i, tak) { continue }
		//switch on arg
		switch a {
		 //use test input
		 case "--test":
			if !silent { fmt.Println("in test mode, using built-in test file") }
			in = []byte(test_input)
			if !silent { fmt.Fprintln(os.Stderr, "\033[33m"+test_input+"\033[0m") }

		 //silence messages
		 case "-s", "--silent": if !silent { silent = true } else {
				err_out("called arg %s but was already set", a) 
			}

		 //file input 
		 case "-f", "--file":
			if contains_int(i+1, tak) {
				err_out("arg %s called but already taken (at %d)", a, idx_of_int(i+1, tak))
			}
			if len(os.Args[1:]) >= i+1 {
				tak = append(tak, i+1)
				file = os.Args[i+2] 
			} else { err_out("called %s but no value given", a) }

		 //count lines
		 case "-l", "--lines": count.lines = true

		 //ignore end braces
		 case "--ignore-brace", "--no-brace", "-B": count.endB = false

		 //ignore semi-colons
		 case "--ignore-semi-colons", "--no-semi", "-C": count.semi = false

		 //print help screen
		 case "-h", "--help": print_help()

		 //parse quotes
		 case "-q", "--parse-quotes": esc_quot = false
		 
		 //string of custom bytes to count 
		 case "-c", "--custom": 
			if contains_int(i+1, tak) {
				err_out("arg %s called but already taken (at %d)", a, idx_of_int(i+1, tak))
			}
			if len(os.Args[1:]) >= i+1 {
				tak = append(tak, i+1)
				count.cust = append(count.cust, split_str(os.Args[i+2])...)
			} else { err_out("called %s but no value given", a) }

			//invalid arg
		 default: err_out("invalid arg: %s", a)
		}
		//add current index to taken args
		tak = append(tak, i)
	}
}
