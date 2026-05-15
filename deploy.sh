#!/bin/bash

# Deploy fwb.html to GitHub Pages
echo "Deploying fwb.html to faw987.github.io..."

# Copy the file
cp /Users/franka.wallace/Projects/fwb/fwb.html /Users/franka.wallace/Projects/faw987.github.io/fwb.html
cp /Users/franka.wallace/Projects/fwb/FWB_user_doc.md /Users/franka.wallace/Projects/faw987.github.io/FWB_user_doc.md
cp /Users/franka.wallace/Projects/fwb/FWB_PRD.md /Users/franka.wallace/Projects/faw987.github.io/FWB_PRD.md


# Go to the pages repo and commit + push
cd /Users/franka.wallace/Projects/faw987.github.io

git add fwb.html
git add FWB_user_doc.md
git add FWB_PRD.md

git commit -m "deploy: update fwb.html, FWB_user_doc.md and FWB_PRD.md from fwb project"
git push

echo "Done! Live at https://faw987.github.io/fwb.html"
