#!/bin/sh
# Build web-sized copies of the photographs for the public bucket.
#
# The bucket currently holds files up to 2048px on the long edge, which is
# comfortably printable. 1400px is more than enough for a full-bleed frame on a
# retina display and removes the print-quality prize entirely.
#
# Copyright metadata is preserved (-strip is deliberately NOT used); only the
# camera EXIF and GPS are dropped, so location data does not ship with the
# photographs.
#
# Needs ImageMagick:  brew install imagemagick
#
#   _bin/resize-gallery.sh ~/photos/originals ~/photos/web
#   gcloud storage rsync -r ~/photos/web gs://zoomio-public/meshkov-page

set -e

SRC="${1:?usage: resize-gallery.sh <src-dir> <out-dir> [max-px]}"
OUT="${2:?usage: resize-gallery.sh <src-dir> <out-dir> [max-px]}"
MAX="${3:-1400}"

mkdir -p "$OUT"

find "$SRC" -type f \( -iname '*.jpg' -o -iname '*.jpeg' \) | while read -r f; do
    rel="${f#"$SRC"/}"
    dst="$OUT/$rel"
    mkdir -p "$(dirname "$dst")"

    magick "$f" \
        -auto-orient \
        -resize "${MAX}x${MAX}>" \
        -quality 82 \
        -sampling-factor 4:2:0 \
        -interlace JPEG \
        -define jpeg:dct-method=float \
        "$dst"

    # Carry the rights metadata across, leave GPS and camera EXIF behind.
    exiftool -overwrite_original -quiet \
        -tagsFromFile "$f" \
        -Copyright -Artist -IPTC:CopyrightNotice -IPTC:By-line -IPTC:Credit \
        -IPTC:Contact -XMP-dc:Rights -XMP-dc:Creator -XMP-xmpRights:all \
        -XMP-iptcCore:CreatorWorkURL -XMP-iptcCore:CreatorWorkEmail \
        "$dst"

    printf '%s  ->  %s\n' "$rel" "$(du -h "$dst" | cut -f1)"
done

echo
echo "Originals stay out of the public bucket. Upload only $OUT."
