# Dockerfile for Gemini CLI OpenAI Worker
# Production-ready build with security optimizations

FROM node:20-slim

# Install security updates and required packages
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y wget curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user for security
RUN groupadd -g 1001 nodejs && \
    useradd -r -u 1001 -g nodejs worker

# Set working directory inside the container
WORKDIR /app

# Install wrangler globally
RUN npm install -g wrangler@4.23.0

# Copy package files first to leverage Docker cache
COPY package*.json yarn.lock* ./

# Install project dependencies with yarn
# Use --production flag for production builds, --frozen-lockfile for dev
ARG NODE_ENV=development
RUN if [ "$NODE_ENV" = "production" ]; then \
        yarn install --frozen-lockfile --production; \
    else \
        yarn install --frozen-lockfile; \
    fi

# Copy the rest of your application code
COPY . .

# Create directories for miniflare storage and wrangler logs, set proper ownership
RUN mkdir -p .mf && \
    mkdir -p /home/worker/.config/.wrangler/logs && \
    chown -R worker:nodejs /app && \
    chown -R worker:nodejs /home/worker

# Switch to non-root user for security
USER worker

# Expose the port miniflare will run on
EXPOSE 8787

# Health check to ensure the service is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8787/health || exit 1

# Command to run the worker
# --host 0.0.0.0 is crucial for Docker to allow external connections
# --port 8787 matches the EXPOSE and wrangler.toml [dev] port
# --local disables proxying to Cloudflare's network, keeping everything local
# --persist-to tells miniflare to use the specified path for local storage
CMD ["sh", "-c", "wrangler dev --host 0.0.0.0 --port 8787 --local --persist-to .mf \
    --var GCP_ACCESS_TOKEN:$GCP_ACCESS_TOKEN \
    --var GCP_REFRESH_TOKEN:$GCP_REFRESH_TOKEN \
    --var GCP_SCOPE:$GCP_SCOPE \
    --var GCP_TOKEN_TYPE:$GCP_TOKEN_TYPE \
    --var GCP_ID_TOKEN:$GCP_ID_TOKEN \
    --var GCP_EXPIRY_DATE:$GCP_EXPIRY_DATE \
    --var OPENAI_API_KEY:$OPENAI_API_KEY \
    --var ENABLE_FAKE_THINKING:$ENABLE_FAKE_THINKING \
    --var ENABLE_REAL_THINKING:$ENABLE_REAL_THINKING \
    --var STREAM_THINKING_AS_CONTENT:$STREAM_THINKING_AS_CONTENT \
    --var ENABLE_AUTO_MODEL_SWITCHING:$ENABLE_AUTO_MODEL_SWITCHING \
    --var ENABLE_GEMINI_NATIVE_TOOLS:$ENABLE_GEMINI_NATIVE_TOOLS \
    --var GEMINI_TOOLS_PRIORITY:$GEMINI_TOOLS_PRIORITY \
    --var DEFAULT_TO_NATIVE_TOOLS:$DEFAULT_TO_NATIVE_TOOLS \
    --var ALLOW_REQUEST_TOOL_CONTROL:$ALLOW_REQUEST_TOOL_CONTROL \
    --var ENABLE_INLINE_CITATIONS:$ENABLE_INLINE_CITATIONS \
    --var INCLUDE_GROUNDING_METADATA:$INCLUDE_GROUNDING_METADATA"]
