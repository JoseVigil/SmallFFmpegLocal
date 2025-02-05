#!/bin/bash

# Define paths
LOCAL_TEMP="$HOME/Desktop/TEMP"
LOCAL_ASSETS="$HOME/repos/SmallFFmpegLocal/assets"
REMOTE_FOLDER="/data/data/com.notimation.small/files"
REMOTE_DATABASE_FOLDER="/data/data/com.notimation.small/databases/contacts.db"

# Step 1: Clean up the LOCAL_ASSETS folder (local computer only)
echo "Cleaning up $LOCAL_ASSETS..."
rm -rf "$LOCAL_ASSETS"/* 2>/dev/null  # Forcefully remove all files, ignore errors
mkdir -p "$LOCAL_ASSETS"              # Recreate the folder if it doesn't exist

# Step 2: Clean up the LOCAL_TEMP folder (local computer only)
echo "Cleaning up $LOCAL_TEMP..."
rm -rf "$LOCAL_TEMP"/* 2>/dev/null    # Forcefully remove all files, ignore errors
mkdir -p "$LOCAL_TEMP"                # Recreate the folder if it doesn't exist

# Step 3: Create a .tar file with a timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TAR_FILE="$LOCAL_TEMP/my_folder_$TIMESTAMP.tar"

echo "Creating .tar file: $TAR_FILE"
adb shell "run-as com.notimation.small tar -cf - $REMOTE_FOLDER" > "$TAR_FILE"

# Check if .tar file was created successfully
if [ ! -f "$TAR_FILE" ]; then
    echo "Error: Failed to create .tar file."
    exit 1
fi

# Step 4: Extract the .tar file to the same location
echo "Extracting .tar file..."
tar -xf "$TAR_FILE" -C "$LOCAL_TEMP"

# Check if extraction was successful
EXTRACTED_FOLDER="$LOCAL_TEMP/data/data/com.notimation.small/files"
if [ ! -d "$EXTRACTED_FOLDER" ]; then
    echo "Error: Failed to extract .tar file or extracted folder not found."
    exit 1
fi

# Step 5: Create a 'databases' folder in LOCAL_ASSETS
DATABASES_FOLDER="$LOCAL_ASSETS/databases"
echo "Creating databases folder: $DATABASES_FOLDER"
mkdir -p "$DATABASES_FOLDER"

# Step 6: Copy the extracted content to the assets folder
echo "Copying extracted content from $EXTRACTED_FOLDER to $LOCAL_ASSETS..."
cp -r "$EXTRACTED_FOLDER"/* "$LOCAL_ASSETS/"

# Step 7: Copy the remote database to the 'databases' folder
echo "Copying remote database to $DATABASES_FOLDER..."
adb exec-out run-as com.notimation.small cat "$REMOTE_DATABASE_FOLDER" > "$DATABASES_FOLDER/contacts.db"

# Check if database copy was successful
if [ ! -f "$DATABASES_FOLDER/contacts.db" ]; then
    echo "Error: Failed to copy remote database."
    exit 1
fi

# Step 8: Remove the .tar file from LOCAL_TEMP
echo "Removing .tar file from $LOCAL_TEMP..."
rm -f "$TAR_FILE"

# Verify .tar file removal
if [ -f "$TAR_FILE" ]; then
    echo "Error: Failed to remove .tar file."
    exit 1
else
    echo "Success: .tar file removed."
fi

echo "Process completed successfully!"