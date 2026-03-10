FROM node:18-alpine

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Fix permissions and install
RUN chown -R node:node /app && \
    npm cache clean --force && \
    npm install

# Switch to non-root user
USER node

# Copy source code
COPY --chown=node:node . .

EXPOSE 3005

CMD ["npm", "run", "dev"]