package main

//#include <signal.h>
import "C"

import (
	"os"
	"log"
	"time"
	"strings"
	"os/exec"
	"strconv"
	"syscall"
	"io/ioutil"
	"os/signal"
)

var ( 
	pulse = 1 * time.Second
	bat = struct {
		Min int
		Lvl int
		Low int
		pre int
		chDown bool
	}{
		Min: 5,
		Lvl:0,
		Low: 80,
	}
)

func main() {
	sigs := make(chan os.Signal, 1)
	quit := make(chan bool)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	go func(){
		_ = <-sigs
		close(quit)
	}()
	var q bool
	var acTracker bool = isPluggedIn()
	for {
		if q { break }
		select {
		 case <-quit: q = true ; break
		 default:
			percB, err := os.ReadFile("/sys/class/power_supply/BAT0/capacity")
			if err != nil {
				log.Fatal(err)
			}
			percStr := string(percB[:len(percB)-1])
			bat.Lvl, _ = strconv.Atoi(percStr)
			if bat.Lvl - bat.pre < 0 {
				bat.chDown = true
			} else { bat.chDown = false }
			if bat.Lvl <= bat.Low && bat.chDown && bat.Lvl % 5 == 0 {
				log.Printf("\033[31mLOW{%d}\033[0m", bat.Lvl)
				notif("critical", "LOW BATTERY",
					strconv.Itoa(bat.Lvl)+"%",
					[]string{"-i", "/home/super/Pictures/icons/warning.png",})
				
			}
			log.Printf("bat.Lvl{%d} bat.Low{%d} bat.chDown{%t} bat.pre{%d}", bat.Lvl, bat.Low, bat.chDown, bat.pre)
			bat.pre = bat.Lvl
			if isPluggedIn() && !acTracker {
				sendRTSIG("waybar", 8)
				log.Print("\033[33mconnected to AC power\033[0m")
				notif("low", "AC Connected",
					"Connected to AC power", nil)
				acTracker = true
			} else if !isPluggedIn() && acTracker {
				sendRTSIG("waybar", 8)
				log.Print("\033[33mdisconnected from AC power\033[0m")
				notif("low", "AC Disconnected",
					"Disconnected from AC power", nil)

				acTracker = false
			}
			time.Sleep(pulse)
		}
	}
	log.Print("exiting....")
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

	log.Print("\033[0muncaught err in detecting AC state\033[0m") 
	return false
}
