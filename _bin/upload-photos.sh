#!/bin/sh
# Upload processed photographs to the public bucket.
#
# Every top-level folder inside the source directory is mirrored to a folder of
# the same name under gs://zoomio-public/meshkov-page/, so:
#
#   photo_data_web/home-gallery/  ->  gs://zoomio-public/meshkov-page/home-gallery/
#   photo_data_web/yt_thumbs/     ->  gs://zoomio-public/meshkov-page/yt_thumbs/
#
# which is exactly where data/photos.json and data/films.json expect them.
#
# Dry run by default. Nothing is written until you pass --apply and confirm.
#
# Usage:
#   _bin/upload-photos.sh                        # show what would change
#   _bin/upload-photos.sh --apply                # upload
#   _bin/upload-photos.sh --apply --delete       # upload and remove bucket
#                                                # objects no longer held locally
#   _bin/upload-photos.sh ~/other/folder --apply

set -e

SRC="photo_data_web"
DEST="gs://zoomio-public/meshkov-page"
APPLY=""
DELETE=""

# Filenames are stable, so a long cache is safe. Re-uploading a corrected edit
# under the same name will take up to this long to propagate; drop it if you
# expect to overwrite frequently.
CACHE_CONTROL="public, max-age=604800"

# Junk that should never reach the bucket.
EXCLUDE='.*/\..*|\..*|.*/Icon\r$'

for arg in "$@"; do
    case "$arg" in
        --apply)            APPLY=1 ;;
        --delete)           DELETE=1 ;;
        --cache-control=*)  CACHE_CONTROL="${arg#--cache-control=}" ;;
        --dest=*)           DEST="${arg#--dest=}" ;;
        -*)                 echo "unknown option: $arg" >&2; exit 2 ;;
        *)                  SRC="$arg" ;;
    esac
done

SRC="${SRC%/}"

if [ ! -d "$SRC" ]; then
    echo "Source directory not found: $SRC" >&2
    exit 1
fi

FOLDERS=$(find "$SRC" -mindepth 1 -maxdepth 1 -type d ! -name '.*' | sort)

if [ -z "$FOLDERS" ]; then
    echo "No folders inside $SRC — nothing to upload." >&2
    exit 1
fi

echo "== $SRC -> $DEST =="
echo
for dir in $FOLDERS; do
    name=$(basename "$dir")
    images=$(find "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' \
        -o -iname '*.png' -o -iname '*.webp' -o -iname '*.avif' \) | wc -l | tr -d ' ')
    other=$(find "$dir" -type f ! -name '.*' \
        ! \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
        -o -iname '*.webp' -o -iname '*.avif' \) | wc -l | tr -d ' ')
    size=$(du -sh "$dir" | cut -f1 | tr -d ' ')
    printf '  %-16s %4s images  %6s  -> %s/%s/\n' "$name" "$images" "$size" "$DEST" "$name"
    [ "$other" -gt 0 ] && printf '  %-16s note: %s non-image file(s) will also be uploaded\n' "" "$other"
done

# CACHE_CONTROL contains a space, so the arguments must stay as separate argv
# entries rather than being flattened into one string.
run_rsync() {
    _src="$1"
    _dst="$2"
    shift 2
    gcloud storage rsync \
        --recursive \
        --exclude="$EXCLUDE" \
        --cache-control="$CACHE_CONTROL" \
        ${DELETE:+--delete-unmatched-destination-objects} \
        "$@" \
        "$_src" "$_dst"
}

if [ -z "$APPLY" ]; then
    echo
    echo "== dry run =="
    for dir in $FOLDERS; do
        name=$(basename "$dir")
        plan=$(run_rsync "$dir" "$DEST/$name" --dry-run 2>&1 || true)

        # "Would copy ... to gs://...#<generation>" means the object already
        # exists and would be overwritten; no generation means it is new.
        new=$(printf '%s\n' "$plan" | grep -c 'Would copy .* to gs://[^#]*$' || true)
        over=$(printf '%s\n' "$plan" | grep -c 'Would copy .* to gs://.*#' || true)
        gone=$(printf '%s\n' "$plan" | grep -c 'Would remove' || true)

        echo
        echo "-- $name --"
        echo "  new:        $new"
        echo "  overwrite:  $over"
        if [ -n "$DELETE" ]; then
            echo "  delete:     $gone"
        elif [ "$gone" -gt 0 ]; then
            echo "  bucket-only: $gone (left alone; pass --delete to remove)"
        fi
        printf '%s\n' "$plan" | grep 'Would copy .* to gs://[^#]*$' \
            | sed 's|.*/||; s/^/    + /' | head -6
    done

    echo
    _bin/check-photo-refs.sh "$SRC" "$DEST" || true

    echo
    echo "Nothing was written. To upload:"
    echo "  _bin/upload-photos.sh $SRC --apply"
    exit 0
fi

echo
[ -n "$DELETE" ] && echo "WARNING: --delete will remove objects under $DEST/<folder>/"
[ -n "$DELETE" ] && echo "         that are not present locally."
printf 'Upload to %s? [y/N] ' "$DEST"
read -r reply
case "$reply" in
    y|Y|yes|YES) ;;
    *) echo "Aborted, nothing uploaded."; exit 0 ;;
esac

for dir in $FOLDERS; do
    name=$(basename "$dir")
    echo
    echo "== uploading $name =="
    run_rsync "$dir" "$DEST/$name"
done

echo
echo "== verifying =="
probe=$(find $FOLDERS -type f -iname '*.jpg' 2>/dev/null | head -1)
if [ -n "$probe" ]; then
    rel="${probe#"$SRC"/}"
    url="https://storage.googleapis.com/${DEST#gs://}/$rel"
    printf 'public read: '
    curl -so /dev/null -w '%{http_code}  %{content_type}\n' "$url"
    echo "  $url"
fi

echo
echo "Done. If the filenames changed, update data/photos.json and data/films.json."
