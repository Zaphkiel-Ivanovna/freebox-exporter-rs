# Stage 1: Builder
FROM rust:latest AS builder

# Install necessary dependencies for cross-compilation
RUN apt-get update && \
  apt-get install -y \
  gcc-aarch64-linux-gnu \
  gcc-arm-linux-gnueabihf \
  musl-tools \
  libssl-dev \
  pkg-config \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install cross
RUN cargo install cross

# Set the working directory
WORKDIR /app

# Copy the project files
COPY . .

# Set environment variables for OpenSSL
ENV OPENSSL_DIR=/usr/lib/ssl
ENV OPENSSL_LIB_DIR=/usr/lib/ssl/lib
ENV OPENSSL_INCLUDE_DIR=/usr/lib/ssl/include
ENV PKG_CONFIG_ALLOW_CROSS=1

# Determine the target triple based on the target platform
ARG TARGETPLATFORM
RUN case "$TARGETPLATFORM" in \
  "linux/amd64")   TARGET_TRIPLE="x86_64-unknown-linux-gnu" ;; \
  "linux/arm64")   TARGET_TRIPLE="aarch64-unknown-linux-gnu" ;; \
  "linux/arm/v7")  TARGET_TRIPLE="armv7-unknown-linux-gnueabihf" ;; \
  *) echo "Unsupported architecture: $TARGETPLATFORM" && exit 1 ;; \
  esac && \
  # Add the Rust target
  rustup target add $TARGET_TRIPLE && \
  # Build the project for the specified target
  cross build --release --target $TARGET_TRIPLE

# Stage 2: Runtime
FROM --platform=$TARGETPLATFORM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache ca-certificates

# Set the working directory
WORKDIR /root/

# Determine the target triple based on the target platform
ARG TARGETPLATFORM
RUN case "$TARGETPLATFORM" in \
  "linux/amd64")   TARGET_TRIPLE="x86_64-unknown-linux-gnu" ;; \
  "linux/arm64")   TARGET_TRIPLE="aarch64-unknown-linux-gnu" ;; \
  "linux/arm/v7")  TARGET_TRIPLE="armv7-unknown-linux-gnueabihf" ;; \
  *) echo "Unsupported architecture: $TARGETPLATFORM" && exit 1 ;; \
  esac

# Copy the compiled binary from the builder stage
COPY --from=builder /app/target/$TARGET_TRIPLE/release/freebox-exporter-rs .

# Copy the configuration file
COPY config.toml /etc/freebox-exporter-rs/config.toml

# Expose the port specified in the configuration
EXPOSE 9102

# Set the default command to run the executable
CMD ["./freebox-exporter-rs"]