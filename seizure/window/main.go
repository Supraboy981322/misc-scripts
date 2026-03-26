package main

import (
	_"math"
	"image/color"
	"math/rand/v2"
	rl "github.com/gen2brain/raylib-go/raylib"
)

var can_move bool

func main() {
	rl.InitWindow(1, 1, "seizure")

	{
		center := rl.GetWindowPosition();
		rl.SetWindowPosition(1,1)
		moved := rl.GetWindowPosition()
		can_move = (center.X != moved.X) && (center.Y != moved.Y)
		rl.SetWindowPosition(int(center.X), int(center.Y));
	}

	defer rl.CloseWindow();
	if !can_move { rl.ToggleFullscreen() }
	rl.SetTargetFPS(144);

	rl.SetExitKey(rl.KeyNull)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()
		rl.ClearBackground(color.RGBA{
			R: uint8(rand.IntN(255)),
			G: uint8(rand.IntN(255)),
			B: uint8(rand.IntN(255)),
		})
		if can_move {
			rl.SetWindowPosition(rand.Int(), rand.Int())
		}
		rl.EndDrawing()
	}
}
