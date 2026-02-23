///usr/bin/env go run "$0" "$@" ; exit $?
package main

//all I need to do this
//  (could drop "unicode", but I'm not checking agains every valid unicode byte)
import ("os";"bufio";"unicode")

func main() {
	//list of things to delete
	del := []string{}

	//get files in directory
	ent, e := os.ReadDir("./")
	if e != nil { close_err(e) }

	//iterate over each entry
	for _, en := range ent {
		n := en.Name()

		//check if contains non-ascii text 
		for _, c := range n {
			if c > unicode.MaxASCII {
				//add to list if so
				del = append(del, n) ; break
			}
		}
	}

	//exit with msg if no found filenames
	if len(del) == 0 {
		os.Stdout.Write([]byte("no non-ascii filenames found\n"))
		os.Exit(0)
	}

	//iterate over list of bad filenames
	for _, fi := range del {
		//print current name
		os.Stdout.Write([]byte("\nremoving: "+fi+"\n"))
		var skip bool

		//repeatedly ask to continue until valid answer
		for {
			//prompt
			os.Stdout.Write([]byte("continue? [y/n]: "))

			//read input as lowercase
			r := to_lower(scanf())

			//skip file or continue 
			if r == "n" {
				skip = true ; break
			} else if r == "y" { break } 

			//if neither invalid 
			os.Stdout.Write([]byte("invalid answer\n"))
		}

		//delete if not skip
		if !skip { 
			e := os.Remove(fi) 
			if e != nil { close_err(e) }
		}
	}
}

//helper to print err and close
func close_err(e error) {
	os.Stderr.Write([]byte("err: "+e.Error()+"\n"))
	os.Exit(1)
}

//helper to read input
func scanf() string {
	var res string

	//create scanner
	scanr := bufio.NewScanner(os.Stdin)

	//get input
	if scanr.Scan() {
		res = cut_space(scanr.Text()) //remove spaces
	}

	return res
}

//who needs the "strings" module anyways?
func to_lower(str string) string {
	var res string

	//iterate over input string
	for i := 0; i < len(str); i++ {
		//get current char
		c := str[i]

		//if capital letter, make lower case 
		if c >= 'A' && c <= 'Z' {
			res += string(c+32)
		//add otherwise
		} else { res += string(c) }
	}

	return res
}

//again, "who needs the 'strings' module anyways?"
func cut_space(str string) string {
	var res string

	//range over input string 
	for _, c := range str {
		switch c {
			//skip spaces
			case ' ', '\n', '\t', '\r':
		
			//add otherwise
			default: res += string(c)
		}
	}

	return res
}
