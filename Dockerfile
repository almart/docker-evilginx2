FROM golang:alpine

ARG BUILD_RFC3339="1970-01-01T00:00:00Z"
ARG COMMIT="local"
ARG VERSION="v3.3.0"
ARG GOPATH=/opt/go
ENV GITHUB_USER="kgretzky"
ENV EVILGINX_REPOSITORY="github.com/${GITHUB_USER}/evilginx2"
ENV INSTALL_PACKAGES="git make gcc musl-dev go"
ENV PROJECT_DIR="${GOPATH}/src/${EVILGINX_REPOSITORY}"
ENV EVILGINX_BIN="/bin/evilginx"
ARG ORGANISATION_NAME="DenSecure"
ARG COMMON_NAME="DenSecure CA"

RUN mkdir -p ${GOPATH}/src/github.com/${GITHUB_USER} \
    && apk add --no-cache ${INSTALL_PACKAGES} \
    && git -C ${GOPATH}/src/github.com/${GITHUB_USER} clone https://github.com/${GITHUB_USER}/evilginx2

RUN  cd ${GOPATH}/src/github.com/${GITHUB_USER}/evilginx2  && git checkout edadd52
	

# Remove IOCs
## Remove the Evilginx3 header
RUN set -ex \
    && sed -i -e 's/req.Header.Set(p.getHomeDir(), o_host)/\/\/req.Header.Set(p.getHomeDir(), o_host)/g' ${PROJECT_DIR}/core/http_proxy.go

# Remove IOCs OLD Evilginx2
#RUN set -ex \
#    && sed -i -e 's/egg2 := req.Host/\/\/egg2 := req.Host/g' \
#     -e 's/e_host := req.Host/\/\/e_host := req.Host/g' \
#     -e 's/req.Header.Set(string(hg), egg2)/\/\/req.Header.Set(string(hg), egg2)/g' \
#     -e 's/req.Header.Set(string(e), e_host)/\/\/req.Header.Set(string(e), e_host)/g' \
#     -e 's/p.cantFindMe(req, e_host)/\/\/p.cantFindMe(req, e_host)/g' ${PROJECT_DIR}/core/http_proxy.go
    
## Rename the selfsigned certificate used in developer mode (Thx to @Dreyvor - https://github.com/Dreyvor)
RUN set -ex \
   && sed -i -e "s/Evilginx Signature Trust Co./${ORGANISATION_NAME}/g" \
   -e "s/Evilginx Super-Evil Root CA/${COMMON_NAME}/g" ${PROJECT_DIR}/core/certdb.go

# Add "security" & "tech" TLD
RUN set -ex \
    && sed -i 's/arpa/security\|arpa/g' ${PROJECT_DIR}/core/http_proxy.go

# Add date to EvilGinx3 log
RUN set -ex \
    && sed -i 's/"%02d:%02d:%02d", t.Hour()/"%02d\/%02d\/%04d - %02d:%02d:%02d", t.Day(), int(t.Month()), t.Year(), t.Hour()/g' ${PROJECT_DIR}/log/log.go


RUN cd ${PROJECT_DIR} \
      && go get ./... && make \
		&& cp ${PROJECT_DIR}/build/evilginx ${EVILGINX_BIN} \
		&& apk del ${INSTALL_PACKAGES} && rm -rf /var/cache/apk/* 

# The below comment was used previously for Evilginx2 Phishlet support and to remove IoCs by line. However, can be dangerous to randomly remove lines as code changes we can accidently delete critical HTTP functionality.
# && cd ${PROJECT_DIR}/ && sed -n -e '183p;350p;377,379p;381p;407p;562,566p;580p;1456,1463p' core/http_proxy.go && sed -n -e '993p' core/phishlet.go && sed -i '993s/.*/                re, err := regexp.Compile(d)/' core/phishlet.go && 

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
