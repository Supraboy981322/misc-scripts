#!/usr/bin/env bash

# TODO: Nix shebang for dependencies
#   - ffmpeg

#if [[ $# -lt 2 ]]; then
#  printf "not enough args"
#  exit 1
#fi

declare continue=true;
declare selected="$(ls | shuf | head -n 1)"
while $continue;do
  declare upnext="$selected"
  printf "\rplaying: '%s'; upnext: '%s'" "$selected" "$upnext"
  ffplay "$selected" -nodisp -autoexit -hide_banner
  selected="$upnext"
done

printf "exiting\n"
