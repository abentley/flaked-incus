#!/usr/bin/env bash
set -eux -o pipefail
: ${target=$1}
incus storage volume snapshot restore local flaked-incus latest
incus launch nixos-base builder --config security.nesting=true > /dev/null
incus config device add builder nix-dir disk pool=local source=flaked-incus path=/nix > /dev/null
incus file push flake.nix builder/etc/nixos/flake.nix > /dev/null
incus file push flake.lock builder/etc/nixos/flake.lock > /dev/null
sleep 5
STORE_PATH=$(incus exec -- builder env XDG_CACHE_HOME=/nix/eval-cache nix build /etc/nixos#.nixosConfigurations.${target}.config.system.build.toplevel --print-out-paths --no-link)
incus storage volume snapshot create local flaked-incus latest --reuse
incus rm --force builder
echo $STORE_PATH
