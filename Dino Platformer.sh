#!/bin/sh
echo -ne '\033c\033]0;Dino Platformer\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Dino Platformer.x86_64" "$@"
