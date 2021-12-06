FROM registry.access.redhat.com/ubi8-minimal AS build-env

ENV KEYCLOAK_VERSION 15.0.2
ARG KEYCLOAK_DIST=https://github.com/keycloak/keycloak/releases/download/$KEYCLOAK_VERSION/keycloak.x-preview-$KEYCLOAK_VERSION.tar.gz

RUN microdnf install -y tar gzip

ADD $KEYCLOAK_DIST /tmp/keycloak/

# The next step makes it uniform for local development and upstream built.
# If it is a local tar archive then it is unpacked, if from remote is just downloaded.
RUN (cd /tmp/keycloak && \
    tar -xvf /tmp/keycloak/keycloak.x*.tar.gz && \
    rm /tmp/keycloak/keycloak.x*.tar.gz) || true

RUN mv /tmp/keycloak/keycloak.x* /opt/keycloak


FROM index.docker.io/appsmith/appsmith-ce

# copy keycloak binary into place
COPY --from=build-env /opt/keycloak /opt/keycloak

# add keycloak supervisord config
COPY ./supervisord/keycloak.conf /opt/appsmith/templates/supervisord/application_process/

# update the nginx conf templates with keycloak ingress
RUN sed -e '/^server {/,/^}/{/^}/i\  location /auth {\n    proxy_pass http://localhost:8180;\n  }' -e '}' /opt/appsmith/templates/nginx-app-http.conf.template.sh > /opt/appsmith/templates/nginx-app-http.conf.template.sh_new && \
  mv /opt/appsmith/templates/nginx-app-http.conf.template.sh_new /opt/appsmith/templates/nginx-app-http.conf.template.sh && \
  sed -e '/^server {/,/^}/{/^}/i\  location /auth {\n    proxy_pass http://localhost:8180;\n  }' -e '}' /opt/appsmith/templates/nginx-app-https.conf.template.sh > /opt/appsmith/templates/nginx-app-https.conf.template.sh_new && \
  mv /opt/appsmith/templates/nginx-app-https.conf.template.sh_new /opt/appsmith/templates/nginx-app-https.conf.template.sh && \
  mkdir -p /opt/keycloak/logs

# TODO add phasetwo ear, jars, theme and cli startup scripts

# Temporarily expose keycloak directly for debugging
EXPOSE 8180

# no entrypoint required. supervisord takes care of this
#ENTRYPOINT [ "/opt/keycloak/bin/kc.sh" ]
