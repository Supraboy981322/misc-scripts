package main

type f func(f)

func main() {
	for { go foo(foo) }
}

func foo(f) {
 for { go foo(foo)	}
}
