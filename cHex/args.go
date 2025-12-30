package main

import ("os";"fmt")

func wordArg(a string, i int, tak []int) []int {
	switch a[2:] {
	 case "help": help()
	 case "rgb", "true-color":
		chTyp("rgb")
		if len(args) >= i+4 {
			colors.R = args[i+1]
			colors.G = args[i+2]
			colors.B = args[i+3]
			tak = append(tak, []int{i+1, i+2, i+3,}...)
		}
	 case "256":
		chTyp("256")
		if len(args) >= i+1 {
			colors.OldMan = args[i+1]
			tak = append(tak, []int{i+1,}...)
		}
	 case "hex":
		chTyp("hex")
		if len(args) >= i+1 {
			colors.Hex = args[i+1]
			tak = append(tak, []int{i+1,}...)
		}
	 case "bold": format.Bold = true
	 case "italic": format.Italic = true
	 case "underline": format.Underline = true
	 case "blink": format.Blink = true
	 case "strikethrough": format.Strikethrough = true
	 case "bg", "background": format.Which = "4"
	 case "fg", "foreground": format.Which = "3"
	 case "off": fmt.Print("\033[0m");os.Exit(0)
	 default: eror("invalid arg", a)
	}
	tak = append(tak, i)
	return tak
}

func charArg(a string, i int, tak []int) []int {
	for _, c := range a[1:] {
		switch c {
		 case 'h': help()
		 case '3':
			chTyp("rgb")
			if len(args) >= i+4 {
				colors.R = args[i+1]
				colors.G = args[i+2]
				colors.B = args[i+3]
				tak = append(tak, []int{i+1, i+2, i+3,}...)
			}
		 case '2':
			chTyp("256")
			if len(args) >= i+1 {
				colors.OldMan = args[i+1]
				tak = append(tak, []int{i+1,}...)
			}
		 case '1', 'H':
			chTyp("hex")
			if len(args) >= i+1 {
				colors.Hex = args[i+1]
				tak = append(tak, []int{i+1,}...)
			}
		 case 'b': format.Bold = true
		 case 'i': format.Italic = true
		 case 'u': format.Underline = true
		 case 'B': format.Blink = true
		 case 's': format.Strikethrough = true
		 case '0': format.Which = "4"
		 case 'f': format.Which = "3"
	 	 case 'o': fmt.Print("\033[0m");os.Exit(0)
		 default: eror("invalid arg", "char "+string(c)+" in "+a)
		}
	} 
	tak = append(tak, i)
	return tak
}
