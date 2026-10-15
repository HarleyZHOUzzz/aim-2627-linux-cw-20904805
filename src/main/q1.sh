#!/bin/bash
# Q1: Resolve the handover directory and copy the requested source text.
# The input and output paths can contain spaces, so every expansion is quoted.
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# Resolve the actual absolute path instead of relying on the caller's directory.
handover=$(cd -- "$input/handover" && pwd -P)
printf '%s\n' "$handover" > "$output/location.txt"

# Copy file contents verbatim, including their final newlines.
cat "$input/handover/.robot-id" > "$output/robot-id.txt"
cat "$input/notes/welcome.txt" > "$output/welcome.txt"
