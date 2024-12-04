# Stage 1: Build stage
FROM --platform=$BUILDPLATFORM rust:alpine AS builder

# Install necessary dependencies
RUN apk add --no-cache musl-dev openssl-dev perl make gcc

# Set the Current Working Directory inside the container
WORKDIR /app

# Copy the Cargo.toml and Cargo.lock files
COPY Cargo.toml Cargo.lock ./

# Copy the source code
COPY src ./src

# Build the project
ARG TARGETPLATFORM
RUN case "$TARGETPLATFORM" in \
  "linux/amd64")   rustup target add x86_64-unknown-linux-musl ;; \
  "linux/arm64")   rustup target add aarch64-unknown-linux-musl ;; \
  "linux/arm/v7")  rustup target add armv7-unknown-linux-musleabihf ;; \
  esac && \
  cargo build --release --target $(rustc -Vv | grep 'host:' | awk '{print $2}')

# Stage 2: Final stage
FROM --platform=$TARGETPLATFORM alpine:latest

# Install necessary runtime dependencies
RUN apk add --no-cache ca-certificates

# Set the Current Working Directory inside the container
WORKDIR /root/

# Copy the compiled binary from the build stage
COPY --from=builder /app/target/*/release/freebox-exporter-rs .

# Copy the configuration file
COPY config.toml /etc/freebox-exporter-rs/config.toml

# Expose the port specified in the config.toml
EXPOSE 9102

# Command to run the executable with the default argument
CMD ["/root/freebox-exporter-rs"]
