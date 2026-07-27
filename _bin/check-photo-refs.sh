#!/bin/sh
# Cross-check the photo URLs in data/*.json against what exists locally and in
# the bucket, so a missing file is caught before it shows up as a broken image
# on the site.
#
#   _bin/check-photo-refs.sh [src-dir] [gs://dest]

set -e

SRC="${1:-photo_data_web}"
DEST="${2:-gs://zoomio-public/meshkov-page}"

# The URLs in data/*.json are written against photoOrigin, so take the prefix
# from there rather than deriving it from the upload destination — otherwise a
# mismatch silently matches nothing and reports a false all-clear.
ORIGIN=$(sed -n "s/^[[:space:]]*photoOrigin[[:space:]]*=[[:space:]]*['\"]\(.*\)['\"].*/\1/p" hugo.toml 2>/dev/null | head -1)
[ -z "$ORIGIN" ] && ORIGIN="https://storage.googleapis.com/${DEST#gs://}"

remote=$(gcloud storage ls --recursive "$DEST/**" 2>/dev/null || true)

printf '%s\n' "$remote" \
    | sed "s|^$DEST/||" \
    | grep -v '/$' > /tmp/_refs_remote.txt || true

find "$SRC" -type f ! -name '.*' 2>/dev/null \
    | sed "s|^$SRC/||" > /tmp/_refs_local.txt || true

REFS="$SRC" ORIGIN="$ORIGIN" python3 <<'PY'
import json, os, pathlib, sys

origin = os.environ["ORIGIN"].rstrip("/")
have = set()
for f in ("/tmp/_refs_local.txt", "/tmp/_refs_remote.txt"):
    p = pathlib.Path(f)
    if p.exists():
        have |= {l.strip() for l in p.read_text().splitlines() if l.strip()}

refs = {}


def note(url, where):
    if isinstance(url, str) and url.startswith(origin):
        refs.setdefault(url[len(origin):].lstrip("/"), set()).add(where)


photos = pathlib.Path("data/photos.json")
if photos.exists():
    d = json.loads(photos.read_text())
    for u in d.get("featured", []):
        note(u, "photos.json:featured")
    for name, arr in (d.get("series") or {}).items():
        for p in arr:
            note(p.get("src"), f"photos.json:{name}")

films = pathlib.Path("data/films.json")
if films.exists():
    for f in json.loads(films.read_text()).get("films", []):
        note(f.get("thumb"), "films.json")

missing = {k: v for k, v in refs.items() if k not in have}

print("== reference check ==")
print(f"  origin: {origin}")
print(f"  {len(refs)} photo URLs referenced by data/*.json")

if not refs:
    print("  ! no URLs matched that origin — photoOrigin in hugo.toml and the")
    print("    URLs in data/*.json disagree, so nothing was actually checked.")
    sys.exit(1)

if not missing:
    print("  all resolve to a local file or an existing bucket object")
    sys.exit(0)

print(f"  {len(missing)} WILL NOT RESOLVE:")
for k in sorted(missing):
    print(f"    ! {k}")
    for w in sorted(missing[k]):
        print(f"        referenced by {w}")
sys.exit(1)
PY
