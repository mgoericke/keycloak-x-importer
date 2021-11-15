# Keycloak.x import realms on startup

Example/workaround how to import a Keycloak realm into a "Keycloak Distribution X" (Keycloak on Quarkus) container.

## Run the example

### Build an image

```
docker build -t javamark/keycloak-x .
```

### Run the container

```
docker run -p 8080:8080 javamark/keycloak-x
```

### Access Admin Console

Open http://localhost:8080/auth/admin/master/console/#/realms/quarkus in a browser and login as admin:admin. 


## How it works

* create a new [Dockerfile](.Dockerfile) (extend the [Keycloak.X Docker Image](https://github.com/keycloak/keycloak-containers/tree/main/server-x) base image)
    * copy the quarkus-realm.json - [security-keycloak-authorization-quickstart](https://github.com/quarkusio/quarkus-quickstarts/tree/main/security-keycloak-authorization-quickstart)
    * copy the helper scripts
        * [entrypoint-wrapper.sh](entrypoint-wrapper.sh) - custom entrypoint script - [Run multiple services in a container](https://docs.docker.com/config/containers/multi-service_container/)
        * import-realms.sh - import realms with `kcadm` - [Keycloak Admin CLI](https://github.com/keycloak/keycloak-documentation/blob/main/server_admin/topics/admin-cli.adoc)
        * wait-for.sh - wait until keycloak is started and the master realm is available
    * run the `kc config` command 
    * add the healthcheck - the container becomes healthy as soon as the **Quarkus** realm is available
    * overwrite the entrypoint script with the custom script


### Dockerfile

```docker
# extend the keycloak-x base image
FROM quay.io/keycloak/keycloak-x

LABEL maintainer=mark@javamark.de
LABEL "build.command"="docker build -t javamark/keycloak-x ."

# Keycloak admin
ENV KEYCLOAK_ADMIN=admin
ENV KEYCLOAK_ADMIN_PASSWORD=admin

# Keycloak database configuration
ENV DB_VENDOR=h2

WORKDIR /opt/jboss/keycloak

# add a self signed certificate - for development only
RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=dev-server" -alias server -ext "SAN=DNS:dev-server" -keystore conf/server.keystore

# COPY config
# copy the realm
COPY config config

# copy the custom entrypoint script
COPY entrypoint-wrapper.sh entrypoint-wrapper.sh

# copy the realm-importer
COPY import-realms.sh import-realms.sh

# copy a helper script
COPY wait-for.sh wait-for.sh

# -Dquarkus.http.root-path=/auth -> missing /auth root path fix (backward compatibility)
# --http-enabled=true -> HEALTHCHECK and import-realms.sh
RUN ./bin/kc.sh config \
    --http-enabled=true \
    --spi-theme-static-max-age=-1 \
    --db-username=sa \
    --db-password=keycloak \
    --cluster=local \
    -Dquarkus.http.root-path=/auth

# Healthcheck
# keycloak becomes "healthy" as soon as the quarkus realm is available
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 CMD curl --fail http://localhost:8080/auth/realms/quarkus

# overwrite entrypoint with the custom entrypoint script
ENTRYPOINT "./entrypoint-wrapper.sh"

```

---
# References

* Entrypoint wrapper script source:
https://docs.docker.com/config/containers/multi-service_container/
* Realm config source:
https://github.com/quarkusio/quarkus-quickstarts/tree/main/security-keycloak-authorization-quickstart
* Keycloak Admin CLI: https://github.com/keycloak/keycloak-documentation/blob/main/server_admin/topics/admin-cli.adoc
