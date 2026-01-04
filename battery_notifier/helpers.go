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
	if bat.Path != "" {
		if _, err := os.Stat(bat.Path); err == nil {
			return true
		}
	}

	var batToUse string
	var largest int
	dirs, err := os.ReadDir("/sys/class/power_supply/")
	if err != nil {
		log.Printf("\033[31mfailed to read batteries:  %v\033[0m", err)
		return false
	}

	for _, d := range dirs {
		if strings.HasPrefix(d.Name(), "BAT") {
			p := filepath.Join("/sys/class/power_supply/", d.Name())
			mB, err := os.ReadFile(filepath.Join(p, "charge_full"))
			if err != nil { fmt.Println(err) ; continue }

			mStr := strings.TrimSpace(string(mB))

			mI, _ := strconv.Atoi(mStr)
			if mI > largest { batToUse = p ; largest = mI }
		}
	};if batToUse == "" { return false }

	if bat.Path != "" { bat.Path = filepath.Join(batToUse, "capacity") }
	log.Printf("using battery:  %s\n", bat.Path)

	return true
}

func chkAC() bool {
	var acToUse string
	dirs, err := os.ReadDir("/sys/class/power_supply/")
	if err != nil {
		log.Printf("\033[31mfailed to read power supplies:  %v\033[0m", err)
		return false
	}

	for _, d := range dirs {
		if strings.HasPrefix(d.Name(), "AC") {
			p := filepath.Join("/sys/class/power_supply/", d.Name())
			tB, err := os.ReadFile(filepath.Join(p, "type"))
			if err != nil { fmt.Println(err) ; continue }

			tStr := strings.TrimSpace(string(tB))
			if tStr == "Mains" { ac.Path = filepath.Join(p, "online") ; break }
		}
	};if acToUse == "" { return false }

	log.Printf("using power supply:  %s\n", ac.Path)
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
	acBytes, err := ioutil.ReadFile(ac.Path)
	if err != nil {
		log.Printf("\033[31merr reading AC state:  %v\033[0m", err)
		return false
	}

	acStr := strings.TrimSpace(string(acBytes))
	if acStr == "0" { return false } else { return true }

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

func readConf() {
	var conf gomn.Map
	{
		h, err := os.UserHomeDir()
		if err != nil {	log.Print(err) }

		p := filepath.Join(h, ".config/Supraboy981322/battery_notifier/config.gomn")

		conf, err = gomn.ParseFile(p)
		if err != nil {	log.Print(err) }
	}

	if pu, ok := conf["pulse"].(int); ok && pu > 0 {
		pulse = time.Duration(pu) * time.Second
	}

	if batConf, ok := conf["battery"].(gomn.Map); ok {
		bat.Path, _ = batConf["path"].(string) //if bad, it's auto set later

		bat.Low, _ = batConf["low"].(int)
		if bat.Low >= 0 { bat.Low = 25 }
	} else {
		log.Print("can't assert \"battery\" in config to a map")
		return
	}

	if acConf, ok := conf["ac"].(gomn.Map); ok {
		ac.chk, _ = acConf["check"].(bool)
		ac.Path, _ = acConf["path"].(string)
	} else {
		log.Print("can't assert \"ac\" in config to a map")
		return
	}

	return
}

