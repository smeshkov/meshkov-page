#!/bin/sh
# Stop the photo bucket from being publicly listable.
#
# Right now `curl https://storage.googleapis.com/zoomio-public?max-keys=1000`
# returns an index of every object in the bucket, so the whole archive can be
# enumerated and bulk-downloaded by anyone. That comes from `allUsers` holding
# roles/storage.objectViewer, which includes storage.objects.list.
#
# roles/storage.legacyObjectReader grants storage.objects.get WITHOUT list:
# individual images still load for visitors, the index no longer resolves.
#
# Usage:
#   _bin/lock-bucket.sh                      # dry run, default bucket
#   _bin/lock-bucket.sh --apply              # apply, default bucket
#   _bin/lock-bucket.sh my-bucket --apply    # apply, named bucket

set -e

BUCKET="zoomio-public"
APPLY=""
PROBE="meshkov-page/home-gallery/ARV04718_three_rocks.jpg"

for arg in "$@"; do
    case "$arg" in
        --apply) APPLY=1 ;;
        -*)      echo "unknown option: $arg" >&2; exit 2 ;;
        *)       BUCKET="$arg" ;;
    esac
done

echo "== public bindings on gs://$BUCKET =="

# Read the policy on its own so a gcloud failure is not swallowed by the
# grep pipeline below.
policy=$(gcloud storage buckets get-iam-policy "gs://$BUCKET" \
    --flatten="bindings[].members" \
    --format="value[separator='  '](bindings.members, bindings.role)") || {
    echo >&2
    echo "Could not read the IAM policy for gs://$BUCKET — stopping." >&2
    exit 1
}

public=$(printf '%s\n' "$policy" \
    | grep -E '^(allUsers|allAuthenticatedUsers)[[:space:]]' || true)

if [ -n "$public" ]; then
    printf '%s\n' "$public" | sed 's/^/  /'
else
    echo "  (none — bucket is not publicly readable)"
fi

if [ -z "$APPLY" ]; then
    echo
    echo "Dry run. To apply:"
    echo "  _bin/lock-bucket.sh $BUCKET --apply"
    exit 0
fi

# Never hand public read to a bucket that does not already have it.
if ! printf '%s\n' "$public" | grep -q '^allUsers[[:space:]]*roles/storage.objectViewer$'; then
    echo
    echo "allUsers does not hold roles/storage.objectViewer here, so there is"
    echo "nothing to swap. Leaving the policy alone rather than granting public"
    echo "read to a bucket that may be private on purpose."
    exit 0
fi

# legacyBucketReader independently grants storage.objects.list, so leaving it
# in place would keep the bucket listable no matter what we do to objectViewer.
HAS_LEGACY_BUCKET=""
if printf '%s\n' "$public" | grep -q '^allUsers[[:space:]]*roles/storage.legacyBucketReader$'; then
    HAS_LEGACY_BUCKET=1
fi

echo
echo "== plan for gs://$BUCKET =="
echo "  grant   allUsers  roles/storage.legacyObjectReader   (objects.get only)"
echo "  revoke  allUsers  roles/storage.objectViewer         (carried objects.list)"
if [ -n "$HAS_LEGACY_BUCKET" ]; then
    echo "  revoke  allUsers  roles/storage.legacyBucketReader   (also carries objects.list)"
fi
echo
printf 'Apply this to gs://%s? [y/N] ' "$BUCKET"
read -r reply
case "$reply" in
    y|Y|yes|YES) ;;
    *) echo "Aborted, nothing changed."; exit 0 ;;
esac

echo
echo "== granting legacyObjectReader (read without list) =="
gcloud storage buckets add-iam-policy-binding "gs://$BUCKET" \
    --member=allUsers --role=roles/storage.legacyObjectReader >/dev/null

echo "== revoking objectViewer (which carried the list permission) =="
gcloud storage buckets remove-iam-policy-binding "gs://$BUCKET" \
    --member=allUsers --role=roles/storage.objectViewer >/dev/null

if [ -n "$HAS_LEGACY_BUCKET" ]; then
    echo "== revoking legacyBucketReader (also carried the list permission) =="
    gcloud storage buckets remove-iam-policy-binding "gs://$BUCKET" \
        --member=allUsers --role=roles/storage.legacyBucketReader >/dev/null
fi

echo
echo "== verifying =="

printf 'listing  (want AccessDenied): '
listing=$(curl -s "https://storage.googleapis.com/$BUCKET?max-keys=3")
case "$listing" in
    *AccessDenied*)      echo "OK — listing refused" ;;
    *ListBucketResult*)  echo "STILL PUBLIC — listing returned objects"; exit 1 ;;
    *)                   echo "unexpected:"; echo "$listing" | head -c 200 ;;
esac

printf 'image    (want HTTP 200):     '
curl -so /dev/null -w '%{http_code}\n' "https://storage.googleapis.com/$BUCKET/$PROBE"
