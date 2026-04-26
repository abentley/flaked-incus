#!/usr/bin/env bash
: ${target=$1}
set -eux -o pipefail
make_snapshot() {
  incus storage volume snapshot create local flaked-incus $SNAPSHOT_HASH
  incus storage volume snapshot create local flaked-incus latest --reuse
}
incus storage volume snapshot restore local flaked-incus latest
incus launch nixos-base builder --config security.nesting=true
incus config device add builder nix-dir disk pool=local source=flaked-incus path=/nix
incus file push flake.nix builder/etc/nixos/flake.nix
incus file push flake.lock builder/etc/nixos/flake.lock
sleep 5
STORE_PATH=$(incus exec -- builder nix build /etc/nixos#.nixosConfigurations.${target}.config.system.build.toplevel --print-out-paths)
SNAPSHOT_HASH=$(echo -n "$STORE_PATH"|sha256sum|cut -c1-16)
if ! incus storage volume snapshot show local flaked-incus/$SNAPSHOT_HASH &> /dev/null; then
  make_snapshot
fi
incus rm --force builder
incus storage volume copy local/flaked-incus/$SNAPSHOT_HASH local/flaked-incus-$target-workload
incus launch nixos-base $target
incus config device add $target flaked-incus-$target-workload disk pool=local source=flaked-incus path=/nix
sleep 5
incus exec -- $target $STORE_PATH/bin/switch-to-configuration switch
