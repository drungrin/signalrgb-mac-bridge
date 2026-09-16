# SignalRGB Mac bridge

Drives RGB peripherals attached to a **Mac** from **SignalRGB running on a
Windows PC**, per LED.

SignalRGB has no macOS version, and these peripherals stay plugged into the Mac.
This add-on streams the SignalRGB canvas across to a small agent on the Mac,
which writes the colours over HID. The keyboard appears on the canvas with its
real key geometry, so per-key effects work as they would on a local device.

| Device | LEDs |
| --- | --- |
| Corsair K70 MAX | 116 keys (142 hardware channels) |
| Corsair MM700 RGB | 3 zones |
| Logitech G560 | 4 zones |
| Corsair Scimitar Elite Wireless SE | 3 zones |

## How it works

The Mac agent listens only on `127.0.0.1`, so nothing is exposed on the network.
The PC reaches it through an SSH tunnel, and this add-on connects to the local
end of that tunnel:

```
SignalRGB  ->  127.0.0.1:7532  ==SSH==>  Mac agent  ->  HID  ->  peripherals
```

Frames are plain binary: a 6-byte header (`SG`, version, device id, little-endian
payload length) followed by RGB triples. The agent coalesces to the newest frame
per device, paces its HID writes, and falls back to its own local effect about
three seconds after the frames stop — so the Mac keeps its lighting when the PC
sleeps or SignalRGB closes.

## Requirements

1. The Mac agent installed and running. It lives in the `mac-agent/` directory
   of [headless-rgb](https://github.com/drungrin/headless-rgb).
2. An SSH tunnel from the PC to the Mac, forwarding port 7532:

   ```
   ssh -N -L 7532:127.0.0.1:7532 mac
   ```

   `headless-rgb` ships `windows/start-mac-tunnel.ps1`, which keeps the tunnel
   up and reconnects when it drops.

## Install

In SignalRGB: **Settings → Add-ons**, then add this repository URL.

Devices appear once the add-on is enabled. There is no IP to configure: the
target is always the local end of the tunnel.

## Troubleshooting

**Devices appear but stay dark.** The tunnel is probably down. Check it with:

```
ssh mac 'printf "STATUS\n" | /usr/bin/nc 127.0.0.1 7531'
```

A healthy agent answers `OK effect=... k70=ok mm700=ok g560=ok scimitar=ok`.

**One device reports an error.** It is unplugged, powered off, or — for the
Scimitar — missing macOS Accessibility permission, which it needs for RGB and
for its side buttons.

## Development

The K70 tables in `headless-lights-mac.js` are generated from the agent's
`k70max_layout.h` by `tools/gen_k70_layout.py` in the headless-rgb repository.
Edit that header and regenerate rather than editing the tables by hand.

The headless-rgb test suite runs this plugin under Node against a fake canvas and
decodes the frames it produces with the agent's own parser, so the two ends
cannot drift apart silently.

## Licence

GPL-3.0-or-later. The K70 key coordinates derive from the OpenLinkHub K70 MAX
layout, which carries that licence.
