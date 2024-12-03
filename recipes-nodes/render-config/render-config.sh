#!/bin/sh
# Renders a mustache template using the provided JSON input configuration

set -e
if (set -o pipefail 2>/dev/null); then
  set -o pipefail
fi
export LC_ALL=C

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <input_config> <template_file>

Renders a mustache template using the provided JSON input configuration.

Arguments:
  <input_config>   JSON configuration file to use as input
  <template_file>  Mustache template file to render

Options:
  -h, --help      Show this help message and exit
  -u, --unsafe    Disable removal of unsafe sequences from input. Enable interpretation of filters (known filters are: base64)
EOF
  exit "${1:-0}"
}

# Initialize variables
unsafe_mode=false
input_config=""
template_file=""

# Parse arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage 0
      ;;
    -u|--unsafe)
      unsafe_mode=true
      shift
      ;;
    *)
      if [ -z "$input_config" ]; then
        input_config="$1"
      elif [ -z "$template_file" ]; then
        template_file="$1"
      else
        echo "Error: Unexpected argument: $1" >&2
        usage 1
      fi
      shift
      ;;
  esac
done

# Validate required arguments
if [ -z "$input_config" ] || [ -z "$template_file" ]; then
  echo "Error: Missing required arguments" >&2
  usage 1
fi

# Check if files exist
if [ ! -f "$input_config" ]; then
  echo "Error: Input config file does not exist: $input_config" >&2
  exit 1
fi

if [ ! -f "$template_file" ]; then
  echo "Error: Template file does not exist: $template_file" >&2
  exit 1
fi

# Process the input
process_input() {
  if [ "$unsafe_mode" = true ]; then
    jq -c 'walk(if type=="object" then with_entries(if .key|endswith("#base64") then .key|=sub("#base64$";"")|.value|=@base64d else . end) else . end)' "$input_config" | mustache "$template_file"
  else
    jq -c '.' "$input_config" | # make sure the input is a valid JSON
      sed -E 's/[^[:graph:] ]//g' | # remove non-printable characters
      sed -E 's/\\(a|b|c|e|f|n|r|t|v|x[0-9a-f]{2}|u[0-9a-f]{4}|U[0-9a-f]{8}|[0-7]{3})/\\\\\1/g' | # escape sequences that have special meaning in Go (https://go.dev/ref/spec#Rune_literals)
      mustache "$template_file"
  fi
}

process_input
