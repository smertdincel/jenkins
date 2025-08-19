#!/usr/bin/env bash
set -e
ART_DIR="dist"
rm -rf "$ART_DIR"
mkdir -p "$ART_DIR"
cp -r app.py requirements.txt "$ART_DIR"/
tar -czf "$ART_DIR/app.tar.gz" -C "$ART_DIR" app.py requirements.txt
echo "Artifact created at $ART_DIR/app.tar.gz"