package main

import (
	"os"
	"log"
	"time"
	_ "embed"
	"strconv"
	"syscall"
	"os/signal"
	"path/filepath"
)

//go:embed icons/warning.png
var iconEmbed []byte

var (
	pulse = 1 * time.Second
	bat = struct {
		Min int
		Lvl int
		Low int
		pre int
		chDown bool
		Path string
	}{
		Min: 5,
		Lvl:0,
		Low: 25,
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
			percB, err := os.ReadFile(bat.Path)
			if err != nil {
				log.Fatal(err)
			}
			percStr := string(percB[:len(percB)-1])
			bat.Lvl, _ = strconv.Atoi(percStr)
			if bat.Lvl - bat.pre < 0 {
				bat.chDown = true
			} else { bat.chDown = false }
			if bat.Lvl <= bat.Low && bat.chDown && bat.Lvl % 5 == 0 {
				dir := dumpIcon()
				log.Printf("\033[31mLOW{%d}\033[0m", bat.Lvl)
				notif("critical", "LOW BATTERY",
					strconv.Itoa(bat.Lvl)+"%",
					[]string{"-i", filepath.Join(dir, "warning.png"),})
				err := os.RemoveAll(dir)
				if err != nil {
					log.Printf("\033[31mfailed to remove directory\033[0m:  %v", err)
				}
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
