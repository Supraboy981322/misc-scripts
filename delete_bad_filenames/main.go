package main

import ("os";"bufio";"unicode")

func main() {
	del := []string{}
	ent, e := os.ReadDir("./")
	if e != nil { close_err(e) }
	for _, en := range ent {
		n := en.Name()
		for _, c := range n {
			if c > unicode.MaxASCII {
				del = append(del, n) ; break
			}
		}
	}
	for _, fi := range del {
		os.Stdout.Write([]byte("\nremoving: "+fi+"\n"))
		var skip bool
		for {
			os.Stdout.Write([]byte("continue? [y/n]: "))
			r := to_lower(scanf())
			if r == "n" {
				skip = true ; break
			} else if r == "y" { break } 
			os.Stdout.Write([]byte("invalid answer\n"))
		}
		if !skip { 
			e := os.Remove(fi) 
			if e != nil { close_err(e) }
		}
	}
}

func close_err(e error) {
	os.Stderr.Write([]byte("err: "+e.Error()+"\n"))
	os.Exit(1)
}

func scanf() string {
	var res string
	scanr := bufio.NewScanner(os.Stdin)
	if scanr.Scan() {
		res = cut_space(scanr.Text())
	}

	return to_lower(res)
}

func to_lower(str string) string {
	var res string
	for i := 0; i < len(str); i++ {
		c := str[i]
		if c >= 'A'&& c <= 'Z' {
			res += string(str[i]+32)
		} else { res += string(c) }
	}
	return res
}

func cut_space(str string) string {
	var res string
	for _, c := range str {
		switch c {
			case ' ', '\n', '\t', '\r':
			default: res += string(c)
		}
	}
	return res
}
