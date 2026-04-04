package main

import (
	"io"
	"os"
	"net"
	"fmt"
	"sync"
	"strconv"
	"net/http"
	"crypto/rand"
	"github.com/gliderlabs/ssh"
)

type Protocol int
const (
	HTTP Protocol = iota
	SSH
	TCP
)

var ports = map[Protocol]int{
	HTTP: 9865,
	SSH: 8543,
	TCP: 4309,
}
var wg sync.WaitGroup

func init() {
	if len(os.Args) > 1 {
		for _, a := range os.Args[1:] {
			parts := split(a)
			ports[parts.proto] = parts.port
		}
	}
}

func main() {

	{
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

		fmt.Printf(`
	listening on ports:
		%s
		%s
		%s

`,
			fmt_port_print("ssh", SSH),
			fmt_port_print("http", HTTP),
			fmt_port_print("tcp", TCP),
		)
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Printf(
			"(\x1b[34mhttp\x1b[0m) request: ip{%s}\n",
			r.RemoteAddr,
		)
		do_the_thing(w)
	})

	ssh.Handle(func(s ssh.Session) {
		fmt.Printf(
			"(\x1b[33mssh\x1b[0m) connection: %s",
			s.RemoteAddr().String(),
		)
		do_the_thing(s)
	})

	wg.Go(func() {
		defer wg.Done()
		fmt.Fprintf(
			os.Stderr,
			"%v\n",
			http.ListenAndServe(":"+strconv.Itoa(ports[HTTP]), nil),
		)
	})

	wg.Go(func() {
		defer wg.Done()
		fmt.Fprintf(
			os.Stderr,
			"%v\n",
			ssh.ListenAndServe(":"+strconv.Itoa(ports[SSH]), nil),
		)
	})

	wg.Go(func() {
		defer wg.Done()

		listener, e := net.Listen("tcp", ":"+strconv.Itoa(ports[TCP]))
		if e != nil {
			fmt.Fprintf(os.Stderr, "%v\n",e)
			return
		}
		defer listener.Close() //shouldn't happen anyways

		for {
			conn, e := listener.Accept()
			if e != nil { continue }
			go func() {
				fmt.Printf(
					"(\x1b[35mtcp\x1b[0m) connection: %s",
					conn.RemoteAddr(),
				)
				do_the_thing(conn)
			}()
		}
	})

	wg.Wait()
}

func do_the_thing(wr io.Writer) {
		for {
			b := make([]byte, 1)
			_, e := rand.Read(b)
			if e != nil { panic(e) }
			wr.Write(b)
		}
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
