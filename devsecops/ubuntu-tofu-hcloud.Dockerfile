# syntax = docker/dockerfile:1.4.0
# Build command :
#   DOCKER_BUILDKIT=1 docker build --rm -f devsecops/ubuntu-tofu-hcloud.Dockerfile -t haidarns/devsecops:ubuntu-tofu-hcloud .
  
# Gunakan Ubuntu sebagai base image
FROM ubuntu:latest

# Hindari interaksi saat instalasi package
ENV DEBIAN_FRONTEND=noninteractive

# Update dan instal dependensi dasar
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    curl \
    jq \
    unzip \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Instal OpenTofu menggunakan script resmi
RUN curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh \
    && chmod +x install-opentofu.sh \
    && ./install-opentofu.sh --install-method deb \
    && rm -f install-opentofu.sh \
    && tofu --version

# Instal Huawei Cloud CLI (hcloud / KooCLI)
RUN curl -LO "https://cn-north-4-hdn-koocli.obs.cn-north-4.myhuaweicloud.com/cli/latest/huaweicloud-cli-linux-amd64.tar.gz" \
    && tar -zxvf huaweicloud-cli-linux-amd64.tar.gz \
    && mv hcloud /usr/local/bin/ \
    && rm huaweicloud-cli-linux-amd64.tar.gz \
    && hcloud version

# Set environment variables (opsional, sesuaikan dengan kebutuhan)
ENV TF_IN_AUTOMATION=true

# Entrypoint default
CMD ["/bin/bash"]
