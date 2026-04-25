#!/usr/bin/env bash
set -eux -o pipefail
rm root || true
rm meta || true
nixos-rebuild build-image --image-variant lxc --flake .#container
ln -s $(realpath result/tarball/nixos-image-lxc*) root
nixos-rebuild build-image --image-variant lxc-metadata --flake .#container
ln -s $(realpath result/tarball/nixos-image-lxc-metadata*) meta
incus image import meta root
