#!/bin/bash

download_plugin() {
  # Download plugins
  echo "Downloading plugin $1..."
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
          echo "Old version of $1 is already installed (unzipped plugin directories match)"
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

download_theme() {
  # Download theme
  echo "Downloading theme $1..."
  curl -O `curl -i -s https://wordpress.org/themes/$1/ | egrep -o "https://downloads.wordpress.org/theme/$1[^']+.zip"`
  if [ $? -eq 0 ]; then
    new_fname=`ls $1.*.zip`
    new_sha=`sha256sum $new_fname| awk '{print $1}'`
    old_fname=`ls /usr/share/nginx/www/wp-content/theme-downloads/$1.*.zip`
    if [ $? -ne 0 ]; then
      cp $new_fname /usr/share/nginx/www/wp-content/theme-downloads/
      old_fname="/usr/share/nginx/www/wp-content/theme-downloads/$new_fname"
      old_sha="x"
    else
      old_sha=`sha256sum $old_fname| awk '{print $1}'`
    fi
    if [ "$old_sha" == "$new_sha" ]; then
      echo "Old version of $1 is already installed (theme zip files match)"
      #rm -f $new_fname
    else
      rm -rf /usr/share/nginx/www/wp-content/themes-new/$1
      unzip -o $new_fname -d /usr/share/nginx/www/wp-content/themes-new
      if [ $? -eq 0 ]; then
        diff -r /usr/share/nginx/www/wp-content/themes-new/$1 /usr/share/nginx/www/wp-content/themes/$1
        if [ $? -eq 0 ]; then
          # No difference in unzipped files
          echo "Old version of $1 is already installed (unzipped theme directories match)"
          #rm -f $new_fname
        else
          rm -f $old_fname
          mv $new_fname /usr/share/nginx/www/wp-content/theme-downloads/
          rm -rf /usr/share/nginx/www/wp-content/themes/$1
          mv /usr/share/nginx/www/wp-content/themes-new/$1 /usr/share/nginx/www/wp-content/themes/$1
        fi
      else
        rm -f $new_fname
        rm -rf /usr/share/nginx/www/wp-content/themes/$1
        rm -rf /usr/share/nginx/www/wp-content/themes-new/$1
        unzip -o $old_fname -d /usr/share/nginx/www/wp-content/themes
      fi
    fi
  fi
  chown -R www-data:www-data /usr/share/nginx/www/wp-content/themes/$1
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

# Download plugins
mkdir /usr/share/nginx/www/wp-content/plugins-new
mkdir /usr/share/nginx/www/wp-content/plugin-downloads
if [ "x$WORDPRESS_PLUGINS" == "x" ]; then
  plugins=(nginx-helper wordfence jetpack akismet wp-dbmanager nextgen-gallery)
else
  IFS=',' read -r -a plugins <<< "$WORDPRESS_PLUGINS"
fi

for plugin in "${plugins[@]}"
do
  download_plugin $plugin
done

# Download plugins
mkdir /usr/share/nginx/www/wp-content/themes-new
mkdir /usr/share/nginx/www/wp-content/theme-downloads
if [ "x$WORDPRESS_THEMES" == "x" ]; then
  themes=(twentyten twentyeleven twentytwelve twentythirteen twentyfourteen twentyfifteen twentysixteen twentyseventeen)
else
  IFS=',' read -r -a themes <<< "$WORDPRESS_THEMES"
fi

for theme in "${themes[@]}"
do
  download_theme $theme
done

# Support migrating over to WPMU
if [ "$WORDPRESS_MU_ENABLED" == "true" ]; then
  cat << ENDL >> /usr/share/nginx/www/wp-config.php

  /* Multisite */
  define( 'WP_ALLOW_MULTISITE', true );

ENDL
fi

# Activate plugins once logged in
cat << ENDL >> /usr/share/nginx/www/wp-config.php
define( 'WP_AUTO_UPDATE_CORE', false );
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
