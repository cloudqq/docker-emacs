#!/bin/sh
VERSION=2.1
docker build -f Dockerfile.emacs26-2 . -t cloudqq/emacs:v$VERSION

