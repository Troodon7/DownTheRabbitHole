import os
import subprocess
import ctypes
import sys

def list_files_in_directory(extension):
    # Get a list of files in the current working directory with the specified extension
    files = [f for f in os.listdir('.') if os.path.isfile(f) and f.lower().endswith(extension)]
    return files

def read_key_from_file(file_path):
    try:
        with open(file_path, 'r') as key_file:
            # Read the key from the file and remove leading/trailing spaces
            key = key_file.read().strip()
            return key
    except FileNotFoundError:
        print(f"Error: Key file not found at {file_path}")
        return None
    except Exception as e:
        print(f"An unexpected error occurred while reading the key file: {e}")
        return None

def is_running_as_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

def elevate_script():
    if not is_running_as_admin():
        print("The script needs to be run with administrative privileges.")
        print("Do you want to run it as an administrator now? (yes/no): ")
        choice = input().strip().lower()
        if choice == "yes" or choice == "y":
            try:
                ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, " ".join(sys.argv), None, 1)
                sys.exit(0)
            except Exception as e:
                print(f"Error while elevating the script: {e}")
                sys.exit(1)
        else:
            print("Operation canceled. Exiting.")
            sys.exit(1)

def ask_for_exe_location():
    exe_location = input("Enter the location of the PS3Dec.exe file: ").strip('"')
    return exe_location

def create_output_directory(output_directory):
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)
        print(f"Output directory '{output_directory}' created successfully.")

def ask_for_key_file():
    key_files = list_files_in_directory('.dkey')
    if not key_files:
        print("No key files (.dkey) found in the current directory.")
        return None

    print("Key files in the current directory:")
    for i, key_file_name in enumerate(key_files):
        print(f"{i+1}. {key_file_name}")

    key_file_index = int(input("Select a key file by entering its number: ")) - 1

    if 0 <= key_file_index < len(key_files):
        key_file_path = key_files[key_file_index]
        return key_file_path

def ask_for_key():
    return input("Enter the key: ")

def run_exe_with_input(arguments):
    try:
        # Check if the script is running as an administrator, and elevate if needed
        elevate_script()

        # Ask for the exe location after elevation
        exe_path = ask_for_exe_location()

        while True:

            print("Options:")
            print("1. List ISO files in the current directory")
            print("2. Enter the path of the ISO file")

            option = input("Select an option: ")

            if option == "1":
                # Get a list of ISO files in the current directory
                iso_files = list_files_in_directory('.iso')

                if not iso_files:
                    print("No ISO files (.iso) found in the current directory.")
                    continue

                print("ISO files in the current directory:")
                for i, iso_file_name in enumerate(iso_files):
                    print(f"{i+1}. {iso_file_name}")

                # Get user input for the ISO file selection
                iso_file_index = int(input("Select an ISO file to decrypt by entering its number: ")) - 1

                if 0 <= iso_file_index < len(iso_files):
                    iso_file = iso_files[iso_file_index]
                else:
                    print("Invalid ISO file selection. Try again.")
                    continue

            elif option == "2":
                iso_file = input("Enter the path to the ISO file: ").strip('"')

                if not os.path.isfile(iso_file) or not iso_file.lower().endswith('.iso'):
                    print("Invalid ISO file path. Try again.")
                    continue
            else:
                print("Invalid option. Try again.")
                continue

            # Get user input for the key file or key
            key_option = input("Select key input option:\n1. Enter key manually\n2. Select from list\n3. Enter key file path ")

            if key_option == "1":
                # Get user input for the key
                key = ask_for_key()
            elif key_option == "2":
                # Get user input for the key file
                key_file_path = ask_for_key_file()
                key = read_key_from_file(key_file_path)
            elif key_option == "3":
                # Get user input for the key file path
                key_file_path = input("Enter the path to the key file (.dkey): ").strip('"')
                key = read_key_from_file(key_file_path)
            else:
                print("Invalid option. Try again.")
                continue

            if key is not None:
                # Get user input for the export location
                export_location = input("Enter the export location for decrypted files: ").strip('"')
                if not export_location:
                    export_location = "."  # Save in the current directory

                # Prompt the user for the output folder name
                output_folder_name = input("What would you like the output folder name to be? ")

                if not output_folder_name:
                    output_folder_name = "temp"  # Default to "temp" if no name is provided

                output_directory = os.path.join(export_location, output_folder_name)

                # Print the selected files and ask for verification
                print("\nSelected files:")
                print(f"ISO File: {iso_file}")
                print(f"Key: {key}")
                print(f"Export Location: {export_location}")
                print(f"Output Folder Name: {output_folder_name}")

                verification = input("\nIs everything correct? (yes/reselect option/start over (any other key)): ").lower()
                if verification in {"yes", "y"}:
                    # Create the output directory
                    create_output_directory(output_directory)

                    # Automatically generate the new file name with "decrypted" before ".iso"
                    base_name = os.path.splitext(os.path.basename(iso_file))[0] + "_decrypted"
                    newfile = os.path.join(output_directory, f"{base_name}.iso")

                    # Check if the file already exists, and if so, append a character
                    counter = 1
                    while os.path.exists(newfile):
                        newfile = os.path.join(output_directory, f"{base_name}_{counter}.iso")
                        counter += 1

                    # Construct the command
                    command = [exe_path, "d", "key", key, iso_file, newfile] + arguments

                    # Run the executable in the terminal
                    subprocess.run(command, check=True)

                    # Mount the ISO file
                    abs_newfile = os.path.abspath(newfile)
                    mount_command = ["powershell", "Mount-DiskImage", "-ImagePath", f'"{abs_newfile}"']
                    subprocess.run(mount_command, check=True)

                    # Get the drive letter of the mounted ISO
                    drive_letter_command = ["powershell", "(Get-DiskImage -ImagePath", f'"{abs_newfile}" | Get-Volume).DriveLetter']
                    drive_letter_process = subprocess.Popen(drive_letter_command, stdout=subprocess.PIPE, text=True)
                    drive_letter, _ = drive_letter_process.communicate()

                    if drive_letter:
                        drive_letter = drive_letter.strip()
                        print(f"ISO file {abs_newfile} is mounted on drive {drive_letter}.")

                        # Create the source path starting from the drive letter
                        source_path = f"{drive_letter}:\\"

                        # Copy the contents of the mounted ISO to the export location
                        copy_command = ["robocopy", source_path, output_directory, "/MIR"]
                        robocopy_process = subprocess.Popen(copy_command, stdout=subprocess.PIPE, text=True)
                        for line in robocopy_process.stdout:
                            print(line, end='')

                        robocopy_process.wait()  # Wait for robocopy to complete

                        # Unmount the ISO file
                        unmount_command = ["powershell", "Dismount-DiskImage", "-ImagePath", f'"{abs_newfile}"']
                        subprocess.run(unmount_command, check=True)

                        print("\nFiles copied successfully.")

                        # Prompt for file deletion
                        delete_files = input(f"\nDo you want to delete the following files? (yes/no):\n'{iso_file}'\n'{key_file_path}'\n'{newfile}'\n ").strip().lower()
                        if delete_files in {"yes", "y"}:
                            files_to_delete = [iso_file, key_file_path, newfile]
                            deleted_files = []
                            for file_to_del in files_to_delete:
                                if os.path.exists(file_to_del):
                                    os.remove(file_to_del)
                                    deleted_files.append(file_to_del)

                            if deleted_files:
                                print("\nFiles deleted:")
                                for deleted_file in deleted_files:
                                    print(deleted_file)

                        # Prompt to run the script again
                        run_again = input("\nDo you want to run the script again? (yes/no): ").strip().lower()
                        if run_again not in {"yes", "y"}:
                            break  # Exit the loop

                    else:
                        print("Failed to retrieve the drive letter of the mounted ISO.")

                else:
                    print("Operation canceled. Exiting.")
                    break  # Exit the loop if verification is not "yes"

            else:
                print("Failed to retrieve the drive letter of the mounted ISO.")

    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
    except ValueError as e:
        print(f"ValueError: {e}")
    except IndexError as e:
        print(f"IndexError: {e}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

if __name__ == "__main__":
    arguments = []  # Replace with your executable arguments
    run_exe_with_input(arguments)
