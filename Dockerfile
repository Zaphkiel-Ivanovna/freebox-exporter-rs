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
ENV CFLAGS="-fno-stack-protector -DOPENSSL_NO_ASM"
ENV RUSTFLAGS="-Z threads=8 -C link-arg=-lm"
ENV OPENSSL_NO_ASM=1
RUN rustup target add x86_64-unknown-linux-musl --toolchain nightly
WORKDIR /usr/src/freebox-exporter-rs
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo +nightly build --jobs 2 --release --target x86_64-unknown-linux-musl

# Builder pour arm64
FROM rustlang/rust:nightly AS builder-arm64
RUN apt-get update && \
  apt-get install -y musl-tools musl-dev libssl-dev pkg-config && \
  ln -sf /usr/bin/ar /usr/bin/musl-ar && \
  ln -sf /usr/bin/ranlib /usr/bin/musl-ranlib
ENV OPENSSL_DIR=/usr
ENV OPENSSL_STATIC=1
ENV OPENSSL_NO_ASM=1
ENV CC=musl-gcc
ENV AR=musl-ar
ENV RANLIB=musl-ranlib
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/share/pkgconfig
ENV CFLAGS="-fno-stack-protector -DOPENSSL_NO_ASM"
ENV RUSTFLAGS="-Z threads=8 -C link-arg=-lm"
ENV MAKEFLAGS="-j1"
RUN rustup target add aarch64-unknown-linux-musl
WORKDIR /usr/src/freebox-exporter-rs
COPY Cargo.toml Cargo.lock ./
RUN cargo fetch
COPY src ./src
RUN cargo +nightly build --jobs 2 --release --target aarch64-unknown-linux-musl

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
RUN cargo +nightly build --jobs 2 --release --target arm-unknown-linux-musleabihf

# Image finale pour amd64
FROM alpine:latest AS final-amd64
RUN apk add --no-cache ca-certificates
COPY --from=builder-amd64 /usr/src/freebox-exporter-rs/target/x86_64-unknown-linux-musl/release/freebox-exporter-rs /freebox-exporter-rs
COPY config.toml /etc/freebox-exporter-rs/config.toml
EXPOSE 9102
CMD ["/freebox-exporter-rs"]

# Image finale pour arm64
FROM alpine:latest AS final-arm64
RUN apk add --no-cache ca-certificates
COPY --from=builder-arm64 /usr/src/freebox-exporter-rs/target/aarch64-unknown-linux-musl/release/freebox-exporter-rs /freebox-exporter-rs
COPY config.toml /etc/freebox-exporter-rs/config.toml
EXPOSE 9102
CMD ["/freebox-exporter-rs"]

# Image finale pour armv7
FROM alpine:latest AS final-armv7
RUN apk add --no-cache ca-certificates
COPY --from=builder-armv7 /usr/src/freebox-exporter-rs/target/arm-unknown-linux-musleabihf/release/freebox-exporter-rs /freebox-exporter-rs
COPY config.toml /etc/freebox-exporter-rs/config.toml
EXPOSE 9102
CMD ["/freebox-exporter-rs"]