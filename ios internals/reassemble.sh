#!/bin/sh
# "Mac OS X and iOS Internals.mp4" exceeds GitHub LFS's 2 GB per-file limit, so it is stored in parts.
# Run this after cloning (with git-lfs installed) to rebuild the original file.
set -e
cd "$(dirname "$0")"
cat "Mac OS X and iOS Internals.mp4.part-"* > "Mac OS X and iOS Internals.mp4"
echo "e1cfd14ea3e2c471fce630d019e215abd7ec70c272df5efaed9ae9f4c32ede4c  Mac OS X and iOS Internals.mp4" | shasum -a 256 -c -
