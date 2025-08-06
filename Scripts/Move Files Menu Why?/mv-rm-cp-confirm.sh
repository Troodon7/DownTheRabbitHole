#!/bin/bash

# Function to display the menu
display_menu() {
    echo "1. Move files"
    echo "2. Copy files"
    echo "3. Delete files"
    echo "4. Cancel"
}

# Function to confirm the operation with the user
confirm_operation() {
    read -p "Are you sure you want to proceed? (y/n): " confirm
    if [ "$confirm" != "y" ]; then
        echo "Operation canceled."
        exit 0
    fi
}

# Function to move files of a specified type with progress messages
move_files() {
    confirm_operation

    read -p "Enter the source directory: " source_dir
    read -p "Enter the destination directory: " destination_dir
    read -p "Enter the file type (e.g., txt, jpg, etc.): " file_type

    # ... (rest of the move_files function remains unchanged)
}

# Function to copy files of a specified type
copy_files() {
    confirm_operation

    read -p "Enter the source directory: " source_dir
    read -p "Enter the destination directory: " destination_dir
    read -p "Enter the file type (e.g., txt, jpg, etc.): " file_type

    # ... (rest of the copy_files function remains unchanged)
}

# Function to delete files of a specified type
delete_files() {
    confirm_operation

    read -p "Enter the directory: " directory
    read -p "Enter the file type (e.g., txt, jpg, etc.): " file_type

    # ... (rest of the delete_files function remains unchanged)
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
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter 1, 2, 3, or 4."
            ;;
    esac
done
