FROM ubuntu:latest

COPY test.sh /test.sh

RUN chown :1000 /test.sh && chmod 750 /test.sh

USER nonroot:nonroot

CMD ["/test.sh"]
