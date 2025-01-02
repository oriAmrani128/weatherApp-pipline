#!/bin/bash

# קובץ שמכיל את הגרסה
VERSION_FILE="VERSION"

# בדוק אם קיימים תגיות ב-Git
if ! git describe --tags --abbrev=0 > /dev/null 2>&1; then
    echo "No tags found in Git. Initializing with 1.0.0"
    echo "1.0.0" > $VERSION_FILE
    git add $VERSION_FILE
    git commit -m "Initialize versioning to 1.0.0"
    git tag "v1.0.0"
fi

# קבל את התג האחרון
LATEST_TAG=$(git describe --tags --abbrev=0)
LATEST_VERSION=${LATEST_TAG#v} # הסר את ה-"v" אם קיים
IFS='.' read -r MAJOR MINOR PATCH <<< "$LATEST_VERSION"

# הצג את הגרסה הנוכחית
echo "Current version (from Git tag): $LATEST_VERSION"
echo "Which part to update? (major/minor/patch): "
read PART

# עדכן את החלק שבחרת
case $PART in
    major)
        ((MAJOR++))
        MINOR=0
        PATCH=0
        ;;
    minor)
        ((MINOR++))
        PATCH=0
        ;;
    patch)
        ((PATCH++))
        ;;
    *)
        echo "Invalid option!"
        exit 1
        ;;
esac

# צור גרסה חדשה
NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# עדכן את התג ואת קובץ הגרסה
echo "$NEW_VERSION" > $VERSION_FILE
git checkout main
git add $VERSION_FILE
git commit -m "Bump version to $NEW_VERSION"
git push http://${GITLAB_USERNAME}:${GITLAB_PASS}@10.0.128.91/oriamrani128/weatherapp.git main
git tag "v$NEW_VERSION"
git push http://${GITLAB_USERNAME}:${GITLAB_PASS}@10.0.128.91/oriamrani128/weatherapp.git main  "v$NEW_VERSION"



echo "Version updated to $NEW_VERSION and tagged in Git."
