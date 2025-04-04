#!/bin/zsh

# Author: Martin Widén, Linköping University, 2025
# This script starts a migration from Self Service Classic to
# Self Service+ on macOS devices managed by Jamf Pro.
# It ensures that Self Service Classic is not running,
# uninstalls the application along with its associated files,
# and triggers a Jamf Pro policy to install Self Service+.
# Pre requisites:
# - swiftDialog must be installed
# - The Mac must be managed by Jamf Pro
# - The script must be run with root privileges (eg from a Jamf Pro policy)

# Variables
# Set the path to Self Service
selfservice_path="/Applications/Self Service.app"

# Check if swiftDialog is present
is_swiftdialog_installed() {
    if [[ -f "/Library/Application Support/Dialog/Dialog.app/Contents/MacOS/Dialog" ]]; then
        print "swiftDialog is installed."
        return
    fi
    print "swiftDialog is not installed."
    return 1
}

# Check if Self Service is installed
is_self_service_installed() {
    if [[ -d "$selfservice_path" ]]; then
        print "Self Service.app is installed."
        return
    fi
    print "Self Service.app is not installed."
    return 1
}

uninstall_self_service() {
    # Paths to remove
    paths_to_remove=(
        "$selfservice_path"
        "/Library/Application Support/com.jamfsoftware.selfservice.mac"
        "/Library/Application Support/com.jamfsoftware.selfservice.mac_1"
        "/Library/Caches/com.jamfsoftware.selfservice.mac"
        "/Library/HTTPStorages/com.jamfsoftware.selfservice.mac"
        "/Library/Logs/JAMF/selfservice.log"
        "/Library/Logs/JAMF/selfservice_debug.log"
        "/Library/Preferences/com.jamfsoftware.selfservice.mac.plist"
        "/var/db/receipts/com.jamfsoftware.selfservice.mac.bom"
        "/var/db/receipts/com.jamfsoftware.selfservice.mac.plist"
    )

    # Remove each path
    for path in $paths_to_remove; do
        if [[ -f $path || -L $path ]]; then
            /bin/rm $path && print "Removed file: $path" || print "Failed to remove file: $path"
            continue
        fi
        if [[ -d $path ]]; then
            /bin/rm -r $path && print "Removed directory: $path" || print "Failed to remove directory: $path"
            continue
        fi
        print "Path does not exist: $path"
    done
}

install_self_service_plus() {
    # Trigger Jamf Pro policy to install Self Service+
    # Edit this to the name of your custom trigger for the policy
    /usr/local/bin/jamf policy -event installSelfServicePlus
    if [ $? -eq 0 ]; then
        print "Triggered Jamf Pro policy to install Self Service+."
        return
    fi
    print "Failed to trigger Jamf Pro policy."
}

check_self_service_running() {
    # Check if Self Service is not running
    if ! pgrep -xq "Self Service"; then
        print "Self Service is not running."
        return 0
    fi

    # If Self Service is running, prompt the user
    /usr/local/bin/dialog \
        --title "Self Service Migration Notice" \
        --message "Self Service is currently running. Please choose an action to proceed with the migration." \
        --icon "$selfservice_path/Contents/Resources/AppIcon.icns" \
        --button1text "Quit Self Service" \
        --button2text "Cancel"

    dialog_exit_code=$?
    if [[ $dialog_exit_code -eq 0 ]]; then
        # User chose "Quit Self Service"
        pkill "Self Service"
        install_self_service_plus
        if [[ $? -eq 0 ]]; then
            print "Self Service has been quit."
            return 1
        fi
        print "Failed to quit Self Service."
        return 2
    fi
    if [[ $dialog_exit_code -eq 2 ]]; then
        # User chose "Cancel"
        print "Migration canceled by the user."
        exit 1
    fi
    print "Unexpected dialog exit code: $dialog_exit_code."
    return 1
}

# Main script execution
check_command_success() {
    if [[ $? -eq 0 ]]; then
        return 0
    fi
    print "$1 Exiting."
    exit 1
}

check_migration_canceled() {
    if [[ $? -eq 2 ]]; then
        print "Migration canceled by the user. Exiting."
        exit 0
    fi
}

is_swiftdialog_installed
is_self_service_installed
check_self_service_running
uninstall_self_service
install_self_service_plus

# Final message
print "Migration complete."
