# Dockerfile for Zwimm Agent Build Environment
FROM ubuntu:24.04

# Install system dependencies (incl. Swift runtime deps: libncurses, libcurl, libxml2, ...)
RUN apt-get update && apt-get install -y git curl python3 python3-pip software-properties-common \
    libncurses6 libcurl4-openssl-dev libedit2 libpython3-dev libsqlite3-dev \
    libxml2-dev libz3-dev pkg-config tzdata zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Swift 6.3.3 (verified release: HTTP 200 on download.swift.org, ~1.07 GB)
RUN apt-get update && apt-get install -y wget && \
    wget https://download.swift.org/swift-6.3.3-release/ubuntu2404/swift-6.3.3-RELEASE/swift-6.3.3-RELEASE-ubuntu24.04.tar.gz && \
    tar -xzf swift-6.3.3-RELEASE-ubuntu24.04.tar.gz && \
    mv swift-6.3.3-RELEASE-ubuntu24.04 /opt/swift && \
    rm swift-6.3.3-RELEASE-ubuntu24.04.tar.gz && \
    ln -s /opt/swift/usr/bin/swift /usr/local/bin/swift && \
    ln -s /opt/swift/usr/bin/swiftc /usr/local/bin/swiftc

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list
RUN apt-get update && apt-get install -y gh && rm -rf /var/lib/apt/lists/*

# Python dependencies (using --break-system-packages for Ubuntu 24.04)
RUN pip3 install --no-cache-dir --break-system-packages python-dotenv

# Set working directory
WORKDIR /app

# Copy project files (see .dockerignore for exclusions; .env is NEVER copied)
COPY . .

# Make agent runner executable
RUN chmod +x agent_runner.py

# Sanity check at build time: Swift must be reachable
RUN swift --version

# Default command runs the full build+test loop
CMD ["./agent_runner.py"]
