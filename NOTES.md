# Nextcloud Notes

## Webfinger and Social

Webfinger will only produce results when Social is active.

To test (Nextcloud)

    curl -v -H "Accept: application/json" \
    'http://192.168.138.131/public.php?service=webfinger&resource=acct%3aadmin%40localhost'

To test (UBOS merge)

    curl -v -H "Accept: application/json" \
    'http://192.168.138.131/.well-known/webfinger?resource=acct%3aadmin%40localhost'

## Logging

In the config file:

    "loglevel" => "0",

where 0: debug; 1: info; 2: warn; 3: error; 4: fatal

In the code:

    \OC::$server->getLogger()->XXX( msg )

where XXX is one of error, warning, notice, info, debug.


## Social

It's a moving target; needs to mature more before we can do a lot on the UBOS side.

## Annotated `.htaccess` file

This `.htaccess` file was created from a Nextcloud 26 / 29 deployment at the / context
(only minor differences) with:

```
sudo -u http php ./occ maintenance:update:htaccess
```

There are in-line annotations for how we transform it into what we use with UBOS:


```
<IfModule mod_headers.c>
```

`mod_headers` is always on (Nextcloud `ubos-manifest.json` file)

The following section does not apply. We don't use any of those APIs:

```
  <IfModule mod_setenvif.c>
    <IfModule mod_fcgid.c>
       SetEnvIfNoCase ^Authorization$ "(.+)" XAUTHORIZATION=$1
       RequestHeader set XAuthorization %{XAUTHORIZATION}e env=XAUTHORIZATION
    </IfModule>
    <IfModule mod_proxy_fcgi.c>
       SetEnvIfNoCase Authorization "(.+)" HTTP_AUTHORIZATION=$1
    </IfModule>
    <IfModule mod_lsapi.c>
      SetEnvIfNoCase ^Authorization$ "(.+)" XAUTHORIZATION=$1
      RequestHeader set XAuthorization %{XAUTHORIZATION}e env=XAUTHORIZATION
    </IfModule>
  </IfModule>

  <IfModule mod_env.c>
```

`mod_env` is always on (Nextcloud `ubos-manifest.json` file). So we want
the following section:

```
    # Add security and privacy related headers

    # Avoid doubled headers by unsetting headers in "onsuccess" table,
    # then add headers to "always" table: https://github.com/nextcloud/server/pull/19002
    Header onsuccess unset Referrer-Policy
    Header always set Referrer-Policy "no-referrer"

    Header onsuccess unset X-Content-Type-Options
    Header always set X-Content-Type-Options "nosniff"

    Header onsuccess unset X-Frame-Options
    Header always set X-Frame-Options "SAMEORIGIN"

    Header onsuccess unset X-Permitted-Cross-Domain-Policies
    Header always set X-Permitted-Cross-Domain-Policies "none"

    Header onsuccess unset X-Robots-Tag
    Header always set X-Robots-Tag "noindex, nofollow"

    Header onsuccess unset X-XSS-Protection
    Header always set X-XSS-Protection "1; mode=block"

    SetEnv modHeadersAvailable true
  </IfModule>
```

We want the same cache control:

```
  # Add cache control for static resources
  <FilesMatch "\.(css|js|svg|gif|png|jpg|ico|wasm|tflite)$">
    <If "%{QUERY_STRING} =~ /(^|&)v=/">
      Header set Cache-Control "max-age=15778463, immutable"
    </If>
    <Else>
      Header set Cache-Control "max-age=15778463"
    </Else>
  </FilesMatch>

  # Let browsers cache WOFF files for a week
  <FilesMatch "\.woff2?$">
    Header set Cache-Control "max-age=604800"
  </FilesMatch>
</IfModule>
```

We use PHP 8, so we don't use the 7 section but do use the 8 section

```
# PHP 7.x
<IfModule mod_php7.c>
  php_value mbstring.func_overload 0
  php_value default_charset 'UTF-8'
  php_value output_buffering 0
  <IfModule mod_env.c>
    SetEnv htaccessWorking true
  </IfModule>
</IfModule>

# PHP 8+
<IfModule mod_php.c>
  php_value mbstring.func_overload 0
  php_value default_charset 'UTF-8'
  php_value output_buffering 0
  <IfModule mod_env.c>
    SetEnv htaccessWorking true
  </IfModule>
</IfModule>
```

We use mod_mime. We have some of those already, but it doesn't hurt to
keep them.

```
<IfModule mod_mime.c>
  AddType image/svg+xml svg svgz
  AddType application/wasm wasm
  AddEncoding gzip svgz
  # Serve ESM javascript files (.mjs) with correct mime type
  AddType text/javascript js mjs
</IfModule>
```

We already do this:

```
<IfModule mod_dir.c>
  DirectoryIndex index.php index.html
</IfModule>
```

We don't know whether we will have this module, so we keep this in:

```
<IfModule pagespeed_module>
  ModPagespeed Off
</IfModule>
```

`mod_rewrite` is always on (Nextcloud `ubos-manifest.json` file).

```
<IfModule mod_rewrite.c>
  RewriteEngine on
  RewriteCond %{HTTP_USER_AGENT} DavClnt
  RewriteRule ^$ /remote.php/webdav/ [L,R=302]
  RewriteRule .* - [env=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
  RewriteRule ^\.well-known/carddav /remote.php/dav/ [R=301,L]
  RewriteRule ^\.well-known/caldav /remote.php/dav/ [R=301,L]
  RewriteRule ^remote/(.*) remote.php [QSA,L]
  RewriteRule ^(?:build|tests|config|lib|3rdparty|templates)/.* - [R=404,L]
  RewriteRule ^\.well-known/(?!acme-challenge|pki-validation) /index.php [QSA,L]
  RewriteRule ^ocm-provider/?$ index.php [QSA,L]
  RewriteRule ^(?:\.(?!well-known)|autotest|occ|issue|indie|db_|console).* - [R=404,L]
</IfModule>
```

The following section we want but need to put outside of the <Directory>

```
# Clients like xDavv5 on Android, or Cyberduck, use chunked requests.
# When FastCGI or FPM is used with apache, requests arrive to Nextcloud without any content.
# This leads to the creation of empty files.
# The following directive will force the problematic requests to be buffered before being forwarded to Nextcloud.
# This way, the "Transfer-Encoding" header is removed, the "Content-Length" header is set, and the request content is proxied to Nextcloud.
# Here are more information about the issue:
#  - https://docs.cyberduck.io/mountainduck/issues/fastcgi/
#  - https://docs.nextcloud.com/server/latest/admin_manual/issues/general_troubleshooting.html#troubleshooting-webdav
<IfModule setenvif.c>
  <Location "/remote.php">
    SetEnvIf Transfer-Encoding "chunked" proxy-sendcl=1
  </Location>
</IfModule>

AddDefaultCharset utf-8
Options -Indexes
#### DO NOT CHANGE ANYTHING ABOVE THIS LINE ####

ErrorDocument 403 /index.php/error/403
ErrorDocument 404 /index.php/error/404
<IfModule mod_rewrite.c>
  Options -MultiViews
  RewriteRule ^core/js/oc.js$ index.php [PT,E=PATH_INFO:$1]
  RewriteRule ^core/preview.png$ index.php [PT,E=PATH_INFO:$1]
  RewriteCond %{REQUEST_FILENAME} !\.(css|js|mjs|svg|gif|png|html|ttf|woff2?|ico|jpg|jpeg|map|webm|mp4|mp3|ogg|wav|wasm|tflite)$
  RewriteCond %{REQUEST_FILENAME} !/core/ajax/update\.php
  RewriteCond %{REQUEST_FILENAME} !/core/img/(favicon\.ico|manifest\.json)$
  RewriteCond %{REQUEST_FILENAME} !/(cron|public|remote|status)\.php
  RewriteCond %{REQUEST_FILENAME} !/ocs/v(1|2)\.php
  RewriteCond %{REQUEST_FILENAME} !/robots\.txt
  RewriteCond %{REQUEST_FILENAME} !/(ocs-provider|updater)/
  RewriteCond %{REQUEST_URI} !^/\.well-known/(acme-challenge|pki-validation)/.*
  RewriteCond %{REQUEST_FILENAME} !/richdocumentscode(_arm64)?/proxy.php$
  RewriteRule . index.php [PT,E=PATH_INFO:$1]
  RewriteBase /
  <IfModule mod_env.c>
    SetEnv front_controller_active true
    <IfModule mod_dir.c>
      DirectorySlash off
    </IfModule>
  </IfModule>
</IfModule>
```
