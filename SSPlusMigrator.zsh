#!/bin/zsh

# Author: Martin Widén, Linköping University, 2025
# This script starts a migration from Self Service Classic to
# Self Service+ on macOS devices managed by Jamf Pro.
# It ensures that Self Service Classic is not running,
# uninstalls the application along with its associated files,
# and triggers a Jamf Pro policy to install Self Service+.

check_self_service_running() {
    if pgrep -xq "Self Service"; then
        /Library/Application\ Support/Dialog/Dialog.app/Contents/MacOS/Dialog \
            --notification \
            --title "Migration Notice" \
            --message "Please quit Self Service before proceeding with the migration." \
            --icon "/Applications/Self Service.app/Contents/Resources/AppIcon.icns" \
            --overlayicon caution \
            exit 1
    fi
}

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
        if [[ -f $path || -L $path ]]; then
            /bin/rm $path && print "Removed file: $path" || print "Failed to remove file: $path"
        elif [[ -d $path ]]; then
            /bin/rm -r $path && print "Removed directory: $path" || print "Failed to remove directory: $path"
        else
            print "Path does not exist: $path"
        fi
    done
}

install_self_service_plus() {
    # Trigger Jamf Pro policy to install Self Service+
    # Edit this to the name of your custom trigger for the policy
    /usr/local/bin/jamf policy -event installSelfServicePlus
    if [ $? -eq 0 ]; then
        print "Triggered Jamf Pro policy to install Self Service+."
    else
        print "Failed to trigger Jamf Pro policy."
    fi
}

# Main script execution
check_self_service_running
print "Uninstalling Self Service..."
uninstall_self_service
print "Installing Self Service+..."
install_self_service_plus
print "Migration complete."
