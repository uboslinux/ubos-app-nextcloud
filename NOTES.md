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
