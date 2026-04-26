#!/usr/bin/env bash
: ${target=$1}
set -eux -o pipefail
make_snapshot() {
  incus storage volume snapshot restore local flaked-incus latest
  incus launch nixos-base builder --config security.nesting=true
  incus config device add builder nix-store disk pool=local source=flaked-incus path=/nix/store
  sleep 5
  incus file push flake.nix builder/etc/nixos/flake.nix
  incus file push flake.lock builder/etc/nixos/flake.lock
  incus exec -- builder nixos-rebuild build --flake /etc/nixos#$target
  incus rm --force builder
  incus storage volume snapshot create local flaked-incus $target
  incus storage volume snapshot create local flaked-incus latest --reuse
}

if ! incus storage volume snapshot show local flaked-incus/$target &> /dev/null; then
  make_snapshot
fi
incus storage volume copy local/flaked-incus/$target local/flaked-incus-$target-workload
incus launch nixos-base $target
incus config device add $target flaked-incus-$target-workload disk pool=local source=flaked-incus path=/nix/store
incus file push flake.nix $target/etc/nixos/flake.nix
incus file push flake.lock $target/etc/nixos/flake.lock
sleep 5
incus exec -- $target nixos-rebuild switch --flake /etc/nixos#$target
