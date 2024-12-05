FROM rust:latest AS builder

RUN apt-get update && \
    apt-get install -y \
    musl-tools \
    libssl-dev \
    pkg-config \
    gcc-arm-linux-gnueabihf \
    gcc-aarch64-linux-gnu \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .

RUN rustup target add \
    x86_64-unknown-linux-musl \
    armv7-unknown-linux-musleabihf \
    aarch64-unknown-linux-musl

RUN CC=musl-gcc cargo build --release --target x86_64-unknown-linux-musl
RUN CC=arm-linux-gnueabihf-gcc cargo build --release --target armv7-unknown-linux-musleabihf
RUN CC=aarch64-linux-gnu-gcc cargo build --release --target aarch64-unknown-linux-musl

FROM alpine:latest
RUN apk add --no-cache ca-certificates

WORKDIR /root/

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

COPY config.toml /etc/freebox-exporter-rs/config.toml

EXPOSE 9102

CMD ["./freebox-exporter-rs"]
