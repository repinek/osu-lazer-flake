#!/usr/bin/env -S nix shell nixpkgs#curl nixpkgs#jq -c bash
set -euo pipefail

releases="$(curl -fsSL "https://api.github.com/repos/ppy/osu/releases")"

lazer="$(jq -c 'first(.[] | select(.tag_name | endswith("-lazer")))' <<< "$releases")"
tachyon="$(jq -c 'first(.[] | select(.tag_name | endswith("-tachyon")))' <<< "$releases")"

lazer_version="$(jq -r '.tag_name | rtrimstr("-lazer")' <<< "$lazer")"
tachyon_version="$(jq -r '.tag_name | rtrimstr("-tachyon")' <<< "$tachyon")"

lazer_hash="$(nix hash convert --hash-algo sha256 "$(jq -r '.assets[] | select(.name == "osu.AppImage") | .digest | ltrimstr("sha256:")' <<< "$lazer")")"
tachyon_hash="$(nix hash convert --hash-algo sha256 "$(jq -r '.assets[] | select(.name == "osu.AppImage") | .digest | ltrimstr("sha256:")' <<< "$tachyon")")"

jq -n \
  --arg lazer_version "$lazer_version" \
  --arg lazer_hash "$lazer_hash" \
  --arg tachyon_version "$tachyon_version" \
  --arg tachyon_hash "$tachyon_hash" \
  '{
    lazer: { tag: "lazer", version: $lazer_version, hash: $lazer_hash },
    tachyon: { tag: "tachyon", version: $tachyon_version, hash: $tachyon_hash }
  }' > osu-lazer-bin/releases.json

sed -Ei \
  -e "s|(releases/tag/)[0-9.]+-lazer|\\1${lazer_version}-lazer|" \
  -e "s|(badge/lazer-)[0-9.]+(-ff66aa)|\\1${lazer_version}\\2|" \
  -e "s|(releases/tag/)[0-9.]+-tachyon|\\1${tachyon_version}-tachyon|" \
  -e "s|(badge/tachyon-)[0-9.]+(-8866ee)|\\1${tachyon_version}\\2|" \
  README.md
