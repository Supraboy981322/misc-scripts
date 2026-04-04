package main

import (
	"os"
	"io"
	"log"
	"net"
	"bytes"
	_"embed"
	"strconv"
	"net/http"
	"math/rand/v2"
	"github.com/gliderlabs/ssh"
	keeper "github.com/Supraboy981322/keeper/golang"
)

//go:embed foo.txt
var stolen_data []byte

//go:embed foo.html
var browser_page []byte

var port = "9983"

func init() {
	if len(os.Args) > 1 {
		port = os.Args[1]
	}
	{
		var css_stuff []byte
		for i := range 100 {
			newline := append(
				[]byte(strconv.Itoa(i)),
				append(
					append(
						[]byte("%{background-color:"),
						random_hex()...,
					),
					'}',
				)...,
			)
			css_stuff = append(css_stuff, newline...)
		}
		browser_page = bytes.ReplaceAll(browser_page, []byte("/* ze stuff */"), css_stuff)
	}
}

func main() {
	ssh.Handle(func(s ssh.Session) {
		log.Printf("connection (ssh): %s", s.RemoteAddr().String())
		give_seizure(s)
	})

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if is_browser(r) {
			log.Printf("request (browser) (http): %s", r.RemoteAddr)
			w.Write(browser_page)
		} else {
			log.Printf("request (not browser) (http): %s", r.RemoteAddr)
			give_seizure(w)
		}
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

func is_browser(r *http.Request) bool { 
	accept := r.Header["Accept"]
	if len(accept) > 1 { return true }
	if len(accept) < 1 { return false }
	if len(bytes.Split([]byte(accept[0]), []byte{','})) > 1 { return true }
	return false
}
