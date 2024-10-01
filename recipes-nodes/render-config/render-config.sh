#!/bin/sh
# Renders a mustache template using the provided JSON input configuration
# Usage: render_configs.sh <input_config> <template_file>
set -e -o pipefail
export LC_ALL=C

INPUT_CONFIG=$1
TEMPLATE_FILE=$2

jq -c '.' "$INPUT_CONFIG" | # make sure the input is a valid JSON
  sed -E 's/[^[:graph:] ]//g' | # remove non-printable characters
  sed -E 's/\\(a|b|c|e|f|n|r|t|v|x[0-9a-f]{2}|u[0-9a-f]{4}|U[0-9a-f]{8}|[0-7]{3})/\\\\\1/g' | # escape sequences that have special meaning in Go (https://go.dev/ref/spec#Rune_literals)
  mustache $TEMPLATE_FILE
