# dotfiles

Personal Arch Linux + Sway configuration featuring dynamic pywal16 theming, a custom Waybar status bar, and lightweight Wayland-native utilities.

---

## Highlights

- **Dynamic Semantic Theming**: Wallpapers managed via `awww` generate a pywal16 palette, which a custom WCAG-contrast engine (`semantic-colors.py`) maps across Sway, Waybar, Ghostty, Fuzzel, Swaylock, Yazi, and RMPC without restarting the session.
- **Unified Clipboard History**: Integrated `cliphist` + `fuzzel` picker with inline image thumbnails (~35px), dynamic metadata tags (`IMAGE · PNG · <DIMS>`), uniform row heights, and cancel-safe clipboard restoration.
- **Compact System Monitoring**: Single-icon (``) Waybar system-info module with rich multi-sensor tooltips (CPU, GPU, NVMe, RAM, Disk, Power, Load, Uptime) and a quick-launch binding to `btop`.
- **System Health Diagnostics**: Standalone terminal health checker (`syscheck`) evaluating sensor temperatures, memory, mount points, systemd units, network interfaces, and audio daemons with colored status badges.
- **Wayland Utilities**: Custom Fuzzel-driven menus for PipeWire audio output switching (`audio-output`), session controls (`sys-menu`), and direct compositor screenshots (`grim` + `slurp`).

---

## Environment & Stack

| Component | Tool | Description |
| :--- | :--- | :--- |
| **OS** | Arch Linux | Kernel 7.x, systemd, btrfs |
| **Compositor** | [Sway](.config/sway/config) | i3-compatible Wayland compositor with 1.25 output scale |
| **Status Bar** | [Waybar](.config/waybar/config.jsonc) | Compact pill design with pywal16 CSS theming |
| **Launcher / Menus** | [Fuzzel](.config/fuzzel/fuzzel.ini) | Lightweight Wayland dmenu replacement with icon support |
| **Terminal** | [Ghostty](.config/ghostty/config.ghostty) | GPU-accelerated terminal with dynamic theme updates |
| **Shell** | [Fish](.config/fish/config.fish) | Custom functions, completions, and prompt |
| **File Manager** | Yazi | Terminal file manager with dedicated wallpaper picker mode |
| **Wallpaper** | [awww](.config/fish/scripts/wallpaper-ctl.fish) | Smooth fade transitions; synchronized to swaylock |
| **Theming** | [pywal16](.config/wal/semantic-colors.py) | 16-color derivation with WCAG 2.1 contrast math |
| **Clipboard** | [cliphist](.local/bin/cliphist-picker) + `wl-clipboard` | Persistent multi-type clipboard history |
| **Audio** | PipeWire + WirePlumber | Managed via `wpctl` and custom output switcher |
| **Music** | RMPC + MPD | Terminal music player client with dynamic theme reload |
| **Pointer Control** | [warpd](.local/bin/warpd-sway) | Modal keyboard-driven mouse navigation |

---

## Custom Desktop Utilities & Keybindings

All custom shortcuts use `$mod` (<kbd>Super</kbd> / <kbd>Windows</kbd>).

| Keybinding | Command / Script | Purpose |
| :--- | :--- | :--- |
| `$mod+Return` | `ghostty` | Open terminal emulator |
| `$mod+d` | `fuzzel` | Application launcher |
| `$mod+Shift+v` | [`cliphist-picker`](.local/bin/cliphist-picker) | Fuzzel clipboard history with image thumbnails |
| `$mod+o` | [`audio-output`](.local/bin/audio-output) | PipeWire audio sink switcher |
| `$mod+x` | [`sys-menu`](.local/bin/sys-menu) | System control menu (lock, suspend, reboot, poweroff, kill) |
| `$mod+p` | Direct `grim -g "$(slurp)"` | Interactive region screenshot (saved to file + copied) |
| `$mod+Shift+p` | Direct `grim` | Fullscreen screenshot (saved to file + copied) |
| `$mod+Alt+w` | [`wallpaper-picker.fish`](.config/fish/scripts/wallpaper-picker.fish) | Open Yazi-based wallpaper selector |
| `$mod+Shift+w` | [`wallpaper-next.fish`](.config/fish/scripts/wallpaper-next.fish) | Advance to next wallpaper in active theme |
| `$mod+m` | [`rmpc-launch`](.local/bin/rmpc-launch) | Launch RMPC music client in dedicated terminal session |
| `$mod+Ctrl+p` | `pavucontrol` | PulseAudio / PipeWire volume control GUI |
| `$mod+Escape` | [`tod-lock`](.local/bin/tod-lock) | Lock screen via swaylock with 10-minute hibernate timer |
| `$mod+Mod1+x/c/g` | [`warpd-sway`](.local/bin/warpd-sway) | warpd hint / normal / grid pointer control |

---

## Desktop Infrastructure & Pipelines

### 1. Dynamic Theming & Wallpaper Pipeline

Desktop theming is automated through [`wallpaper-ctl.fish`](.config/fish/scripts/wallpaper-ctl.fish):
1. **Selection**: Wallpapers are organized under `~/.config/wallpapers/themes/<theme>/home/`. Selecting an image sets the wallpaper using `awww img --transition-type fade`.
2. **Palette Derivation**: Invokes `wal -i <image> --cols16 darken -n -e` to extract dominant colors.
3. **Semantic Synthesis**: [`semantic-colors.py`](.config/wal/semantic-colors.py) calculates accessible foreground/background contrast ratios (WCAG 2.1 relative luminance) and outputs structured target themes:
   - `~/.cache/wal/sway-colors` (window borders and titlebars)
   - `~/.cache/wal/waybar.css` (module foregrounds, borders, backgrounds)
   - `~/.cache/wal/ghostty.conf` (terminal color palette)
   - `~/.cache/wal/fuzzel.ini` (launcher selection, text, borders)
   - `~/.cache/wal/swaylock` (lock screen styling)
   - `~/.cache/wal/rmpc-theme.ron` (music player styling)
4. **Live Reload**: Pushes updated themes to RMPC via IPC (`rmpc remote set theme`), mirrors lockscreen imagery, and reloads Sway (`swaymsg reload`).

### 2. Clipboard History ([`cliphist-picker`](.local/bin/cliphist-picker))

Integrated clipboard management based on `sentriz/cliphist`:
- **Daemon**: Sway starts `wl-paste --watch cliphist store` on login.
- **Picker UI**: Triggered via `$mod+Shift+v`.
  - **Uniform Geometry**: Every row renders at a consistent 40px line height (`--line-height=40`).
  - **Image Previews**: Decodes image payloads to `~/.cache/cliphist/thumbnails/<id>.<ext>`, rendered by Fuzzel as ~35px thumbnail icons.
  - **Dynamic Metadata**: Generates clean labels beside thumbnails (`IMAGE · PNG · 1920×1080`) instead of raw binary descriptors.
  - **3-Column Architecture**: Column 1 preserves sequence ID, Column 2 holds visible labels, and Column 3 provides searchable tags (`--with-nth 2 --match-nth 3`).
  - **Cancellation Guard**: Pressing <kbd>Esc</kbd> exits cleanly without wiping the active clipboard.
  - **Restoration**: Pipes selected items to `cliphist decode | wl-copy`, preserving byte-for-byte text formatting and `image/png` binary payloads.

### 3. Waybar System Information Module ([`waybar-sysinfo`](.local/bin/waybar-sysinfo))

Waybar uses a compact layout where standalone CPU, RAM, and temperature modules are consolidated into a single custom component:
- **Bar Display**: Renders solely the `` glyph in the right pill.
- **Detailed Tooltip**: Hovering reveals an aggregated diagnostic readout:
  ```text
  CPU: 24%  44°C
  GPU: 42°C
  NVMe: 30°C
  RAM: 5.0/14.9 GiB
  Disk: 418G free / 476G (12%)
  Power: 8.4 W
  Load: 1.56 1.40 1.46
  Up: 1 day, 5 hours, 48 minutes
  ```
- **Interactivity**: Clicking the module launches `btop` inside Ghostty.

### 4. System Health Diagnostic ([`syscheck`](.local/bin/syscheck))

Run `syscheck` in any terminal to inspect system hardware, daemons, and storage:
- Categorized status indicators: `[ OK ]`, `[WARN]`, `[FAIL]`.
- Sensor tracking: CPU (`Tctl`/`Tdie`), GPU (`edge`), and NVMe (`Composite`) temperatures with threshold warnings.
- Memory: RAM usage percentage and swap consumption.
- Filesystems: Real mount points deduplicated with percentage usage warnings.
- Systemd: Failed unit detection.
- Network & Audio: Active interfaces and PipeWire/WirePlumber daemon health.

---

## Repository Structure

```text
.
├── .bash_profile
├── .bashrc
├── .config/
│   ├── environment.d/           # Wayland environment variables (e.g. Firefox)
│   ├── fish/
│   │   ├── completions/         # Shell completions
│   │   ├── functions/           # Shell helper functions
│   │   └── scripts/             # Wallpaper control and prewarm scripts
│   ├── fuzzel/
│   │   └── fuzzel.ini           # Launcher configuration & pywal include
│   ├── ghostty/
│   │   └── config.ghostty       # Terminal emulator settings
│   ├── gtk-3.0/ & gtk-4.0/      # GTK theme configuration
│   ├── nvim/                    # Neovim configuration (init.lua)
│   ├── rmpc/                    # RMPC music player configuration & theme
│   ├── sway/
│   │   └── config               # Core Sway compositor configuration
│   ├── swaylock/
│   │   └── config               # Lock screen behavior
│   ├── wal/
│   │   └── semantic-colors.py   # WCAG-compliant color derivation engine
│   ├── wallpapers/              # Theme wallpaper directories
│   ├── waybar/
│   │   ├── config.jsonc         # Waybar module layouts & definitions
│   │   └── style.css            # Waybar styling & pywal imports
│   └── xdg-desktop-portal/      # Wayland portal configuration
├── .gitconfig
├── .gitignore
├── .local/
│   ├── bin/                     # Standalone CLI tools & desktop scripts
│   │   ├── audio-output         # PipeWire sink switcher
│   │   ├── cliphist-picker      # Uniform Fuzzel clipboard picker
│   │   ├── rmpc-launch          # RMPC session wrapper
│   │   ├── sys-menu             # Fuzzel system actions menu
│   │   ├── syscheck             # Terminal system diagnostic utility
│   │   ├── tod-lock             # Screen locking wrapper with hibernate timer
│   │   ├── waybar-sysinfo       # Waybar monitoring metric collector
│   │   └── wlsunset-toggle      # Night light toggle utility
│   └── share/
│       └── dotfiles/
│           └── packages/        # Explicit package inventories
│               ├── aur-explicit.txt
│               └── pacman-explicit.txt
└── README.md
```

---

## Installation & Bootstrapping

These dotfiles are tracked directly in `$HOME` using a bare Git repository.

### 1. Clone Bare Repository

```bash
git clone --bare https://github.com/TodScissorhands/dotfiles--2.git "$HOME/.dotfiles"
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
dotfiles checkout
dotfiles config --local status.showUntrackedFiles no
```

*Note: If existing default configuration files conflict with the checkout, back them up before checking out.*

### 2. Install Package Dependencies

Install the tracked explicit packages:

```bash
# Official packages
sudo pacman -S --needed - < "$HOME/.local/share/dotfiles/packages/pacman-explicit.txt"

# AUR packages (using yay or paru)
yay -S --needed - < "$HOME/.local/share/dotfiles/packages/aur-explicit.txt"
```

### 3. Initialize Theming

Set an initial wallpaper to generate semantic colors:

```bash
~/.config/fish/scripts/wallpaper-ctl.fish set-path ~/.config/wallpapers/themes/<theme>/home/<image.png>
```

---

## Hardware Caveats & Machine Specifics

- **Display Scaling**: The Sway configuration sets `output * scale 1.25`, calibrated for high pixel density on 13-inch 1080p laptop panels. Adjust in [`.config/sway/config`](.config/sway/config) if using alternative displays.
- **Hardware Sensors**: Sensor definitions in [`syscheck`](.local/bin/syscheck) and [`waybar-sysinfo`](.local/bin/waybar-sysinfo) check AMD Ryzen (`k10temp`/`Tctl`), AMD GPU (`amdgpu`/`edge`), and NVMe (`Composite`) thermal inputs. Intel or NVIDIA hardware may require adapting sensor names.
- **Battery Interface**: Power discharge rate is read from `/org/freedesktop/UPower/devices/battery_BAT1`. Modify the device node if your system numbers batteries differently.

---

## Credits & Upstream Inspirations

- **[sentriz/cliphist](https://github.com/sentriz/cliphist)**: Wayland clipboard manager and base `cliphist-fuzzel-img` integration.
- **[BreadOnPenguins/scripts](https://github.com/BreadOnPenguins/scripts)**: Architecture reference for system control and diagnostic workflows.
- **[pywal16](https://github.com/eylles/pywal16)**: 16-color palette extraction.
- **[Fuzzel](https://codeberg.org/dnkl/fuzzel)**: Application launcher and dmenu interface for Wayland.
