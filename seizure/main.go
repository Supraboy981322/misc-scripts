package main

import (
	"os"
	"io"
	"log"
	"net"
	"bytes"
	_"embed"
	"net/http"
	"math/rand/v2"
	"github.com/gliderlabs/ssh"
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
	ssh.Handle(func(s ssh.Session) {
		log.Printf("connection (ssh): %s", s.RemoteAddr().String())
		give_seizure(s)
	})

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		log.Printf("request (http): %s", r.RemoteAddr)
		give_seizure(w)
	})

	go func() {
		log.Printf("ssh listening on port: %d", 22222)
		panic(ssh.ListenAndServe(":22222", nil))
	}()

	go func() {
		log.Printf("http listening on port: %s", port)
		panic(http.ListenAndServe(":"+port, nil))
	}()

	go panic(tcp())

	select{}
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

func give_seizure(w io.Writer) { 
	for {
		frame := stolen_data
		frame = bytes.ReplaceAll(frame, []byte("{{one}}"), random_hex())
		frame = bytes.ReplaceAll(frame, []byte("{{two}}"), random_hex())
		w.Write(frame)
	}
}

func tcp() error {
	listener, e := net.Listen("tcp", ":7445")
	if e != nil { return e }
	defer listener.Close() //shouldn't happen anyways
	log.Printf("tcp listening on port 7445")

	for {
		conn, e := listener.Accept()
		if e != nil { continue }
		go func() {
			log.Printf("connection (tcp): %s", "")
			give_seizure(conn)
		}()
	}
}
