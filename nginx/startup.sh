#!/bin/bash

#
# Generate the root signing certificate if it doesn't exist:
#
# Note: Locally trust the certificate by importing rootCA.pem into your Keychain Access
# and enable Always Trust on that certificate.
#
if [ ! -f /etc/nginx/ssl/rootCA.key ]; then
  openssl genrsa -out "/etc/nginx/ssl/rootCA.key" 2048
  openssl req -x509 -new -nodes -key "/etc/nginx/ssl/rootCA.key" -sha256 -days 1024 -out "/etc/nginx/ssl/rootCA.pem" -subj "/CN=default/O=default/C=UK"
  chmod 644 /etc/nginx/ssl/rootCA.key
fi

#
# Generate the SSL certificate for https://wefix.test
# If you want to add more subdomains to this then update the wefix.test.v3.ext file to
# add more entries under the alt_names section.
#
# Note the nginx config for wefix.test should have the following entires:
#
# ssl_certificate /etc/nginx/ssl/wefix.test/server.crt;
# ssl_certificate_key /etc/nginx/ssl/wefix.test/server.key;
#
if [ ! -d /etc/nginx/ssl/wefix.test ]; then
  mkdir /etc/nginx/ssl/wefix.test
  openssl req -new -sha256 -nodes -out "/etc/nginx/ssl/wefix.test/server.csr" -newkey rsa:2048 -keyout "/etc/nginx/ssl/wefix.test/server.key" -config "/opt/server.csr.cnf"
  openssl x509 -req -in "/etc/nginx/ssl/wefix.test/server.csr" -CA "/etc/nginx/ssl/rootCA.pem" -CAkey "/etc/nginx/ssl/rootCA.key" -CAcreateserial -out "/etc/nginx/ssl/wefix.test/server.crt" -days 500 -sha256 -extfile "/opt/wefix.test.v3.ext"
fi

#
# Generate Default nginx certificate if it doesn't exist:
#
if [ ! -f /etc/nginx/ssl/default.crt ]; then
    openssl genrsa -out "/etc/nginx/ssl/default.key" 2048
    openssl req -new -key "/etc/nginx/ssl/default.key" -out "/etc/nginx/ssl/default.csr" -subj "/CN=default/O=default/C=UK"
    openssl x509 -req -days 365 -in "/etc/nginx/ssl/default.csr" -signkey "/etc/nginx/ssl/default.key" -out "/etc/nginx/ssl/default.crt"
    chmod 644 /etc/nginx/ssl/default.key
fi

# Start crond in background
crond -l 2 -b

# Start nginx in foreground
nginx
