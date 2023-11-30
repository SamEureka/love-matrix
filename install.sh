#!/usr/bin/env bash

## (c) 2023 // Sam Dennon


# Packages to be installed
package_list=(
  neofetch
  make
  libgraphicsmagick++-dev
  libwebp-dev
  python3-pip
  # Add more packages as needed
)

# Repository URLs variables
repo_urls=(
    "https://github.com/hzeller/rpi-rgb-led-matrix.git"
    "https://github.com/SamEureka/love-matrix.git"
    # Add more repository URLs as needed
)

# Directory where led-image-viewer will be built
led_viewer_dir="rpi-rgb-led-matrix/utils"

# Directory where "love" will be moved to
love_source="love-matrix/love"
love_destination="/opt/"

set -u

danger_will() {
    printf "%s\n" "$@" >&2
    exit 1337
}

check_ubuntu() {
    if [ -e /etc/os-release ]; then
        source /etc/os-release
        if [ "$ID" != "ubuntu" ]; then
            danger_will "This script is intended to run on Ubuntu Linux only."
        fi

        # Check the Ubuntu release version
        if [ "${VERSION_ID}" != "23.10" ]; then
            danger_will "This script is intended for Ubuntu 23.10. Detected version: ${VERSION_ID}"
        fi
    else
        danger_will "Unable to determine the operating system. This script is intended for Ubuntu Linux."
    fi
}

root_sudo_check() {
    if [[ $EUID -ne 0 ]]; then
        danger_will "This script must be run as root or with sudo."
    fi
}

install_packages() {
    # Check for Ubuntu 23.10
    check_ubuntu

    # Check for root/sudo privileges
    root_sudo_check

    # Update package cache
    sudo apt update -qq

    # Install packages non-interactively and quietly
    sudo apt install -y -qq "${package_list[@]}"
}

clone_repository() {
    if [ "$#" -eq 0 ]; then
        danger_will "No repository URLs provided."
    fi

    for repo_url in "$@"; do
        echo "Cloning the repository: $repo_url"
        git clone "$repo_url" || danger_will "Failed to clone the repository: $repo_url"
    done
}

make_image_viewer() {
    pushd "$led_viewer_dir" || danger_will "Failed to change directory to $led_viewer_dir"
    
    # Build led-image-viewer
    make led-image-viewer || danger_will "Failed to build led-image-viewer."

    # Move the built binary to /usr/bin/
    sudo mv led-image-viewer /usr/bin/ || danger_will "Failed to move led-image-viewer to /usr/bin/"

    popd || danger_will "Failed to return to the original directory."
}

move_love() {
    sudo mv "$love_source" "$love_destination" || danger_will "Failed to move 'love' directory."
    sudo chmod +x "$love_destination/love.sh" "$love_destination/toggler.sh" || danger_will "Failed to change permissions."
}

add_cron_entries() {
    # Ensure the crontab entries are not already present
    if ! (sudo crontab -l | grep -q "/opt/love/love.sh" && sudo crontab -l | grep -q "/opt/love/toggler.sh"); then
        # Add entries to root crontab using sed
        sudo sed -i '$a@reboot cd /opt/love && /opt/love/love.sh' <(sudo crontab -l) || danger_will "Failed to add crontab entry for love.sh"
        sudo sed -i '$a@reboot /opt/love/toggler.sh' <(sudo crontab -l) || danger_will "Failed to add crontab entry for toggler.sh"
        echo "Crontab entries added successfully."
    else
        echo "Crontab entries are already present. Skipping addition."
    fi
}

install_rpi_gpio() {
    local external_managed_file="/usr/lib/python3.11/EXTERNALLY_MANAGED"

    echo "Removing EXTERNALLY_MANAGED file if exists..."
    sudo rm -f "$external_managed_file" || danger_will "Failed to remove EXTERNALLY_MANAGED file."
    echo "EXTERNALLY_MANAGED file removed successfully."

    echo "Installing RPi.GPIO library..."
    sudo pip install RPi.GPIO || danger_will "Failed to install RPi.GPIO library."
    echo "RPi.GPIO library installed successfully."
}

blacklist_snd_module() {
    local blacklist_file="/etc/modprobe.d/blacklist-rgb-matrix.conf"

    echo "Blacklisting snd_bcm2835 module..."

    # Check if the file exists, create it if not
    [ -e "$blacklist_file" ] || sudo touch "$blacklist_file"

    # Use sed to delete existing line and append the new entry
    sudo sed -i '/^blacklist snd_bcm2835/d' "$blacklist_file" || danger_will "Failed to update blacklist entry with sed."
    echo "blacklist snd_bcm2835" | sudo tee -a "$blacklist_file" > /dev/null || danger_will "Failed to append blacklist entry."

    sudo update-initramfs -u || danger_will "Failed to update initramfs."
    echo "Initramfs updated successfully."
}


reboot_prompt() {
    local counter=0

    while true; do
        echo "This script requires a reboot. Do you want to reboot now? (y/n)"
        read -r answer

        case $answer in
            [Yy])
                echo "Rebooting..."
                sudo reboot
                ;;
            [Nn])
                ((counter++))
                if [ "$counter" -lt 2 ]; then
                    echo "No problem. You can manually reboot later if needed."
                else
                    echo "You've declined to reboot multiple times. Rebooting now..."
                    sudo reboot
                fi
                ;;
            *)
                echo "Invalid response. Please enter 'y' for yes or 'n' for no."
                ;;
        esac
    done
}

add_isolcpu_to_cmdline() {
    local cmdline_file="/boot/firmware/cmdline.txt"

    echo "Adding isolcpu=3 to cmdline.txt..."

    # Check if isolcpu=3 is already present in the first line
    if ! grep -q "^.*isolcpu=3\b" "$cmdline_file"; then
        # If not present, add isolcpu=3 to the end of the first line
        sudo sed -i '1s/$/ isolcpu=3/' "$cmdline_file" || danger_will "Failed to update cmdline.txt with sed."
        echo "isolcpu=3 added to cmdline.txt."
    else
        echo "isolcpu=3 is already present in cmdline.txt. Skipping addition."
    fi
}

# Call the functions
install_packages
clone_repository "${repo_urls[@]}"
make_image_viewer
move_love
add_cron_entries
install_rpi_gpio
blacklist_snd_module
add_isolcpu_to_cmdline
reboot_prompt