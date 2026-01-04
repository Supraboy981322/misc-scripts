package main

import ("os";"log")

func init() {
	readConf()

	//exit if no battery detected
	if !hasBat() {
		log.Print("no battery detected")
		os.Exit(0)
	}

	//exit with notif (and log) if no battery path was set
	if bat.Path == "" {
		log.Print("err no battery found or configured")
		notif("low", "Err no battery",
				"no battery found or configured", nil)
		os.Exit(1)
	}

	//if the set to check ac, then make sure ac is ok
	if ac.chk {//otherwise don't execute function
		if !chkAC() { //exit with notif (and log) if not found 
			log.Print("no AC power found or configured")
			notif("low", "Err no power supply",	"no AC power found or configured; "+
					`please disable "check" in AC config to ignore`, nil)
			os.Exit(1)
		}
	}
}
