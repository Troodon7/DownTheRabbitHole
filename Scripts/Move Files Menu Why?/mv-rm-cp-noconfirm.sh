#!/bin/bash

# Function to display the menu
display_menu() {
    echo "1. Move files"
    echo "2. Copy files"
    echo "3. Delete files"
    echo "4. Cancel"
}

# Function to move files of a specified type with progress messages
move_files() {
    read -p "Enter the source directory: " source_dir
    read -p "Enter the destination directory: " destination_dir
    read -p "Enter the file type (e.g., txt, jpg, etc.): " file_type

    # Check if source directory exists
    if [ ! -d "$source_dir" ]; then
        echo "Error: Source directory '$source_dir' does not exist."
        return
    fi

    # Check if destination directory exists, create if not
    if [ ! -d "$destination_dir" ]; then
        mkdir -p "$destination_dir"
    fi

    # Get the total number of files to move
    total_files=$(find "$source_dir" -maxdepth 1 -type f -name "*.$file_type" | wc -l)
    current_files=0

    # Move files of the specified type with progress messages
    for file in "$source_dir"/*.$file_type; do
        mv "$file" "$destination_dir"/
        ((current_files++))
        echo "Progress: $current_files/$total_files files moved."
    done

    echo "Files of type $file_type moved from $source_dir to $destination_dir."
}

# Function to copy files of a specified type
copy_files() {
    read -p "Enter the source directory: " source_dir
    read -p "Enter the destination directory: " destination_dir
    read -p "Enter the file type (e.g., txt, jpg, etc.): " file_type

    # Check if source directory exists
    if [ ! -d "$source_dir" ]; then
        echo "Error: Source directory '$source_dir' does not exist."
        return
    fi

    # Check if destination directory exists, create if not
    if [ ! -d "$destination_dir" ]; then
        mkdir -p "$destination_dir"
    fi

    # Copy files of the specified type
    cp "$source_dir"/*.$file_type "$destination_dir"/

    echo "Files of type $file_type copied from $source_dir to $destination_dir."
}

# Function to delete files of a specified type
delete_files() {
    read -p "Enter the directory: " directory
    read -p "Enter the file type (e.g., txt, jpg, etc.): " file_type

    # Check if directory exists
    if [ ! -d "$directory" ]; then
        echo "Error: Directory '$directory' does not exist."
        return
    fi

    # Delete files of the specified type
    rm "$directory"/*.$file_type

    echo "Files of type $file_type deleted from $directory."
}

# Main script

while true; do
    display_menu

    read -p "Enter your choice (1, 2, 3, or 4): " choice

    case $choice in
        1)
            move_files
            ;;
        2)
            copy_files
            ;;
        3)
            delete_files
            ;;
        4)
            echo "Operation canceled."
            break
            ;;
        *)
            echo "Invalid choice. Please enter 1, 2, 3, or 4."
            ;;
    esac
done
