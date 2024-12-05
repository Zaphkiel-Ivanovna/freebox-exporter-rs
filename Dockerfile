FROM rust:latest AS builder-x86_64
RUN apt-get update && \
    apt-get install -y musl-tools libssl-dev pkg-config && \
    rustup target add x86_64-unknown-linux-musl
WORKDIR /app
COPY . .
RUN CC=musl-gcc cargo build --release --target x86_64-unknown-linux-musl

FROM rust:latest AS builder-aarch64
RUN apt-get update && \
    apt-get install -y musl-tools libssl-dev pkg-config && \
    rustup target add aarch64-unknown-linux-musl
WORKDIR /app
COPY . .
RUN CC=musl-gcc cargo build --release --target aarch64-unknown-linux-musl

FROM rust:latest AS builder-armv7
RUN apt-get update && \
    apt-get install -y musl-tools libssl-dev pkg-config && \
    rustup target add armv7-unknown-linux-musleabihf
WORKDIR /app
COPY . .
RUN CC=musl-gcc cargo build --release --target armv7-unknown-linux-musleabihf

FROM alpine:latest
RUN apk add --no-cache ca-certificates
WORKDIR /root/
COPY --from=builder-x86_64 /app/target/x86_64-unknown-linux-musl/release/freebox-exporter-rs .
COPY --from=builder-aarch64 /app/target/aarch64-unknown-linux-musl/release/freebox-exporter-rs .
COPY --from=builder-armv7 /app/target/armv7-unknown-linux-musleabihf/release/freebox-exporter-rs .
COPY config.toml /etc/freebox-exporter-rs/config.toml
EXPOSE 9102
CMD ["./freebox-exporter-rs"]
