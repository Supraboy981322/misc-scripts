#! /usr/bin/env nix-shell
#! nix-shell -i bash -p go mesa libXi libXcursor libXrandr libglvnd libXinerama wayland libxkbcommon pkg-config bash
TMP=$(mktemp "$(dirname "$0")/tmp_XXXXXXX.go")
trap 'rm -f "$TMP"' EXIT INT TERM
sed '1,7 s/.*//' "$0" > "$TMP"
go run "$TMP" "$@"
exit $?
package main

import (
	"os"
	"time"
	rl "github.com/gen2brain/raylib-go/raylib"
)

func main() {

	msg := "unknown error"
	if len(os.Args) > 1 { msg = os.Args[1] }
	msg_width := rl.MeasureText(msg, 20)

  rl.InitWindow(msg_width * 2, 400, "thar hath been an error")
  defer func(){
		rl.BeginDrawing()
		rl.ClearBackground(rl.Black)
		closing_msg_width := rl.MeasureText("closing...", 20)
		closing_msg_left_pad := (int32(rl.GetScreenWidth()) - closing_msg_width) / 2
		//print message 
		rl.DrawText(
			"closing...",
			closing_msg_left_pad,
			int32(rl.GetScreenHeight() / 2),
			20,
			rl.RayWhite,
		)
		rl.EndDrawing()
		//wait 75ms before exiting
		time.Sleep(75 * time.Millisecond)
		rl.CloseWindow()
	}()

  rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
    rl.BeginDrawing()
		left_pad := (int32(rl.GetScreenWidth()) - msg_width) / 2
	 	msg_width = rl.MeasureText(msg, 20)

    rl.ClearBackground(rl.Black)
    rl.DrawText(
			msg,
			left_pad,
			int32(rl.GetScreenHeight() / 2),
			20,
			rl.Red,
		)

		if is_ctrl_down() && rl.IsKeyDown(rl.KeyC) {
			goto foo
		}

    rl.EndDrawing()
  }
	foo: {
		rl.EndDrawing()
	}
}

func is_ctrl_down() bool {
	return rl.IsKeyDown(rl.KeyRightControl) || rl.IsKeyDown(rl.KeyLeftControl)
}
