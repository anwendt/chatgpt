#!/bin/bash

set -euo pipefail

usage() {
  echo "Usage: $0 [-d|-e] <source_file> <target_file>" >&2
  echo "  -d    Decrypt" >&2
  echo "  -e    Encrypt" >&2
  exit 1
}

if [ $# -ne 3 ]; then
  usage
fi

MODE="$1"
SRC="$2"
DEST="$3"

if [ "$MODE" != "-d" ] && [ "$MODE" != "-e" ]; then
  usage
fi

if [ ! -f "$SRC" ]; then
  echo "Source file $SRC does not exist." >&2
  exit 1
fi

if ! command -v sops >/dev/null 2>&1; then
  echo "sops is not installed." >&2
  exit 1
fi

if ! command -v age >/dev/null 2>&1; then
  echo "age is not installed." >&2
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is not installed." >&2
  exit 1
fi

if ! kubectl get namespace argocd >/dev/null 2>&1; then
  echo "Namespace argocd not found." >&2
  exit 1
fi

if ! kubectl get secret helm-secrets-private-keys -n argocd >/dev/null 2>&1; then
  echo "Secret helm-secrets-private-keys not found in namespace argocd." >&2
  exit 1
fi

KEY_DATA=$(kubectl get secret helm-secrets-private-keys -n argocd -o jsonpath='{.data.key\.txt}' 2>/dev/null || true)
if [ -z "$KEY_DATA" ]; then
  echo "keys.txt not found in secret helm-secrets-private-keys." >&2
  exit 1
fi

DECODED=$(echo "$KEY_DATA" | base64 -d)
PRIVATE=$(echo "$DECODED" | grep -m1 'AGE-SECRET-KEY-' | sed 's/^private: *//')
if [ -z "$PRIVATE" ]; then
  echo "Could not extract private key from key.txt." >&2
  exit 1
fi

KEY_FILE=$(mktemp)
trap 'rm -f "$KEY_FILE"' EXIT

echo "$PRIVATE" > "$KEY_FILE"
export SOPS_AGE_KEY_FILE="$KEY_FILE"

if [ "$MODE" = "-e" ]; then
  sops --encrypt "$SRC" > "$DEST"
else
  sops --decrypt "$SRC" > "$DEST"
fi

