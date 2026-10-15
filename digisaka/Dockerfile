# Dev image for the web app: the Express API and the Vite dev server share it.
# Sources are bind-mounted by compose; dependencies live in the image. better-sqlite3 has no
# prebuilt binary for this Node on arm64, so the build tools are installed to compile it.
FROM node:22-bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends python3 make g++ \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY client/package.json client/package-lock.json client/
RUN npm --prefix client ci
COPY . .
EXPOSE 3000 5173
