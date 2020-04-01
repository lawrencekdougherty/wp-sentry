if [[ ! -e php-scoper.phar ]]; then
  echo " > Downloading php-scoper.phar"
  echo ""

  curl -sSL -o php-scoper.phar https://github.com/humbug/php-scoper/releases/download/0.13.1/php-scoper.phar
fi

echo " > Making sure composer vendor files are on the locked version"
echo ""

# Install the dependencies (as defined in the composer.lock) first so we can package them up
composer install --no-dev --no-interaction --no-progress

echo ""
echo " > Scoping the PHP files to prevent conflicts with other plugins"

php php-scoper.phar add-prefix -s -q --force

echo " > Patching composer.json for scoped autoloader"

sed -i '' 's/src\\\//..\/src\//g' ./build/composer.json

echo " > Dumping new composer autoloader for scoped vendor"
echo ""

cd build && composer dump-autoload --classmap-authoritative --no-interaction && cd ../
