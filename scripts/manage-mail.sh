#!/bin/bash

# Fungsi untuk menambah domain baru
add_domain() {
    local DOMAIN=$1
    docker exec infrastructure_postfixadmin php /var/www/html/scripts/postfixadmin-cli domain add $DOMAIN
    echo "Domain $DOMAIN added to mail server"
}

# Fungsi untuk menambah mailbox baru
add_mailbox() {
    local EMAIL=$1
    local PASSWORD=$2
    local NAME=$3
    
    docker exec infrastructure_postfixadmin php /var/www/html/scripts/postfixadmin-cli mailbox add \
        $EMAIL \
        --password $PASSWORD \
        --password2 $PASSWORD \
        --name "$NAME"
    echo "Mailbox $EMAIL created"
}

# Fungsi untuk generate DKIM keys
generate_dkim() {
    local DOMAIN=$1
    mkdir -p docker/rspamd/conf/dkim
    openssl genrsa -out docker/rspamd/conf/dkim/${DOMAIN}.private.key 2048
    openssl rsa -in docker/rspamd/conf/dkim/${DOMAIN}.private.key -pubout -out docker/rspamd/conf/dkim/${DOMAIN}.public.key
    
    echo "DKIM keys generated for $DOMAIN"
    echo "Add this TXT record to your DNS:"
    echo "mail._domainkey.$DOMAIN IN TXT \"v=DKIM1; k=rsa; p=$(cat docker/rspamd/conf/dkim/${DOMAIN}.public.key | grep -v '^-' | tr -d '\n')\""
}

# CLI Menu
case "$1" in
    add-domain)
        add_domain "$2"
        ;;
    add-mailbox)
        add_mailbox "$2" "$3" "$4"
        ;;
    setup-dkim)
        generate_dkim "$2"
        ;;
    *)
        echo "Usage:"
        echo "  $0 add-domain <domain.com>"
        echo "  $0 add-mailbox <user@domain.com> <password> <Full Name>"
        echo "  $0 setup-dkim <domain.com>"
        exit 1
        ;;
esac