FROM alpine:3.9.2

ARG PROJECT=
ARG VERSION=
ARG GIT_SHA=

LABEL PROJECT="${PROJECT}"

RUN apk upgrade --no-cache --update && \
    apk add --no-cache bash && \
    echo "${VERSION} (git-${GIT_SHA})" > "/${PROJECT}-version"

COPY src /bin
ENTRYPOINT ["/bin/kube-watch"]
