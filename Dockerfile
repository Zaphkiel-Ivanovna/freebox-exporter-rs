# Stage 1: Build the application using cross
FROM rust:latest AS builder

# Install cross
RUN cargo install cross

# Set the working directory
WORKDIR /app

# Copy the project files
COPY . .

# Build the project for the specified target
# Replace `x86_64-unknown-linux-gnu` with your target triple
RUN cross build --release --target x86_64-unknown-linux-gnu

# Stage 2: Create the final image
FROM alpine:latest

# Install necessary runtime dependencies
RUN apk add --no-cache ca-certificates

# Set the working directory
WORKDIR /root

# Copy the compiled binary from the builder stage
COPY --from=builder /app/target/x86_64-unknown-linux-gnu/release/freebox-exporter-rs .

# Copy the configuration file
COPY config.toml /etc/freebox-exporter-rs/config.toml

# Expose the port specified in the configuration
EXPOSE 9102

# Set the default command to run the executable
CMD ["./freebox-exporter-rs"]