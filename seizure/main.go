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
	"math/rand/v2"
	"github.com/gliderlabs/ssh"
	keeper "github.com/Supraboy981322/keeper/golang"
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

func is_browser(r *http.Request) bool { 
	accept := r.Header["Accept"]
	if len(accept) > 1 { return true }
	if len(accept) < 1 { return false }
	if len(bytes.Split([]byte(accept[0]), []byte{','})) > 1 { return true }
	return false
}

func split(in string) struct{ proto Protocol; port int } {
	for i, r := range in {
		if r == '=' {

			var proto_raw []rune
			for _, r2 := range in[:i] {
				if r2 >= 'A' && r2 <= 'Z' {
					proto_raw = append(proto_raw, r2+32)
				} else {
					proto_raw = append(proto_raw, r2)
				}
			}

			var proto Protocol
			switch (string(proto_raw)) {
				case "http": { proto = HTTP }
				case "ssh":  { proto = SSH  }
				case "tcp":  { proto = TCP  }
				default: {
					fmt.Fprintf(
						os.Stderr,
						"invalid or unsupported protocol: %s\n",
						string(proto_raw),
					)
					os.Exit(1)
				}
			}

			var port int
			if i+1 >= len(in) { goto bad_port } else {
				var e error
				port, e = strconv.Atoi(in[i+1:])
				if e != nil { goto bad_port }
			}

			return struct{
				proto Protocol;
				port int
			} {
				proto: proto,
				port: port,
			}

			bad_port: {
				fmt.Fprintf(
					os.Stderr,
					"invalid port number: %s\n",
					in[i+1:],
				)
				os.Exit(1)
			}
		}
	}

	fmt.Fprintf(
		os.Stderr,
		"invalid port assignment (need something like this: 'http=9774'): %s",
		in,
	)
	os.Exit(1)
	panic(nil) 
}
