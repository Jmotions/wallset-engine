#!/bin/bash

# === wallselect.sh ===

# Config
WORKSHOP_DIR="$HOME/.local/share/Steam/steamapps/workshop/content/431960"
ID_LIST="$HOME/.config/wallset-engine/wallpaperengine_ids.txt"
MONITORS=("DP-3" "HDMI-A-1")
STARTUP_SCRIPT="$HOME/.config/wallset-engine/wallpaper_startup.sh"
SCREENSHOT_DIR="$HOME/.config/wallset-engine/screenshots"

# Ensure directories exist
mkdir -p "$(dirname "$ID_LIST")"
mkdir -p "$SCREENSHOT_DIR"

# Check dependencies
for cmd in jq fzf wal linux-wallpaperengine; do
  if ! command -v "$cmd" >/dev/null; then
    echo "Error: '$cmd' is required but not installed."
    exit 1
  fi
done

# Step 1: Update wallpaper ID list
> "$ID_LIST"
for ID_DIR in "$WORKSHOP_DIR"/*/; do
  ID=$(basename "$ID_DIR")
  TITLE=""

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

# Step 3: Prompt for audio enable
read -p "Enable audio for this wallpaper? (y/N): " enable_audio
enable_audio=${enable_audio,,}  # Lowercase

# Step 4: Kill running wallpaperengine
pkill -f linux-wallpaperengine
sleep 0.5

# Step 5: Screenshot for pywal (only if it doesn't exist yet)
SS_FILE="$SCREENSHOT_DIR/$WALLPAPER_ID.png"
if [[ ! -f "$SS_FILE" ]]; then
  linux-wallpaperengine --screenshot "$SS_FILE" --bg "$WALLPAPER_ID" >/dev/null 2>&1
fi

# Step 6: Apply pywal theme
wal -i "$SS_FILE" >/dev/null 2>&1

# Step 7: Build and launch wallpaperengine commands
> "$STARTUP_SCRIPT"
echo "#!/bin/bash" > "$STARTUP_SCRIPT"
echo "# Auto-generated startup script" >> "$STARTUP_SCRIPT"
echo "pkill -f linux-wallpaperengine" >> "$STARTUP_SCRIPT"
echo "sleep 0.5" >> "$STARTUP_SCRIPT"
echo "" >> "$STARTUP_SCRIPT"

for i in "${!MONITORS[@]}"; do
  MON="${MONITORS[$i]}"
  CMD=(linux-wallpaperengine --scaling default --60fps --screen-root "$MON" --bg "$WALLPAPER_ID")
  [[ "$enable_audio" != "y" && "$enable_audio" != "yes" || "$i" -ne 0 ]] && CMD+=(--silent)
  echo "nohup ${CMD[@]} >/dev/null 2>&1 &" >> "$STARTUP_SCRIPT"
  echo "disown" >> "$STARTUP_SCRIPT"
  nohup "${CMD[@]}" >/dev/null 2>&1 &
  disown
done

chmod +x "$STARTUP_SCRIPT"

# Final output
echo "\nWallpaper '$WALLPAPER_ID' applied to monitors: ${MONITORS[*]}"
[[ "$enable_audio" == "y" || "$enable_audio" == "yes" ]] && echo "Audio enabled." || echo "Audio disabled."
echo "Pywal theme applied."
echo "Startup script saved to: $STARTUP_SCRIPT"
echo "\nYou're all set!"
sleep 0.3
echo "\nFeel free to close this terminal!"
