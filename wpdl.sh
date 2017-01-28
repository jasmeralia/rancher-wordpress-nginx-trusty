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

if [ "x$1" == "x" || "x$2" == "x" ]; then
  echo "Usage: $0 <theme|plugin> <name>"
  exit 1
fi

if [ $1 == "theme" ]; then
  download_theme $2
elif [ $1 == "plugin" ]; then
  download_plugin $2
else
  echo "Usage: $0 <theme|plugin> <name>"
  exit 1
fi
