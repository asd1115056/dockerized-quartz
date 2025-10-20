#!/bin/bash

QUARTZ_DIR="/usr/src/app/quartz"
VAULT_DIR="/vault"

if [ "$VAULT_DO_GIT_PULL_ON_UPDATE" = true ]; then
  echo "Executing git pull in /vault directory"
  cd $VAULT_DIR

  if [ ! -d ".git" ]; then
    echo "Warning: /vault is not a git repository. Skipping git pull."
  else
    # Configure git credentials if provided
    if [ -n "$VAULT_GIT_USERNAME" ] && [ -n "$VAULT_GIT_TOKEN" ]; then
      git config credential.helper '!f() { echo "username=${VAULT_GIT_USERNAME}"; echo "password=${VAULT_GIT_TOKEN}"; }; f'
    fi

    # Pull changes
    if git pull; then
      echo "Successfully pulled latest changes."
    else
      echo "Error: git pull failed. Continuing with existing vault contents..."
    fi

    # Clear credentials
    if [ -n "$VAULT_GIT_USERNAME" ] && [ -n "$VAULT_GIT_TOKEN" ]; then
      git config --unset credential.helper
    fi
  fi
fi

cd $QUARTZ_DIR

echo "Running Quartz build..."
if [ -n "$NOTIFY_TARGET" ]; then
  apprise -vv --title="Dockerized Quartz" --body="Quartz build has been started." "$NOTIFY_TARGET"
fi

npx quartz build --directory /vault --output /usr/share/nginx/html
BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
  echo "Quartz build completed successfully."
  if [ -n "$NOTIFY_TARGET" ]; then
    apprise -vv --title="Dockerized Quartz" --body="Quartz build completed successfully." "$NOTIFY_TARGET"
  fi
else
  echo "Quartz build failed."
  if [ -n "$NOTIFY_TARGET" ]; then
    apprise -vv --title="Dockerized Quartz" --body="Quartz build failed!" "$NOTIFY_TARGET"
  fi
  exit 1
fi