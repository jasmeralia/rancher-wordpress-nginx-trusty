#!/bin/bash
if [ "x$1" == "x" ]; then
  DELIM=": "
else
  DELIM="="
fi
echo "WORDPRESS_AUTH_KEY$DELIM`pwgen -c -n -1 65`"
echo "WORDPRESS_SECURE_AUTH_KEY$DELIM`pwgen -c -n -1 65`"
echo "WORDPRESS_LOGGED_IN_KEY$DELIM`pwgen -c -n -1 65`"
echo "WORDPRESS_NONCE_KEY$DELIM`pwgen -c -n -1 65`"
echo "WORDPRESS_AUTH_SALT$DELIM`pwgen -c -n -1 65`"
echo "WORDPRESS_SECURE_AUTH_SALT$DELIM`pwgen -c -n -1 65`"
echo "WORDPRESS_LOGGED_IN_SALT$DELIM`pwgen -c -n -1 65`"
echo "WORDPRESS_NONCE_SALT$DELIM`pwgen -c -n -1 65`"
