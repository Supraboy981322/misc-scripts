package main

import ("os";"fmt";"strconv")

func main() {
	var str string
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "reading from stdin")
		_, e := fmt.Fscanln(os.Stdin, &str)
		if e != nil {
			fmt.Fprintf(os.Stderr, "failed to read from stdin: %v\n", e)
			return
		}
	} else {
		str = os.Args[1]
	}
	raw_size, e := strconv.ParseInt(str, 10, 64)
	if e != nil {
		fmt.Fprintf(os.Stderr, "not a number: %s\n", str)
		os.Exit(1)
	}
	var d int64 = 1000
	var ex int
	var as_str string
	if raw_size > d {
		for n := raw_size / 1000; n >= 1000; n /= 1000 {
			d *= 1000  ;  ex++
		}
		as_str = fmt.Sprintf("%.2f %cB", float64(raw_size)/float64(d), " KMBTPEZY"[ex])
	} else {
		as_str = fmt.Sprintf("%d B", raw_size)
	}
	fmt.Println(as_str)
}
