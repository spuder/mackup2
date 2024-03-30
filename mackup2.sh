#!/bin/bash

# Define color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

if ! command -v unison &> /dev/null; then
    printf "${RED}Unison is not installed. Please install it before running mackup2.${NC}\n"
    exit 1
fi
if ! command -v unison-fsmonitor &> /dev/null; then
    printf "${RED}Unison-fsmonitor is not installed. Please install it before running mackup2.${NC}\n"
    exit 1
fi


if ! mkdir -p "$HOME/Library/Application Support/mackup2" &> /dev/null; then
    printf "${RED}Error creating /var/run/. Aborting.${NC}\n"
    exit 1
fi
if [ -e "$HOME/Library/Application Support/mackup2/mackup2.pid" ]; then
    printf "${RED}Error, mackup2.pid already exists. Aborting.${NC}\n"
    exit 1
fi
/bin/echo $$ > "$HOME/Library/Application Support/mackup2/mackup2.pid"

cleanup() {
    rm "$HOME/Library/Application Support/mackup2/mackup2.pid"
}
trap cleanup EXIT

# Define the iCloud Drive location
icloud_drive_path="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Mackup"

# Array to store PIDs of background processes
declare -a pids  # Use 'declare -a' for safer array handling
mkdir -p ~/Library/Logs/mackup2 &> /dev/null || true

# Define a function to parse the configuration file
parse_config() {
    local config_file="$1"
    local current_section=""
    local app_name=""

    while IFS= read -r line; do
        # Trim whitespace from the line
        line="${line#"${line%%[! \t]*}"}"   # remove leading whitespace characters
        line="${line%"${line##*[! \t]}}"}"  # remove trailing whitespace characters

        # Check for section headers
        if [[ "$line" =~ ^\[.*\]$ ]]; then
            current_section="${line//[\[\]]/}"
            continue
        fi

        # Process the application section
        if [[ "$current_section" == "application" ]]; then
            if [[ "$line" =~ ^name[[:space:]]*=(.*)$ ]]; then
                app_name="${BASH_REMATCH[1]}"
                app_name="${app_name#"${app_name%%[![:space:]]*}"}" # remove leading whitespace characters
                printf "${GREEN}Application: %s${NC}\n" "$app_name"
            fi
        fi

        # Process the configuration_files section
        if [[ "$current_section" == "configuration_files" ]]; then
            # If the line is blank, ignore it
            if [ -z "$line" ]; then
                continue
            fi

            # Treat the entire line as the value for configuration file paths
            local value="$line"
            local source_path="$HOME/$value"
            local destination_path="$icloud_drive_path/$value"

            # Check if source and destination exist
            if [ -e "$source_path" ] && [ -e "$destination_path" ]; then
                if [[ -L "$source_path" ]]; then
                    printf "${RED}Error: source is a symlink. Aborting: ${source_path}${NC}\n"
                    exit 1
                fi
                if  [[ -L "$destination_path" ]]; then
                    printf "${RED}Error: destination is a symlink. Aborting: ${destination_path}${NC}\n"
                    exit 1
                fi
                # Check if one is a file and the other is a directory
                if [ -d "$source_path" ] && [ -f "$destination_path" ]; then
                    printf "${RED}Critical error: source path is a directory, but destination path is a file. Aborting.${NC}\n"
                    exit 1
                elif [ -f "$source_path" ] && [ -d "$destination_path" ]; then
                    printf "${RED}Critical error: source path is a file, but destination path is a directory. Aborting.${NC}\n"
                    exit 1
                fi
            elif [ -e "$source_path" ]; then
                # Source exists, check if it's a file or directory
                if [ -d "$source_path" ]; then
                    # Source is a directory
                    if [ ! -d "$destination_path" ]; then
                        printf "${YELLOW}Creating directory: $destination_path${NC}\n"
                        mkdir -p "$destination_path"
                        unison -auto -batch -terse -prefer "$source_path" -logfile "$HOME/Library/Logs/mackup2/mackup2.log" "$source_path" "$destination_path"
                    fi
                elif [ ! -f "$destination_path" ]; then
                    printf "${YELLOW}Creating file: $destination_path${NC}\n"
                    touch "$destination_path"
                    unison -auto -batch -terse -prefer "$source_path" -logfile "$HOME/Library/Logs/mackup2/mackup2.log" "$source_path" "$destination_path"
                fi
            elif [ -e "$destination_path" ]; then
                # Destination exists, check if it's a file or directory
                if [ -d "$destination_path" ]; then
                    # Destination is a directory
                    if [ ! -d "$source_path" ]; then
                        printf "${YELLOW}Creating directory: $source_path${NC}\n"
                        mkdir -p "$source_path"
                        unison -auto -batch -terse -prefer "$destination_path" -logfile "$HOME/Library/Logs/mackup2/mackup2.log" "$source_path" "$destination_path"
                    fi
                elif [ ! -f "$source_path" ]; then
                    printf "${YELLOW}Creating file: $source_path${NC}\n"
                    touch "$source_path"
                    unison -auto -batch -terse -prefer "$destination_path" -logfile "$HOME/Library/Logs/mackup2/mackup2.log" "$source_path" "$destination_path"
                fi
            else
                # Neither source nor destination exists
                printf "${RED}Error: both source and destination paths do not exist. Aborting ${NC}\n"
                printf "${RED}${source_path}${NC}\n"
                printf "${RED}${destination_path}${NC}\n"
                exit 1
            fi            
            echo -e "Syncing ${GREEN}$source_path${NC} <-> ${GREEN}$destination_path${NC}"
            nohup unison -auto -batch -repeat watch -terse -prefer "$destination_path" "$source_path" "$destination_path" | tee -a "$HOME/Library/Logs/mackup2/$app_name.log" &
            pids+=($!)  # Append PID to the array
            # Log PID for debugging
            #echo "PID for $source_path: $!"
        fi

    done < "$config_file"
}

mkdir -p ~/.mackup2
# Check if any files exist in the ~/.mackup2 directory
if [ -z "$(ls -A ~/.mackup2)" ]; then
    echo "No files found in ~/.mackup2 directory. Exiting."
    exit 0
fi

# Iterate over the .cfg files in the ~/.mackup2 directory
for config_file in ~/.mackup2/*.cfg; do
    if [[ -f "$config_file" ]]; then
        parse_config "$config_file"
    fi
done

#TODO: if any of the pids die, the entire script should restart
wait "${pids[@]}"
