#!/bin/bash

# Check if the correct number of arguments is provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Missing arguments."
    echo "Usage: ./builder.sh <drupal_or_symfony> <target_directory>"
    exit 1
fi

# Set the project type (drupal or symfony) and target directory from arguments
PROJECT_TYPE="$1"
TARGET_DIR="$2"

# Set the repository URL and branch based on the project type
REPO_URL="https://github.com/pogfra/app.git"
BRANCH_NAME="feature/builder"
BUILDER_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
TMP_DIR="tmp/$PROJECT_TYPE"
DOCROOT_DIR="."
ENV_TEMPLATE_FILE=".env"
CONTAINER_NAME="app-${TARGET_DIR}"
DOCKER_COMPOSE_FILE="docker-compose.yml"

# Step 1: Clone the repository if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    echo "Cloning the repository into '$TARGET_DIR'..."
    git clone $REPO_URL $TARGET_DIR
    cd $TARGET_DIR
    git checkout $BRANCH_NAME

    # Copy the .env.template to .env
    cp $BUILDER_DIR/.env.template .env

    # Replace the PROJECT variable in the .env file with the provided directory name ($TARGET_DIR)
    echo "Updating PROJECT variable in $ENV_TEMPLATE_FILE with '$TARGET_DIR'..."
    sed -i "s/PROJECT=app/PROJECT=$TARGET_DIR/g" .env

else
    echo "Repository already exists in '$TARGET_DIR'. Pulling the latest changes..."
    cd $TARGET_DIR
    git pull origin $BRANCH_NAME
fi

# Step 2: Launch container (assuming the setup uses Docker Compose)
echo "Launch container"
make up

# Step 3: Set up project based on the chosen project type (Drupal or Symfony)
if [ "$PROJECT_TYPE" == "drupal" ]; then
    # If the project type is Drupal:
    echo "Creating a fresh Drupal project using Composer in a temporary directory..."
    make composer create-project drupal/recommended-project:11.x-dev $TMP_DIR -- --no-interaction

    echo "Moving the Drupal project to the docroot directory..."
    rm -rf web
    mv $TMP_DIR/* $DOCROOT_DIR/

    echo "Add settings template"
    cp $BUILDER_DIR/settings.php web/sites/default/settings.php

    # Install Drush and dotenv
    echo "Add Drush"
    make composer require drush/drush -- --no-interaction --optimize-autoloader

    echo "Add dotenv"
    make composer require symfony/dotenv -- --no-interaction --optimize-autoloader

    # Install Drpal
    echo "Install Drupal"
    make drush si minimal -- -y

elif [ "$PROJECT_TYPE" == "symfony" ]; then
    # If the project type is Symfony:
    echo "Creating a fresh Symfony project using Composer in a temporary directory..."
    make composer create-project symfony/skeleton $TMP_DIR -- --no-interaction

    echo "Moving the Symfony project to the docroot directory..."
    rm -rf public
    mv $TMP_DIR/* $DOCROOT_DIR/

    # Create the 'web' directory
    echo "Creating 'web' directory for public assets..."
    mkdir -p web

    # Update composer.json to use 'web' as the public directory
    echo "Updating composer.json to set 'web' as the public directory..."
    jq '.extra."public-dir" = "web"' composer.json > tmp.json && mv tmp.json composer.json

    # Move the contents of public to web
    echo "Moving public content to web directory..."
    mv $DOCROOT_DIR/public/* web/

    # Install Symfony dependencies
    echo "Installing Symfony dependencies"
    make composer install -- --no-interaction
else
    echo "Error: Unsupported project type. Please choose 'drupal' or 'symfony'."
    exit 1
fi

# Step 4: Cleanup: Remove the temporary directory
echo "Cleaning up the temporary directory..."
rm -rf tmp

echo "$PROJECT_TYPE setup process is complete!"
