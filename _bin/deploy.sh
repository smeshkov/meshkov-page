#!/bin/sh

BUCKET="$1"
PROJECT="$2"

if [ -z "$BUCKET" ]; then
    BUCKET="www.meshkov.page"
fi

if [ -z "$PROJECT" ]; then
    PROJECT="zoomer-app"
fi

rm -rf public
# for drafts use: hugo -D
hugo
gcloud config set project $PROJECT
gsutil -m rsync -R public "gs://$BUCKET"