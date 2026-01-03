package main

//#include <signal.h>
import "C"

import (
	"os"
	"log"
	"fmt"
	"os/exec"
	"syscall"
	"strconv"
	"strings"
	"io/ioutil"
	"path/filepath"
)


func hasBat() bool {
	var batToUse string
	var largest int
	dirs, err := os.ReadDir("/sys/class/power_supply/")
	if err != nil {
		log.Printf("\033[31mfailed to read power supplies:  %v\033[0m", err)
		return false
	}

	for _, d := range dirs {
		if strings.HasPrefix(d.Name(), "BAT") {
			mStr, err := os.ReadFile(filepath.Join(d.Name(), "charge_full"))
			if err != nil { fmt.Println(err) ; continue }

			mI, _ := strconv.Atoi(string(mStr))
			if mI > largest { batToUse = d.Name() ; largest = mI }
		}
	};if batToUse == "" { return false }

	bat.Path = fmt.Sprintf("/sys/class/power_supply/%s/capacity", batToUse)
	return true
}

func dumpIcon() string {
	dir, err := os.MkdirTemp("/tmp", "battery_warning*")
	if err != nil {
		log.Printf("\033[31mfailed to create temp dir:  %v\033[0m", err)
		return ""
	}
	path := filepath.Join(dir, "warning.png")
	err = os.WriteFile(path, iconEmbed, 0644)
	if err != nil {
		log.Printf("\033[31mfailed to write file:  %v\033[0m", err)
		return dir
	}
	return dir
}

func isPluggedIn() bool {
	acPath := "/sys/class/power_supply/AC0/online"

	acBytes, err := ioutil.ReadFile(acPath)
	if err != nil {
		log.Printf("\033[31merr reading AC state:  %v\033[0m", err)
		return false
	}

	acStr := strings.TrimSpace(string(acBytes))
	if acStr == "0" {
		return false
	} else {
		return true
	}

	log.Print("\033[31muncaught err in detecting AC state\033[0m") 
	return false
}

func getPID(process string) int {
	cmd := exec.Command("pgrep", process)
	output, err := cmd.Output()
	if err != nil {
		log.Printf("\033[31mfailed to get process PID:  %v\033[0m", err)
		return -1
	}
	
	pids := strings.Fields(string(output))
	if len(pids) == 0 {
		log.Printf("\033[31mno %s process\033[0m", process)
		return -1
	}

	//	assume it's the first one
	pid, err := strconv.Atoi(pids[0])
	if err != nil {
		log.Printf("\033[31merr converting PID to int:  %v\033[0m", err)
	}
	return pid
}

func sendRTSIG(process string, signal int) error {
	pid := getPID(process)

	proc, err := os.FindProcess(pid)
	if err != nil {
		return err
	}
 
	sig := syscall.Signal(int(C.SIGRTMIN) + signal)
	if err := proc.Signal(sig); err != nil {
		return err
	}

//	log.Printf("sig: %d  ;  pid: %d  ;  process: %s  ;  signal: %d",
//		sig, pid, process, signal)
	return nil
}

func notif(urgency string, title string, msg string, extraArgs []string) {
	args := []string{
		"-u", urgency,
		title, msg,
	};if len(extraArgs) > 0 {
		args = append(args, extraArgs...)
	}

	cmd := exec.Command("notify-send", args...)
	if err := cmd.Run(); err != nil {
		log.Printf("\033[31merr sending notification:  %v\033[0m", err)
		return
	}

	log.Print("sent notification")
}
