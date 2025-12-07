FROM node:18-bullseye-slim

# Create app directory
WORKDIR /app

# Install dependencies first (package.json + package-lock.json)
COPY package*.json ./
RUN npm ci --silent

# Copy app sources
COPY . .

ENV NODE_ENV=development
ENV PORT=3001
EXPOSE 3001

# Use the dev server for convenience in local development inside Docker.
# For production, change to `npm run build && npm run start`.
CMD ["npm", "run", "dev"]
