#!/bin/sh

BRANCH=$1
VERSION=$2

# Warn user
echo "Are you sure all files are committed? This action will remove staged/untracked files."
sleep 5

# Warn user Make sure the deployment dir exists and is empty
mkdir -p /tmp/$BRANCH

# Start at master, remove staging branch
git checkout master
git branch -D "$BRANCH"-staging
git checkout -b "$BRANCH"-staging

# Set version
mvn versions:set -DnewVersion=$VERSION
mvn versions:commit
git commit -a -m "Updated to version $VERSION"

# Initiate deployment
mvn clean deploy -DskipTests -Dproject.deploy.target=$BRANCH

# Remove target branch first (just in case)
git branch -D $BRANCH

# Create orphan branch, having no history
git checkout --orphan $BRANCH

# Remove all files in the working tree, by resetting to head (which is orphaned)
git reset --hard
git commit -m "Initial commit" --allow-empty
git stash -u

# Move in the deployment artifacts
cp -r /tmp/$BRANCH/. .

# Add them to the working tree, taking care to not add non-artifact files, while also preserving them through .gitignore
git add .
git commit -m "Maven artifacts for $VERSION"

# Push to remote
git push -f --set-upstream origin $BRANCH

# Get back the stash
git stash pop

# Back to master
git checkout master
git branch -D $BRANCH
