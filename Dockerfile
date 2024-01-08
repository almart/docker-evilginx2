FROM golang:alpine

ARG BUILD_RFC3339="1970-01-01T00:00:00Z"
ARG COMMIT="local"
ARG VERSION="v3.2.0"

ENV GITHUB_USER="kgretzky"
ENV EVILGOPHISH_USER="fin3ss3g0d"
ENV EVILGINX_REPOSITORY="github.com/${GITHUB_USER}/evilginx2"
ENV INSTALL_PACKAGES="git make gcc musl-dev go"
ENV PROJECT_DIR="${GOPATH}/src/${EVILGINX_REPOSITORY}"
ENV EVILGINX_BIN="/bin/evilginx"

RUN mkdir -p ${GOPATH}/src/github.com/${GITHUB_USER} \
    && mkdir -p ${GOPATH}/src/github.com/${EVILGOPHISH_USER} \
    && apk add --no-cache ${INSTALL_PACKAGES} \
    && git -C ${GOPATH}/src/github.com/${GITHUB_USER} clone https://github.com/${GITHUB_USER}/evilginx2 \
    && git -C ${GOPATH}/src/github.com/${EVILGOPHISH_USER} clone https://github.com/${EVILGOPHISH_USER}/evilgophish

RUN cp -r ${GOPATH}/src/github.com/${EVILGOPHISH_USER}/evilginx3/Core/. ${GOPATH}/src/github.com/${GITHUB_USER}/evilginx2/Core \
    && cp -r ${GOPATH}/src/github.com/${EVILGOPHISH_USER}/evilginx3/Database/. ${GOPATH}/src/github.com/${GITHUB_USER}/evilginx2/Database \
    && cp -r ${GOPATH}/src/github.com/${EVILGOPHISH_USER}/evilginx3/Log/. ${GOPATH}/src/github.com/${GITHUB_USER}/evilginx2/Log \
    && cp -r ${GOPATH}/src/github.com/${EVILGOPHISH_USER}/evilginx3/Media/Img/. ${GOPATH}/src/github.com/${GITHUB_USER}/evilginx2/Media/Img \
    && cp -r ${GOPATH}/src/github.com/${EVILGOPHISH_USER}/evilginx3/parser/. ${GOPATH}/src/github.com/${GITHUB_USER}/evilginx2/parser \
    && cp -r ${GOPATH}/src/github.com/${EVILGOPHISH_USER}/evilginx3/redirectors/. ${GOPATH}/src/github.com/${GITHUB_USER}/evilginx2/redirectors \
    && cp -r ${GOPATH}/src/github.com/${EVILGOPHISH_USER}/evilginx3/vendor/. ${GOPATH}/src/github.com/${GITHUB_USER}/evilginx2/vendor

RUN set -ex \
        && cd ${PROJECT_DIR}/ && go get ./... && make \
		&& cp ${PROJECT_DIR}/build/evilginx ${EVILGINX_BIN} \
		&& apk del ${INSTALL_PACKAGES} && rm -rf /var/cache/apk/* && rm -rf ${GOPATH}/src/*

COPY ./docker-entrypoint.sh /opt/
RUN chmod +x /opt/docker-entrypoint.sh
		
ENTRYPOINT ["/opt/docker-entrypoint.sh"]
EXPOSE 443

STOPSIGNAL SIGKILL

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.name="Evilginx2 Docker" \
  org.label-schema.description="Evilginx2 Docker Build" \
  org.label-schema.url="https://github.com/almart/docker-evilginx2" \
  org.label-schema.vcs-ref=$VCS_REF \
  org.label-schema.vcs-url="https://github.com/almart/docker-evilginx2" \
  org.label-schema.vendor="warhorse" \
  org.label-schema.version=$VERSION \
  org.label-schema.schema-version="1.0"
