#!/bin/bash

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

# Download nginx helper plugin
if [ ! -d /usr/share/nginx/www/wp-content/plugins/nginx-helper ]; then
  curl -O `curl -i -s https://wordpress.org/plugins/nginx-helper/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  unzip -o nginx-helper.*.zip -d /usr/share/nginx/www/wp-content/plugins
  chown -R www-data:www-data /usr/share/nginx/www/wp-content/plugins/nginx-helper
fi

# Download WordFence plugin
if [ ! -d /usr/share/nginx/www/wp-content/plugins/wordfence ]; then
  curl -O `curl -i -s https://wordpress.org/plugins/wordfence/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  unzip -o wordfence.*.zip -d /usr/share/nginx/www/wp-content/plugins
  chown -R www-data:www-data /usr/share/nginx/www/wp-content/plugins/wordfence
fi

# Download JetPack plugin
if [ ! -d /usr/share/nginx/www/wp-content/plugins/jetpack ]; then
  curl -O `curl -i -s https://wordpress.org/plugins/jetpack/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  unzip -o jetpack.*.zip -d /usr/share/nginx/www/wp-content/plugins
  chown -R www-data:www-data /usr/share/nginx/www/wp-content/plugins/jetpack
fi

# Download Akismet plugin
if [ ! -d /usr/share/nginx/www/wp-content/plugins/akismet ]; then
  curl -O `curl -i -s https://wordpress.org/plugins/akismet/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  unzip -o akismet.*.zip -d /usr/share/nginx/www/wp-content/plugins
  chown -R www-data:www-data /usr/share/nginx/www/wp-content/plugins/akismet
fi

# Download WP-DBManager plugin
if [ ! -d /usr/share/nginx/www/wp-content/plugins/wp-dbmanager ]; then
  curl -O `curl -i -s https://wordpress.org/plugins/wp-dbmanager/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  unzip -o wp-dbmanager.*.zip -d /usr/share/nginx/www/wp-content/plugins
  chown -R www-data:www-data /usr/share/nginx/www/wp-content/plugins/wp-dbmanager
fi

# Download NextGEN Gallery plugin
if [ ! -d /usr/share/nginx/www/wp-content/plugins/nextgen-gallery ]; then
  curl -O `curl -i -s https://wordpress.org/plugins/nextgen-gallery/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  unzip -o nextgen-gallery.*.zip -d /usr/share/nginx/www/wp-content/plugins
  chown -R www-data:www-data /usr/share/nginx/www/wp-content/plugins/nextgen-gallery
fi

if [ "$WORDPRESS_MU_ENABLED" == "true" ]; then
  cat << ENDL >> /usr/share/nginx/www/wp-config.php

  /* Multisite */
  define( 'WP_ALLOW_MULTISITE', true );

ENDL
fi

# Activate nginx plugin once logged in
cat << ENDL >> /usr/share/nginx/www/wp-config.php
\$plugins = get_option( 'active_plugins' );
if ( count( \$plugins ) === 0 ) {
  require_once(ABSPATH .'/wp-admin/includes/plugin.php');
  \$pluginsToActivate = array( 'nginx-helper/nginx-helper.php',
                               'wordfence/wordfence.php',
                               'jetpack/jetpack.php',
                               'wp-dbmanager/wp-dbmanager.php',
                               'nextgen-gallery/nggallery.php',
                               'akismet/akismet.php' );
  foreach ( \$pluginsToActivate as \$plugin ) {
    if ( !in_array( \$plugin, \$plugins ) ) {
      activate_plugin( '/usr/share/nginx/www/wp-content/plugins/' . \$plugin );
    }
  }
}
ENDL

chown www-data:www-data /usr/share/nginx/www/wp-config.php

touch /var/log/php-fpm.log

# start all the services
/usr/local/bin/supervisord -n -c /etc/supervisord.conf
