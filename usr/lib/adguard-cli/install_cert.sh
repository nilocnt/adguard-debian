#!/bin/bash

set -e

FIREFOX_PROFILE_PATH=""
CERT_PATH=""

# Function usage prints the note about how to use the script.
usage() {
  echo 'Usage: install_cert.sh [-c cert_path] [-f firefox_profile_path] [-h]' 1>&2
}

# Function parse_opts parses the options list and validates it's combinations.
parse_opts() {
  while getopts 'hc:f:' opt "$@"
  do
    case "$opt"
    in
    'c')
      CERT_PATH="$OPTARG"
      ;;
    'h')
      usage
      exit 0
      ;;
    'f')
      FIREFOX_PROFILE_PATH="$OPTARG"
      ;;
    *)
      echo "bad option $OPTARG"
      usage
      exit 1
    ;;
    esac
  done
}

# Check if user is root
sudo_command=''
if [ "$EUID" -ne 0 ]; then
    sudo_command='sudo'
fi

parse_opts "$@"

# Check if a path to the certificate is provided
if [[ -z "$CERT_PATH" || ! -f "$CERT_PATH" ]]; then
    echo "Usage: $0 -c <path_to_certificate>"
    echo "<path_to_certificate>: Full path to the .pem certificate file."
    exit 1
fi

# Check extension
if [[ "${CERT_PATH}" != *.pem ]]; then
    echo "Error: Only .pem certificate files are supported."
    exit 1
fi

# Extract the filename without the extension for use as the certificate name
CERT_NAME=$(basename "${CERT_PATH}" .pem)


# Prepare file paths
if [[ -z "${SYSTEM_CERT_DIR}" ]]; then
    for i in "/usr/local/share/ca-certificates" \
             "/usr/share/pki/trust/anchors" \
             "/etc/pki/ca-trust/source/anchors" \
             "/etc/ca-certificates/trust-source/anchors"; \
    do
        if [[ -d "${i}" ]]; then
            SYSTEM_CERT_DIR="${i}"
            break
        fi
    done
fi
if [[ ! -d "${SYSTEM_CERT_DIR}" ]]; then
    echo "Don't know where to put the certificate. Please specify a directory path in SYSTEM_CERT_DIR."
    exit 1
fi
SYSTEM_CERT_PATH="${SYSTEM_CERT_DIR}/${CERT_NAME}.crt"

echo "SYSTEM_CERT_DIR: ${SYSTEM_CERT_DIR}"
echo "SYSTEM_CERT_PATH: ${SYSTEM_CERT_PATH}"

# Find certutil
CERTUTIL=$(command -v certutil || true)
if [ -z "$CERTUTIL" ]; then
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    if [ -x "$SCRIPT_DIR/certutil" ]; then
        CERTUTIL="$SCRIPT_DIR/certutil"
    else
        echo "Error: certutil not found. Please re-download AdGuard CLI from the official website and try again."
        exit 1
    fi
fi


# Copy certificate to the system's trusted certificates directory, if not already there
if [ ! -f "${SYSTEM_CERT_PATH}" ]; then
    echo "Copying certificate to the system's trusted certificates directory..."
    $sudo_command cp "${CERT_PATH}" "${SYSTEM_CERT_PATH}"
    echo "Updating the system's trusted certificates..."
    $sudo_command update-ca-certificates || failed_1="1"
    $sudo_command update-ca-trust || failed_2="1"
    if [[ ${failed_1:-"0"} -eq "1" && ${failed_2:-"0"} -eq "1" ]]; then
        echo "Failed to update trust settings"
        exit 1
    fi
else
    echo "Certificate already exists in system trust store."
fi

# Check firefox profile section
is_matching_profile() {
    local name="$1"
    local path="$2"
    local default="$3"

    if [[ -z "$path" ]]; then
        return 1
    fi

    if [[ -z "$FIREFOX_PROFILE_PATH" && "$default" -eq 1 ]]; then
        return 0
    elif [[ "$FIREFOX_PROFILE_PATH" == "$path" ]]; then
        return 0
    fi

    return 1
}

# Function to find Firefox profiles
find_firefox_profiles() {
    # if abs path
    if [[ "$FIREFOX_PROFILE_PATH" == /* && -d "$FIREFOX_PROFILE_PATH" ]]; then
        echo "$FIREFOX_PROFILE_PATH"
        return
    fi

    local profile_dirs=()
    # Dir for Firefox installed via apt
    [[ -d "$HOME/.mozilla/firefox" ]] && profile_dirs+=("$HOME/.mozilla/firefox")
    # Dirs for Firefox installed via snap
    for snap_dir in "$HOME"/snap/firefox*/common/.mozilla/firefox; do
        [[ -d "$snap_dir" ]] && profile_dirs+=("$snap_dir")
    done

    for dir in "${profile_dirs[@]}"; do
        local ini_path="${dir}/profiles.ini"
        if [[ -f "$ini_path" ]]; then
            local in_section=0
            local path=""
            local name=""
            local default=0
            local is_relative=1
            while IFS= read -r line; do
                if [[ "$line" =~ ^\[Profile[0-9]+\]$ ]]; then
                    if is_matching_profile "$name" "$path" "$default"; then
                        if [[ "$is_relative" -eq 1 ]]; then
                            echo "${dir}/${path}"
                        else
                            echo "$path"
                        fi
                    fi

                    in_section=1
                    path=""
                    name=""
                    default=0
                    is_relative=1
                elif [[ "$in_section" -eq 1 ]]; then
                    if [[ "$line" =~ ^Name= ]]; then
                        name="${line#Name=}"
                    elif [[ "$line" =~ ^Path= ]]; then
                        path="${line#Path=}"
                    elif [[ "$line" == "IsRelative=0" ]]; then
                        is_relative=0
                    elif [[ "$line" == "Default=1" ]]; then
                        default=1
                    elif [[ "$line" =~ ^\[.*\]$ ]]; then
                        in_section=0
                    fi
                fi
            done < "$ini_path"
            if is_matching_profile "$name" "$path" "$default"; then
                if [[ "$is_relative" -eq 1 ]]; then
                    echo "${dir}/${path}"
                else
                    echo "$path"
                fi
            fi
        fi
    done
}

FIREFOX_PROFILES=$(find_firefox_profiles)

if [ -z "$FIREFOX_PROFILES" ]; then
    echo "Firefox profile not found."
else
    echo "$FIREFOX_PROFILES" | while IFS= read -r profile; do
        [ -n "$profile" ] || continue
        echo "Firefox profile found: $profile"
        echo "Adding certificate to Firefox's certificate store..."
        "$CERTUTIL" -A -n "${CERT_NAME}" -t "TC,C,T" -i "${CERT_PATH}" -d sql:"${profile}"
        echo "Certificate added to Firefox profile successfully: $profile"
    done
fi

# Function to find Chrome/Chromium profiles
find_chrome_profiles() {
    local profile_dirs=(
        # Dir for Chrome installed via apt or downloaded from the website
        "$HOME/.pki/nssdb"
        # Dir for Chromium installed via snap
        "$HOME/snap/chromium/current/.pki/nssdb"
    )

    for dir in "${profile_dirs[@]}"; do
        echo "$dir"
    done
}

echo "Finding Chrome profile..."
CHROME_PROFILES=$(find_chrome_profiles)

if [ -z "$CHROME_PROFILES" ]; then
    echo "Chrome profile not found."
else
    echo "$CHROME_PROFILES" | while IFS= read -r profile; do
        # Find database if there is none
        if [ ! -f "$profile/cert9.db" ]; then
            echo "No cert9.db found at: $profile"
            continue
        fi

        [ -n "$profile" ] || continue
        echo "Chrome profile found: $profile"
        echo "Adding certificate to Chrome's certificate store..."
        "$CERTUTIL" -A -n "${CERT_NAME}" -t "TC,C,T" -i "${CERT_PATH}" -d sql:"${profile}"
        echo "Certificate added to Chrome profile successfully: $profile"
    done
fi

echo "All steps completed successfully."
