#!/usr/bin/env bash

## (c) 2023 // Sam Dennon

set -u

# We need to check if a function has already run this stores the breadcrumbs to keep track
temp_file="/tmp/ran_functions.txt"

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

start_spinner() {
  local eight_dot_cell_pattern=("⣾" "⢿" "⡿" "⣷" "⣯" "⢟" "⡻" "⣽")
  local braille_spinner=("${eight_dot_cell_pattern[@]}")
  local frame_duration=0.1

  local spinner_index=0
  (
    while :; do
      printf "\r%s " "${braille_spinner[spinner_index]}"
      spinner_index=$(( (spinner_index + 1) % ${#braille_spinner[@]} ))
      sleep "$frame_duration"
    done
  ) &
  spinner_pid=$!
  disown
}

stop_spinner() {
  kill -9 "$1"  # Stop the spinner loop
  printf "\r%s " "⠀"  # Print U+2800 (Braille Pattern Blank) and move to the next line
  display_message "$1"
}

has_function_run() {
    local function_name="$1"

    touch "$temp_file"

    grep -q "$function_name" "$temp_file" 
}

mark_function_complete() {
    local function_name="$1"

    echo "$function_name" >> "$temp_file"
}

danger_will() {
    printf "%s\n" "$@" >&2
    exit 1
}

check_ubuntu() {
    if [ -e /etc/os-release ]; then
        # shellcheck disable=SC1091
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
    local function_name="install_packages"

    if has_function_run "$function_name"; then
        echo "$function_name has already run."
    else
            # Check for empty package list
        if [ "$#" -eq 0 ]; then
            danger_will "No packages provided for installation."
        fi

        # Update package cache
        apt update -qq

        # Install packages non-interactively and quietly
        apt install -y -qq "$@"

        mark_function_complete "$function_name"
    fi
}

clone_repository() {
    local function_name="clone_repository"

    if has_function_run "$function_name"; then
        echo "$function_name has already run."
    else   
        if [ "$#" -eq 0 ]; then
            danger_will "No repository URLs provided."
        fi

        for repo_url in "$@"; do
            repo_name=$(basename "$repo_url" .git)
            repo_dir="./$repo_name"

            if [ -d "$repo_dir" ]; then
                echo "Repository $repo_name already exists. Skipping cloning."
            else
                echo "Cloning the repository: $repo_url"
                git clone "$repo_url" || danger_will "Failed to clone the repository: $repo_url"
            fi
        done

        mark_function_complete "$function_name"
    fi
}

make_image_viewer() {
    local function_name="make_image_viewer"
    if has_function_run "$function_name"; then
        echo "$function_name has already run."
    else
        pushd "$led_viewer_dir" || danger_will "Failed to change directory to $led_viewer_dir"
        
        # Build led-image-viewer
        make led-image-viewer || danger_will "Failed to build led-image-viewer."

        # Move the built binary to /usr/bin/
        mv led-image-viewer /usr/bin/ || danger_will "Failed to move led-image-viewer to /usr/bin/"

        popd || danger_will "Failed to return to the original directory."

        mark_function_complete "$function_name"
    fi
}

move_love() {
    local function_name="move_love"

    if has_function_run "$function_name"; then
        echo "$function_name has already run."
    else
        mv -fu "$love_source" "$love_destination" || danger_will "Failed to move 'love' directory."
        
        chmod +x "${love_destination}/love/love.sh" "${love_destination}/love/toggler.sh" || danger_will "Failed to change permissions."

        mark_function_complete "$function_name"
    fi
}

add_cron_entries() {
    # Ensure the crontab entries are not already present
    if ! (crontab -l | grep -q "/opt/love/love.sh" && sudo crontab -l | grep -q "/opt/love/toggler.sh"); then
        # Create a temporary file to hold the new crontab entries
        temp_crontab=$(mktemp)

        # Add entries to the temporary file using echo
        {
            echo "@reboot cd /opt/love && /opt/love/love.sh"
            echo "@reboot /opt/love/toggler.sh"
            echo "0 18 * * * /usr/bin/screen -S love -X quit"
            echo "0 5 * * * cd /opt/love /opt/love/love.sh"
         } >> "$temp_crontab"

        # Replace the existing crontab with the updated one
        crontab "$temp_crontab" || danger_will "Failed to update crontab"

        # Remove the temporary file
        rm "$temp_crontab"

        echo "Crontab entries added successfully."
    else
        echo "Crontab entries are already present. Skipping addition."
    fi
}

install_rpi_gpio() {
    local function_name="install_rpi_gpio"

    if has_function_run "$function_name"; then
        echo "$function_name has already run."
    else
        local external_managed_file="/usr/lib/python3.11/EXTERNALLY-MANAGED"

        echo "Removing EXTERNALLY_MANAGED file if exists..."
        if [ -e "$external_managed_file" ]; then
            rm -f "$external_managed_file" || danger_will "Failed to remove EXTERNALLY_MANAGED file."
            echo "EXTERNALLY_MANAGED file removed successfully."
        else
            echo "EXTERNALLY_MANAGED file does not exist."
        fi

        echo "Installing RPi.GPIO library..."
        pip install RPi.GPIO || danger_will "Failed to install RPi.GPIO library."
        echo "RPi.GPIO library installed successfully."

        mark_function_complete "$function_name"
    fi
}

blacklist_snd_module() {
    local function_name="blacklist_snd_module"

    if has_function_run "$function_name"; then
        echo "$function_name has already run."
    else
        local blacklist_file="/etc/modprobe.d/blacklist-rgb-matrix.conf"

        echo "Blacklisting snd_bcm2835 module..."

        # Check if the file exists, create it if not
        [ -e "$blacklist_file" ] || sudo touch "$blacklist_file"

        # Use sed to delete existing line and append the new entry
        sed -i '/^blacklist snd_bcm2835/d' "$blacklist_file" || danger_will "Failed to update blacklist entry with sed."
        echo "blacklist snd_bcm2835" | sudo tee -a "$blacklist_file" > /dev/null || danger_will "Failed to append blacklist entry."

        update-initramfs -u || danger_will "Failed to update initramfs."
        echo "Initramfs updated successfully."

        mark_function_complete "$function_name"
    fi
}

add_isolcpus_to_cmdline() {
    local cmdline_file="/boot/firmware/cmdline.txt"

    echo "Adding isolcpus=3 to cmdline.txt..."

    # Check if isolcpu=3 is already present in the first line
    if ! grep -q "^.*isolcpus=3\b" "$cmdline_file"; then
        # If not present, add isolcpu=3 to the end of the first line
        sed -i '1s/$/ isolcpus=3/' "$cmdline_file" || danger_will "Failed to update cmdline.txt with sed."
        echo "isolcpus=3 added to cmdline.txt."
    else
        echo "isolcpus=3 is already present in cmdline.txt. Skipping addition."
    fi
}

delete_cloned_repos() {
    local repos=("$@")

    if [ "${#repos[@]}" -gt 0 ]; then
        for repo_url in "${repos[@]}"; do
            local repo_name
            repo_name=$(basename "$repo_url" .git)
            local repo_path="${repo_name}"
            
            if [[ -d "${repo_path}" ]]; then
                echo "Deleting repository: ${repo_path}"
                rm -rf "${repo_path}"
            else
                "Repository does not exist: ${repo_path}"
            fi
        done
    fi
}

config_neofetch(){
    local neofetch_config_path="/root/.config/neofetch"
    
    # Create path if it doesn't exist
    if [[ ! -d "$neofetch_config_path" ]]; then
        mkdir -p "$neofetch_config_path"
    fi

    # Remove the config if it exists
    if [ -e "$neofetch_config_path/config.conf" ]; then
        rm "$neofetch_config_path/config.conf"
    fi

tee "$neofetch_config_path/config.conf" > /dev/null << END_OF_LINE
    print_info() {
        info title
        info underline

        info "OS" distro
        info "Host" model
        info "Kernel" kernel
        info "Uptime" uptime
        info "Packages" packages
        info "Shell" shell
        info "CPU" cpu
        info "Memory" memory
    }
    ascii_distro="Raspbian_small"
END_OF_LINE
}

cleanup_motd() {
    local motd_path="/etc/update-motd.d"
    local wrapper_path="/usr/share/landscape/landscape-sysinfo.wrapper"
    local files_to_remove=(
        "91-contract-ua-esm-status"
        "95-hwe-eol"
        "10-help-text"
        "50-motd-news"
    )

    for file in "${files_to_remove[@]}"; do
        rm "$motd_path/$file" 2>/dev/null
    done

tee "$wrapper_path" > /dev/null << END_OF_LINE
    #!/usr/bin/env bash
    neofetch
END_OF_LINE

}

reboot_prompt() {
    read -pr "You need to reboot now. (y to reboot, n to do it later) " CONT
    if test "$CONT" = "y"; then
        echo "See ya!"
        reboot
    else
        echo "Cool, we can reboot later. The doing of things is complete!"
        return 0
    fi
}

# Call the functions
start_spinner
check_ubuntu
root_sudo_check
install_packages "${package_list[@]}"
clone_repository "${repo_urls[@]}"
make_image_viewer
move_love
add_cron_entries
install_rpi_gpio
blacklist_snd_module
add_isolcpus_to_cmdline
delete_cloned_repos "${repo_urls[@]}"
config_neofetch
cleanup_motd
stop_spinner "$spinner_pid"
reboot_prompt