#!/bin/sh

# Define the allowed keys
ALLOWED_KEYS="JWT_SECRET RELAY_SECRET_KEY OPTIMISTIC_RELAY_SECRET_KEY COINBASE_SECRET_KEY CL_NODE_URL AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY RCLONE_S3_ENDPOINT"

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
    if expr match "$1" "^0x[a-fA-F0-9]*$" >/dev/null
    then
        return 0
    fi

    return 1
}

# Function to validate URL
validate_url() {
    echo $1
    if expr match "$1" "^'\?https\?://.*'\?$" >/dev/null
    then
        return 0
    fi

    return 1
}

# Function to validate AWS Access Key ID (32 characters: A-Z, 0-9)
validate_aws_access_key_id() {
    if expr match "$1" "^[a-z0-9]\{32\}$" >/dev/null
    then
        return 0
    fi

    return 1
}

# Function to validate AWS Secret Access Key (64 characters: A-Za-z0-9+/=)
validate_aws_secret_access_key() {
    if expr match "$1" "^[a-z0-9]\{64\}$" >/dev/null
    then
        return 0
    fi

    return 1
}

# Parse JSON and export allowed keys with validation
for key in $ALLOWED_KEYS; do
    value=$(jq -r ".$key // empty" "$JSON_FILE" | xargs printf "%q")
    if [ -n "$value" ]; then
        case "$key" in
            JWT_SECRET|RELAY_SECRET_KEY|OPTIMISTIC_RELAY_SECRET_KEY|COINBASE_SECRET_KEY)
                if ! validate_hex "$value"; then
                    echo "Error: Invalid format for $key. Expected 0x followed by hex characters." >&2
                    exit 1
                fi
                ;;
            CL_NODE_URL|RCLONE_S3_ENDPOINT)
                if ! validate_url "$value"; then
                    echo "Error: Invalid format for $key. Expected http:// or https:// URL." >&2
                    exit 1
                fi
                ;;
            AWS_ACCESS_KEY_ID)
                if ! validate_aws_access_key_id "$value"; then
                    echo "Error: Invalid format for $key. Expected 32 characters: a-z, 0-9." >&2
                    exit 1
                fi
                ;;
            AWS_SECRET_ACCESS_KEY)
                if ! validate_aws_secret_access_key "$value"; then
                    echo "Error: Invalid format for $key. Expected 64 characters: a-z0-9." >&2
                    exit 1
                fi
                ;;
        esac
        echo "export $key=$value"
    fi
done
