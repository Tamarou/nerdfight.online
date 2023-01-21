FROM hexpm/elixir:1.14.2-erlang-25.0.4-alpine-3.17.0 as builder

ENV MIX_ENV=prod

ARG BRANCH=stable

RUN apk update \
    && apk add git gcc g++ musl-dev make cmake file-dev pandoc

RUN git clone -b "${BRANCH}" --depth=1 https://akkoma.dev/AkkomaGang/akkoma.git

WORKDIR /akkoma

COPY ./prod.secret.exs config/prod.secret.exs

RUN mix local.hex --force &&\
    mix local.rebar --force &&\
    mix deps.get --only ${MIX_ENV} &&\
    mkdir release &&\
    mix release --path release

COPY ./tos.md tos.md
RUN pandoc -o tos.html tos.md

FROM alpine:3.17.0 as final

ENV UID=911 GID=911

ARG HOME=/opt/akkoma
ARG DATA=/var/lib/akkoma

RUN addgroup -g ${GID} akkoma &&\
    adduser --system --shell /bin/false --home ${HOME} -D -G akkoma -u ${UID} akkoma

RUN apk update &&\
    apk add exiftool ffmpeg imagemagick libmagic ncurses postgresql-client su-exec shadow curl &&\
    mkdir -p ${DATA}/uploads &&\
    mkdir -p ${DATA}/static &&\
    chown -R akkoma:akkoma ${DATA} &&\
    mkdir -p ${HOME}/config &&\
    chown -R akkoma:akkoma ${HOME} &&\
    mkdir -p /etc/akkoma &&\
    chown -R akkoma:akkoma /etc/akkoma

USER akkoma

COPY --from=builder --chown=akkoma /akkoma/config/docker.exs /etc/akkoma/config.exs
COPY --from=builder --chown=akkoma /akkoma/config/prod.secret.exs /var/lib/akkoma/config.exs
COPY --from=builder --chown=akkoma /akkoma/release ${HOME}
COPY --chown=akkoma docker-entrypoint.sh ${HOME}
COPY --chown=akkoma favicon.png ${DATA}/static/favicon.png
COPY --from=builder --chown=akkoma /akkoma/tos.html ${DATA}/static/tos.html

RUN curl -L https://akkoma-updates.s3-website.fr-par.scw.cloud/frontend/stable/admin-fe.zip --output ${DATA}/admin-fe.zip &&\
    mkdir -p ${DATA}/static/frontends/admin-fe &&\
    unzip -d ${DATA}/static/frontends/admin-fe ${DATA}/admin-fe.zip &&\
    mv ${DATA}/static/frontends/admin-fe/dist ${DATA}/static/frontends/admin-fe/stable &&\
    rm ${DATA}/admin-fe.zip

RUN curl -L https://akkoma-updates.s3-website.fr-par.scw.cloud/frontend/stable/akkoma-fe.zip --output ${DATA}/akkoma-fe.zip &&\
    mkdir -p ${DATA}/static/frontends/pleroma-fe &&\
    unzip -d ${DATA}/static/frontends/pleroma-fe ${DATA}/akkoma-fe.zip &&\
    mv ${DATA}/static/frontends/pleroma-fe/dist ${DATA}/static/frontends/pleroma-fe/stable &&\
    rm ${DATA}/akkoma-fe.zip

EXPOSE 4000

ENTRYPOINT ["/opt/akkoma/docker-entrypoint.sh"]

