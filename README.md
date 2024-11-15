# Auto Bolt Sync Script - Usage Guide

This script automatically watches for Bolt.new project ZIP files and syncs their contents to your git repository.

## Setup

1. Place these files in your desired working directory:

   - `auto-bolt-sync.sh` (the main script)
   - `auto-bolt-sync-config.ini` (configuration file)

2. Create `auto-bolt-sync-config.ini` with one of these configurations:

   For syncing to the same directory the script is in:

   ```ini
   TARGET_REPO=.
   ```

   For syncing to a different git repository:

   ```ini
   TARGET_REPO=/path/to/your/git/repo
   ```

   Note: Use absolute paths (e.g., /home/user/myrepo) or paths relative to the script's location.

   Optional settings:

   ```ini
   # ZIP_PATTERN=project-bolt-*.zip  # Change the zip file pattern to watch
   # SYNCED_DIR=bolt_synced              # Change the directory for processed files
   ```

3. Make the script executable:

   ```bash
   chmod +x auto-bolt-sync.sh
   ```

4. Add the bolt_synced directory to .gitignore in your target repository:
   ```bash
   echo "bolt_synced/" >> /path/to/your/git/repo/.gitignore
   ```
   If using the current directory (TARGET_REPO=.), simply run:
   ```bash
   echo "bolt_synced/" >> .gitignore
   ```
   If .gitignore doesn't exist, this will create it. If it does exist, it will append the line.

## Running the Script

1. Start the script:

   ```bash
   ./auto-bolt-sync.sh
   ```

2. The script will:
   - Watch for files matching `project-bolt-*.zip` in the script's directory
   - Create a `bolt_synced` directory if it doesn't exist
   - Process any matching ZIP files it finds

## How It Works

When a matching ZIP file is found:

1. The contents are extracted
2. Files from the `project` directory inside the ZIP are copied to your target repository
3. Changes are committed with message "bolt.new changes sync YYYYMMDDHHMMSS"
4. Changes are pushed to the remote repository
5. The ZIP file is moved to the `bolt_synced` directory

Important notes:

- The ZIP file must contain a `project` directory
- Files from the `project` directory will overwrite existing files in the repository
- If no changes are detected, the ZIP file is still moved to `bolt_synced`
- The script continues running until you stop it with Ctrl+C
- The `bolt_synced` directory is ignored by git (via .gitignore)

## Directory Structure

If running in the same directory as the git repository (TARGET_REPO=.):

```
your-git-repo/
├── .gitignore              # Contains "bolt_synced/"
├── auto-bolt-sync.sh
├── auto-bolt-sync-config.ini
├── bolt_synced/                 # Created automatically (git-ignored)
│   └── (processed zip files)
└── (your repository files)
```

If running in a separate directory:

```
working-directory/          # Where the script runs
├── auto-bolt-sync.sh
├── auto-bolt-sync-config.ini
└── bolt_synced/                 # Created automatically
    └── (processed zip files)

/path/to/your/git/repo/    # Target repository
├── .gitignore             # Contains "bolt_synced/"
└── (your repository files)
```

## Requirements

- Git must be installed and configured
- Your git repository must be initialized
- You must have push access to the remote repository
- The `unzip` command must be available
- If using a separate target repository:
  - The target path must be accessible
  - You must have write permissions to the target path

## Troubleshooting

1. If the script can't find ZIP files:

   - Check that the files match the pattern `project-bolt-*.zip`
   - Verify the files are in the same directory as the script

2. If git push fails:

   - Check your git credentials
   - Verify you have push access to the repository
   - Ensure your branch is tracking a remote branch

3. If files aren't being copied:

   - Verify the ZIP file contains a `project` directory
   - Check file permissions in the repository
   - If using a separate target repository:
     - Verify the path in auto-bolt-sync-config.ini is correct
     - Check permissions on the target directory

4. If processed files are showing in git status:
   - Verify the `bolt_synced/` line is in your .gitignore
   - If you added the line after creating the directory, run:
     ```bash
     cd /path/to/your/git/repo  # Change to your target repo
     git rm -r --cached bolt_synced/
     git commit -m "Remove bolt_synced directory from git tracking"
     ```

## Stopping the Script

Press Ctrl+C to stop the script at any time. It will complete any in-progress file processing before stopping.
