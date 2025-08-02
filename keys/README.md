# LnOS Digital Signature Keys

This directory contains the public keys used for verifying LnOS release signatures.

## Files

- `lnos-public-key.pem` - Public key for verifying release signatures
- `lnos-public-key-fingerprint.txt` - Key fingerprint for verification

## Usage

### Automatic Verification
Use the provided script for easy verification:
```bash
curl -fsSL https://raw.githubusercontent.com/bakkertj/LnOS/main/scripts/verify-signature.sh | bash -s -- <filename>
```

### Manual Verification
1. Download the public key:
```bash
curl -fsSL https://raw.githubusercontent.com/bakkertj/LnOS/main/keys/lnos-public-key.pem -o lnos-public-key.pem
```

2. Verify the signature:
```bash
openssl dgst -sha256 -verify lnos-public-key.pem -signature <file>.sig <file>
```

## Key Information

**Algorithm**: RSA-4096 or ECDSA P-384 (depending on SignServer configuration)
**Hash**: SHA-256
**Usage**: Code signing for LnOS releases
**Valid From**: [Date when key was generated]
**Expires**: [Key expiration date]

## Trust Chain

The signing key is managed by our SignServer PKI infrastructure, which ensures:
- Secure key generation and storage
- Proper access controls
- Audit logging of all signing operations
- Key rotation capabilities

## Verification

Before trusting this key, verify its fingerprint matches what's published through multiple channels:
- GitHub repository
- Official website
- Social media announcements
- Direct communication from maintainers

## Contact

For questions about key verification or if you suspect a compromised key:
- Open an issue: https://github.com/bakkertj/LnOS/issues
- Email: [security contact]
- Security advisory: Follow responsible disclosure practices