#!/bin/bash
#
# LnOS Release GPG Signature Verification Script
# Usage: ./verify-signature.sh <file> [signature_file]
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: $0 <file> [signature_file]"
    echo ""
    echo "Examples:"
    echo "  $0 lnos-2025.08.01-x86_64.iso"
    echo "  $0 lnos-arm64-2025.08.01.img lnos-arm64-2025.08.01.img.asc"
    echo ""
    echo "This script will:"
    echo "  1. Import the LnOS GPG public key if needed"
    echo "  2. Verify the GPG signature"
    echo "  3. Display verification results"
}

# Check arguments
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    print_usage
    exit 1
fi

FILE="$1"
SIG_FILE="${2:-${FILE}.asc}"

echo -e "${BLUE}🔐 LnOS Release GPG Signature Verification${NC}"
echo "========================================"
echo ""

# Check if file exists
if [ ! -f "$FILE" ]; then
    echo -e "${RED}❌ Error: File '$FILE' not found${NC}"
    echo "Please ensure the file is in the current directory"
    exit 1
fi

# Check if signature file exists
if [ ! -f "$SIG_FILE" ]; then
    echo -e "${RED}❌ Error: Signature file '$SIG_FILE' not found${NC}"
    echo "Please ensure the signature file is in the current directory"
    echo "Signature files have the same name as the original file with .asc extension"
    exit 1
fi

# GPG key fingerprint for LnOS releases
LNOS_KEY_FINGERPRINT="FF3B 2203 9FA1 CBC0 72E5  8967 9486 7593 1287 6AD7"
LNOS_KEY_ID="9486759312876AD7"

# Check if GPG key is imported
if ! gpg --list-keys "$LNOS_KEY_ID" >/dev/null 2>&1; then
    echo -e "${YELLOW}📥 LnOS GPG key not found. Importing from GitHub...${NC}"
    
    # Download and import public key
    curl -fsSL "https://raw.githubusercontent.com/bakkertj/LnOS/main/keys/lnos-public-key.asc" | gpg --import || {
        echo -e "${RED}❌ Failed to import public key${NC}"
        echo "Please manually import the public key:"
        echo "curl -fsSL https://raw.githubusercontent.com/bakkertj/LnOS/main/keys/lnos-public-key.asc | gpg --import"
        exit 1
    }
    
    echo -e "${GREEN}✅ Public key imported${NC}"
fi

echo "📁 File: $FILE"
echo "🔏 Signature: $SIG_FILE"
echo "🔑 GPG Key ID: $LNOS_KEY_ID"
echo ""

# Display file information
echo -e "${BLUE}📊 File Information:${NC}"
echo "Size: $(ls -lh "$FILE" | awk '{print $5}')"
echo "SHA256: $(sha256sum "$FILE" | cut -d' ' -f1)"
echo ""

# Verify GPG signature
echo -e "${BLUE}🔍 Verifying GPG signature...${NC}"

if gpg --verify "$SIG_FILE" "$FILE" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ SIGNATURE VALID${NC}"
    echo "The file is authentic and has not been tampered with."
    echo ""
    
    # Show signature details
    echo -e "${BLUE}📋 Signature Details:${NC}"
    gpg --verify "$SIG_FILE" "$FILE" 2>&1 | grep -E "(Good signature|using|created)" || true
    echo ""
    echo -e "${GREEN}🎉 This file is officially signed by the LnOS development team${NC}"
else
    echo -e "${RED}❌ SIGNATURE INVALID${NC}"
    echo "⚠️  WARNING: This file may have been corrupted or tampered with!"
    echo "DO NOT use this file for installation."
    echo ""
    echo "Possible causes:"
    echo "- File was corrupted during download"
    echo "- File has been modified or tampered with"
    echo "- Wrong signature file for this file"
    echo "- GPG key is incorrect or outdated"
    echo ""
    echo "Detailed GPG output:"
    gpg --verify "$SIG_FILE" "$FILE" 2>&1 || true
    exit 1
fi

echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "- The file is verified and safe to use"
echo "- You can proceed with installation"
echo "- For support, visit: https://github.com/bakkertj/LnOS"