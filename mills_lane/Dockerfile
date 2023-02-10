FROM perl:latest

RUN cpanm Carton

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        carton \
        libssl-dev \
        libzip-dev \
        libpq-dev \
    && apt-get clean

ARG APP_DIR=/usr/local/mills_lane
RUN mkdir -p $APP_DIR

WORKDIR $APP_DIR

COPY cpanfile* $APP_DIR
RUN carton install --deployment

COPY ./ $APP_DIR

ENTRYPOINT ["carton", "exec"]
CMD ["./fnff.pl"]
