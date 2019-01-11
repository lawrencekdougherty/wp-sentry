#!/bin/bash

SVN_URL="https://plugins.svn.wordpress.org/wp-sentry-integration/"
TMP_DIR="/tmp/wordpress-wp-sentry-plugin-svn"

# If there is no release version ask for it
if [[ -z "${RELEASE_VERSION}" ]]; then
    # Get the latest tag so we can show it
    GIT_LATEST="$(git describe --abbrev=0 --tags)"

    # Read the version we are going to release
    echo "?> Latest Git tag is: ${GIT_LATEST}"
    read -p "?> Specify the release version (ex: 2.0.0): " RELEASE_VERSION
else
    echo "!> Using release version from environment variable"
fi

# For CI builds get the credentials sotred
if [[ -z "${SVN_USERNAME}" ]]; then
    echo "!> Using SVN credentials stored on system or supplied interactive"
else
    echo "!> Using SVN credentials from environment variables"

    yes yes | svn --username="${SVN_USERNAME}" --password="{$SVN_PASSWORD}" ls ${SVN_URL} &>/dev/null
fi

echo "=> Starting release of version v${RELEASE_VERSION}..."
echo "   To SVN repository hosted on: ${SVN_URL}"
echo "   Using temporary folder: ${TMP_DIR}"
echo "-----------------------------------------------------"

echo " > Making sure composer vendor files are on the locked version"

# Install the dependencies (as defined in the composer.lock) first so we can package them up
composer install --no-dev --optimize-autoloader --no-interaction --no-progress

# Cleanup the old dir if it is there
rm -rf /tmp/wordpress-wp-sentry-plugin-svn

echo " > Checking out the SVN repository... (this might take a while)"

svn co -q ${SVN_URL} ${TMP_DIR}

echo " > Copying files to trunk"

rsync -Rrd --delete --delete-excluded --exclude-from 'release-exclude.txt' ./ ${TMP_DIR}/trunk/

cd ${TMP_DIR}/

svn status | grep '^!' | awk '{print $2}' | xargs svn delete
svn add --force * --auto-props --parents --depth infinity -q

svn status

echo "!> Early debug exit for testing! Nothing has changed!"
exit 0

svn commit -m "Syncing v${RELEASE_VERSION} from GitHub"

echo " > Creating release tag"

mkdir ${TMP_DIR}/tags/${RELEASE_VERSION}
svn add ${TMP_DIR}/tags/${RELEASE_VERSION}
svn commit -m "Creating tag for v${RELEASE_VERSION}"

echo " > Copying versioned files to v${RELEASE_VERSION} tag"

svn cp --parents trunk/* tags/${RELEASE_VERSION}

svn commit -m "Tagging v${RELEASE_VERSION}"

echo "-----------------------------------------------------"
echo "=> Finished releasing version v${RELEASE_VERSION}!"
