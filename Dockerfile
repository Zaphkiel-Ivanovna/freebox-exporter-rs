# Builder pour x86_64
FROM --platform=linux/amd64 rustlang/rust:nightly AS builder-amd64
RUN apt-get update && \
  apt-get install -y musl-tools musl-dev libssl-dev pkg-config && \
  ln -sf /usr/bin/ar /usr/bin/musl-ar && \
  ln -sf /usr/bin/ranlib /usr/bin/musl-ranlib
ENV OPENSSL_DIR=/usr
ENV OPENSSL_STATIC=1
ENV CC=musl-gcc
ENV AR=musl-ar
ENV RANLIB=musl-ranlib
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig

# Désactiver les optimisations ASM problématiques
ENV CFLAGS="-fno-stack-protector -DOPENSSL_NO_ASM"
ENV RUSTFLAGS="-Z threads=8 -C link-arg=-lm"
ENV OPENSSL_NO_ASM=1
RUN rustup target add x86_64-unknown-linux-musl --toolchain nightly
WORKDIR /usr/src/freebox-exporter-rs

COPY Cargo.toml Cargo.lock ./
COPY src ./src

RUN cargo +nightly build --release --target x86_64-unknown-linux-musl

# Builder pour arm64
FROM --platform=linux/arm64 rustlang/rust:nightly AS builder-arm64
RUN apt-get update && \
  apt-get install -y musl-tools musl-dev libssl-dev pkg-config && \
  ln -sf /usr/bin/ar /usr/bin/musl-ar && \
  ln -sf /usr/bin/ranlib /usr/bin/musl-ranlib
ENV OPENSSL_DIR=/usr
ENV OPENSSL_STATIC=1
ENV CC=musl-gcc
ENV AR=musl-ar
ENV RANLIB=musl-ranlib
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV PKG_CONFIG_PATH=/usr/lib/aarch64-linux-gnu/pkgconfig:/usr/share/pkgconfig
ENV CFLAGS="-fno-stack-protector -DOPENSSL_NO_ASM"
ENV RUSTFLAGS="-Z threads=8 -C link-arg=-lm"
RUN rustup target add aarch64-unknown-linux-musl
WORKDIR /usr/src/freebox-exporter-rs
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo +nightly build --release --target aarch64-unknown-linux-musl

# Builder pour armv7
FROM --platform=linux/arm/v7 rustlang/rust:nightly AS builder-armv7
RUN apt-get update && \
  apt-get install -y musl-tools musl-dev libssl-dev pkg-config && \
  ln -sf /usr/bin/ar /usr/bin/musl-ar && \
  ln -sf /usr/bin/ranlib /usr/bin/musl-ranlib
ENV OPENSSL_DIR=/usr
ENV OPENSSL_STATIC=1
ENV CC=musl-gcc
ENV AR=musl-ar
ENV RANLIB=musl-ranlib
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV PKG_CONFIG_PATH=/usr/lib/arm-linux-gnueabihf/pkgconfig:/usr/share/pkgconfig
ENV CFLAGS="-fno-stack-protector -DOPENSSL_NO_ASM"
ENV RUSTFLAGS="-Z threads=8 -C link-arg=-lm"
RUN rustup target add arm-unknown-linux-musleabihf
WORKDIR /usr/src/freebox-exporter-rs
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo +nightly build --release --target arm-unknown-linux-musleabihf

# Image finale
FROM alpine:latest
RUN apk add --no-cache ca-certificates
ARG TARGETARCH
COPY --from=builder-amd64 /usr/src/freebox-exporter-rs/target/x86_64-unknown-linux-musl/release/freebox-exporter-rs ./freebox-exporter-rs
COPY --from=builder-arm64 /usr/src/freebox-exporter-rs/target/aarch64-unknown-linux-musl/release/freebox-exporter-rs ./freebox-exporter-rs
COPY --from=builder-armv7 /usr/src/freebox-exporter-rs/target/arm-unknown-linux-musleabihf/release/freebox-exporter-rs ./freebox-exporter-rs-armv7

COPY config.toml /etc/freebox-exporter-rs/config.toml
EXPOSE 9102

CMD ["./freebox-exporter-rs"]





