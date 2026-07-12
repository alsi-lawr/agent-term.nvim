#!/usr/bin/env bash
set -euo pipefail

for gif in "$(dirname "$0")"/../assets/*.gif; do
	tmp="$gif.tmp"
	trap 'rm -f "$tmp"' EXIT
	nix run nixpkgs#imagemagick -- -limit memory 1GiB -limit map 2GiB "$gif" -coalesce \
		-bordercolor none -border 40 \
		-write mpr:frames -channel A -blur 0x20 -channel RGB -evaluate set 0 +channel \
		null: mpr:frames -layers Composite -channel A -ordered-dither o8x8 +channel \
		-layers Optimize "gif:$tmp"
	mv "$tmp" "$gif"
done
