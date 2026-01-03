package main

import ("os";"log")

func init() {
	//exit if no battery detected
	if !hasBat() {
		log.Print("no battery detected")
		os.Exit(0)
	}
}
