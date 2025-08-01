#!/bin/bash

# Script to prepare debug keystore for GitHub Secrets
# This script encodes your local debug keystore to base64 for use in GitHub Actions

set -e

DEBUG_KEYSTORE_PATH="$HOME/.android/debug.keystore"
OUTPUT_FILE="debug-keystore-base64.txt"

echo "🔑 Preparing debug keystore for GitHub Secrets..."
echo ""

# Check if debug keystore exists
if [ ! -f "$DEBUG_KEYSTORE_PATH" ]; then
    echo "❌ Debug keystore not found at: $DEBUG_KEYSTORE_PATH"
    echo "   Please ensure you have built the app locally at least once to generate the debug keystore."
    exit 1
fi

echo "✅ Found debug keystore at: $DEBUG_KEYSTORE_PATH"
echo ""

# Encode keystore to base64
echo "📝 Encoding keystore to base64..."
base64 "$DEBUG_KEYSTORE_PATH" > "$OUTPUT_FILE"

# Get the base64 content
BASE64_CONTENT=$(cat "$OUTPUT_FILE")

echo "✅ Base64 encoded keystore saved to: $OUTPUT_FILE"
echo ""
echo "🔐 Next steps:"
echo "1. Copy the content of $OUTPUT_FILE"
echo "2. Go to your GitHub repository settings"
echo "3. Navigate to Secrets and variables > Actions"
echo "4. Create a new repository secret named: DEBUG_KEYSTORE_BASE64"
echo "5. Paste the base64 content as the secret value"
echo ""
echo "📋 Base64 content (first 100 characters):"
echo "${BASE64_CONTENT:0:100}..."
echo ""
echo "📏 Total length: ${#BASE64_CONTENT} characters"
echo ""
echo "⚠️  Security note: Keep this file secure and delete it after adding to GitHub Secrets"
echo "   You can delete it with: rm $OUTPUT_FILE" 