# Stage 1: Builder
FROM --platform=$BUILDPLATFORM rust:latest AS builder

# Install necessary dependencies for cross-compilation
RUN apt-get update && \
  apt-get install -y \
  gcc-aarch64-linux-gnu \
  gcc-arm-linux-gnueabihf \
  musl-tools \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add Rust targets for cross-compilation
RUN rustup target add \
  x86_64-unknown-linux-musl \
  aarch64-unknown-linux-musl \
  armv7-unknown-linux-musleabihf

# Set the working directory
WORKDIR /app

# Copy the Cargo manifest files
COPY Cargo.toml Cargo.lock ./

# Copy the source code
COPY src/ ./src/

# Determine the target triple based on the target platform
ARG TARGETPLATFORM
RUN case "$TARGETPLATFORM" in \
  "linux/amd64")   TARGET_TRIPLE="x86_64-unknown-linux-musl" ;; \
  "linux/arm64")   TARGET_TRIPLE="aarch64-unknown-linux-musl" ;; \
  "linux/arm/v7")  TARGET_TRIPLE="armv7-unknown-linux-musleabihf" ;; \
  *) echo "Unsupported architecture: $TARGETPLATFORM" && exit 1 ;; \
  esac && \
  # Build the project for the specified target
  cargo build --release --target $TARGET_TRIPLE

# Stage 2: Runtime
FROM --platform=$TARGETPLATFORM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache ca-certificates

# Set the working directory
WORKDIR /root/

# Determine the target triple based on the target platform
ARG TARGETPLATFORM
RUN case "$TARGETPLATFORM" in \
  "linux/amd64")   TARGET_TRIPLE="x86_64-unknown-linux-musl" ;; \
  "linux/arm64")   TARGET_TRIPLE="aarch64-unknown-linux-musl" ;; \
  "linux/arm/v7")  TARGET_TRIPLE="armv7-unknown-linux-musleabihf" ;; \
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