package main

import ("os";"log")

func init() {
	readConf()

	//exit if no battery detected
	if !hasBat() {
		log.Print("no battery detected")
		os.Exit(0)
	}

	if bat.Path == "" {
		notif("low", "Err no battery",
				"no battery found or configured", nil)
		os.Exit(1)
	};if ac.Path == "" && ac.chk { 
		if !chkAC() {
			log.Print("no AC power found or configured")
			notif("low", "Err no power supply",
					"no AC power found or configured; "+
					"please disable \"check\" in AC config to ignore", nil)
			os.Exit(1)
		}
	}
}
