#!/usr/bin/env bash
# exit on error
set -o errexit

# Clean install
rm -rf node_modules
npm install

# Install Chrome for Puppeteer explicitly
echo "Installing Chrome for Puppeteer..."
npx puppeteer browsers install chrome

# Sync Database Schema (Create tables/columns if missing)
echo "Syncing Database Schema..."
npx prisma db push

# Generate Prisma Client
echo "Generating Prisma Client..."
npx prisma generate

echo "Build script completed successfully!"
