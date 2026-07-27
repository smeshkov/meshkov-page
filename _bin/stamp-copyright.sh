#!/bin/sh
# Embed IPTC/XMP copyright and contact metadata into the photographs.
#
# This is the part that survives being copied: it travels inside the file, it
# is what reverse-image and provenance tooling reads, and stripping it is
# itself an offence under US DMCA 1202 and equivalents elsewhere.
#
# Needs exiftool:  brew install exiftool
# Run this on your ORIGINALS, before resizing and uploading.
#
#   _bin/stamp-copyright.sh /path/to/photos

set -e

DIR="${1:?usage: stamp-copyright.sh <directory>}"
YEAR="${2:-$(date +%Y)}"

CREATOR="Sergey Meshkov"
CONTACT="hello@meshkov.page"
SITE="https://www.meshkov.page/"
TERMS="https://www.meshkov.page/licensing/"
NOTICE="© $YEAR $CREATOR. All rights reserved."
USAGE="All rights reserved. No reproduction, redistribution, or use as training data for machine learning or generative models. Text and data mining rights expressly reserved. Licensing: $TERMS"

echo "Stamping $DIR ..."

exiftool -overwrite_original -r \
    -Copyright="$NOTICE" \
    -IPTC:CopyrightNotice="$NOTICE" \
    -XMP-dc:Rights="$NOTICE" \
    -Artist="$CREATOR" \
    -IPTC:By-line="$CREATOR" \
    -XMP-dc:Creator="$CREATOR" \
    -XMP-xmpRights:Marked=True \
    -XMP-xmpRights:WebStatement="$TERMS" \
    -XMP-xmpRights:UsageTerms="$USAGE" \
    -XMP-plus:Licensor="$SITE" \
    -IPTC:Credit="$CREATOR" \
    -IPTC:Contact="$CONTACT" \
    -XMP-iptcCore:CreatorWorkURL="$SITE" \
    -XMP-iptcCore:CreatorWorkEmail="$CONTACT" \
    -ext jpg -ext jpeg -ext tif -ext tiff -ext png \
    "$DIR"

echo
echo "Spot check:"
find "$DIR" -type f \( -name '*.jpg' -o -name '*.jpeg' \) | head -1 | while read -r f; do
    exiftool -Copyright -Artist -UsageTerms -WebStatement "$f"
done
