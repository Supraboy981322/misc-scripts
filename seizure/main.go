package main

import (
	"os"
	"log"
	_"embed"
	"net/http"
)

//go:embed foo.txt
var stolen_data []byte

var port = "9983"

func init() {
	if len(os.Args) > 1 {
		port = os.Args[1]
	}
}

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("request: %s", r.RemoteAddr)
		for {
			w.Write(stolen_data)
		}
	})
	log.Printf("listening on port: %s", port)
	panic(http.ListenAndServe(":"+port, nil))
}
