#!/usr/bin/env bash
echo "Starting prebuild app center prebuild script"
if [ -z "$VERSION_NAME" ]
then
    echo "You need define the VERSION_NAME variable in App Center"
    exit
fi

PROJECT_NAME=NbmapStoryboard
INFO_PLIST_FILE=$APPCENTER_SOURCE_DIRECTORY/$PROJECT_NAME/Info.plist

if [ -e "$INFO_PLIST_FILE" ]
then
    echo "Updating version name to $VERSION_NAME in Info.plist"
    plutil -replace NBMapKey  -string $NBAI_API_KEY $INFO_PLIST_FILE

    echo "File content:"
    cat $INFO_PLIST_FILE
fi
