#!/bin/bash
set -e

# Configuration
SERVICE_NAME="meshkov-page-proxy"
REGION="us-central1" # Or your preferred region
PROJECT_ID=zoomer-app
IMAGE_NAME="gcr.io/$PROJECT_ID/$SERVICE_NAME"

echo "Deploying to Project: $PROJECT_ID"
echo "Service: $SERVICE_NAME"
echo "Region: $REGION"

# Build the container image
echo "Building container..."
gcloud builds submit --tag "$IMAGE_NAME" .

# Deploy to Cloud Run
echo "Deploying to Cloud Run..."
gcloud run deploy "$SERVICE_NAME" \
  --image "$IMAGE_NAME" \
  --platform managed \
  --region "$REGION" \
  --allow-unauthenticated \
  --port 8080

echo "Deployment complete!"
echo "You can now map your custom domain in the Cloud Run console:"
echo "https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME/integrations"
