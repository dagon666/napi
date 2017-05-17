FROM debian

ENV INSTALL_DIR /tmp/napi
ENV NAPI_HOME /home/napi

RUN apt-get update -y
RUN apt-get install -y \
        wget \
        p7zip-full \
        libav-tools \
        mediainfo \
        make \
        cmake

RUN useradd -m -U napi -d $NAPI_HOME
RUN mkdir -p $INSTALL_DIR
WORKDIR $INSTALL_DIR

ADD . $INSTALL_DIR
RUN mkdir -p build && \
        cd build && \
        cmake .. && \
        make && \
        make install

USER napi
ENTRYPOINT ["napi.sh"]
