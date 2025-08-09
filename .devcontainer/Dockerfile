# LnOS Development Container
# Based on Arch Linux for archiso compatibility
FROM archlinux:latest

# Set non-interactive frontend for package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update system and install required packages
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        # Core development tools
        base-devel \
        git \
        vim \
        nano \
        wget \
        curl \
        sudo \
        # ISO building tools
        archiso \
        # System utilities
        parted \
        dosfstools \
        btrfs-progs \
        efibootmgr \
        grub \
        # Network tools
        networkmanager \
        dhcpcd \
        openssh \
        iw \
        # Development utilities
        shellcheck \
        tree \
        htop \
        # Interactive tools
        gum \
        # Container utilities
        docker \
        qemu-user-static \
        # Version control and GitHub
        github-cli \
    && pacman -Scc --noconfirm

# Create a non-root user for development (optional)
RUN useradd -m -G wheel -s /bin/bash developer && \
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

# Set up workspace directory
WORKDIR /workspace

# Copy utility scripts
COPY setup-dev-env.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-dev-env.sh

# Create helpful aliases
RUN echo 'alias ll="ls -la"' >> /root/.bashrc && \
    echo 'alias build-x86="/workspace/build-iso.sh x86_64"' >> /root/.bashrc && \
    echo 'alias build-arm="/workspace/build-iso.sh aarch64"' >> /root/.bashrc && \
    echo 'alias build-both="/workspace/build-iso.sh x86_64 && /workspace/build-iso.sh aarch64"' >> /root/.bashrc && \
    echo 'alias clean-build="rm -rf /workspace/out/ /tmp/archiso-tmp/"' >> /root/.bashrc

# Add welcome message
RUN echo 'echo "=== LnOS Development Container ==="' >> /root/.bashrc && \
    echo 'echo "Available commands:"' >> /root/.bashrc && \
    echo 'echo "  build-x86    - Build x86_64 ISO"' >> /root/.bashrc && \
    echo 'echo "  build-arm    - Build aarch64 ISO"' >> /root/.bashrc && \
    echo 'echo "  build-both   - Build both architectures"' >> /root/.bashrc && \
    echo 'echo "  clean-build  - Clean build artifacts"' >> /root/.bashrc && \
    echo 'echo "  ./build-iso.sh --help for more options"' >> /root/.bashrc && \
    echo 'echo "=================================="' >> /root/.bashrc

# Expose any necessary ports (none needed for this project)
# EXPOSE 8080

# Set default command
CMD ["/bin/bash"]

# Health check to ensure archiso is working
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD which mkarchiso || exit 1