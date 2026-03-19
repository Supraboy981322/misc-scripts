package main

import (
	"os"
	"log"
	"bytes"
	_"embed"
	"net/http"
	"math/rand/v2"
	keeper "github.com/Supraboy981322/keeper/golang"
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
			frame := stolen_data
			frame = bytes.ReplaceAll(frame, []byte("{{one}}"), random_hex())
			frame = bytes.ReplaceAll(frame, []byte("{{two}}"), random_hex())
			w.Write(frame)
		}
	})
	log.Printf("listening on port: %s", port)
	panic(http.ListenAndServe(":"+port, nil))
}

func random_hex() []byte {
	res := []byte{'#'}
	possible := []byte("0123456789abcdef")
	for range 6 {
		picked := possible[rand.IntN(len(possible))]
		keeper.Add(&res, picked)
	}
	return res
}
