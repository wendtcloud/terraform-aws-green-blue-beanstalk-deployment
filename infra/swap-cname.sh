#!/usr/bin/env bash
set -euo pipefail

SOURCE_ENV="${1:-blue-deployment-environment}"
DEST_ENV="${2:-green-deployment-environment}"
REGION="${3:-eu-north-1}"

aws elasticbeanstalk swap-environment-cnames \
  --source-environment-name "$SOURCE_ENV" \
  --destination-environment-name "$DEST_ENV" \
  --region "$REGION"

while true; do
  STATUSES=$(aws elasticbeanstalk describe-environments \
    --environment-names "$SOURCE_ENV" "$DEST_ENV" \
    --region "$REGION" \
    --query "Environments[].Status" \
    --output text)

  echo "Current statuses: $STATUSES"

  if [[ "$STATUSES" != *"Updating"* && "$STATUSES" != *"Pending"* ]]; then
    break
  fi

  sleep 5
done

aws elasticbeanstalk describe-environments \
  --environment-names "$SOURCE_ENV" "$DEST_ENV" \
  --region "$REGION" \
  --query "Environments[*].{Name:EnvironmentName,Status:Status,Health:Health,Version:VersionLabel,CNAME:CNAME}" \
  --output table