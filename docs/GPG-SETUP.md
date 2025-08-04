# GPG Setup for LnOS Release Signing

This guide explains how to set up GPG signing for LnOS releases - a simple, secure alternative to SignServer.

## 🔑 Key Generation

### 1. Generate a GPG Key Pair

```bash
# Generate a new GPG key (interactive)
gpg --full-generate-key

# Select options:
# - Key type: RSA and RSA (default)
# - Key size: 4096 bits
# - Expiration: 2 years (recommended)
# - Name: LnOS Development Team
# - Email: your-signing-email@example.com
# - Comment: LnOS Release Signing Key
```

### 2. Alternative: Non-interactive Generation

```bash
# Create key generation config
cat > gpg-key-config << EOF
%echo Generating LnOS signing key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: LnOS Development Team
Name-Email: releases@lnos.example.com
Expire-Date: 2y
Passphrase: YOUR_SECURE_PASSPHRASE
%commit
%echo done
EOF

# Generate key
gpg --batch --generate-key gpg-key-config
rm gpg-key-config
```

## 📤 Export Keys

### 1. Get Key Information

```bash
# List your keys
gpg --list-secret-keys --keyid-format=long

# Example output:
# sec   rsa4096/ABC123DEF456 2024-08-01 [SC] [expires: 2026-08-01]
#       1234567890ABCDEF1234567890ABCDEF12345678
# uid                 [ultimate] LnOS Development Team <releases@lnos.example.com>
# ssb   rsa4096/GHI789JKL012 2024-08-01 [E] [expires: 2026-08-01]

# Your key ID is: ABC123DEF456
```

### 2. Export Public Key

```bash
# Export ASCII-armored public key
gpg --armor --export ABC123DEF456 > lnos-public-key.asc

# Export key fingerprint
gpg --fingerprint ABC123DEF456 > lnos-key-fingerprint.txt
```

### 3. Export Private Key (for GitHub Secrets)

```bash
# Export private key (keep this secure!)
gpg --armor --export-secret-keys ABC123DEF456 > lnos-private-key.asc

# Note: This file contains your private key - treat it like a password!
```

## 🔐 GitHub Secrets Setup

Add these secrets to your GitHub repository:

### Required Secrets:

1. **`GPG_PRIVATE_KEY`**:
   ```bash
   # Copy the entire contents of lnos-private-key.asc
   cat lnos-private-key.asc
   ```

2. **`GPG_PASSPHRASE`**:
   ```
   Your GPG key passphrase
   ```

### Setting up Secrets:

1. Go to GitHub Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add both secrets above

## 📁 Repository Files

### 1. Add Public Key to Repository

```bash
# Copy public key to repository
cp lnos-public-key.asc keys/

# Update verification script with your key ID
# Edit scripts/verify-signature.sh:
# LNOS_KEY_ID="ABC123DEF456"
# LNOS_KEY_FINGERPRINT="1234 5678 90AB CDEF 1234  5678 90AB CDEF 1234 5678"
```

### 2. Update Key Information

Edit `scripts/verify-signature.sh` and replace:
```bash
LNOS_KEY_FINGERPRINT="YOUR_KEY_FINGERPRINT_HERE"
LNOS_KEY_ID="YOUR_KEY_ID_HERE"
```

With your actual values:
```bash
LNOS_KEY_FINGERPRINT="1234 5678 90AB CDEF 1234  5678 90AB CDEF 1234 5678"
LNOS_KEY_ID="ABC123DEF456"
```

## 🧪 Testing

### 1. Test Local Signing

```bash
# Create test file
echo "test data" > test.txt

# Sign it
gpg --detach-sign --armor test.txt

# Verify
gpg --verify test.txt.asc test.txt
```

### 2. Test GitHub Action

1. Push changes to trigger the workflow
2. Check the Action logs for signing output
3. Download release artifacts and verify signatures

### 3. Test Verification Script

```bash
# Test the verification script
./scripts/verify-signature.sh test.txt test.txt.asc
```

## 🔄 Key Management

### Key Rotation

```bash
# Generate new key (follow generation steps above)
# Update GitHub secrets with new private key
# Replace public key in repository
# Announce key change to users
```

### Key Backup

```bash
# Backup entire GPG directory
tar -czf gpg-backup-$(date +%Y%m%d).tar.gz ~/.gnupg/

# Store securely offline
# Consider using hardware security keys for production
```

### Key Distribution

```bash
# Upload to key servers (optional)
gpg --send-keys ABC123DEF456

# Publish fingerprint through multiple channels:
# - GitHub repository
# - Official website
# - Social media
# - Documentation
```
