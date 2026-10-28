# fap-sim — run a Flipper Zero FAP on your computer

Builds a FAP against a host implementation of the firmware API and renders its
screens to images, so UI and logic can be exercised without a device.

```
./build.sh <app-dir> <entry-symbol>
```

```sh
FLIPPER_FW=~/flipper/flipperzero-firmware ./build.sh . demo_menu_app
SIM_SCRIPT=tour.script ./out/sim out/
```

## What is real

- **Your app's own code**, unmodified. Nothing is recompiled from a rewritten source.
- **The firmware's u8g2 and font tables** (helvB08 / haxrcorp4089 / profont22), so
  glyphs and pixels match the panel.
- **Threads are real pthreads**, so worker loops actually run against a synthetic
  radio; timers, stream buffers and storage have working implementations.
- **Menu, Popup, Widget and the scene manager** are ported in `gui.c`. The menu's
  geometry is copied from `applications/services/gui/modules/menu.c`: three rows at
  baselines 14/36/58, labels at x=22, framed middle row at y=21.

## What is not

- **The radio.** `furi_hal_subghz_*` returns a synthetic spectrum. NFC, LF, IR and
  BLE are stubs. A passing run says nothing about the physical layer.
- **Icon artwork.** Icons come from a generated asset blob; the icon slot is left
  empty and labels keep their real x.
- **Stack limits.** Host pthreads refuse a 3 KB stack, so the simulator runs with
  16 KB. It measures the high-water mark instead and reports it per thread.
- **Missing modules**: DialogEx, TextInput, the real VariableItemList widget, the
  sub-GHz protocol block library, `lib/flipper_application`.

## Driving it

`SIM_SCRIPT` replaces the built-in tour with a text file:

```
scene page0      # render the current screen to page0.pgm
key R!           # R L U D OK B, suffix ! = long press
wait 400         # let the workers run
record           # start CSV logging
walk             # run the config-row walk
```

`SIM_ENTRY` selects the entry symbol at build time, so one shim serves any app
linked into the binary.

## Resources are limited, not ignored

- The heap is a fixed pool; over budget `malloc` returns NULL like the device.
  `SIM_HEAP=12288` to force the failure paths.
- `SIM_SD_FAIL=n` makes every write fail after n bytes (a full card).
- `SIM_SD_MS=n` makes writes block, which punches holes in sample loops.
- `SIM_RECORD=1` starts logging before the tour.
- `SIM_VERBOSE=1` shows the app's log output.

## Screenshots

`shots/` is a full render of the app this was built for.

## Licence

GPL-3.0-or-later. See NOTICE: `gui.c` reimplements the firmware's GUI modules from
their layout constants, and those are GPL-3.0.
