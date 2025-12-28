#!/bin/sh
#
# Get OAuth2 access token for Broadcom VCF Usage Management
#

SCRIPT_DIR=$(dirname "$0")
. "$SCRIPT_DIR/vcf.broadcom.com.credentials.sh"

echo "Client ID: $CLIENT_ID"

TOKEN_ENDPOINT="https://login.broadcom.com/as/token.oauth2"
SCOPE="usage_management"

RESPONSE=$(curl -sS -X POST "$TOKEN_ENDPOINT" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "$CLIENT_ID:$CLIENT_SECRET" \
  --data "grant_type=client_credentials" \
  --data "scope=$SCOPE")

echo "$RESPONSE" | grep -q '"access_token"' || {
  echo "ERROR: Failed to obtain access token" >&2
  echo "$RESPONSE" >&2
  exit 1
}

ACCESS_TOKEN=$(echo "$RESPONSE" \
  | sed -n 's/.*"access_token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')

echo "$ACCESS_TOKEN"

