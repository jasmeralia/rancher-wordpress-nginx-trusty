#!/bin/bash
if [ ! -f /usr/share/nginx/www/wp-content/wp-config.php ]; then
  cp /usr/share/nginx/www/wp-content/wp-config.php /usr/share/nginx/www/wp-config.php
  chown www-data:www-data /usr/share/nginx/www/wp-config.php

  # Download nginx helper plugin
  curl -O `curl -i -s https://wordpress.org/plugins/nginx-helper/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  unzip -o nginx-helper.*.zip -d /usr/share/nginx/www/wp-content/plugins
  chown -R www-data:www-data /usr/share/nginx/www/wp-content/plugins/nginx-helper
fi

if [ ! -f /usr/share/nginx/www/wp-config.php ]; then
  # Here we generate random passwords (thank you pwgen!). The first two are for mysql users, the last batch for random keys in wp-config.php
  sed -e "s/database_name_here/$WORDPRESS_DB_NAME/
  s/localhost/$WORDPRESS_DB_HOST/
  s/username_here/$WORDPRESS_DB_USER/
  s/password_here/$WORDPRESS_DB_PASS/
  /'AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'SECURE_AUTH_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'LOGGED_IN_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'NONCE_KEY'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'SECURE_AUTH_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'LOGGED_IN_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/
  /'NONCE_SALT'/s/put your unique phrase here/`pwgen -c -n -1 65`/" /usr/share/nginx/www/wp-config-sample.php > /usr/share/nginx/www/wp-config.php

  # Download nginx helper plugin
  curl -O `curl -i -s https://wordpress.org/plugins/nginx-helper/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  unzip -o nginx-helper.*.zip -d /usr/share/nginx/www/wp-content/plugins
  chown -R www-data:www-data /usr/share/nginx/www/wp-content/plugins/nginx-helper

  # Activate nginx plugin once logged in
  cat << ENDL >> /usr/share/nginx/www/wp-config.php
\$plugins = get_option( 'active_plugins' );
if ( count( \$plugins ) === 0 ) {
  require_once(ABSPATH .'/wp-admin/includes/plugin.php');
  \$pluginsToActivate = array( 'nginx-helper/nginx-helper.php' );
  foreach ( \$pluginsToActivate as \$plugin ) {
    if ( !in_array( \$plugin, \$plugins ) ) {
      activate_plugin( '/usr/share/nginx/www/wp-content/plugins/' . \$plugin );
    }
  }
}
ENDL

  cp /usr/share/nginx/www/wp-config.php /usr/share/nginx/www/wp-content/wp-config.php
  chown www-data:www-data /usr/share/nginx/www/wp-config.php  /usr/share/nginx/www/wp-content/wp-config.php
fi

# start all the services
/usr/local/bin/supervisord -n
