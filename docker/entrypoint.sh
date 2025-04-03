#!/bin/bash
# Author : Minho Lee (https://github.com/iminolee)

set -e

if [ ! -f /tmp/.docker.xauth ]; then
    touch /tmp/.docker.xauth
    xauth_list=$(xauth nlist :0 | sed -e 's/^..../ffff/')
    if [ ! -z "$xauth_list" ]; then
        echo "$xauth_list" | xauth -f /tmp/.docker.xauth nmerge -
    fi
    chmod a+r /tmp/.docker.xauth
fi

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║ 🚀  Habitat-Sim Docker Environment Ready!            ║"
echo "║ 📂  Working Directory : /workspace                   ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

export PYTHONPATH=$PYTHONPATH:/tmp/habitat-sim/src_python

cd /workspace

exec bash