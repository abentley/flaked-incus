#!/usr/bin/env bash
set -eux -o pipefail
scriptdir=$(dirname $(readlink -f $0))
: ${target=$1}
: ${instance=$2}
STORE_PATH=$($scriptdir/ensure-flake.sh $target)
incus storage volume copy local/flaked-incus/latest local/flaked-incus-$instance-workload
incus launch nixos-base $instance
incus config device add $instance flaked-incus-$instance-workload disk pool=local source=flaked-incus-$instance-workload path=/nix
sleep 5
incus exec -- $instance $STORE_PATH/bin/switch-to-configuration switch
