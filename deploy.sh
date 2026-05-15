#!/bin/bash

# Deploy fwb.html (+ docs) from the fwb project to the GitHub Pages repo.
# Live at https://faw987.github.io/fwb.html after a successful push.

set -euo pipefail

SRC="/Users/franka.wallace/Projects/fwb"
DEST="/Users/franka.wallace/Projects/faw987.github.io"
FILES=(fwb.html FWB_user_doc.md FWB_PRD.md)

echo "Deploying to faw987.github.io..."

# Sanity-check the app JS before shipping it.
node -e "const fs=require('fs');const h=fs.readFileSync('$SRC/fwb.html','utf8');const m=h.match(/<script>\n\(\(\) => \{([\s\S]*)\}\)\(\);\n<\/script>/);new Function('(()=>{'+m[1]+'})()');" \
  && echo "  JS sanity check: OK" \
  || { echo "  JS sanity check FAILED - aborting deploy"; exit 1; }

# Show which version is being deployed.
VERSION=$(grep -o 'class="badge version">V[0-9.]*' "$SRC/fwb.html" | grep -o 'V[0-9.]*' || echo "unknown")
echo "  Deploying version: $VERSION"

# Copy the files.
for f in "${FILES[@]}"; do
  cp "$SRC/$f" "$DEST/$f"
done

cd "$DEST"
git add "${FILES[@]}"

# Nothing changed? Don't make an empty commit.
if git diff --cached --quiet; then
  echo "No changes to deploy - $VERSION already live."
  exit 0
fi

git commit -m "deploy: update fwb.html, FWB_user_doc.md and FWB_PRD.md from fwb project ($VERSION)"
git push

echo "Done! $VERSION deployed as $(git rev-parse --short HEAD)"
echo "Live at https://faw987.github.io/fwb.html (allow ~1 min for GitHub Pages)"
