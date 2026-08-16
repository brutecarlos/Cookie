#!/usr/bin/env bash
set -euo pipefail
# Usage: ./publish_repo.sh [REPO_NAME] [public|private]
REPO_NAME=${1:-Cookie}
VISIBILITY=${2:-public}
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required. Install git and retry." >&2
  exit 2
fi

if [ -d .git ]; then
  echo "Existing git repository detected. Using current repo.";
else
  git init
fi

git add --all
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  git commit -m "Update" || true
else
  git commit -m "Initial commit" || true
fi

if command -v gh >/dev/null 2>&1; then
  echo "Using GitHub CLI to create and push repository..."
  gh repo create "$REPO_NAME" --$VISIBILITY --source="$ROOT_DIR" --remote=origin --push --confirm
  exit 0
fi

if [ -n "${GITHUB_TOKEN-}" ]; then
  echo "Creating repository via GitHub API using GITHUB_TOKEN..."
  if [ "$VISIBILITY" = "private" ]; then
    PRIVATE_JSON=true
  else
    PRIVATE_JSON=false
  fi
  resp=$(curl -s -H "Authorization: token $GITHUB_TOKEN" -d "{\"name\":\"$REPO_NAME\",\"private\":$PRIVATE_JSON}" https://api.github.com/user/repos)
  full=$(echo "$resp" | grep -o '"full_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n1 | sed 's/.*: *"\([^"]*\)"/\1/')
  if [ -z "$full" ]; then
    echo "Failed to create repo: $resp" >&2
    exit 3
  fi
  remote_url="https://x-access-token:$GITHUB_TOKEN@github.com/$full.git"
  git remote add origin "$remote_url" 2>/dev/null || git remote set-url origin "$remote_url"
  git push -u origin HEAD:main
  echo "Pushed to https://github.com/$full"
  exit 0
fi

cat <<EOF
Could not find GitHub CLI nor GITHUB_TOKEN.
To publish, either:
  1) Install GitHub CLI and run:
       gh repo create $REPO_NAME --public --source=. --remote=origin --push --confirm
  2) Or set GITHUB_TOKEN environment variable and re-run this script.

This script initializes git, commits the files, creates the remote repository, and pushes the current branch as `main`.
EOF

exit 1
