# Nextcloud Notes

## Webfinger and Social

Webfinger will only produce results when Social is active.

To test (Nextcloud)

    curl -v -H "Accept: application/json" \
    'http://192.168.138.131/public.php?service=webfinger&resource=acct%3aadmin%40localhost'

To test (UBOS merge)

    curl -v -H "Accept: application/json" \
    'http://192.168.138.131/.well-known/webfinger?resource=acct%3aadmin%40localhost'
