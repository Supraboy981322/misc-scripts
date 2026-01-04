package main

import (
	"os"
	"log"
	"time"
	_ "embed" //embeds warning icon
	"strconv"
	"syscall"
	"os/signal"
	"path/filepath"
)

//go:embed icons/warning.png
var iconEmbed []byte

var (
	//how long the pause between checks lasts 
	pulse = 1 * time.Second

	ac = struct {
		chk bool
		trakr bool
		Path string
	}{ chk: true, } //could be overwritten by config

	//holds battery settings
	//  (changed by init() func)
	bat = struct {
		Min int
		Lvl int
		Low int
		pre int
		chDown bool
		Path string
	}{
		Min: 5, //may do something with this at some point
		Low: 25, //could be overwritten by config
	}
)

func main() {
	//create os signal channel
	sigs := make(chan os.Signal, 1)

	//comms to coordinate closing the program 
	quit := make(chan bool)

	//register to recieve sys signals
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

	//watch for an end/terminate signal
	go func(){
		_ = <-sigs
		close(quit)
	}()

	var q bool //used to check if loop should break

	//start ac tracker with current state
	//  (so a notification isn't sent immediately
	ac.trakr = isPluggedIn()
	for {
		if q { break }
		select {
		 case <-quit: q = true ; break //stop loop 
		 default:
			//read the battery level from the kernel's VFS 
			percB, err := os.ReadFile(bat.Path)
			if err != nil {
				log.Fatal(err)
			}
			//remove newline and convert to string 
			percStr := string(percB[:len(percB)-1])

			//set level (assumed to be a number)
			bat.Lvl, _ = strconv.Atoi(percStr)

			//check if level is less than previous
			if bat.Lvl < bat.pre {
				bat.chDown = true //note that it went down
			} else { bat.chDown = false }

			//check if conditions are correct for notification
			//  - level is less than or equal to "low"
			//  - the percent went down compared to last check
			//  - and it's a multiple of 5 (don't send notification for every 1% decrease) 
			if bat.Lvl <= bat.Low && bat.chDown && bat.Lvl % 5 == 0 {
				//log current status
				log.Printf("\033[31mLOW{%d}\033[0m", bat.Lvl)

				//convert to string and add `%` 
				batLvlStr := strconv.Itoa(bat.Lvl)+"%"

				//send low battery notification
				dir := dumpIcon() //loads notif icon into temp dir
				notifArgs := []string{"-i", filepath.Join(dir, "warning.png"),}
				notif("critical", "LOW BATTERY", batLvlStr, notifArgs)

				//remove temp notif icon dir
				if err := os.RemoveAll(dir); err != nil {
					log.Printf("\033[31mfailed to remove directory\033[0m:  %v", err)
				}
			}
			
			//log checked battery values
			log.Printf("bat.Lvl{%d} bat.Low{%d} bat.chDown{%t} bat.pre{%d}",
						bat.Lvl, bat.Low, bat.chDown, bat.pre)

			//update battery tracker
			bat.pre = bat.Lvl

			//compare old and current AC status
			if isPluggedIn() && !ac.trakr {
				//notify waybar
				sendRTSIG("waybar", 8)

				//send notification
				log.Print("\033[33mconnected to AC power\033[0m")
				notif("low", "AC Connected", "Connected to AC power", nil)

				//update status 
				ac.trakr = true
			} else if !isPluggedIn() && ac.trakr {
				//notify waybar
				sendRTSIG("waybar", 8)

				//send notification
				log.Print("\033[33mdisconnected from AC power\033[0m")
				notif("low", "AC Disconnected", "Disconnected from AC power", nil)

				//update status
				ac.trakr = false
			}

			//wait before starting next cycle
			time.Sleep(pulse)
		}
	}

	//loop exited
	log.Print("exiting....")
}
