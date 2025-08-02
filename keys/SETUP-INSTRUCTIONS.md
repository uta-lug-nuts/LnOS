# SignServer Setup Instructions for LnOS

This document explains how to set up SignServer for digitally signing LnOS releases.

## Prerequisites

1. **SignServer Instance**: Running SignServer 5.x or later
2. **PKI Infrastructure**: Certificate Authority for issuing signing certificates
3. **GitHub Secrets**: Access to configure repository secrets

## SignServer Configuration

### 1. Create a Code Signing Worker

```bash
# Example SignServer worker configuration
bin/signserver setproperty 1 TYPE PROCESSABLE
bin/signserver setproperty 1 IMPLEMENTATION org.signserver.module.cmssigner.CMSSigner
bin/signserver setproperty 1 NAME "LnOS-CodeSigner"
bin/signserver setproperty 1 AUTHTYPE NOAUTH
bin/signserver setproperty 1 KEYDATA_SHA256 true
bin/signserver setproperty 1 INCLUDE_CERTIFICATE_LEVELS 1
bin/signserver setproperty 1 DETACHEDSIGNATURE true

# Reload configuration
bin/signserver reload 1
```

### 2. Generate/Install Signing Certificate

Option A - Generate new certificate:
```bash
# Generate key pair and certificate request
bin/signserver generatekey 1 RSA 4096

# Get the certificate request
bin/signserver certreq 1

# Submit to your CA and install the certificate
bin/signserver installcert 1 certificate.pem
```

Option B - Import existing certificate:
```bash
# Import PKCS#12 file
bin/signserver installkey 1 keystore.p12 password
```

### 3. Extract Public Key

```bash
# Get the signing certificate
bin/signserver getcertificate 1 > signing-cert.pem

# Extract public key
openssl x509 -pubkey -noout -in signing-cert.pem > lnos-public-key.pem

# Get fingerprint for verification
openssl x509 -fingerprint -sha256 -noout -in signing-cert.pem
```

## GitHub Secrets Configuration

Add these secrets to your GitHub repository:

```
SIGNSERVER_URL=https://your-signserver.example.com
SIGNSERVER_USERNAME=your-username
SIGNSERVER_PASSWORD=your-password  
SIGNSERVER_WORKER_ID=1
```

## Alternative Implementations

### Option 1: Client-side Signing Tool

If you prefer a local signing tool instead of HTTP API:

```bash
# Install SignServer client tools
# Create signing script using signserver client command
bin/signserver signdocument 1 input.iso output.sig
```

### Option 2: GPG Signing (Simpler Alternative)

If SignServer is not available, you can use GPG signing:

```yaml
- name: Sign with GPG
  env:
    GPG_PRIVATE_KEY: ${{ secrets.GPG_PRIVATE_KEY }}
    GPG_PASSPHRASE: ${{ secrets.GPG_PASSPHRASE }}
  run: |
    echo "$GPG_PRIVATE_KEY" | gpg --batch --import
    for file in *.iso *.img *.xz; do
      if [ -f "$file" ]; then
        gpg --batch --yes --passphrase "$GPG_PASSPHRASE" --detach-sign --armor "$file"
      fi
    done
```

### Option 3: Azure Code Signing

For cloud-based signing with Azure:

```yaml
- name: Sign with Azure Code Signing
  uses: azure/trusted-signing-action@v0.3.16
  with:
    azure-tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    azure-client-id: ${{ secrets.AZURE_CLIENT_ID }}
    azure-client-secret: ${{ secrets.AZURE_CLIENT_SECRET }}
    endpoint: https://your-codesigning.azure.net/
    trusted-signing-account-name: your-account
    certificate-profile-name: your-profile
    files-folder: ./isos/
    files-folder-filter: iso,img,xz
```

## Testing the Setup

1. **Test SignServer Worker**:
```bash
echo "test data" | bin/signserver signdocument 1
```

2. **Test GitHub Action**: Push to a test branch and verify signing works

3. **Test Verification**: Use the verification script to ensure signatures validate

## Security Considerations

1. **Key Protection**: Store private keys in HSM or secure key vault
2. **Access Control**: Limit who can trigger signing operations
3. **Audit Logging**: Enable comprehensive logging in SignServer
4. **Key Rotation**: Plan for periodic key rotation
5. **Network Security**: Use HTTPS and VPN for SignServer access

## Troubleshooting

### Common Issues:

**Error: "Worker not found"**
- Check worker ID in secrets matches SignServer configuration

**Error: "Authentication failed"**  
- Verify username/password in GitHub secrets
- Check SignServer user permissions

**Error: "Certificate not found"**
- Ensure certificate is properly installed in SignServer
- Verify certificate is not expired

**Error: "Empty signature file"**
- Check SignServer logs for processing errors
- Verify file upload succeeded

### Debug Commands:

```bash
# Check worker status
bin/signserver getstatus brief 1

# View worker configuration  
bin/signserver dumpproperties 1

# Test signing locally
echo "test" | bin/signserver signdocument 1

# Check certificate
bin/signserver getcertificate 1
```