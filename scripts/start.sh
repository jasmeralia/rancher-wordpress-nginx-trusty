#!/bin/bash

# Configure NewRelic if appropriate
if [ -e '/newrelic.license' ] && [ -s '/newrelic.license' ]; then
  cp /newrelic.license /etc/php5/fpm/conf.d/30-newrelic.ini
  if [ "x$NEWRELIC_APPNAME" != "x" ]; then
    echo "newrelic.appname=\"$NEWRELIC_APPNAME\"" >> /etc/php5/fpm/conf.d/30-newrelic.ini
  fi
fi

# Set sane defaults if not passed via environment variables
if [ "x$WORDPRESS_DB_PRFX" == "x" ]; then
  WORDPRESS_DB_PRFX="wp_"
fi

if [ "x$WORDPRESS_AUTH_KEY" == "x" ]; then
  WORDPRESS_AUTH_KEY=`pwgen -c -n -1 65`
fi

if [ "x$WORDPRESS_SECURE_AUTH_KEY" == "x" ]; then
  WORDPRESS_SECURE_AUTH_KEY=`pwgen -c -n -1 65`
fi

if [ "x$WORDPRESS_LOGGED_IN_KEY" == "x" ]; then
  WORDPRESS_LOGGED_IN_KEY=`pwgen -c -n -1 65`
fi

if [ "x$WORDPRESS_NONCE_KEY" == "x" ]; then
  WORDPRESS_NONCE_KEY=`pwgen -c -n -1 65`
fi

if [ "x$WORDPRESS_AUTH_SALT" == "x" ]; then
  WORDPRESS_AUTH_SALT=`pwgen -c -n -1 65`
fi

if [ "x$WORDPRESS_SECURE_AUTH_SALT" == "x" ]; then
  WORDPRESS_SECURE_AUTH_SALT=`pwgen -c -n -1 65`
fi

if [ "x$WORDPRESS_LOGGED_IN_SALT" == "x" ]; then
  WORDPRESS_LOGGED_IN_SALT=`pwgen -c -n -1 65`
fi

if [ "x$WORDPRESS_NONCE_SALT" == "x" ]; then
  WORDPRESS_NONCE_SALT=`pwgen -c -n -1 65`
fi

# Create the WP config file from scratch at each boot to ensure best update from env variables.
sed -e "s/database_name_here/$WORDPRESS_DB_NAME/
  s/localhost/$WORDPRESS_DB_HOST/
  s/username_here/$WORDPRESS_DB_USER/
  s/password_here/$WORDPRESS_DB_PASS/
  /^.table_prefix/s/wp_/$WORDPRESS_DB_PRFX/
  /'AUTH_KEY'/s/put your unique phrase here/$WORDPRESS_AUTH_KEY/
  /'SECURE_AUTH_KEY'/s/put your unique phrase here/$WORDPRESS_SECURE_AUTH_KEY/
  /'LOGGED_IN_KEY'/s/put your unique phrase here/$WORDPRESS_LOGGED_IN_KEY/
  /'NONCE_KEY'/s/put your unique phrase here/$WORDPRESS_NONCE_KEY/
  /'AUTH_SALT'/s/put your unique phrase here/$WORDPRESS_AUTH_SALT/
  /'SECURE_AUTH_SALT'/s/put your unique phrase here/$WORDPRESS_SECURE_AUTH_SALT/
  /'LOGGED_IN_SALT'/s/put your unique phrase here/$WORDPRESS_LOGGED_IN_SALT/
  /'NONCE_SALT'/s/put your unique phrase here/$WORDPRESS_NONCE_SALT/" /usr/share/nginx/www/wp-config-sample.php > /usr/share/nginx/www/wp-config.php

# Download plugins
if [ "x$WORDPRESS_PLUGINS" == "x" ]; then
  plugins=(nginx-helper wordfence jetpack akismet wp-dbmanager nextgen-gallery)
else
  IFS=',' read -r -a plugins <<< "$WORDPRESS_PLUGINS"
fi

for plugin in "${plugins[@]}"
do
  /wpdl.sh plugin $plugin
done

# Download themes
if [ "x$WORDPRESS_THEMES" == "x" ]; then
  themes=(twentyten twentyeleven twentytwelve twentythirteen twentyfourteen twentyfifteen twentysixteen twentyseventeen)
else
  IFS=',' read -r -a themes <<< "$WORDPRESS_THEMES"
fi

for theme in "${themes[@]}"
do
  /wpdl.sh theme $theme
done

su -c "/usr/local/bin/wp plugin update --all --path='/usr/share/nginx/www'" www-data
su -c "/usr/local/bin/wp theme update --all --path='/usr/share/nginx/www'" www-data

# Support migrating over to WPMU
if [ "$WORDPRESS_MU_ENABLED" == "true" ]; then
  cat << ENDL >> /usr/share/nginx/www/wp-config.php

  /* Multisite */
  define( 'WP_ALLOW_MULTISITE', true );

ENDL
fi

# Support test site URL overriding
if [ "x$WORDPRESS_URL" != "x" ]; then
  cat << ENDL >> /usr/share/nginx/www/wp-config.php

  /* Hardcode site URLs */
  define( 'WP_HOME', "$WORDPRESS_URL" );
  define( 'WP_SITEURL', "$WORDPRESS_URL" );

ENDL
fi

# Enable debug logging upon request via env variable
if [ "x$WORDPRESS_DEBUG" != "x" ]; then
  cat << ENDL >> /usr/share/nginx/www/wp-config.php
  // Debug settings
  define('WP_DEBUG', true);
  define('WP_DEBUG_LOG', true);
  define('WP_DEBUG_DISPLAY', false);
  define('SCRIPT_DEBUG', false);
  define('SAVEQUERIES', false);
  @ini_set('display_errors', 0);
ENDL
fi

# Disable automatic updates
cat << ENDL >> /usr/share/nginx/www/wp-config.php
  define( 'WP_AUTO_UPDATE_CORE', false );
ENDL

chown www-data:www-data /usr/share/nginx/www/wp-config.php

touch /var/log/php-fpm.log

# start all the services
/usr/local/bin/supervisord -n -c /etc/supervisord.conf
