# Étape de construction pour amd64
FROM --platform=linux/amd64 rust:latest AS builder-amd64
RUN apt-get update && \
    apt-get install -y musl-tools libssl-dev pkg-config && \
    rustup target add x86_64-unknown-linux-musl
WORKDIR /app
COPY . .
RUN CC=musl-gcc cargo build --release --target x86_64-unknown-linux-musl

# Étape de construction pour arm64
FROM --platform=linux/arm64 rust:latest AS builder-arm64
RUN apt-get update && \
    apt-get install -y musl-tools libssl-dev pkg-config && \
    rustup target add aarch64-unknown-linux-musl
WORKDIR /app
COPY . .
RUN CC=musl-gcc cargo build --release --target aarch64-unknown-linux-musl

# Étape de construction pour arm/v7
FROM --platform=linux/arm/v7 rust:latest AS builder-armv7
RUN apt-get update && \
    apt-get install -y musl-tools libssl-dev pkg-config && \
    rustup target add armv7-unknown-linux-musleabihf
WORKDIR /app
COPY . .
RUN CC=musl-gcc cargo build --release --target armv7-unknown-linux-musleabihf

# Étape finale pour créer l'image multi-plateforme
FROM alpine:latest
RUN apk add --no-cache ca-certificates
WORKDIR /root/
COPY --from=builder-amd64 /app/target/x86_64-unknown-linux-musl/release/freebox-exporter-rs ./freebox-exporter-rs-amd64
COPY --from=builder-arm64 /app/target/aarch64-unknown-linux-musl/release/freebox-exporter-rs ./freebox-exporter-rs-arm64
COPY --from=builder-armv7 /app/target/armv7-unknown-linux-musleabihf/release/freebox-exporter-rs ./freebox-exporter-rs-armv7
COPY config.toml /etc/freebox-exporter-rs/config.toml
EXPOSE 9102
CMD ["./freebox-exporter-rs"]
