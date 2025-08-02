#!/bin/bash
#
# LnOS Release Signature Verification Script
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
    echo "  $0 lnos-arm64-2025.08.01.img lnos-arm64-2025.08.01.img.sig"
    echo ""
    echo "This script will:"
    echo "  1. Download the LnOS public key if needed"
    echo "  2. Verify the digital signature"
    echo "  3. Display verification results"
}

# Check arguments
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    print_usage
    exit 1
fi

FILE="$1"
SIG_FILE="${2:-${FILE}.sig}"

echo -e "${BLUE}🔐 LnOS Release Signature Verification${NC}"
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
    echo "Signature files have the same name as the original file with .sig extension"
    exit 1
fi

# Check for public key
PUBLIC_KEY="lnos-public-key.pem"
if [ ! -f "$PUBLIC_KEY" ]; then
    echo -e "${YELLOW}📥 Public key not found. Downloading from GitHub...${NC}"
    
    # Download public key (you'll need to host this)
    curl -fsSL "https://raw.githubusercontent.com/bakkertj/LnOS/main/keys/lnos-public-key.pem" -o "$PUBLIC_KEY" || {
        echo -e "${RED}❌ Failed to download public key${NC}"
        echo "Please manually download the public key from:"
        echo "https://github.com/bakkertj/LnOS/blob/main/keys/lnos-public-key.pem"
        exit 1
    }
    
    echo -e "${GREEN}✅ Public key downloaded${NC}"
fi

echo "📁 File: $FILE"
echo "🔏 Signature: $SIG_FILE"
echo "🔑 Public Key: $PUBLIC_KEY"
echo ""

# Display file information
echo -e "${BLUE}📊 File Information:${NC}"
echo "Size: $(ls -lh "$FILE" | awk '{print $5}')"
echo "SHA256: $(sha256sum "$FILE" | cut -d' ' -f1)"
echo ""

# Verify signature
echo -e "${BLUE}🔍 Verifying digital signature...${NC}"

if openssl dgst -sha256 -verify "$PUBLIC_KEY" -signature "$SIG_FILE" "$FILE" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ SIGNATURE VALID${NC}"
    echo "The file is authentic and has not been tampered with."
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
    echo "- Public key is incorrect or outdated"
    exit 1
fi

echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo "- The file is verified and safe to use"
echo "- You can proceed with installation"
echo "- For support, visit: https://github.com/bakkertj/LnOS"