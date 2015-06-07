FROM ubuntu:12.04

RUN apt-get update -y
RUN apt-get install -y \
        busybox \
        libssl-dev \
        make \
        bison \
        flex \
        patch \
        shunit2 \
        mplayer2 \
        mediainfo \
        ffmpeg \
        gcc-multilib \
        g++-multilib \
        ncurses-dev \
        libwww-perl \
        original-awk \
        p7zip-full \
        mawk \
        gawk \
        wget \
        automake \
        autoconf \
        make \
        texinfo \
        install-info


ENV VAGRANT_HOME /home/vagrant
ENV VAGRANT_BIN $VAGRANT_HOME/bin

RUN useradd -m -U vagrant
RUN mkdir -p $VAGRANT_BIN
RUN ln -sf /bin/busybox $VAGRANT_BIN

ADD tests/prepare_*.pl /tmp/
RUN chmod +x /tmp/prepare_*.pl

RUN /tmp/prepare_shells.pl
RUN /tmp/prepare_assets.pl
