package main

import ("math")

func main() {
	for { go fork() }
}

func fork() {
	for {
		go func() {
			var foo = []uint64{}
			for { foo = append(foo, math.MaxUint64) }
		}()
	}
}
