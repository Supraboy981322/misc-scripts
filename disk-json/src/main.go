package main

import (
  "fmt"
	"time"
	"bytes"
	"slices"
	"os/exec"
	"context"
	"strconv"
	"strings"
  "net/http"
	"github.com/charmbracelet/log"
)

var (
	port = 8357 //TODO: custom port 
)

func init() {
	log.Info("initializing...")

	//TODO: config

	log.Info("initialized.")
}

func main() {
	http.HandleFunc("/", listener)

	//log port
	log.Infof("listening on port %d", port)

	//start http server 
	log.Fatal(http.ListenAndServe(":"+strconv.Itoa(port), nil))
}

func listener(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	//context with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 250*time.Millisecond)
	defer cancel()

	var bufErr bytes.Buffer
	var bufOut bytes.Buffer

	//get drives
	cmd := exec.CommandContext(ctx, "sh", "-c", "df", "-h") 
	cmd.Stderr = &bufErr //copy to err buffer
	cmd.Stdout = &bufOut //copy to std buffer
	err := cmd.Start()
	if err != nil && err.Error() != "signal: killed" {
		log.Error(err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}

	//kill command if timeout didn't work
	//  (only occurs on my Alpine server, for some reason)
	time.Sleep(251 * time.Millisecond)
	if cmd.Process != nil {
		if kErr := cmd.Process.Kill(); kErr != nil {
			log.Error(err.Error())
			http.Error(w, err.Error(), http.StatusInternalServerError)
		} else { log.Warn("cmd took far too long, killed for incompetance") }
	}
	
	//block until killed or finished
	cmd.Wait()

	oR := bufOut.String()

	//split into slice of lines
	oL := strings.Split(string(oR), "\n")
	//last line is just a newline
	//  and remove table header
	oL = oL[1:len(oL)-1]
	oL = slices.DeleteFunc(oL, func(itm string) bool{
		return itm == ""
	})
	for i, l := range oL {
		lS := strings.Split(l, " ")
		lS = slices.DeleteFunc(lS, func(itm string) bool {
			return itm == "" || itm == " "
		})
		if len(lS) < 6 {
			oL[i+1] = strings.Join(lS, " ") + " " + oL[i+1]
		}
	}
	 
	//map of fields
	stuff := map[int]string{
		0: "Filesystem",
		1: "Size",
		2: "Used",
		3: "Avail",
		4: "Use%",
		5: "Mounted on",
	}

	//create json array
	res := "[\n"
	//range over each line of output 
	for i, l := range oL {
		//create a json object
		lS := strings.Split(l, " ")
		lS = slices.DeleteFunc(lS, func(itm string) bool{
			return itm == "" || itm == " "
		})
		if len(lS) == 1 { continue }
		res += "  {\n"
		var j int //used to keep track of used items in slice 
		for _, t := range strings.Split(l, " ") {
			if t != "" {//ignore whitespace
				//create key-value pair
				res += fmt.Sprintf("    \"%s\": \"%s\"", stuff[j], t)

				//add comma if not last item in object
				if j != len(stuff)-1 { res += "," }

				res += "\n"//newline (clearly)

				j++ //increment counter
			}
		}
		//close object
		res += "  }"

		//add comma if not last object in array
		if i != len(oL)-1 { res += "," }

		res += "\n" //add newline
	}
	res += "]\n" //close json array
	
	//send json result
	w.Write([]byte(res))
}
