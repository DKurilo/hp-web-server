FROM fpco/stack-build:lts-16.10 as build

RUN mkdir /opt/build /opt/app
COPY . /opt/build

VOLUME /tmp/stackroot

RUN cd /opt/build && stack --stack-root=/tmp/stackroot build --system-ghc --copy-bins --local-bin-path /opt/app

FROM fpco/pid1
RUN mkdir -p /opt/app
ARG BINARY_PATH
WORKDIR /opt/app

RUN apt-get update && apt-get install -y \
  ca-certificates \
  libgmp-dev

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

COPY --from=build /opt/app .

CMD ["/opt/app/page-builder"]
