FROM --platform=$BUILDPLATFORM rust:latest AS builder

RUN apt-get update && \
    apt-get install -y \
    musl-tools \
    libssl-dev \
    pkg-config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . .

ENV OPENSSL_DIR=/usr/lib/ssl
ENV OPENSSL_LIB_DIR=/usr/lib/ssl/lib
ENV OPENSSL_INCLUDE_DIR=/usr/lib/ssl/include
ENV PKG_CONFIG_ALLOW_CROSS=1

ARG TARGETPLATFORM
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    case "$TARGETPLATFORM" in \
        "linux/amd64") \
            export TARGET_TRIPLE="x86_64-unknown-linux-musl" ;; \
        "linux/arm64") \
            export TARGET_TRIPLE="aarch64-unknown-linux-musl" ;; \
        "linux/arm/v7") \
            export TARGET_TRIPLE="armv7-unknown-linux-musleabihf" ;; \
        *) \
            echo "Architecture non prise en charge : $TARGETPLATFORM" && exit 1 ;; \
    esac && \
    rustup target add $TARGET_TRIPLE && \
    export CC_VAR=$(echo $TARGET_TRIPLE | tr '-' '_') && \
    export CC_$CC_VAR=musl-gcc && \
    export CARGO_TARGET_${CC_VAR}_LINKER=musl-gcc && \
    cargo build --release --target $TARGET_TRIPLE

FROM alpine:latest

RUN apk add --no-cache ca-certificates

WORKDIR /root/

ARG TARGETPLATFORM
RUN case "$TARGETPLATFORM" in \
        "linux/amd64") \
            export TARGET_TRIPLE="x86_64-unknown-linux-musl" ;; \
        "linux/arm64") \
            export TARGET_TRIPLE="aarch64-unknown-linux-musl" ;; \
        "linux/arm/v7") \
            export TARGET_TRIPLE="armv7-unknown-linux-musleabihf" ;; \
        *) \
            echo "Architecture non prise en charge : $TARGETPLATFORM" && exit 1 ;; \
    esac

COPY --from=builder /app/target/$TARGET_TRIPLE/release/freebox-exporter-rs .

COPY config.toml /etc/freebox-exporter-rs/config.toml

EXPOSE 9102

CMD ["./freebox-exporter-rs"]
