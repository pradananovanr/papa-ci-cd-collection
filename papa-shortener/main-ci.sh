#!/bin/bash
set -e

echo "Starting build process for shortener ($GITHUB_REF_NAME)..."

# Build verification
docker build \
  --tag papa-shortener:$GITHUB_SHA \
  --tag ghcr.io/pradananovanr/papa-shortener:latest \
  .

# Push and Deploy (since this is main branch)
echo "Logging into GHCR..."
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_ACTOR" --password-stdin

echo "Pushing image to GHCR..."
docker build \
  --tag ghcr.io/pradananovanr/papa-shortener:$GITHUB_SHA \
  --tag ghcr.io/pradananovanr/papa-shortener:latest \
  --push \
  .

if [ -n "$DOKPLOY_WEBHOOK_URL" ]; then
  echo "Triggering Dokploy redeploy..."
  curl -f -X GET "$DOKPLOY_WEBHOOK_URL"
else
  echo "DOKPLOY_WEBHOOK_URL is not set, skipping deployment trigger."
fi
