#!/bin/bash -e

# Find the regions where the given instance types are available
# Writes regions-<family>.txt (used by increase-quotas.sh) and prints a Markdown table for README.md

INSTANCES="g4dn.xlarge g5.xlarge g6.xlarge g6e.xlarge p4d.24xlarge"

REGIONS=$(aws ec2 describe-regions | jq -r '.Regions[].RegionName' | sort)

for REGION in ${REGIONS}; do
  echo "=== Region: ${REGION}" >&2
  # Instance availability
  aws --region ${REGION} ec2 describe-instance-type-offerings --location-type "region" --filters Name=instance-type,Values=${INSTANCES// /,} | jq -c .InstanceTypeOfferings
done > instance-regions.json

for INSTANCE in ${INSTANCES}; do
  FILE=regions-${INSTANCE%.*}.txt
  echo "--- ${FILE}" >&2
  jq -r ".[] | select(.InstanceType == \"${INSTANCE}\") | .Location" instance-regions.json | sort > ${FILE}
done

echo "|Region|${INSTANCES// /|}|"
echo "|------$(for INSTANCE in ${INSTANCES}; do echo -n '|:-:'; done)|"
for REGION in ${REGIONS}; do
  echo -n "|${REGION}"
  for INSTANCE in ${INSTANCES}; do
    grep -qx ${REGION} regions-${INSTANCE%.*}.txt && echo -n "|✓" || echo -n "|"
  done
  echo "|"
done

rm -f instance-regions.json
