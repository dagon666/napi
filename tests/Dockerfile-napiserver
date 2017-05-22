FROM python:2.7

ENV NAPISERVER_HOME /home/napiserver
ENV NAPISERVER_OPT /opt/napiserver
ENV NAPISERVER_SHARE $NAPISERVER_OPT/share
ENV NAPISERVER_PORT 8000
ENV INSTALL_DIR /tmp/install

EXPOSE $NAPISERVER_PORT

# napiserver specific
ADD napiserver $INSTALL_DIR/napiserver
WORKDIR $INSTALL_DIR
RUN ./napiserver/bin/prepare_pretenders.sh

ENTRYPOINT ["python", "-m", "pretenders.server.server", "--host", "0.0.0.0"]
CMD ["--port", "8000"]
