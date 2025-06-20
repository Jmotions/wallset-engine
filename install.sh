#!/bin/bash

# === install.sh ===
# Installer for Wallselect Engine

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_NAME="wallselect"
SOURCE_SCRIPT="wallselect.sh"
TARGET_SCRIPT="$INSTALL_DIR/$SCRIPT_NAME"

# --- Helper Functions ---
# A function for standardized output messages
inform() {
    echo "[$SCRIPT_NAME Installer] $1"
}

# --- Main Script ---
inform "🔧 Installing..."

# 1. Ensure the source script exists in the current directory
if [[ ! -f "$SOURCE_SCRIPT" ]]; then
    inform "❌ Error: Source script '$SOURCE_SCRIPT' not found."
    inform "   Please run this installer from the same directory as '$SOURCE_SCRIPT'."
    exit 1
fi

# 2. Ensure the target directory exists
inform "Ensuring install directory exists at $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

# 3. Copy the script and make it executable
inform "Copying '$SOURCE_SCRIPT' to '$TARGET_SCRIPT'..."
cp "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
chmod +x "$TARGET_SCRIPT"
inform "✅ Script installed successfully."

# 4. Check if the installation directory is in the user's PATH
if [[ ":$PATH:" == *":$INSTALL_DIR:"* ]]; then
    inform "🟢 '$INSTALL_DIR' is already in your PATH."
    inform "You can now run the script by typing: $SCRIPT_NAME"
else
    inform "⚠️  Warning: Your PATH does not include '$INSTALL_DIR'."
    
    # Ask the user if they want to fix it automatically
    read -p "Would you like to add it to your shell configuration file? (y/n) " choice
    echo # Newline for cleaner output

    case "$choice" in
      y|Y )
        # Determine shell and config file
        SHELL_RC_FILE=""
        CURRENT_SHELL=$(basename "$SHELL")

        if [ "$CURRENT_SHELL" = "bash" ]; then
            SHELL_RC_FILE="$HOME/.bashrc"
        elif [ "$CURRENT_SHELL" = "zsh" ]; then
            SHELL_RC_FILE="$HOME/.zshrc"
        fi

        if [ -z "$SHELL_RC_FILE" ]; then
            inform "Could not detect bash or zsh. Please add the following line to your shell's config file:"
            inform "  export PATH=\"$INSTALL_DIR:\$PATH\""
        else
            inform "Adding PATH configuration to $SHELL_RC_FILE..."
            # Append the export command to the shell config file
            echo '' >> "$SHELL_RC_FILE"
            echo '# Added by wallselect installer' >> "$SHELL_RC_FILE"
            echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_RC_FILE"
            inform "✅ Configuration updated!"
            inform "Please restart your terminal or run 'source $SHELL_RC_FILE' to apply changes."
            inform "You can then run the script by typing: $SCRIPT_NAME"
        fi
        ;;
      n|N )
        inform "Okay. To run the script, you can either:"
        inform "1. Call it using its full path: $TARGET_SCRIPT"
        inform "2. Or, add this line to your shell config (e.g. ~/.bashrc or ~/.zshrc):"
        inform "   export PATH=\"$INSTALL_DIR:\$PATH\""
        ;;
      * )
        inform "Invalid choice. Please add the PATH manually."
        inform "Add this line to your shell config (e.g. ~/.bashrc or ~/.zshrc):"
        inform "  export PATH=\"$INSTALL_DIR:\$PATH\""
        ;;
    esac
fi

inform "🚀 Done!"
