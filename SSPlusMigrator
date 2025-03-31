#!/bin/zsh

# Made by Martin Widén at Linköping University 2025.
# This script uninstalls Self Service and installs Self Service+.
# It is designed to be run on macOS devices managed by Jamf Pro.
# It removes the existing Self Service application and its associated files,
# then triggers a Jamf Pro policy to install Self Service+.

uninstall_self_service() {
    # Paths to remove
    paths_to_remove=(
        "/Applications/Self Service.app"
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
        if -f $path || -L $path; then
            rm $path && print "Removed file: $path" || print "Failed to remove file: $path"
        elif -d $path; then
            rm -r $path && print "Removed directory: $path" || print "Failed to remove directory: $path"
        else
            print "Path does not exist: $path"
        fi
    done
}

install_self_service_plus() {
    # Trigger Jamf Pro policy to install Self Service+
    /usr/local/bin/jamf policy -event installSelfServicePlus
    if $? -eq 0; then
        print "Triggered Jamf Pro policy to install Self Service+."
    else
        print "Failed to trigger Jamf Pro policy."
    fi
}

print "Uninstalling Self Service..."
uninstall_self_service
print "Installing Self Service+..."
install_self_service_plus
print "Migration complete."
