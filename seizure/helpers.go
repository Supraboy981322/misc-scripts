package main

import (
	"os"
	"strconv"
	"net/http"
	"math/rand/v2"
)

func is_browser(r *http.Request) bool { 
	accept := r.Header["Accept"]
	if len(accept) > 1 { return true }
	if len(accept) < 1 { return false }
	if len(split_header(accept[0], ',')) > 1 { return true }
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
					log.Error(
						"invalid or unsupported protocol:",
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
				log.Error(
					"invalid port number:",
					in[i+1:],
				)
				os.Exit(1)
			}
		}
	}

	log.Error(
		"invalid port assignment (need something like this: 'http=9774'):",
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
		res = append(res, picked)
	}
	return res
}

func split_header(og string, by rune) []string {
	var res []string
	var start int
	loop: for i, r := range og {
		if r == by {
			if start < i && og[start:i] != string(by) {
				res = append(res, og[start:i])
				start = i+1
			}
			continue loop
		}
	}
	if og[start:] != string(by) && len(og[start:]) > 0 {
		res = append(res, og[start:])
	}
	return res
}
