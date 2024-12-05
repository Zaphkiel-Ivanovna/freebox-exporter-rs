# syntax=docker/dockerfile:1.4
# Étape 1 : Construction du binaire
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

# Copier les fichiers du projet
COPY . .

# Définir les variables d'environnement pour OpenSSL
ENV OPENSSL_DIR=/usr/lib/ssl
ENV OPENSSL_LIB_DIR=/usr/lib/ssl/lib
ENV OPENSSL_INCLUDE_DIR=/usr/lib/ssl/include
ENV PKG_CONFIG_ALLOW_CROSS=1

# Déterminer le triple cible en fonction de la plateforme cible
ARG TARGETPLATFORM
RUN --mount=type=cache,target=/usr/local/cargo/registry \
  --mount=type=cache,target=/app/target \
  case "$TARGETPLATFORM" in \
  "linux/amd64") \
  TARGET_TRIPLE="x86_64-unknown-linux-musl" ;; \
  "linux/arm64") \
  TARGET_TRIPLE="aarch64-unknown-linux-musl" ;; \
  "linux/arm/v7") \
  TARGET_TRIPLE="armv7-unknown-linux-musleabihf" ;; \
  *) \
  echo "Architecture non prise en charge : $TARGETPLATFORM" && exit 1 ;; \
  esac && \
  rustup target add $TARGET_TRIPLE && \
  CC_${TARGET_TRIPLE//-/_}=musl-gcc \
  CARGO_TARGET_${TARGET_TRIPLE//-/_}_LINKER=musl-gcc \
  cargo build --release --target $TARGET_TRIPLE

# Étape 2 : Création de l'image finale
FROM alpine:latest

# Installer les dépendances nécessaires à l'exécution
RUN apk add --no-cache ca-certificates

# Définir le répertoire de travail
WORKDIR /root/

# Copier le binaire compilé depuis l'étape de construction
ARG TARGETPLATFORM
RUN case "$TARGETPLATFORM" in \
  "linux/amd64") \
  TARGET_TRIPLE="x86_64-unknown-linux-musl" ;; \
  "linux/arm64") \
  TARGET_TRIPLE="aarch64-unknown-linux-musl" ;; \
  "linux/arm/v7") \
  TARGET_TRIPLE="armv7-unknown-linux-musleabihf" ;; \
  *) \
  echo "Architecture non prise en charge : $TARGETPLATFORM" && exit 1 ;; \
  esac
COPY --from=builder /app/target/$TARGET_TRIPLE/release/freebox-exporter-rs .

# Copier le fichier de configuration
COPY config.toml /etc/freebox-exporter-rs/config.toml

# Exposer le port spécifié dans la configuration
EXPOSE 9102

# Définir la commande par défaut pour exécuter l'exécutable
CMD ["./freebox-exporter-rs"]