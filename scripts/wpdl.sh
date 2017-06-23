#!/bin/bash

download_plugin() {
  old_fdir="/usr/share/nginx/www/wp-content/plugins/$1"
  if [ ! -e $old_fdir ]; then
    # Download plugin
    su -c "/usr/local/bin/wp plugin install $1 --activate --path='/usr/share/nginx/www'" www-data
  fi
}

download_theme() {
  old_fdir="/usr/share/nginx/www/wp-content/themes/$1"
  if [ ! -e $old_fdir ]; then
    # Download plugin
    su -c "/usr/local/bin/wp theme install $1 --activate --path='/usr/share/nginx/www'" www-data
  fi
}

# Ensure requisite parameters are set
if [ "x$1" == "x" ]; then
  echo "Usage: $0 <theme|plugin> <name>"
  exit 1
fi

if [ "x$2" == "x" ]; then
  echo "Usage: $0 <theme|plugin> <name>"
  exit 1
fi

# do the work
if [ "$1" == "theme" ]; then
  download_theme $2
elif [ "$1" == "plugin" ]; then
  download_plugin $2
else
  echo "Usage: $0 <theme|plugin> <name>"
  exit 1
fi
