#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

directory=${1:?Usage: $(basename "$0") GIF_DIRECTORY}

[[ -d $directory ]] || {
    printf 'Not a directory: %s\n' "$directory" >&2
    exit 1
}

width=1600
height=900
fps=15
radius=9
shadow_size=40
shadow_blur=12
shadow_opacity=0.45

canvas_width=$((width + shadow_size * 2))
canvas_height=$((height + shadow_size * 2))

gifs=("$directory"/*.gif)

((${#gifs[@]} > 0)) || {
    printf 'No GIFs found in %s\n' "$directory" >&2
    exit 1
}

tmpdir=$(mktemp -d)
trap 'rm -rf -- "$tmpdir"' EXIT

mask="$tmpdir/rounded-mask.png"
shadow="$tmpdir/shadow.png"

frame_x=$shadow_size
frame_y=$shadow_size
frame_right=$((frame_x + width - 1))
frame_bottom=$((frame_y + height - 1))

magick \
    -size "${width}x${height}" \
    xc:black \
    -fill white \
    -draw "roundrectangle 0,0,$((width - 1)),$((height - 1)),$radius,$radius" \
    "$mask"

magick \
    -size "${canvas_width}x${canvas_height}" \
    xc:none \
    -fill black \
    -draw "roundrectangle $frame_x,$frame_y,$frame_right,$frame_bottom,$radius,$radius" \
    -channel A \
    -blur "0x$shadow_blur" \
    -evaluate multiply "$shadow_opacity" \
    +channel \
    "$shadow"

for gif in "${gifs[@]}"; do
    output="${gif%.gif}.webp"
    tmp_output="$tmpdir/$(basename -- "$output")"

    printf '%s -> %s\n' "$gif" "$output"

    ffmpeg \
        -hide_banner \
        -loglevel warning \
        -y \
        -ignore_loop 1 \
        -i "$gif" \
        -loop 1 \
        -framerate "$fps" \
        -i "$shadow" \
        -loop 1 \
        -framerate "$fps" \
        -i "$mask" \
        -filter_complex "
            [0:v]
                fps=$fps,
                scale=$width:$height:flags=lanczos,
                format=rgba
                [gif];

            [2:v]
                format=gray
                [mask];

            [gif][mask]
                alphamerge=shortest=1
                [rounded];

            [1:v]
                format=rgba
                [shadow];

            [shadow][rounded]
                overlay=x=$frame_x:y=$frame_y:shortest=1:format=auto,
                format=rgba
                [out]
        " \
        -map '[out]' \
        -an \
        -c:v libwebp_anim \
        -quality 100 \
        -compression_level 3 \
        -lossless 0 \
        -loop 0 \
        "$tmp_output"

    mv -- "$tmp_output" "$output"
done
