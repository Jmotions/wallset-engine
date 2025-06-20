#!/bin/bash

# === wallselect.sh ===

# Config
STANDARD_STEAM_DIR="$HOME/.local/share/Steam/steamapps/workshop/content/431960"
FLATPAK_STEAM_DIR="$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/workshop/content/431960"
ID_LIST="$HOME/.config/wallset-engine/wallpaperengine_ids.txt"
STARTUP_SCRIPT="$HOME/.config/wallset-engine/wallpaper_startup.sh"
SCREENSHOT_DIR="$HOME/.config/wallset-engine/screenshots"
WALLPAPER_FPS=60  # Change as you wish

# Ensure directories exist
mkdir -p "$(dirname "$ID_LIST")"
mkdir -p "$SCREENSHOT_DIR"

# Check dependencies
for cmd in jq fzf wal; do
  if ! command -v "$cmd" >/dev/null; then
    echo "Error: '$cmd' is required but not installed."
    exit 1
  fi
done

# Verify linux-wallpaperengine is installed
if ! command -v linux-wallpaperengine >/dev/null; then
  echo "Error: 'linux-wallpaperengine' is required but not installed."
  echo "Install it from: https://github.com/Almamu/linux-wallpaperengine"
  exit 1
fi

# Function to detect Steam workshop directory
find_workshop_dir() {
  if [[ -d "$STANDARD_STEAM_DIR" ]]; then
    echo "$STANDARD_STEAM_DIR"
  elif [[ -d "$FLATPAK_STEAM_DIR" ]]; then
    echo "$FLATPAK_STEAM_DIR"
  else
    echo "Error: Could not find Wallpaper Engine workshop directory."
    echo "Checked:"
    echo "  - $STANDARD_STEAM_DIR"
    echo "  - $FLATPAK_STEAM_DIR"
    exit 1
  fi
}

WORKSHOP_DIR=$(find_workshop_dir)

# Function to detect monitors
detect_monitors() {
  # Try Hyprland first
  if command -v hyprctl >/dev/null; then
    if hyprctl monitors >/dev/null 2>&1; then
      MONITORS=($(hyprctl monitors -j | jq -r '.[].name'))
      [[ ${#MONITORS[@]} -gt 0 ]] && return 0
    fi
  fi

  # Try xrandr next
  if command -v xrandr >/dev/null; then
    MONITORS=($(xrandr --query | grep " connected" | awk '{print $1}'))
    [[ ${#MONITORS[@]} -gt 0 ]] && return 0
  fi

  # Try wlr-randr for Wayland (Sway, etc.)
  if command -v wlr-randr >/dev/null; then
    MONITORS=($(wlr-randr | grep -A1 "^[^ ]" | grep -v "^ " | awk '{print $1}'))
    [[ ${#MONITORS[@]} -gt 0 ]] && return 0
  fi

  # Fallback to DRM (more low-level)
  if [[ -d /sys/class/drm ]]; then
    MONITORS=($(ls -1 /sys/class/drm | grep "^card.-" | sed 's/.*-//'))
    [[ ${#MONITORS[@]} -gt 0 ]] && return 0
  fi

  # Final fallback - just try some common names
  MONITORS=("DP-1" "HDMI-1" "eDP-1")
  echo "Warning: Could not detect monitors, falling back to defaults: ${MONITORS[*]}" >&2
  return 1
}

# Function to find preview image
find_preview_image() {
  local wallpaper_dir="$1"
  # Common preview image names and locations
  local preview_locations=(
    "$wallpaper_dir/preview.jpg"
    "$wallpaper_dir/preview.jpeg"
    "$wallpaper_dir/preview.png"
    "$wallpaper_dir/preview.gif"
    "$wallpaper_dir/project.json"  # Sometimes contains preview path
    "$wallpaper_dir/thumbnail.jpg"
  )

  for img in "${preview_locations[@]}"; do
    if [[ -f "$img" ]]; then
      # If it's project.json, extract preview path
      if [[ "$img" == *".json" ]]; then
        local preview_path=$(jq -r '.preview // .thumbnail // empty' "$img" 2>/dev/null)
        if [[ -n "$preview_path" && -f "$wallpaper_dir/$preview_path" ]]; then
          echo "$wallpaper_dir/$preview_path"
          return 0
        fi
      else
        echo "$img"
        return 0
      fi
    fi
  done

  return 1
}

# Detect monitors
if ! detect_monitors; then
  echo "Warning: Monitor detection may be inaccurate. You may need to set them manually." >&2
fi

echo "Detected monitors: ${MONITORS[*]}"

# Step 1: Update wallpaper ID list
> "$ID_LIST"
for ID_DIR in "$WORKSHOP_DIR"/*/; do
  ID=$(basename "$ID_DIR")
  TITLE=""

  # Try to get title from metadata files
  for file in manifest.json metadata.json project.json; do
    [[ -z "$TITLE" && -f "$ID_DIR/$file" ]] && TITLE=$(jq -r '.title // empty' "$ID_DIR/$file" 2>/dev/null)
  done

  [[ -z "$TITLE" ]] && TITLE="$ID"

  echo "$ID  $TITLE" >> "$ID_LIST"
done

# Step 2: Select wallpaper
CHOICE=$(cat "$ID_LIST" | fzf --prompt="Select wallpaper: ")
[[ -z "$CHOICE" ]] && echo "No wallpaper selected. Exiting." && exit 1
WALLPAPER_ID=$(awk '{print $1}' <<< "$CHOICE")
WALLPAPER_DIR="$WORKSHOP_DIR/$WALLPAPER_ID"

# Step 3: Prompt for audio enable
read -p "Enable audio for this wallpaper? (y/N): " enable_audio
enable_audio=${enable_audio,,}  # Lowercase

# Step 4: Kill running wallpaperengine
pkill -f linux-wallpaperengine
sleep 0.5

# Step 5: Find or create image for pywal
WALLPAPER_IMAGE=""
if PREVIEW_IMAGE=$(find_preview_image "$WALLPAPER_DIR"); then
  echo "Using existing preview image: $PREVIEW_IMAGE"
  WALLPAPER_IMAGE="$PREVIEW_IMAGE"
else
  # Fallback to screenshot if no preview exists
  echo "No preview image found, capturing screenshot..."
  SS_FILE="$SCREENSHOT_DIR/$WALLPAPER_ID.png"
  (linux-wallpaperengine --screenshot "$SS_FILE" --bg "$WALLPAPER_ID" >/dev/null 2>&1 &)
  disown
  sleep 2  # Give it time to capture screenshot
  WALLPAPER_IMAGE="$SS_FILE"
fi

# Step 6: Apply pywal theme
if [[ -f "$WALLPAPER_IMAGE" ]]; then
  wal -i "$WALLPAPER_IMAGE" >/dev/null 2>&1
else
  echo "Warning: Could not find or create image for pywal"
fi

# Step 7: Build and launch wallpaperengine commands
> "$STARTUP_SCRIPT"
echo "#!/bin/bash" > "$STARTUP_SCRIPT"
echo "# Auto-generated startup script" >> "$STARTUP_SCRIPT"
echo "pkill -f linux-wallpaperengine" >> "$STARTUP_SCRIPT"
echo "sleep 0.5" >> "$STARTUP_SCRIPT"
echo "" >> "$STARTUP_SCRIPT"

for i in "${!MONITORS[@]}"; do
  MON="${MONITORS[$i]}"
  CMD=(linux-wallpaperengine --no-foreground --scaling default --"$WALLPAPER_FPS"fps --screen-root "$MON" --bg "$WALLPAPER_ID")
  [[ "$enable_audio" != "y" && "$enable_audio" != "yes" || "$i" -ne 0 ]] && CMD+=(--silent)
  echo "nohup ${CMD[@]} >/dev/null 2>&1 &" >> "$STARTUP_SCRIPT"
  echo "disown" >> "$STARTUP_SCRIPT"
  nohup "${CMD[@]}" >/dev/null 2>&1 &
  disown
done

chmod +x "$STARTUP_SCRIPT"

# Final output
echo ""
echo "Wallpaper '$WALLPAPER_ID' applied to monitors: ${MONITORS[*]}"
[[ "$enable_audio" == "y" || "$enable_audio" == "yes" ]] && echo "Audio enabled." || echo "Audio disabled."
[[ -n "$PREVIEW_IMAGE" ]] && echo "Pywal theme applied from preview image." || echo "Pywal theme applied from screenshot."
echo "Startup script saved to: $STARTUP_SCRIPT"
echo ""
echo "You're all set!"
echo "Feel free to close this terminal"
