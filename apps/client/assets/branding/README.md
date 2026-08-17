# OpenCode Notify icon sources

The icon combines a terminal prompt with outbound signal waves. It is an
original project mark and does not reuse the OpenCode logo artwork.

## Palette

- Background: `#211E1E`
- Border: `#4B4646`
- Prompt: `#F1ECEC`
- Signal: `#D7FF64`

`app_icon.svg` is the launcher icon source. `tray_icon.svg` has fewer details
and a circular field so it remains legible on light and dark system panels.

When changing either source, regenerate all raster and ICO outputs and inspect
the 16, 24, 32, 48, and 256 pixel sizes.

From `apps/client`, run:

```bash
./tool/generate_icons.sh
```
