#!/bin/bash

download_plugin() {
  # Download nginx helper plugin
  curl -O `curl -i -s https://wordpress.org/plugins/$1/ | egrep -o "https://downloads.wordpress.org/plugin/[^']+"`
  if [ $? -eq 0 ]; then
    new_fname=`ls $1.*.zip`
    new_sha=`sha256sum $new_fname| awk '{print $1}'`
    old_fname=`ls /usr/share/nginx/www/wp-content/plugin-downloads/$1.*.zip`
    if [ $? -ne 0 ]; then
      cp $new_fname /usr/share/nginx/www/wp-content/plugin-downloads/
      old_fname="/usr/share/nginx/www/wp-content/plugin-downloads/$new_fname"
      old_sha="x"
    else
      old_sha=`sha256sum $old_fname| awk '{print $1}'`
    fi
    if [ "$old_sha" == "$new_sha" ]; then
      echo "Old version of $1 is already installed (plugin zip files match)"
      #rm -f $new_fname
    else
      rm -rf /usr/share/nginx/www/wp-content/plugins-new/$1
      unzip -o $new_fname -d /usr/share/nginx/www/wp-content/plugins-new
      if [ $? -eq 0 ]; then
        diff -r /usr/share/nginx/www/wp-content/plugins-new/$1 /usr/share/nginx/www/wp-content/plugins/$1
        if [ $? -eq 0 ]; then
          # No difference in unzipped files
          echo "Old version of $1 is already installed (unzipped directories match)"
          #rm -f $new_fname
        else
          rm -f $old_fname
          mv $new_fname /usr/share/nginx/www/wp-content/plugin-downloads/
          rm -rf /usr/share/nginx/www/wp-content/plugins/$1
          mv /usr/share/nginx/www/wp-content/plugins-new/$1 /usr/share/nginx/www/wp-content/plugins/$1
        fi
      else
        rm -f $new_fname
        rm -rf /usr/share/nginx/www/wp-content/plugins/$1
        rm -rf /usr/share/nginx/www/wp-content/plugins-new/$1
        unzip -o $old_fname -d /usr/share/nginx/www/wp-content/plugins
      fi
    fi
  fi
  chown -R www-data:www-data /usr/share/nginx/www/wp-content/plugins/$1
}

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

mkdir /usr/share/nginx/www/wp-content/plugins-new
mkdir /usr/share/nginx/www/wp-content/plugin-downloads

# Download plugins
download_plugin nginx-helper
download_plugin wordfence
download_plugin jetpack
download_plugin akismet
download_plugin wp-dbmanager
download_plugin nextgen-gallery

# Support migrating over to WPMU
if [ "$WORDPRESS_MU_ENABLED" == "true" ]; then
  cat << ENDL >> /usr/share/nginx/www/wp-config.php

  /* Multisite */
  define( 'WP_ALLOW_MULTISITE', true );

ENDL
fi

# Activate plugins once logged in
cat << ENDL >> /usr/share/nginx/www/wp-config.php
\$plugins = get_option( 'active_plugins' );
if ( count( \$plugins ) === 0 ) {
  require_once(ABSPATH .'/wp-admin/includes/plugin.php');
  \$pluginsToActivate = array( 'nginx-helper/nginx-helper.php',
                               'wordfence/wordfence.php',
                               'jetpack/jetpack.php',
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
