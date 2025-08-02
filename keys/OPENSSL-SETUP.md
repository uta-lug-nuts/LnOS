# OpenSSL Setup for LnOS Release Signing

This guide shows how to use OpenSSL directly for release signing - a middle-ground approach between GPG simplicity and SignServer enterprise features.

## 🔑 Key and Certificate Generation

### 1. Generate Private Key

```bash
# Generate RSA 4096-bit private key
openssl genrsa -aes256 -out lnos-signing-key.pem 4096

# Alternative: Generate ECDSA key (smaller, faster)
openssl ecparam -genkey -name secp384r1 -out lnos-signing-key.pem
openssl ec -in lnos-signing-key.pem -aes256 -out lnos-signing-key.pem
```

### 2. Create Certificate Signing Request

```bash
# Create CSR configuration
cat > lnos-csr.conf << EOF
[req]
default_bits = 4096
prompt = no
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]
C=US
ST=State
L=City
O=LnOS Development Team
OU=Release Engineering
CN=LnOS Release Signing
emailAddress=releases@lnos.example.com

[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = codeSigning
EOF

# Generate CSR
openssl req -new -key lnos-signing-key.pem -out lnos-signing.csr -config lnos-csr.conf
```

### 3. Self-Signed Certificate (for open source)

```bash
# Create self-signed certificate
openssl x509 -req -in lnos-signing.csr -signkey lnos-signing-key.pem -out lnos-signing-cert.pem -days 730 -extensions v3_req -extfile lnos-csr.conf

# Extract public key
openssl x509 -pubkey -noout -in lnos-signing-cert.pem > lnos-public-key.pem
```

### 4. Alternative: CA-Signed Certificate

```bash
# Submit CSR to your Certificate Authority
# Install the signed certificate as lnos-signing-cert.pem
# Obtain the CA certificate chain if needed
```

## 📤 GitHub Actions Integration

### OpenSSL Signing Step

```yaml
- name: Sign release files with OpenSSL
  if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/ISO'
  env:
    OPENSSL_PRIVATE_KEY: ${{ secrets.OPENSSL_PRIVATE_KEY }}
    OPENSSL_PASSPHRASE: ${{ secrets.OPENSSL_PASSPHRASE }}
  run: |
    cd ./isos/
    
    echo "🔐 Signing release files with OpenSSL..."
    
    # Create private key file
    echo "$OPENSSL_PRIVATE_KEY" > signing-key.pem
    chmod 600 signing-key.pem
    
    # Sign all release files
    for file in *.iso *.img *.xz; do
      if [ -f "$file" ]; then
        echo "🔏 Signing: $file"
        
        # Create SHA-256 signature
        openssl dgst -sha256 -sign signing-key.pem -passin env:OPENSSL_PASSPHRASE -out "${file}.sig" "$file"
        
        if [ -f "${file}.sig" ]; then
          echo "✅ Successfully signed: $file -> ${file}.sig"
          echo "📝 Signature size: $(wc -c < "${file}.sig") bytes"
        else
          echo "❌ Failed to sign: $file"
        fi
      fi
    done
    
    # Clean up private key
    rm -f signing-key.pem
    
    echo ""
    echo "=== SIGNED FILES ==="
    ls -lh *.sig 2>/dev/null || echo "No signature files found"
```

## 🔐 GitHub Secrets Setup

Add these secrets to your GitHub repository:

### Required Secrets:

1. **`OPENSSL_PRIVATE_KEY`**:
   ```bash
   # Copy the entire contents of lnos-signing-key.pem
   cat lnos-signing-key.pem
   ```

2. **`OPENSSL_PASSPHRASE`**:
   ```
   Your private key passphrase
   ```

## 📝 Verification Script (OpenSSL)

```bash
#!/bin/bash
# verify-openssl.sh

FILE="$1"
SIG_FILE="${2:-${FILE}.sig}"
CERT_FILE="lnos-signing-cert.pem"

# Download certificate if not present
if [ ! -f "$CERT_FILE" ]; then
    curl -fsSL "https://raw.githubusercontent.com/bakkertj/LnOS/main/keys/lnos-signing-cert.pem" -o "$CERT_FILE"
fi

# Extract public key from certificate
openssl x509 -pubkey -noout -in "$CERT_FILE" > lnos-public-key.pem

# Verify signature
if openssl dgst -sha256 -verify lnos-public-key.pem -signature "$SIG_FILE" "$FILE"; then
    echo "✅ Signature valid - file is authentic"
    
    # Show certificate details
    echo ""
    echo "📋 Certificate Details:"
    openssl x509 -subject -issuer -dates -noout -in "$CERT_FILE"
else
    echo "❌ Signature invalid - file may be corrupted or tampered with"
    exit 1
fi
```

## 🆚 Comparison: Implementation Approaches

### Current SignServer Approach
```yaml
# Complex, requires external infrastructure
curl -X POST -u "$USER:$PASS" -F "data=@$file" "$SIGNSERVER_URL/process" -o "$file.sig"
```

### GPG Approach (Recommended)
```yaml
# Simple, self-contained
gpg --batch --yes --passphrase "$GPG_PASSPHRASE" --detach-sign --armor "$file"
```

### OpenSSL Approach
```yaml
# Manual but flexible
openssl dgst -sha256 -sign key.pem -passin env:PASSPHRASE -out "$file.sig" "$file"
```

## 🏗️ Implementation Choice

### Replace SignServer with GPG (Recommended)

**Advantages:**
- ✅ No external dependencies
- ✅ Standard for open-source projects
- ✅ Easy user verification (`gpg --verify`)
- ✅ Built-in key management
- ✅ ASCII-armored signatures (human readable)
- ✅ Web of trust support
- ✅ Excellent tooling ecosystem

**Implementation:**
- Generate GPG key pair
- Add private key to GitHub secrets
- Users verify with `gpg --verify file.asc file`

### Use OpenSSL Directly

**Advantages:**
- ✅ No external dependencies
- ✅ More control over cryptographic parameters
- ✅ Industry standard (X.509 certificates)
- ✅ Compatible with existing PKI infrastructure

**Disadvantages:**
- ❌ More complex certificate management
- ❌ Users need OpenSSL knowledge for verification
- ❌ No built-in key distribution mechanism
- ❌ Manual trust establishment

## 🎯 Recommended Implementation

For LnOS, **GPG is the best choice** because:

1. **Simplicity**: One command for signing, one for verification
2. **User-friendly**: Standard tool for software verification
3. **No infrastructure**: Self-contained solution
4. **Community standard**: Expected by open-source users
5. **Security**: Well-audited, battle-tested

### Quick Migration from SignServer to GPG:

1. **Remove SignServer step** from GitHub Actions
2. **Add GPG signing step** (already implemented above)
3. **Generate GPG key pair** using the guide
4. **Add GitHub secrets**: `GPG_PRIVATE_KEY` and `GPG_PASSPHRASE`
5. **Update verification script** (already done)
6. **Add public key to repository**

The implementation is already complete - just need to configure the GPG key and secrets!