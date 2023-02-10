FROM perl:latest

RUN cpanm Carton

ARG APP_DIR=/usr/local/fnff
RUN mkdir -p $APP_DIR

WORKDIR $APP_DIR

COPY cpanfile* $APP_DIR
RUN carton install

RUN apt update && apt upgrade -yyq
RUN apt install python

COPY ./ $APP_DIR

ENTRYPOINT ["carton", "exec"]
CMD ["./fnff.pl"]
