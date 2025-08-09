# LnOS Development Container

This devcontainer provides a complete Arch Linux environment for building LnOS ISOs.

## Setup

### VS Code with Dev Containers Extension
1. Install the "Dev Containers" extension in VS Code
2. Open the LnOS repository in VS Code
3. Press `Ctrl+Shift+P` and select "Dev Containers: Reopen in Container"
4. Wait for the container to build (first time may take several minutes)

### Manual Docker Usage
```bash
# Build the container
docker build -t lnos-dev .devcontainer/

# Run the container
docker run -it --privileged -v $(pwd):/workspace lnos-dev

# Inside the container
./build-iso.sh x86_64
```

## Features

### Pre-installed Tools
- **archiso** - For building Arch Linux ISOs
- **base-devel** - Essential development tools
- **git, vim, nano** - Development utilities
- **gum** - Interactive CLI components
- **shellcheck** - Shell script linting
- **qemu-user-static** - For cross-architecture builds

### Convenience Aliases
- `build-x86` - Build x86_64 ISO
- `build-arm` - Build aarch64 ISO  
- `build-both` - Build both architectures
- `clean-build` - Clean build artifacts

### VS Code Extensions
- Shell script formatting and linting
- JSON/YAML support
- Git integration

## Usage

### Building ISOs
```bash
# Build x86_64 ISO
./build-iso.sh x86_64

# Build aarch64 ISO
./build-iso.sh aarch64

# Clean previous builds
clean-build
```

### Development Workflow
1. Make changes to archiso profile or scripts
2. Test build locally: `build-x86`
3. Commit and push to trigger GitHub Actions
4. Download artifacts from GitHub releases

## Container Requirements

### Privileges
The container runs with `--privileged` because:
- `mkarchiso` needs to create loop devices
- Building ISOs requires mounting filesystems
- Package installation needs system-level access

### Mounts
- `/workspace` - Your project directory
- `/var/lib/docker` - For nested Docker builds (aarch64)

## Troubleshooting

### Container Won't Start
- Ensure Docker has sufficient resources (4GB+ RAM)
- Check that privileged containers are allowed
- Verify VS Code Dev Containers extension is installed

### Build Failures
- Run `setup-dev-env.sh` to verify environment
- Check disk space: `df -h`
- Update Arch packages: `pacman -Syu`

### Permission Issues
- The container runs as root by default
- Files created will be owned by root
- Use `chown` to fix ownership if needed

## Architecture Support

- **x86_64**: Native build support
- **aarch64**: Cross-compilation using QEMU
- **Host architecture**: Automatically detected

## Performance Notes

- First build takes longer (downloads packages)
- Subsequent builds use cached packages
- Cross-architecture builds (aarch64) are slower
- Consider using GitHub Actions for production builds