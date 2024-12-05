FROM --platform=linux/amd64 rust:latest AS builder-amd64
RUN apt-get update && \
  apt-get install -y gcc libssl-dev pkg-config && \
  rustup target add x86_64-unknown-linux-gnu
RUN rustup install nightly
RUN rustup target add x86_64-unknown-linux-gnu --toolchain nightly
WORKDIR /app
ENV RUSTFLAGS="-Z threads=8"
COPY . .
RUN cargo +nightly build --release --target x86_64-unknown-linux-gnu

FROM --platform=linux/arm64 rust:latest AS builder-arm64
RUN apt-get update && \
  apt-get install -y gcc-aarch64-linux-gnu libssl-dev pkg-config && \
  rustup target add aarch64-unknown-linux-gnu
RUN rustup install nightly
RUN rustup target add aarch64-unknown-linux-gnu --toolchain nightly
WORKDIR /app
ENV RUSTFLAGS="-Z threads=8"
COPY . .
RUN CC=aarch64-linux-gnu-gcc cargo +nightly build --release --target aarch64-unknown-linux-gnu

FROM --platform=linux/arm/v7 rust:latest AS builder-armv7
RUN apt-get update && \
  apt-get install -y gcc-arm-linux-gnueabihf libssl-dev pkg-config && \
  rustup target add armv7-unknown-linux-gnueabihf
RUN rustup install nightly
RUN rustup target add armv7-unknown-linux-gnueabihf --toolchain nightly
WORKDIR /app
ENV RUSTFLAGS="-Z threads=8"
COPY . .
RUN CC=arm-linux-gnueabihf-gcc cargo +nightly build --release --target armv7-unknown-linux-gnueabihf

FROM alpine:latest
RUN apk add --no-cache ca-certificates openssl
WORKDIR /root/

COPY --from=builder-amd64 /app/target/x86_64-unknown-linux-gnu/release/freebox-exporter-rs ./freebox-exporter-rs
COPY --from=builder-arm64 /app/target/aarch64-unknown-linux-gnu/release/freebox-exporter-rs ./freebox-exporter-rs
COPY --from=builder-armv7 /app/target/armv7-unknown-linux-gnueabihf/release/freebox-exporter-rs ./freebox-exporter-rs
COPY config.toml /etc/freebox-exporter-rs/config.toml

EXPOSE 9102

CMD ["./freebox-exporter-rs"]