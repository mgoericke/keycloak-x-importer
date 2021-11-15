#!/bin/bash

echo "[+] waiting for keycloak to start"
# simply wait until the master realm is available
/opt/jboss/keycloak/wait-for.sh "curl --fail --silent http://localhost:8080/auth/realms/master"

echo "[+] authorize admin user for import"
# authorize admin user
/opt/jboss/keycloak/bin/kcadm.sh config credentials --realm master --user ${KEYCLOAK_ADMIN} --password ${KEYCLOAK_ADMIN_PASSWORD} --server http://localhost:8080/auth

echo "[+] import quarkus realm"
# import the realm config
/opt/jboss/keycloak/bin/kcadm.sh create realms -f /opt/jboss/keycloak/config/quarkus-realm.json --server http://localhost:8080/auth -s enabled=true
