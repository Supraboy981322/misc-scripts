package main

import (
	"os"
	"io"
	"fmt"
	"log"
	"net"
	"sync"
	"bytes"
	_"embed"
	"strconv"
	"net/http"
	"github.com/gliderlabs/ssh"
)

//go:embed foo.txt
var stolen_data []byte

//go:embed foo.html
var browser_page []byte

type Protocol int
const (
	HTTP Protocol = iota
	SSH
	TCP
)

var ports = map[Protocol]int{
	HTTP: 9983,
	SSH: 4059,
	TCP: 2085,
}

func init() {
	if len(os.Args) > 1 {
		for _, a := range os.Args[1:] {
			parts := split(a)
			ports[parts.proto] = parts.port
		}
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
	i := 3
	fmt_port_print := func(which string, proto Protocol) string {
		if len(which) == 3{ which = which + " " }
		defer func(){i++}()
		return fmt.Sprintf(
			"\x1b[3%dm%s\x1b[38;2;100;100;150m {" +
					" \x1b[0;38;2;255;165;0m%d" +
					"\x1b[38;2;100;100;150m }\x1b[0m",
			i,
			which,
			ports[proto],
		)
	}
	log.Printf("\tlistening on ports:")

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

	var wg sync.WaitGroup

	wg.Go(func() {
		log.Printf("\t\t%s", fmt_port_print("http", HTTP))
		panic(http.ListenAndServe(":"+strconv.Itoa(ports[HTTP]), nil))
	})

	wg.Go(func() {
		log.Printf("\t\t%s", fmt_port_print("ssh", SSH))
		panic(ssh.ListenAndServe(":"+strconv.Itoa(ports[SSH]), nil))
	})

	wg.Go(func() {
		log.Printf("\t\t%s", fmt_port_print("TCP", TCP))
		panic(tcp())
	})

	wg.Wait()
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
	listener, e := net.Listen("tcp", ":"+strconv.Itoa(ports[TCP]))
	if e != nil { return e }
	defer listener.Close() //shouldn't happen anyways

	for {
		conn, e := listener.Accept()
		if e != nil { continue }
		go func() {
			log.Printf("connection (tcp): %s", "")
			give_seizure(conn)
		}()
	}
}
