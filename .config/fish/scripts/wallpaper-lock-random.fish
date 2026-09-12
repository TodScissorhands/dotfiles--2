#!/usr/bin/env fish
# Mirror the state-selected desktop image for swaylock.
# Theme lock/ folders remain untouched and are no longer used.

set -g themes_dir "$HOME/.config/wallpapers/themes"
set -g state_file "$HOME/.cache/wallpaper-state.json"
set -g lock_file "$HOME/.cache/current_lock.png"

function fail --argument-names message
    echo "wallpaper-lock-random: $message" >&2
    exit 1
end

function theme_images --argument-names theme
    set -l directory "$themes_dir/$theme/home"
    test -d "$directory"; or return
    for image in "$directory"/*.{png,jpg,jpeg,webp,PNG,JPG,JPEG,WEBP}
        test -f "$image"; and echo "$image"
    end
end

command -q jq; or fail "'jq' is not installed or is not on PATH"
test -f "$state_file"; or fail "no saved wallpaper selection; open the wallpaper picker first"

set -l theme (jq -r '.theme // empty' "$state_file" 2>/dev/null)
set -l index (jq -r '.home_index // 0 | if type == "number" then floor else 0 end' "$state_file" 2>/dev/null)
test -n "$theme"; or fail "state file has no selected theme"

set -l images (theme_images "$theme")
set -l image_count (count $images)
test "$image_count" -gt 0; or fail "theme '$theme' has no supported images in home/"
set index (math "($index % $image_count + $image_count) % $image_count")
set -l array_index (math "$index + 1")

command mkdir -p (path dirname "$lock_file")
command ln -sfn "$images[$array_index]" "$lock_file"
    or fail "could not update lockscreen image"
