#!/bin/bash
set -e

echo "Starting build process for portfolio ($GITHUB_REF_NAME)..."

# Build verification
docker build \
  --tag papa-portfolio:$GITHUB_SHA \
  --tag ghcr.io/pradananovanr/papa-portfolio:latest \
  .

# Run health check
docker run -d --name test-portfolio -p 8888:8080 papa-portfolio:$GITHUB_SHA
sleep 5
curl -sf http://localhost:8888 > /dev/null && echo "✓ Site responds" || { echo "✗ Site not reachable"; docker logs test-portfolio; exit 1; }
docker stop test-portfolio
docker rm test-portfolio

# Push and Deploy (since this is main branch)
echo "Logging into GHCR..."
echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_ACTOR" --password-stdin

echo "Pushing image to GHCR..."
docker build \
  --tag ghcr.io/pradananovanr/papa-portfolio:$GITHUB_SHA \
  --tag ghcr.io/pradananovanr/papa-portfolio:latest \
  --push \
  .

if [ -n "$DOKPLOY_WEBHOOK_URL" ]; then
  echo "Triggering Dokploy redeploy..."
  curl -f -X GET "$DOKPLOY_WEBHOOK_URL"
else
  echo "DOKPLOY_WEBHOOK_URL is not set, skipping deployment trigger."
fi
