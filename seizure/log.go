package main

import ("os")

type Log struct {}

func (Log) Print(stuff ...string) {
	defer os.Stdout.Write([]byte{byte('\n')})
	for _, thing := range stuff {
		os.Stdout.WriteString(thing + " ")
	}
}

func (Log) Error(stuff ...string) {
	defer os.Stderr.Write([]byte{byte('\n')})
	for _, thing := range stuff {
		os.Stderr.WriteString(thing + " ")
	}
}
