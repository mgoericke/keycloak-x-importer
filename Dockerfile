FROM quay.io/keycloak/keycloak-x

LABEL maintainer=mark@javamark.de
LABEL "build.command"="docker build -t javamark/keycloak-x ."

# Keycloak admin
ENV KEYCLOAK_ADMIN=admin
ENV KEYCLOAK_ADMIN_PASSWORD=admin

# Keycloak database configuration
ENV DB_VENDOR=h2

WORKDIR /opt/jboss/keycloak

# self signed certificate
RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=dev-server" -alias server -ext "SAN=DNS:dev-server" -keystore conf/server.keystore

# COPY realms
COPY config config
COPY entrypoint-wrapper.sh entrypoint-wrapper.sh
COPY import-realms.sh import-realms.sh
COPY wait-for.sh wait-for.sh


# -Dquarkus.http.root-path=/auth -> missing /auth root path fix (backward compatibility)
# --http-enabled=true -> HEALTHCHECK
RUN ./bin/kc.sh config \
    --http-enabled=true \
    --spi-theme-static-max-age=-1 \
    --db-username=sa \
    --db-password=keycloak \
    --cluster=local \
    -Dquarkus.http.root-path=/auth

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 CMD curl --fail http://localhost:8080/auth/realms/quarkus

# overwrite Entrypoint
ENTRYPOINT "./entrypoint-wrapper.sh"
