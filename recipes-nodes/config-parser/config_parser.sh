#!/bin/sh

# Define the allowed keys
ALLOWED_KEYS="jwtSecret builderSecretKey builderTxSigningKey BuilderBeaconEndpoints"

# Check if jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is not installed" >&2
    exit 1
fi

# Check if a file is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <json_file>" >&2
    exit 1
fi

JSON_FILE="$1"

# Check if the file exists
if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File not found: $JSON_FILE" >&2
    exit 1
fi

# Function to validate hex string
validate_hex() {
    case "$1" in
        0x[0-9a-fA-F]*) return 0 ;;
        *) return 1 ;;
    esac
}

# Function to validate URL
validate_url() {
    case "$1" in
        http://*|https://*) return 0 ;;
        *) return 1 ;;
    esac
}

# Parse JSON and export allowed keys with validation
missing_keys=""
for key in $ALLOWED_KEYS; do
    value=$(jq -r ".$key // empty" "$JSON_FILE")
    if [ -z "$value" ]; then
        missing_keys="$missing_keys $key"
    else
        case "$key" in
            jwtSecret|builderSecretKey|builderTxSigningKey)
                if ! validate_hex "$value"; then
                    echo "Error: Invalid format for $key. Expected 0x followed by hex characters." >&2
                    exit 1
                fi
                ;;
            BuilderBeaconEndpoints)
                if ! validate_url "$value"; then
                    echo "Error: Invalid format for $key. Expected http:// or https:// URL." >&2
                    exit 1
                fi
                ;;
        esac
        echo "export $key='$value'"
    fi
done

# Check if any keys are missing
if [ -n "$missing_keys" ]; then
    echo "Error: Missing required keys:$missing_keys" >&2
    exit 1
fi