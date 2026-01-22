#!/usr/bin/env bash
# exit on error
set -o errexit

npm install

# Install Chrome for Puppeteer explicitly
echo "Installing Chrome for Puppeteer..."
npx puppeteer browsers install chrome

# Generate Prisma Client
echo "Generating Prisma Client..."
npx prisma generate

echo "Build script completed successfully!"
