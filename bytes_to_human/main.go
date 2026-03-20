package main

import ("os";"fmt";"strconv")

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "not enough args, need number")
		os.Exit(1)
	}
	raw_size, e := strconv.ParseInt(os.Args[1], 10, 64)
	if e != nil {
		fmt.Fprintf(os.Stderr, "not a number: %s\n", os.Args[1])
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
