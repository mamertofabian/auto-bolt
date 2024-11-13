#!/bin/bash

# Default configuration values
CONFIG_FILE="auto-bolt-sync-config.ini"
ZIP_PATTERN="project-bolt-*.zip"
SYNCED_DIR="bolt_synced"

# Store the script's directory
SCRIPT_DIR=$(pwd)

# Function to load configuration
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Configuration file '$CONFIG_FILE' not found"
        exit 1
    fi
    
    # Read target repo from config file
    TARGET_REPO=$(grep "^TARGET_REPO=" "$CONFIG_FILE" | cut -d'=' -f2)
    
    # Optional: override defaults with config values if present
    local config_pattern=$(grep "^ZIP_PATTERN=" "$CONFIG_FILE" | cut -d'=' -f2)
    local config_synced=$(grep "^SYNCED_DIR=" "$CONFIG_FILE" | cut -d'=' -f2)
    
    [ -n "$config_pattern" ] && ZIP_PATTERN="$config_pattern"
    [ -n "$config_synced" ] && SYNCED_DIR="$config_synced"
    
    # Convert relative paths to absolute paths
    TARGET_REPO=$(realpath "$TARGET_REPO")
    SYNCED_DIR=$(realpath "$SCRIPT_DIR/$SYNCED_DIR")
    
    # Validate configuration
    if [ -z "$TARGET_REPO" ]; then
        echo "Error: TARGET_REPO not set in configuration file"
        exit 1
    fi
    
    # Check if target directory exists and is a git repo
    if [ ! -d "$TARGET_REPO/.git" ]; then
        echo "Error: '$TARGET_REPO' is not a git repository"
        exit 1
    fi
}

# Function to process a single zip file
process_zip() {
    local zip_file="$1"
    echo "Processing $zip_file..."
    
    # Create temporary directory for extraction
    local temp_dir=$(mktemp -d)
    
    # Extract zip contents to temporary directory
    if ! unzip -q "$SCRIPT_DIR/$zip_file" -d "$temp_dir"; then
        echo "Error: Failed to extract $zip_file"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Check if project directory exists in the extracted contents
    if [ ! -d "$temp_dir/project" ]; then
        echo "Error: Expected 'project' directory not found in $zip_file"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Copy contents of the project directory to target directory
    cp -rf "$temp_dir/project"/* "$TARGET_REPO"
    
    # Clean up temporary directory
    rm -rf "$temp_dir"
    
    # Generate timestamp for commit message
    local timestamp=$(date +%Y%m%d%H%M%S)
    
    # Change to target directory, commit changes, and push
    cd "$TARGET_REPO" || return 1
    git add .
    if ! git commit -m "bolt.new changes sync $timestamp"; then
        echo "No changes to commit for $zip_file"
        cd "$SCRIPT_DIR"
        # Move the file to bolt_synced directory even if there are no changes
        mkdir -p "$SYNCED_DIR"
        mv "$zip_file" "$SYNCED_DIR/"
        echo "Moved $zip_file to bolt_synced directory (no changes detected)"
        return 0
    fi
    
    # Push changes to remote repository
    if ! git push; then
        echo "Error: Failed to push changes for $zip_file"
        cd "$SCRIPT_DIR"
        return 1
    fi
    
    # Return to script directory
    cd "$SCRIPT_DIR"
    
    # Move zip file to bolt_synced directory
    mkdir -p "$SYNCED_DIR"
    mv "$zip_file" "$SYNCED_DIR/"
    
    echo "Successfully processed $zip_file"
    return 0
}

# Main script
echo "Loading configuration..."
load_config

# Create bolt_synced directory if it doesn't exist
mkdir -p "$SYNCED_DIR"

echo "Watching for $ZIP_PATTERN files..."
echo "Target repository: $TARGET_REPO"
echo "Processed files will be moved to: $SYNCED_DIR"
echo "Press Ctrl+C to stop watching"

# Watch loop
while true; do
    cd "$SCRIPT_DIR"
    # Find all matching zip files in the current directory
    for zip_file in $ZIP_PATTERN; do
        # Check if file exists and is not a pattern expansion
        if [ -f "$zip_file" ]; then
            process_zip "$zip_file"
        fi
    done
    
    # Wait before next check
    sleep 2
done
