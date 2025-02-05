#!/bin/bash

# Define paths
DATABASE_FILE="$HOME/repos/SmallFFmpegLocal/assets/databases/contacts.db"

# Step 1: Close DB Browser for SQLite (if open)
echo "Closing DB Browser for SQLite..."
pkill -x "DB Browser for SQLite"

# Step 2: Wait a moment to ensure it closes
sleep 1

# Step 3: Open DB Browser with the database
echo "Reopening DB Browser with the updated database..."
open -a "DB Browser for SQLite" --args "$DATABASE_FILE"

echo "Database refreshed successfully!"
