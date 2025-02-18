
ARG TARGETARCH

FROM rustlang/rust:nightly AS builder

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
ENV CFLAGS="-fno-stack-protector -DOPENSSL_NO_ASM"
ENV RUSTFLAGS="-Z threads=8 -C link-arg=-lm"
WORKDIR /usr/src/freebox-exporter-rs

RUN case "$TARGETARCH" in \
  "amd64") rustup target add x86_64-unknown-linux-musl && \
  cargo +nightly build --release --target x86_64-unknown-linux-musl ;; \
  "arm64") rustup target add aarch64-unknown-linux-musl && \
  cargo +nightly build --release --target aarch64-unknown-linux-musl ;; \
  "arm")   rustup target add arm-unknown-linux-musleabihf && \
  cargo +nightly build --release --target arm-unknown-linux-musleabihf ;; \
  esac

FROM alpine:latest
RUN apk add --no-cache ca-certificates

ARG TARGETARCH
ARG BINARY_PATH

RUN case "$TARGETARCH" in \
  "amd64") echo "BINARY_PATH=/usr/src/freebox-exporter-rs/target/x86_64-unknown-linux-musl/release/freebox-exporter-rs" >> /etc/env ;; \
  "arm64") echo "BINARY_PATH=/usr/src/freebox-exporter-rs/target/aarch64-unknown-linux-musl/release/freebox-exporter-rs" >> /etc/env ;; \
  "arm")   echo "BINARY_PATH=/usr/src/freebox-exporter-rs/target/arm-unknown-linux-musleabihf/release/freebox-exporter-rs" >> /etc/env ;; \
  esac

COPY --from=builder ${BINARY_PATH} /usr/local/bin/freebox-exporter-rs

COPY config.toml /etc/freebox-exporter-rs/config.toml
EXPOSE 9102

CMD ["/usr/local/bin/freebox-exporter-rs"]