#!/usr/bin/env bash
set -eux -o pipefail
nixos-rebuild build-image --image-variant lxc --flake .#container
root=$(realpath result/tarball/nixos-image-lxc*)
nixos-rebuild build-image --image-variant lxc-metadata --flake .#container
meta=$(realpath result/tarball/nixos-image-lxc-metadata*)
incus image import $meta $root --alias nixos-base
incus launch -e nixos-base builder --config security.nesting=true
incus storage volume create local flaked-incus
incus config device add builder nix-store disk pool=local source=flaked-incus path=/mnt/nix-store
incus exec builder -- bash -c "cd /nix/store && tar -cf - . | tar -xf - -C /mnt/nix-store"
incus config device remove builder nix-store
incus config device add builder nix-store disk pool=local source=flaked-incus path=/nix/store
incus restart builder
incus file push flake.nix builder/etc/nixos/flake.nix
incus exec -- builder nixos-rebuild build --flake /etc/nixos#container
incus stop builder
