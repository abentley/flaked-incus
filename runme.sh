#!/usr/bin/env bash
set -eux -o pipefail
nixos-rebuild build-image --image-variant lxc --flake .#container
root=$(realpath result/tarball/nixos-image-lxc*)
nixos-rebuild build-image --image-variant lxc-metadata --flake .#container
meta=$(realpath result/tarball/nixos-image-lxc-metadata*)
incus image import $meta $root --alias nixos-base
incus launch -e nixos-base builder
incus file push flake.nix builder/etc/nixos/flake.nix
incus exec -- builder nixos-rebuild build --flake /etc/nixos#container
