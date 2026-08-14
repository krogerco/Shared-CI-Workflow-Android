#!/bin/bash
set -e

# Repository ruleset propagation script
# Propagates repository rulesets from ruleset-templates/ to configured repositories

echo "========================================="
echo "Ruleset Propagation Script"
echo "========================================="

# Read the config file and parse repositories
REPOS=$(yq eval '.repositories[]' .github/automation-config.yml)
RULESET_SOURCE_DIR="${RULESET_SOURCE_DIR:-ruleset-templates}"

echo "Source ruleset directory: $RULESET_SOURCE_DIR"
echo ""

# Check if ruleset source directory exists
if [ ! -d "$RULESET_SOURCE_DIR" ]; then
  echo "Error: Ruleset source directory '$RULESET_SOURCE_DIR' not found"
  exit 1
fi

# Count ruleset files
RULESET_COUNT=$(find "$RULESET_SOURCE_DIR" -name "*.json" | wc -l)
echo "Found $RULESET_COUNT ruleset files to propagate"
echo ""

if [ "$RULESET_COUNT" -eq 0 ]; then
  echo "No ruleset files found. Exiting."
  exit 0
fi

# Track successful propagations
SUCCESSFUL_REPOS=()
FAILED_REPOS=()

# Process each repository
while IFS= read -r repo; do
  [ -z "$repo" ] && continue

  echo "========================================="
  echo "Processing repository: $repo"
  echo "========================================="

  REPO_SUCCESS=true

  # Process each ruleset file
  for ruleset_file in "$RULESET_SOURCE_DIR"/*.json; do
    [ -f "$ruleset_file" ] || continue

    # Get the ruleset name from the JSON file itself (not the filename)
    RULESET_NAME=$(jq -r '.name' "$ruleset_file")
    RULESET_FILE_NAME=$(basename "$ruleset_file" .json)
    echo "Applying ruleset: $RULESET_FILE_NAME (name: \"$RULESET_NAME\")"

    # Check if ruleset already exists in the repository
    EXISTING_RULESET_ID=$(gh api \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "/repos/$repo/rulesets" 2>/dev/null | \
      jq -r --arg ruleset_name "$RULESET_NAME" '.[] | select(.name == $ruleset_name) | .id' || echo "")

    if [ -n "$EXISTING_RULESET_ID" ]; then
      echo "  Updating existing ruleset (ID: $EXISTING_RULESET_ID)..."

      ERROR_OUTPUT=$(gh api \
        --method PUT \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/$repo/rulesets/$EXISTING_RULESET_ID" \
        --input "$ruleset_file" 2>&1) || UPDATE_FAILED=true

      if [ "$UPDATE_FAILED" = true ]; then
        echo "  ✗ Failed to update ruleset"
        printf '  Error: %s\n' "$ERROR_OUTPUT" | head -5
        REPO_SUCCESS=false
        UPDATE_FAILED=false
      else
        echo "  ✓ Ruleset updated successfully"
      fi
    else
      echo "  Creating new ruleset..."

      ERROR_OUTPUT=$(gh api \
        --method POST \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/$repo/rulesets" \
        --input "$ruleset_file" 2>&1) || CREATE_FAILED=true

      if [ "$CREATE_FAILED" = true ]; then
        echo "  ✗ Failed to create ruleset"
        echo "  Error: $ERROR_OUTPUT" | head -5
        REPO_SUCCESS=false
        CREATE_FAILED=false
      else
        echo "  ✓ Ruleset created successfully"
      fi
    fi

    echo ""
  done

  if [ "$REPO_SUCCESS" = true ]; then
    SUCCESSFUL_REPOS+=("$repo")
  else
    FAILED_REPOS+=("$repo")
  fi

  echo ""
done <<< "$REPOS"

echo "========================================="
echo "Propagation complete!"
echo "========================================="

if [ ${#SUCCESSFUL_REPOS[@]} -gt 0 ]; then
  echo ""
  echo "Successfully updated repositories:"
  for repo in "${SUCCESSFUL_REPOS[@]}"; do
    echo "  ✓ $repo"
  done
fi

if [ ${#FAILED_REPOS[@]} -gt 0 ]; then
  echo ""
  echo "Failed repositories:"
  for repo in "${FAILED_REPOS[@]}"; do
    echo "  ✗ $repo"
  done
  exit 1
fi
