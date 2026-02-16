# Holdfast

A macOS menu bar utility that brings X11-style window management to macOS — hold a modifier key and click anywhere in a window to move it. Add Shift to resize. No more hunting for title bars or ever-shrinking window edges.

## Usage

| Action | Gesture |
|--------|---------|
| **Move** | Hold modifier + left-click drag anywhere in a window |
| **Resize** | Hold modifier + Shift + left-click drag |
| **Switch mid-drag** | Press/release Shift while dragging to toggle between move and resize |

Resize uses a **3x3 grid** — where you click in the window determines which edges move:

```
┌───────────┬───────────┬────────────┐
│  top-left │    top    │ top-right	 │
├───────────┼───────────┼────────────┤
│   left    │  (bottom- │   right		 │
│           │   right)  │            │
├───────────┼───────────┼────────────┤
│bottom-left│  bottom   │bottom-right│
└───────────┴───────────┴────────────┘
```

The default modifier key is **Option** (⌥). Change it via the menu bar icon to Control or Command.

## Install

Requires macOS 13 (Ventura) or later and Xcode command-line tools.

```sh
git clone https://github.com/tpaine/Holdfast.git
cd Holdfast
make install
```

This builds a release binary, assembles `Holdfast.app`, and copies it to `/Applications`.

To build without installing:

```sh
make build   # produces build/Holdfast.app
make run     # builds and launches (resets Accessibility permission for dev builds)
```

On first launch, macOS will prompt for **Accessibility** permission. Holdfast needs this to intercept mouse events and move/resize windows.

## Configuration

Click the menu bar icon (↔) to:

- **Modifier Key** — choose Control, Option, or Command
- **Start at Login** — toggle launch at login
- **Quit Holdfast**

## How It Works

Holdfast uses a CGEvent tap to intercept mouse events at the session level. When the modifier key is held, left-click events are consumed (preventing them from reaching the target app) and routed through a state machine that applies move/resize operations via the macOS Accessibility API (AXUIElement).

## Inspiration

Inspired by X11 style window management. RIP the Hyperdock app that had this feature buried in settings. 

## License

[MIT](LICENSE)
