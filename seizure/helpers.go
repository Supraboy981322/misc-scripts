package main

import (
	"os"
	"fmt"
	"bytes"
	"strconv"
	"net/http"
	"math/rand/v2"
	keeper "github.com/Supraboy981322/keeper/golang"
)

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

func random_hex() []byte {
	res := []byte{'#'}
	possible := []byte("0123456789abcdef")
	for range 6 {
		picked := possible[rand.IntN(len(possible))]
		keeper.Add(&res, picked)
	}
	return res
}
