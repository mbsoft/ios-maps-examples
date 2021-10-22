
PROJECT_NAME=NbmapStoryboard
INFO_PLIST_FILE=$APPCENTER_SOURCE_DIRECTORY/$PROJECT_NAME/NbmapStoryboard/Info.plist
echo $INFO_PLIST_FILE
cat $INFO_PLIST_FILE
echo -n 'current NBAI_API_KEY environment variable...'
echo $NBAI_API_KEY
echo "Updating API KEY to $NBAI_API_KEY in Info.plist"
plutil -replace NBMapKey -string $NBAI_API_KEY $INFO_PLIST_FILE
echo -n 'current NBAI_GEOCODE_KEY environment variable...'
echo $NBAI_GEOCODE_KEY
echo "Updating GEOCODE KEY to $NBAI_GEOCODE_KEY in Info.plist"
plutil -replace NBGeocodeKey -string $NBAI_GEOCODE_KEY $INFO_PLIST_FILE
echo 'new version of Info.plist'
cat $INFO_PLIST_FILE
