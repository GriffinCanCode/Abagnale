#!/bin/bash

# Set source image
SOURCE_IMAGE="Sources/abagnale/Resources/logo2.png"
ICONSET_NAME="abagnale.iconset"
ICNS_NAME="Sources/abagnale/Resources/abagnale.icns"

# Create iconset directory if it doesn't exist
mkdir -p $ICONSET_NAME

# Generate icons at different sizes
sips -z 16 16     $SOURCE_IMAGE --out "${ICONSET_NAME}/icon_16x16.png"
sips -z 32 32     $SOURCE_IMAGE --out "${ICONSET_NAME}/icon_16x16@2x.png"
sips -z 32 32     $SOURCE_IMAGE --out "${ICONSET_NAME}/icon_32x32.png"
sips -z 64 64     $SOURCE_IMAGE --out "${ICONSET_NAME}/icon_32x32@2x.png"
sips -z 128 128   $SOURCE_IMAGE --out "${ICONSET_NAME}/icon_128x128.png"
sips -z 256 256   $SOURCE_IMAGE --out "${ICONSET_NAME}/icon_128x128@2x.png"
sips -z 256 256   $SOURCE_IMAGE --out "${ICONSET_NAME}/icon_256x256.png"
sips -z 512 512   $SOURCE_IMAGE --out "${ICONSET_NAME}/icon_256x256@2x.png"
sips -z 512 512   $SOURCE_IMAGE --out "${ICONSET_NAME}/icon_512x512.png"
sips -z 1024 1024 $SOURCE_IMAGE --out "${ICONSET_NAME}/icon_512x512@2x.png"

# Create .icns file from iconset
iconutil -c icns $ICONSET_NAME -o $ICNS_NAME

# Clean up
rm -rf $ICONSET_NAME

echo "Icon generation complete! The new icons are in $ICNS_NAME" 