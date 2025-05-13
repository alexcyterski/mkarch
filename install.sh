#!/bin/bash

# arch_theme_installer.sh
# A script to install a minimal, clean, and transparent theme for Arch Linux with Hyprland.

echo "Arch Linux Minimal Theme Installer"
echo "----------------------------------"
echo "This script will install packages and configure them for a consistent transparent theme."
echo "It will attempt to create configuration files for Alacritty, Waybar, and Rofi."
echo "IMPORTANT: If you have existing configurations for these applications in ~/.config, please back them up first!"
read -p "Do you want to proceed? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Installation aborted."
    exit 1
fi

# --- Package Installation ---
echo_blue() {
    echo -e "\\033[0;34m$1\\033[0m"
}

echo_green() {
    echo -e "\\033[0;32m$1\\033[0m"
}

echo_yellow() {
    echo -e "\\033[0;33m$1\\033[0m"
}

PACKAGES=(
    "hyprland"                  # Window manager
    "hyprpaper"                 # Wallpaper daemon (Changed from swww)
    "waybar"                    # Status bar
    "swaync"                    # Notification daemon (Corrected from swaynotificationcenter)
    "network-manager-applet"    # Network manager applet
    "swayidle"                  # Idle management daemon
    "python-pywal"              # Color scheme generator (wal)
    "kitty"                     # Terminal emulator (Changed from alacritty)
    "rofi"                      # Application launcher
    "ttf-font-awesome"          # Icon font (useful for Waybar/Rofi)
    "noto-fonts"                # General purpose fonts
    "noto-fonts-emoji"          # Emoji support
    "jq"                        # JSON processor, useful with wal
    "xdg-desktop-portal-hyprland" # For screen sharing etc.
    "brightnessctl"             # For brightness control modules in waybar
    "pavucontrol"               # For volume control / PipeWire management
    "wlsunset"                  # For automatic screen color temperature adjustment
    "wl-clipboard"              # For clipboard support
)

install_packages() {
    echo_blue "\\n[*] Installing necessary packages..."
    for pkg in "${PACKAGES[@]}"; do
        if pacman -Qs "$pkg" > /dev/null; then
            echo_green "[+] $pkg is already installed."
        else
            echo_yellow "[i] Attempting to install $pkg..."
            sudo pacman -S --noconfirm --needed "$pkg"
            if pacman -Qs "$pkg" > /dev/null; then
                echo_green "[+] Successfully installed $pkg."
            else
                echo "\\033[0;31m[!] Failed to install $pkg. Please install it manually and re-run the script or continue at your own risk.\\033[0m"
                read -p "Continue despite failed package installation? (y/N): " continue_anyway
                if [[ "$continue_anyway" != "y" && "$continue_anyway" != "Y" ]]; then
                    exit 1
                fi
            fi
        fi
    done
}

# --- Configuration Setup ---
CONFIG_DIR="$HOME/.config"
KITTY_DIR="$CONFIG_DIR/kitty" # Changed from ALACRITTY_DIR
WAYBAR_DIR="$CONFIG_DIR/waybar"
ROFI_DIR="$CONFIG_DIR/rofi"
SWAYNC_DIR="$CONFIG_DIR/swaync" # Added swaync directory
HYPR_DIR="$CONFIG_DIR/hypr"
CSS_DIR="$(dirname "$0")/css" # Directory containing CSS files
CONFIG_FILES_DIR="$(dirname "$0")/config" # Directory containing configuration files

create_config_dirs() {
    echo_blue "\\n[*] Creating configuration directories..."
    mkdir -p "$KITTY_DIR"
    mkdir -p "$WAYBAR_DIR"
    mkdir -p "$ROFI_DIR"
    mkdir -p "$SWAYNC_DIR"
    mkdir -p "$HYPR_DIR"
    echo_green "[+] Configuration directories ensured."
}

configure_kitty() { # Renamed from configure_alacritty
    echo_blue "\\n[*] Configuring Kitty..."
    local kitty_config_file="$KITTY_DIR/kitty.conf" # Changed from alacritty.toml

    if [ -f "$kitty_config_file" ]; then
        echo_yellow "[i] Kitty config already exists at $kitty_config_file. Backing it up to $kitty_config_file.bak"
        cp "$kitty_config_file" "$kitty_config_file.bak"
    fi

    # Copy Kitty config from config directory
    cp "$CONFIG_FILES_DIR/kitty/kitty.conf" "$kitty_config_file"
    echo_green "[+] Kitty configuration copied from $CONFIG_FILES_DIR/kitty/kitty.conf"
    echo_yellow "[i] Note: You might need to run 'wal -i <your-wallpaper>' first for colors to apply via colors-kitty.conf."
}

configure_waybar() {
    echo_blue "\\n[*] Configuring Waybar..."
    local waybar_config_file="$WAYBAR_DIR/config"
    local waybar_style_file="$WAYBAR_DIR/style.css"

    if [ -f "$waybar_config_file" ]; then
        echo_yellow "[i] Waybar config already exists. Backing it up to $waybar_config_file.bak"
        cp "$waybar_config_file" "$waybar_config_file.bak"
    fi
    if [ -f "$waybar_style_file" ]; then
        echo_yellow "[i] Waybar style already exists. Backing it up to $waybar_style_file.bak"
        cp "$waybar_style_file" "$waybar_style_file.bak"
    fi

    # Copy Waybar config and style from config and css directories
    cp "$CONFIG_FILES_DIR/waybar/config" "$waybar_config_file"
    cp "$CSS_DIR/waybar/style.css" "$waybar_style_file"
    
    # Replace ~ with $HOME in the CSS file
    sed -i "s|~/.cache|$HOME/.cache|g" "$waybar_style_file"
    
    echo_green "[+] Waybar configuration copied from $CONFIG_FILES_DIR/waybar/config"
    echo_green "[+] Waybar style copied from $CSS_DIR/waybar/style.css"
    echo_yellow "[i] Note: Waybar's @import for Pywal colors needs 'wal -i <wallpaper>' to be run."
    echo_yellow "[i] Waybar's background transparency uses 'alpha(@background, 0.7)'. If this fails, edit style.css to use a direct rgba value like 'rgba(R,G,B,0.7)' based on your generated wal colors."
}

configure_rofi() {
    echo_blue "\\n[*] Configuring Rofi..."
    local rofi_config_file="$ROFI_DIR/config.rasi"
    local rofi_power_menu_script="$ROFI_DIR/rofi-power-menu"

    if [ -f "$rofi_config_file" ]; then
        echo_yellow "[i] Rofi config already exists at $rofi_config_file. Backing it up to $rofi_config_file.bak"
        cp "$rofi_config_file" "$rofi_config_file.bak"
    fi

    # Copy Rofi config and power menu script from config directory
    cp "$CONFIG_FILES_DIR/rofi/style.rasi" "$rofi_config_file"
    cp "$CONFIG_FILES_DIR/rofi/rofi-power-menu" "$rofi_power_menu_script"
    chmod +x "$rofi_power_menu_script"
    echo_green "[+] Rofi configuration copied from $CONFIG_FILES_DIR/rofi/style.rasi"
    echo_green "[+] Rofi power menu script copied from $CONFIG_FILES_DIR/rofi/rofi-power-menu and made executable"
    echo_yellow "[i] Note: Rofi configuration needs 'wal -i <wallpaper>' to be run for colors."
    echo_yellow "[i] The Rofi theme now uses more common Pywal variables like '@active-background'."
    echo_yellow "[i] If 'transparency: \"real\";' causes issues, try '\"screenshot\"' or remove the line from $rofi_config_file."
    echo_yellow "[i] You may need to install 'swaylock' for the lock option: sudo pacman -S swaylock"
}

# --- SwayNotificationCenter (swaync) Configuration ---
configure_swaync() {
    echo_blue "\\n[*] Configuring SwayNotificationCenter (swaync)..."
    local swaync_config_file="$SWAYNC_DIR/config.json"
    local swaync_style_file="$SWAYNC_DIR/style.css"

    if [ -f "$swaync_config_file" ]; then
        echo_yellow "[i] swaync config.json already exists. Backing it up to $swaync_config_file.bak"
        cp "$swaync_config_file" "$swaync_config_file.bak"
    fi
    if [ -f "$swaync_style_file" ]; then
        echo_yellow "[i] swaync style.css already exists. Backing it up to $swaync_style_file.bak"
        cp "$swaync_style_file" "$swaync_style_file.bak"
    fi

    # Copy swaync config and style from config and css directories
    cp "$CONFIG_FILES_DIR/swaync/config.json" "$swaync_config_file"
    cp "$CSS_DIR/swaync/style.css" "$swaync_style_file"
    echo_green "[+] swaync config.json copied from $CONFIG_FILES_DIR/swaync/config.json"
    echo_green "[+] swaync style.css copied from $CSS_DIR/swaync/style.css"
    echo_yellow "[i] Note: swaync's styles also depend on 'wal -i <wallpaper>' for Pywal colors."
    echo_yellow "[i] You may need to adjust the transparency (alpha values) and colors in $swaync_style_file to your liking."
    echo_yellow "[i] For a cleaner blur effect, ensure Hyprland is configured to blur swaync windows. Check comments in $swaync_style_file for example Hyprland settings."
}

configure_hypr() {
    echo_blue "\\n[*] Configuring Hyprland..."
    local hyprland_config_file="$HYPR_DIR/hyprland.conf"
    local hyprpaper_config_file="$HYPR_DIR/hyprpaper.conf"

    if [ -f "$hyprland_config_file" ]; then
        echo_yellow "[i] Hyprland config already exists. Backing it up to $hyprland_config_file.bak"
        cp "$hyprland_config_file" "$hyprland_config_file.bak"
    fi
    if [ -f "$hyprpaper_config_file" ]; then
        echo_yellow "[i] Hyprpaper config already exists. Backing it up to $hyprpaper_config_file.bak"
        cp "$hyprpaper_config_file" "$hyprpaper_config_file.bak"
    fi

    # Copy Hyprland config and hyprpaper config from config directory
    cp "$CONFIG_FILES_DIR/hypr/hyprland.conf" "$hyprland_config_file"
    cp "$CONFIG_FILES_DIR/hypr/hyprpaper.conf" "$hyprpaper_config_file"
    echo_green "[+] Hyprland config copied from $CONFIG_FILES_DIR/hypr/hyprland.conf"
    echo_green "[+] Hyprpaper config copied from $CONFIG_FILES_DIR/hypr/hyprpaper.conf"
}

# --- Main Execution ---
install_packages
create_config_dirs
configure_kitty # Changed from configure_alacritty
configure_waybar
configure_rofi
configure_swaync # Added swaync configuration
configure_hypr

echo_blue "\\n--- Installation and Basic Configuration Complete ---"
echo_green "\\n[+] Next Steps:"
echo "1. Choose a wallpaper and set it with Pywal:"
echo_yellow "   wal -i /path/to/your/wallpaper.jpg"
echo "   (Replace with the actual path to your wallpaper. This will generate color schemes.)"
echo "2. Your Hyprland config already includes 'wal -R && source ~/.cache/wal/colors.sh' on startup,"
echo "   which is good. After running 'wal -i ...' for the first time, these colors should apply to Kitty (via kitty.conf include) and other apps."
echo "3. You might need to restart Waybar, or reload Hyprland (usually SUPER + M, then reload, or logout/login) for all changes to take effect."
echo "   SwayNotificationCenter (swaync) should also pick up themes after 'wal' and a restart if needed (killall swaync; swaync &)."
echo "4. Review the generated config files in ~/.config/kitty, ~/.config/waybar, ~/.config/rofi, and ~/.config/swaync."
echo "   Customize them further to your liking. The Waybar and swaync style.css especially might need tweaks for perfect transparency with your chosen wallpaper colors."
echo "5. For the Rofi power menu lock function, ensure you have a screen locker like 'swaylock' installed ('sudo pacman -S swaylock')."
echo ""
echo_blue "Enjoy your themed setup!"
echo "Remember to make this script executable if you haven't: chmod +x arch_theme_installer.sh" 