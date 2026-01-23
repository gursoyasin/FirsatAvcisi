#!/usr/bin/env bash
# exit on error
set -o errexit

# Clean install
# Clean install dependencies
echo "Installing dependencies..."
npm install

# Install Chrome for Puppeteer explicitly (respecting .puppeteerrc.cjs)
echo "Installing Chrome for Puppeteer..."
npx puppeteer browsers install chrome
echo "Puppeteer Cache Directory should be: $(pwd)/.cache/puppeteer"
ls -R .cache/puppeteer || echo "Cache directory not found!"

# Sync Database Schema (Create tables/columns if missing)
echo "Syncing Database Schema..."
npx prisma db push

# Generate Prisma Client
echo "Generating Prisma Client..."
npx prisma generate

echo "Build script completed successfully!"
