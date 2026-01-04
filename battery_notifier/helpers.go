package main

//#include <signal.h>
import "C"

import (
	"os"
	"log"
	"fmt"
	"time"
	"os/exec"
	"syscall"
	"strconv"
	"strings"
	"io/ioutil"
	"path/filepath"
	"github.com/Supraboy981322/gomn"
)


func hasBat() bool {
	//makes sure config didn't already set it
	if bat.Path != "" {
		//if make sure it exists 
		if _, err := os.Stat(bat.Path); err == nil {
			return true
		} else { log.Print("battery path in config is invalid") }
	}

	//
	var batToUse string
	var largest int
	dirs, err := os.ReadDir("/sys/class/power_supply/")
	if err != nil {
		log.Printf("\033[31mfailed to read batteries:  %v\033[0m", err)
		return false
	}

	//check each item in dir
	for _, d := range dirs {
		//only needs to start with "BAT" 
		if strings.HasPrefix(d.Name(), "BAT") {
			//construct filepath
			p := filepath.Join("/sys/class/power_supply/", d.Name())

			//get the battery capacity
			mB, err := os.ReadFile(filepath.Join(p, "charge_full"))
			if err != nil { fmt.Println(err) ; continue }

			//convert to string and remove whitespace
			mStr := strings.TrimSpace(string(mB))

			//convert to int
			mI, _ := strconv.Atoi(mStr)
			//if it's larger than the last largest battery
			//  replace last largest with new capacity, also
			//    note battery path
			if mI > largest { batToUse = p ; largest = mI }
		}
	};if batToUse == "" { return false } //no battery

	//set the battery path only if it's not already set (config, likely) 
	if bat.Path != "" { bat.Path = filepath.Join(batToUse, "capacity") }

	//log the path
	log.Printf("using battery:  %s\n", bat.Path)

	//returns that it has a battery
	return true
}

func chkAC() bool {
	//makes sure config didn't already set it
	if ac.Path != "" {
		//if make sure it exists 
		if _, err := os.Stat(ac.Path); err == nil {
			return true
		} else { log.Print("ac path in config is invalid") }
	};var acToUse string //holds path of AC

	//get a list of contents in the power_supply VFS 
	dirs, err := os.ReadDir("/sys/class/power_supply/")
	if err != nil {
		log.Printf("\033[31mfailed to read power supplies:  %v\033[0m", err)
		return false
	}

	//checks each item
	for _, d := range dirs {
		//only needs to start with "AC"
		if strings.HasPrefix(d.Name(), "AC") {
			//construct filepath
			p := filepath.Join("/sys/class/power_supply/", d.Name())

			//check the type
			tB, err := os.ReadFile(filepath.Join(p, "type"))
			if err != nil { fmt.Println(err) ; continue }

			//remove whitespace from type
			tStr := strings.TrimSpace(string(tB))

			//break if it's mains (the first mains power it finds)
			if tStr == "Mains" { ac.Path = filepath.Join(p, "online") ; break }
		}
	};if acToUse == "" { return false } //no AC found 

	//log power supply path
	log.Printf("using power supply:  %s\n", ac.Path)

	//return that it exists 
	return true
}

func dumpIcon() string {
	//mk tmp dir to hold icon
	dir, err := os.MkdirTemp("/tmp", "battery_warning*")
	if err != nil {
		log.Printf("\033[31mfailed to create temp dir:  %v\033[0m", err)
		return ""
	}
	//construct filepath
	path := filepath.Join(dir, "warning.png")

	//write tmp icon file to tmp dir
	err = os.WriteFile(path, iconEmbed, 0644)
	if err != nil {
		log.Printf("\033[31mfailed to write file:  %v\033[0m", err)
		return dir //return dir anyways, so it's deleted when check ends
	}
	return dir
}

func isPluggedIn() bool {
	//read the VFS file
	acBytes, err := ioutil.ReadFile(ac.Path)
	if err != nil {
		log.Printf("\033[31merr reading AC state:  %v\033[0m", err)
		return false
	}

	//convert to string and remove whitespace
	acStr := strings.TrimSpace(string(acBytes))
	if acStr == "0" { return false } else { return true }

	//schrodinger's string
	//  (it's not `0` and also is `0`, for some reason)
	log.Print("\033[31muncaught err in detecting AC state\033[0m") 
	return false
}

func getPID(process string) int {
	//just uses `pgrep` cmd from system
	cmd := exec.Command("pgrep", process)
	output, err := cmd.Output()
	if err != nil {
		log.Printf("\033[31mfailed to get process PID:  %v\033[0m", err)
		return -1
	}
	
	//filter the output
	pids := strings.Fields(string(output))
	if len(pids) == 0 {
		log.Printf("\033[31mno %s process\033[0m", process)
		return -1
	}

	//assume it's the first one
	//  (usually is, at least for me)
	pid, err := strconv.Atoi(pids[0])
	if err != nil {
		log.Printf("\033[31merr converting PID to int:  %v\033[0m", err)
	}
	return pid
}

func sendRTSIG(process string, signal int) error {
	pid := getPID(process) //find pid

	//get the process
	proc, err := os.FindProcess(pid)
	if err != nil { return err }

	//calc the signal and send it
	sig := syscall.Signal(int(C.SIGRTMIN) + signal)
	if err := proc.Signal(sig); err != nil { return err }

	//assume ok
	return nil
}

func notif(urgency string, title string, msg string, extraArgs []string) {
	//construct args slice
	args := []string{ "-u", urgency, title, msg, }
	if len(extraArgs) > 0 { args = append(args, extraArgs...) }

	//send notification
	cmd := exec.Command("notify-send", args...)
	if err := cmd.Run(); err != nil {
		log.Printf("\033[31merr sending notification:  %v\033[0m", err)
		return
	}

	//log it
	log.Print("sent notification")
}

func readConf() {
	var conf gomn.Map
	{
		//get user home dir
		h, err := os.UserHomeDir()
		if err != nil {	log.Print(err) ; return }

		//construct absolute path to config
		p := filepath.Join(h, ".config/Supraboy981322/battery_notifier/config.gomn")

		//parse the config (print and return on err)
		conf, err = gomn.ParseFile(p)
		if err != nil {	log.Print(err) ; return }
	}

	//get pulse from config (if invalid, default of 1 stays)
	if pu, ok := conf["pulse"].(int); ok && pu > 0 {
		//set the pulse in seconds
		pulse = time.Duration(pu) * time.Second
	} else { log.Print(`"pulse" invalid or unset, defaulting to 1 second`) }

	//get battery config map
	if batConf, ok := conf["battery"].(gomn.Map); ok {
		bat.Path, _ = batConf["path"].(string) //if bad, it's auto-set later
		bat.Low, _ = batConf["low"].(int) //notif sent at this battery level
		if bat.Low >= 0 { bat.Low = 25 }
	} else { log.Print(`can't assert "battery" in config to a map`) ; return }

	if acConf, ok := conf["ac"].(gomn.Map); ok {
		ac.chk, ok = acConf["check"].(bool)
		if !ok { ac.chk = true } //default to true
		
		ac.Path, _ = acConf["path"].(string)  //if bad, it's auto-set later
	} else { log.Print(`can't assert "ac" in config to a map`) ; return }
}
