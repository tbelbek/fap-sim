#!/bin/sh
# Build a FAP for the host.
#   ./build.sh <app-dir> <entry-symbol> [extra .c ...]
# e.g.
#   ./build.sh . demo_menu_app
#   FLIPPER_FW=~/flipper/flipperzero-firmware ./build.sh ~/apps/my-fap my_app
set -eu
APP=${1:?usage: ./build.sh <app-dir> <entry> [extra.c ...]}
ENTRY=${2:?usage: ./build.sh <app-dir> <entry>}
shift 2
FW=${FLIPPER_FW:-$HOME/Repos/flipper/flipperzero-firmware}
[ -d "$FW/lib/u8g2" ] || { echo "set FLIPPER_FW to the firmware checkout" >&2; exit 1; }
cd "$(dirname "$0")"
mkdir -p out

SRCS=""
for f in "$FW"/lib/u8g2/*.c; do
    case "$f" in *u8g2_glue.c|*u8g2_d_memory.c) continue ;; esac
    SRCS="$SRCS $f"
done
# the app's own sources, never the simulator's own files (the repo root doubles as an app dir)
for f in "$APP"/*.c; do
    case "$f" in
        */tests/*|*_test.c) continue ;;
        ./shim.c|./gui.c|./run.c|shim.c|gui.c|run.c) continue ;;
    esac
    SRCS="$SRCS $f"
done

CFLAGS="-std=c11 -O1 -g -ffunction-sections -fdata-sections -DSIM_ENTRY=$ENTRY -I include -I $FW/lib/u8g2"
cc $CFLAGS shim.c gui.c run.c $SRCS "$@" -o out/sim -lm -lpthread -Wl,-dead_strip
echo "built out/sim for $ENTRY"
