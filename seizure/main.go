package main

import (
	"os"
	"io"
	"net"
	"sync"
	"bytes"
	_"embed"
	"strconv"
	"net/http"
	"github.com/gliderlabs/ssh"
)

var log Log

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
			//who needs fmt.Sprintf anyways?
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
	{
		var mem []byte
		var seeking bool
		var copied = append([]byte(nil), stolen_data...)
		stolen_data = nil
		loop: for _, b := range copied {
				if seeking {
					if b == '{' { continue loop }
					if b != '}'{
						mem = append(mem, b)
					} else {
						switch string(mem) {
							case "one": { stolen_data = append(stolen_data, 0) }
							case "two": { stolen_data = append(stolen_data, 1) }
							default: { panic(string(mem)) }
						}
						mem = nil
						seeking = false 
					}
					continue loop
				}
				switch b {
					case '{': { seeking = true }
					case '}': {}
					default:  { stolen_data = append(stolen_data, b) }
				}
		}
	}
}

func main() {
	i := byte('3')
	fmt_port_print := func(which string, proto Protocol) string {
		if len(which) == 3{ which = which + " " }
		defer func(){i++}()
		//again, who needs fmt.Sprintf anyways?
		return string(append(
			append(
				append(
					append(
						[]byte("\x1b[3"),
						i,
					),
					append(
						[]byte{'m'},
						[]byte(which)...
					)...
				),
				append(
					[]byte("\x1b[38;2;100;100;150m {" +
						" \x1b[0;38;2;255;165;0m"),
					[]byte(strconv.Itoa(ports[proto]))...
				)...
			),
			[]byte("\x1b[38;2;100;100;150m }\x1b[0m")...
		))
		
	}
	log.Print("\tlistening on ports:")

	ssh.Handle(func(s ssh.Session) {
		log.Print("connection (ssh):", s.RemoteAddr().String())
		give_seizure(s)
	})

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if is_browser(r) {
			log.Print("request (browser) (http):", r.RemoteAddr)
			w.Write(browser_page)
		} else {
			log.Print("request (not browser) (http):", r.RemoteAddr)
			give_seizure(w)
		}
	})

	var wg sync.WaitGroup

	wg.Go(func() {
		log.Print("\t\t", fmt_port_print("http", HTTP))
		panic(http.ListenAndServe(":"+strconv.Itoa(ports[HTTP]), nil))
	})

	wg.Go(func() {
		log.Print("\t\t", fmt_port_print("ssh", SSH))
		panic(ssh.ListenAndServe(":"+strconv.Itoa(ports[SSH]), nil))
	})

	wg.Go(func() {
		log.Print("\t\t", fmt_port_print("TCP", TCP))
		panic(tcp())
	})

	wg.Wait()
}

func give_seizure(w io.Writer) { 
	for {
		var frame []byte
		one, two := random_hex(), random_hex()
		for _, b := range stolen_data {
			//could've been a ternary; such a limiting language 
			switch b {
				case 0:  { frame = append(frame, one...) }
				case 1:  { frame = append(frame, two...) }
				default: { frame = append(frame, b) }
			}
		}
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
			log.Print("connection (tcp):", conn.RemoteAddr().String())
			give_seizure(conn)
		}()
	}
}
