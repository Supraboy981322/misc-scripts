package main

import (
	_"math"
	"image/color"
	"math/rand/v2"
	rl "github.com/gen2brain/raylib-go/raylib"
)

func main() {
	rl.InitWindow(0, 0, "seizure")
	defer rl.CloseWindow();
	rl.ToggleFullscreen()
	rl.SetTargetFPS(144);

	rl.SetExitKey(rl.KeyNull)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(color.RGBA{
			R: uint8(rand.IntN(255)),
			G: uint8(rand.IntN(255)),
			B: uint8(rand.IntN(255)),
		})
		rl.EndDrawing()
	}
}
