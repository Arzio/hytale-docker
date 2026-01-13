#!/bin/bash
# Entrypoint for the Hytale server - dockerized

# For now, we will ignore the update check
# because we don't know how to handle them
DOWNLOADER_SKIP_UPDATE_CHECK="true"

# Set the app directory
APP_DIR="${APP_DIR:-/hytale}"

# Go to the app directory
cd $APP_DIR

# Prepare downloader command line
DOWNLOADER_CMD="/bin/hytale-downloader"

# Create a tmp file
DOWNLOADER_TMP_FILE=$(mktemp)

# Delete the tmp file on exit
trap "rm -f $DOWNLOADER_TMP_FILE" EXIT

# Build downloader arguments
DOWNLOADER_ARGS="-download-path $DOWNLOADER_TMP_FILE"

# If DOWNLOADER_CREDENTIALS_PATH is set, add credentials path
if [ -n "$DOWNLOADER_CREDENTIALS_PATH" ]; then
    DOWNLOADER_ARGS="$DOWNLOADER_ARGS -credentials-path $DOWNLOADER_CREDENTIALS_PATH"
fi

# If DOWNLOADER_DOWNLOAD_PATH is set, add download path
if [ -n "$DOWNLOADER_DOWNLOAD_PATH" ]; then
    DOWNLOADER_ARGS="$DOWNLOADER_ARGS -download-path $DOWNLOADER_DOWNLOAD_PATH"
fi

# If DOWNLOADER_PATCHLINE is set, add patchline
if [ -n "$DOWNLOADER_PATCHLINE" ]; then
    DOWNLOADER_ARGS="$DOWNLOADER_ARGS -patchline $DOWNLOADER_PATCHLINE"
fi

# Run the downloader to download/update server files
# Check if HytaleServer.jar exists - if not, run downloader even if skip is set
if [ ! -f "$APP_DIR/HytaleServer.jar" ] || [ -z "$DOWNLOADER_SKIP_UPDATE_CHECK" ]; then
    if [ -z "$DOWNLOADER_SKIP_UPDATE_CHECK" ]; then
        echo "Checking for updates..."
    else
        echo "Downloading server files for the first time..."
    fi

    # Run the downloader to download/update server files
    $DOWNLOADER_CMD $DOWNLOADER_ARGS

    # If the update failed, exit
    if [ $? -ne 0 ]; then
        echo "Failed to update server files"
        exit 1
    fi

    # If server files where downloaded
    if [ -f "$DOWNLOADER_TMP_FILE" ]; then
        echo "Unzipping server files..."

        # Create a tmp folder
        TMP_FOLDER=$(mktemp -d)

        # Delete the tmp folder on exit
        trap "rm -rf $TMP_FOLDER" EXIT

        # Unzip the server files
        # They're inside the "Server" folder in the zip file
        # and need to go to the root directory
        unzip -q $DOWNLOADER_TMP_FILE  -d $TMP_FOLDER

        # Copy the `Server` folder to the app directory
        cp -r $TMP_FOLDER/Server/* $APP_DIR

        if [ $? -ne 0 ]; then
            echo "Failed to unzip server files"
            exit 1
        fi

        # Delete the server files zip
        rm $DOWNLOADER_TMP_FILE
    fi
fi

echo "Initializing server..."

# Prepare the command line
COMMAND_LINE="java -jar $APP_DIR/HytaleServer.jar"

# If the SERVER_ASSETS_ZIP environment variable is set
if [ -n "$SERVER_ASSETS_ZIP" ]; then
    # If it's a local file, add it to the command line
    if [ -f "$SERVER_ASSETS_ZIP" ]; then
        COMMAND_LINE="$COMMAND_LINE --assets $SERVER_ASSETS_ZIP"
    else
        # Download the assets zip
        wget -O $APP_DIR/assets.zip $SERVER_ASSETS_ZIP

        # Add the assets zip to the command line
        COMMAND_LINE="$COMMAND_LINE --assets $APP_DIR/assets.zip"
    fi
fi

# If the SERVER_ACCEPT_EARLY_PLUGINS environment variable is set
if [ -n "$SERVER_ACCEPT_EARLY_PLUGINS" ]; then
    # Add the accept early plugins flag to the command line
    COMMAND_LINE="$COMMAND_LINE --accept-early-plugins"
fi

# If the SERVER_BIND environment variable is set
if [ -n "$SERVER_BIND" ]; then
    # Add the bind flag to the command line
    COMMAND_LINE="$COMMAND_LINE --bind $SERVER_BIND"
fi

# Default backup directory and interval
SERVER_BACKUP_DIR="${SERVER_BACKUP_DIR:-/hytale/backups}"
SERVER_BACKUP_INTERVAL="${SERVER_BACKUP_INTERVAL:-10}"

# Add the backup flag to the command line
COMMAND_LINE="$COMMAND_LINE --backup --backup-dir $SERVER_BACKUP_DIR --backup-frequency $SERVER_BACKUP_INTERVAL"

# Run the server
$COMMAND_LINE
