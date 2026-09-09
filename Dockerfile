# =========================================================
# Stage 1: Build & Dependency Installation
# =========================================================
FROM node:20-alpine AS builder

WORKDIR /app

# Copy ONLY package files first to maximize Docker layer caching
COPY package.json package-lock.json ./

# Clean install all dependencies (much faster in CI pipelines)
RUN npm ci

# Copy the rest of the application source code
COPY . .

# =========================================================
# Stage 2: Tiny Production Runtime Environment
# =========================================================
FROM node:20-alpine AS runner

WORKDIR /app

# Set production environment flags
ENV NODE_ENV=production

# Copy only the compiled/installed code from the builder stage
COPY --from=builder /app ./

# Expose the correct application port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]

