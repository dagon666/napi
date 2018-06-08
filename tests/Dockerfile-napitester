FROM ubuntu:16.04

RUN apt-get update -y
RUN apt-get install -y --fix-missing \
        pkg-config
RUN apt-get install -y \
        autoconf \
        automake \
        binutils-dev \
        bison \
        busybox \
        cmake \
        cmake-data \
        flex \
        g++-multilib \
        gawk \
        gcc-multilib \
        gettext \
        install-info \
        libarchive-extract-perl \
        libav-tools \
        libcurl4-openssl-dev \
        libdw-dev \
        libelf-dev \
        libssl-dev \
        libwww-perl \
        make \
        mawk \
        mediainfo \
        mplayer2 \
        ncurses-dev \
        original-awk \
        p7zip-full \
        patch \
        python-minimal \
        python-pip \
        python-setuptools \
        shunit2 \
        sudo \
        texinfo \
        wget \
        zlib1g \
        zlib1g-dev

RUN apt-get install -y \
        jq

# set-up environment
ENV NAPITESTER_HOME /home/napitester
ENV NAPITESTER_BIN $NAPITESTER_HOME/bin
ENV NAPITESTER_OPT /opt/napi
ENV NAPITESTER_TESTDATA $NAPITESTER_OPT/testdata
ENV NAPITESTER_SHELLS $NAPITESTER_OPT/bash
ENV INSTALL_DIR /tmp/install

RUN useradd -m -U napitester -d $NAPITESTER_HOME
RUN usermod -a -G sudo napitester
RUN mkdir -p $INSTALL_DIR

# setup shells and test assets
ADD common $INSTALL_DIR/common
ADD napitester $INSTALL_DIR/napitester
WORKDIR $INSTALL_DIR
RUN ./napitester/bin/prepare_kcov.pl
RUN ./napitester/bin/prepare_scpmocker.pl
RUN ./napitester/bin/prepare_shells.pl $NAPITESTER_SHELLS
RUN ./napitester/bin/prepare_assets.pl $NAPITESTER_TESTDATA

# allow members of sudo group to execute sudo without password
RUN echo "%sudo ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/nopasswd
RUN chmod 0440 /etc/sudoers.d/nopasswd

# switch to test user
WORKDIR $NAPITESTER_HOME
USER napitester
RUN mkdir -p $NAPITESTER_BIN
