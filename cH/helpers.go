package main

import ("os";"fmt";"strconv")

func help() {
	lines := []string{
		"cHex --> help",
		"  args:",
		"    -h, --help",
		"      returns this message",
		"    -3, --rgb, --true-color",
		"      use true-color rgb instead",
		"    -2, --256",
		"      use 256 color instead",
		"    -1, -H, --hex",
		"      does nothing, more obvious that you're using hex (the default)",
		"    -b, --bold",
		"      bold text",
		"    -i, --italic",
		"      italic text",
		"    -u, --underline",
		"      underline text",
		"    -B, --blink",
		"      blink text",
    "    -s, --strikethrough",
		"      strikethrough text",
		"    -0, --bg, --background",
		"      color background",
		"    -f, --fg, --foreground",
		"      color foreground (text)",
	}
	for _, li := range lines {
		fmt.Printf("%s\n", li)
	}
	os.Exit(0)
}

func eror(str1 string, str2 string) {
	errStr := "\033[1m\033[48;2;200;0;0m"
	errStr += str1+"\033[0m\n    \033[1m"
	errStr += "\033[38;2;255;0;0m"+str2
	errStr += "\033[0m"
	fmt.Fprintf(os.Stderr, "%s\n", errStr)
	os.Exit(1)
}

func chTyp(which string) {
	if typ == "" {
		typ = which 
	} else {
		eror("invalid arg", "declared 256 color, but already using "+typ)
	}
}

/*MODIFIED AND REMOVED CHECKS,
 *  THIS PROGRAM SHOULD HAVE ALREADY
 *    DONE CHECKS. */
func hexToAnsi(hex string) string {
	if len(colors.Hex) < 7 {
		eror("invalid arg", "assumed to be hex, but not long enough")
	}
	hex = hex[1:] //remove leading '#'

	hexRed   := hex[0:2]
	hexGreen := hex[2:4]
	hexBlue  := hex[4:6]

	r, _ := strconv.ParseUint(hexRed, 16, 8)
	g, _ := strconv.ParseUint(hexGreen, 16, 8)
	b, _ := strconv.ParseUint(hexBlue, 16, 8)

	ansi := fmt.Sprintf("8;2;%d;%d;%d", r, g, b)

	return ansi
}

func rgbToAnsi(rgb Colors) string {
	var r, g, b int
	var err error
	if r, err = strconv.Atoi(rgb.R); err != nil {
		eror("invalid Rgb value", "R:  "+rgb.R)
	};if g, err = strconv.Atoi(rgb.G); err != nil {
		eror("invalid rGb value", "G:  "+rgb.G)
	};if b, err = strconv.Atoi(rgb.B); err != nil {
		eror("invalid rgB value", "B:  "+rgb.B)
	}

	return fmt.Sprintf("8;2;%d;%d;%d", r, g, b)
}


