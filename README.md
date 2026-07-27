# Meshkov Page

My personal website.

## Tech stack

- [Go](https://go.dev/)
- [Hugo](https://gohugo.io/)

## Useful commands

- start local server `hugo server -D`
- publish site to production `_bin/deploy.sh`
- create content `hugo new content content/posts/my-first-post.md`
- process gallery photos before uploading `_bin/stamp-copyright.sh ./photo_data/home-gallery && _bin/resize-gallery.sh ./photo_data/home-gallery ./photo_data_web/home-gallery`
- process YT thumbs before uploading `_bin/stamp-copyright.sh ./photo_data/yt_thumbs && _bin/resize-gallery.sh ./photo_data/yt_thumbs ./photo_data_web/yt_thumbs`
- check photo references in the bucket against the local ones `_bin/check-photo-refs.sh`
- upload gallery photos and thumbs `_bin/upload-photos.sh --apply --delete`