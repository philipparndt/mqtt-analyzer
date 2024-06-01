#!/bin/bash

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: set-version.sh <version>"
    exit 1
fi

fastmod --extensions pbxproj "MARKETING_VERSION = .*" "MARKETING_VERSION = $VERSION;"