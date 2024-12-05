# Étape de construction
FROM --platform=$BUILDPLATFORM rust:latest AS builder

# Installer les dépendances nécessaires
RUN apt-get update && \
    apt-get install -y \
    musl-tools \
    libssl-dev \
    pkg-config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers sources
COPY . .

# Ajouter les cibles de compilation pour les différentes architectures
RUN rustup target add \
    x86_64-unknown-linux-musl \
    aarch64-unknown-linux-musl \
    armv7-unknown-linux-musleabihf

# Construire le binaire pour chaque architecture
RUN cargo build --release --target x86_64-unknown-linux-musl && \
    cargo build --release --target aarch64-unknown-linux-musl && \
    cargo build --release --target armv7-unknown-linux-musleabihf

# Étape finale
FROM alpine:latest

# Installer les certificats SSL
RUN apk add --no-cache ca-certificates

# Définir le répertoire de travail
WORKDIR /root/

# Copier le binaire approprié en fonction de la plateforme cible
ARG TARGETPLATFORM
RUN case "$TARGETPLATFORM" in \
        "linux/amd64") \
            cp /app/target/x86_64-unknown-linux-musl/release/freebox-exporter-rs . ;; \
        "linux/arm64") \
            cp /app/target/aarch64-unknown-linux-musl/release/freebox-exporter-rs . ;; \
        "linux/arm/v7") \
            cp /app/target/armv7-unknown-linux-musleabihf/release/freebox-exporter-rs . ;; \
        *) \
            echo "Architecture non prise en charge : $TARGETPLATFORM" && exit 1 ;; \
    esac

# Copier le fichier de configuration
COPY config.toml /etc/freebox-exporter-rs/config.toml

# Exposer le port nécessaire
EXPOSE 9102

# Définir la commande par défaut
CMD ["./freebox-exporter-rs"]
