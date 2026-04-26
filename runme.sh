#!/usr/bin/env bash
set -eux -o pipefail
nixos-rebuild build-image --image-variant lxc --flake .#container
root=$(realpath result/tarball/nixos-image-lxc*)
nixos-rebuild build-image --image-variant lxc-metadata --flake .#container
meta=$(realpath result/tarball/nixos-image-lxc-metadata*)
incus image import $meta $root --alias nixos-base
incus launch -e nixos-base builder --config security.nesting=true
incus storage volume create local flaked-incus
incus config device add builder nix-dir disk pool=local source=flaked-incus path=/mnt/nix
sleep 5
incus exec builder -- bash -c "cd /nix/ && tar -cf - . | tar -xf - -C /mnt/nix"
incus config device remove builder nix-dir
incus config device add builder nix-dir disk pool=local source=flaked-incus path=/nix
incus restart builder
incus file push flake.nix builder/etc/nixos/flake.nix
incus file push flake.lock builder/etc/nixos/flake.lock
sleep 5
incus exec -- builder nixos-rebuild build --flake /etc/nixos#container
incus stop builder
incus storage volume snapshot create local flaked-incus latest
