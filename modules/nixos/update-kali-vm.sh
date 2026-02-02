#!/usr/bin/env bash
# Script to automatically update Kali Linux VM version and hash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KALI_VM_FILE="${SCRIPT_DIR}/kali-vm.nix"
KALI_BASE_URL="https://kali.download/cloud-images/current"

echo "Checking for latest Kali Linux cloud image..."

# Get the latest version from the directory listing
LATEST_FILE=$(curl -s "${KALI_BASE_URL}/" | grep -o 'kali-linux-[0-9.]*-cloud-genericcloud-amd64\.tar\.xz' | head -1 | sort -V | tail -1)

if [ -z "${LATEST_FILE}" ]; then
    echo "Error: Could not find latest Kali Linux image file"
    exit 1
fi

# Extract version from filename (e.g., kali-linux-2025.4-cloud-genericcloud-amd64.tar.xz -> 2025.4)
VERSION=$(echo "${LATEST_FILE}" | sed -n 's/kali-linux-\([0-9.]*\)-cloud-genericcloud-amd64\.tar\.xz/\1/p')

if [ -z "${VERSION}" ]; then
    echo "Error: Could not extract version from filename: ${LATEST_FILE}"
    exit 1
fi

echo "Found latest version: ${VERSION}"
echo "Fetching SHA256 hash..."

# Fetch the hash using nix-prefetch-url
FULL_URL="${KALI_BASE_URL}/${LATEST_FILE}"
HASH=$(nix-prefetch-url --type sha256 "${FULL_URL}" 2>/dev/null | head -1)

if [ -z "${HASH}" ]; then
    echo "Error: Could not fetch hash for ${FULL_URL}"
    exit 1
fi

echo "Hash: ${HASH}"

# Check current version in file
CURRENT_VERSION=$(grep -o 'version = "[^"]*"' "${KALI_VM_FILE}" | sed 's/version = "\(.*\)"/\1/')

if [ "${CURRENT_VERSION}" = "${VERSION}" ]; then
    echo "Already at latest version ${VERSION}"
    exit 0
fi

echo "Updating from version ${CURRENT_VERSION} to ${VERSION}..."

# Create a temporary file for the update
TMP_FILE=$(mktemp)
trap "rm -f ${TMP_FILE}" EXIT

# Update version
sed -E "s/version = \"[^\"]*\"/version = \"${VERSION}\"/" "${KALI_VM_FILE}" > "${TMP_FILE}"

# Update URL (in case the version number is in the URL)
sed -i -E "s|url = \"https://kali\.download/cloud-images/current/kali-linux-[^\"]*\.tar\.xz\"|url = \"${FULL_URL}\"|" "${TMP_FILE}"

# Update hash
sed -i -E "s|sha256 = \"[^\"]*\"|sha256 = \"${HASH}\"|" "${TMP_FILE}"

# Replace original file
mv "${TMP_FILE}" "${KALI_VM_FILE}"

echo "Successfully updated to version ${VERSION}"
echo "Updated file: ${KALI_VM_FILE}"

