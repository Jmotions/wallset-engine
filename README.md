# Wallset Engine

A user-friendly TUI for **linux-wallpaperengine** that makes managing Wallpaper Engine content on Linux simple and accessible. Browse your Steam Workshop wallpapers with an interactive fuzzy finder, automatically apply them across multiple monitors, and generate matching color schemes with **pywal** integration.

## Features

- **Interactive Selection**: Browse your Wallpaper Engine collection with **fzf**
- **Multi-Monitor Support**: Automatic detection for Hyprland, X11, and Wayland
- **Pywal Integration**: Automatic color scheme generation from wallpaper images
- **Audio Control**: Choose whether to enable wallpaper audio
- **Easy Installation**: One-command setup with PATH configuration
- **Startup Scripts**: Auto-generated scripts for session persistence
- **Smart Previews**: Uses existing preview images or captures screenshots

## Prerequisites

### Required Dependencies
- `jq` - JSON processing
- `fzf` - Fuzzy finder for wallpaper selection
- `pywal` (or `wal`) - Color scheme generation
- `linux-wallpaperengine` - Wallpaper Engine runtime for Linux

### (Not so) Required Dependencies
- `kitty` - For preview images
- `chafa` - if you dont want kitty (may break)
### Steam Setup
- Steam installed (native or Flatpak)
- Wallpaper Engine purchased and installed
- At least one wallpaper subscribed in Steam Workshop

### Installation Commands

**Arch Linux:**
```bash
sudo pacman -S jq fzf python-pywal
yay -S linux-wallpaperengine-git  # or your preferred AUR helper
```

**Ubuntu/Debian:**
```bash
sudo apt install jq fzf
pip install pywal
# Install linux-wallpaperengine from: https://github.com/Almamu/linux-wallpaperengine
```

**Fedora:**
```bash
sudo dnf install jq fzf
pip install pywal
# Install linux-wallpaperengine from: https://github.com/Almamu/linux-wallpaperengine
```

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/wallset-engine.git
   cd wallset-engine
   ```

2. **Run the installer:**
   ```bash
   ./install.sh
   ```
3. **Run the script!!**
      ```bash
   ./wallselect.sh
   ```

## Usage

### Basic Usage
Simply run the script and follow the interactive prompts:
```bash
./wallselect
```

### What It Does
1. **Scans** your Steam Workshop directory for Wallpaper Engine content 
2. **Displays** an interactive list of available wallpapers with titles
3. **Prompts** for audio preference
4. **Detects** your monitors automatically
5. **Applies** the wallpaper to all detected monitors
6. **Generates** a color scheme using pywal
7. **Creates** a startup script for session persistence

### Example Session
```
$ ./wallselect
Detected monitors: DP-3 HDMI-A-1
Select wallpaper: 
> 123456789  Cyberpunk City Rain
  987654321  Forest Animated
  456789123  Neon Synthwave

Enable audio for this wallpaper? (y/N): y

Wallpaper '123456789' applied to monitors: DP-3 HDMI-A-1
Audio enabled.
Pywal theme applied from preview image.
Startup script saved to: /home/user/.config/wallset-engine/wallpaper_startup.sh

You're all set!
Feel free to close this terminal!
```

## File Structure

After installation, wallset-engine creates the following structure:

```
~/.config/wallset-engine/
├── wallpaperengine_ids.txt     # Cached wallpaper list
├── wallpaper_startup.sh        # Auto-generated startup script
└── screenshots/                # Screenshot cache for pywal
    ├── 123456789.png
    └── 987654321.png
```
(thats where it stores things that arent in the actual git clone folder. Feel free to move everything into the .config folder after install)

## Configuration

The script automatically detects most settings, but you can customize by editing the variables at the top of `wallselect.sh`:

```bash
# Wallpaper frame rate (30, 60, etc.)
WALLPAPER_FPS=60

# Steam directories (auto-detected)
STANDARD_STEAM_DIR="$HOME/.local/share/Steam/steamapps/workshop/content/431960"
FLATPAK_STEAM_DIR="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/workshop/content/431960"
```

## Monitor Detection

Wallset-engine automatically detects monitors using multiple methods:

1. **Hyprland** (`hyprctl monitors`)
2. **X11** (`xrandr`)
3. **Wayland** (`wlr-randr`)
4. **DRM fallback** (`/sys/class/drm`)
5. **Default fallback** (common monitor names)

## Session Persistence

To automatically restore your wallpaper on login, add the generated startup script to your session:

**For most desktop environments:**
```bash
# Add to your shell's RC file (.bashrc, .zshrc, etc.)
~/.config/wallset-engine/wallpaper_startup.sh
```

**For Hyprland:**
```bash
# Add to hyprland.conf
exec-once = ~/.config/wallset-engine/wallpaper_startup.sh
```

**For i3/sway:**
```bash
# Add to config
exec --no-startup-id ~/.config/wallset-engine/wallpaper_startup.sh
```

## Troubleshooting

### "No wallpapers found"
- Ensure Steam is installed and you've subscribed to Wallpaper Engine wallpapers
- Check that the Steam Workshop directory exists:
  ```bash
  ls ~/.local/share/Steam/steamapps/workshop/content/431960
  # or for Flatpak:
  ls ~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/workshop/content/431960
  ```
### "Monitor detection failed"
- The script will fall back to common monitor names
- You can manually edit the `MONITORS` array in the startup script if needed

### Wallpaper not applying
- Ensure `linux-wallpaperengine` is properly installed
- Check if your wallpaper files are corrupted by testing manually:
  ```bash
  linux-wallpaperengine --bg WALLPAPER_ID
  ```
(please note not all wallpapers will work properly. Check out `linux-wallpaperengine` and their github page to report issues.)
## Contributing

Contributions are welcome! Please feel free to:
- Report bugs
- Suggest features
- Submit pull requests
- Improve documentation

## License

This project is licensed under the GNU GENERAL PUBLIC LICENSE - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [linux-wallpaperengine](https://github.com/Almamu/linux-wallpaperengine) - For making Wallpaper Engine work on Linux
- [pywal](https://github.com/dylanaraps/pywal) - For dynamic color scheme generation
- [fzf](https://github.com/junegunn/fzf) - For the fuzzy finder interface

## Support

If you encounter issues or have questions:
1. Check the [troubleshooting section](#-troubleshooting)
2. Search existing [GitHub issues](https://github.com/yourusername/wallset-engine/issues)
3. Create a new issue with detailed information about your system and the problem

---

**Thanks for reading!!**
