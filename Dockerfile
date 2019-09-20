ARG VERSION=latest
FROM ubuntu:$VERSION

MAINTAINER cloudqq <cloudqq@gmail.com>

# Fix "Couldn't register with accessibility bus" error message
ENV NO_AT_BRIDGE=1

ENV DEBIAN_FRONTEND noninteractive

# basic stuff
RUN sed --in-place --regexp-extended "s/archive\.ubuntu/azure\.archive\.ubuntu/g" /etc/apt/sources.list \
  && echo 'APT::Get::Assume-Yes "true";' >> /etc/apt/apt.conf \
  && apt-get update \
  && apt-get install  software-properties-common \
  apt-utils \
  && apt-add-repository ppa:kelleyk/emacs \
  && apt-get update \
  && apt-get install \
  bash \
  build-essential \
  emacs26 \
  emacs26-el \
  dbus-x11 \
  fontconfig \
  git \
  gzip \
  language-pack-en-base \
  libgl1-mesa-glx \
  make \
  cmake \
  sudo \
  tar \
  unzip \
  wget \
  curl \
  rlwrap \
  libboost-dev \
  libboost-filesystem-dev libboost-regex-dev libboost-system-dev libboost-locale-dev \
  libgoogle-glog-dev \
  libgtest-dev \
  libyaml-cpp-dev \
  libleveldb-dev \
  libmarisa-dev \
  doxygen \
  silversearcher-ag \
  zsh \
  gnupg2 \
  msmtp \
  msmtp-mta \
  ca-certificates \
  ttf-mscorefonts-installer \
  fonts-wqy-zenhei \
  fonts-wqy-microhei \
  ttf-wqy-microhei \
  ttf-wqy-zenhei \
  xfonts-wqy \
  libpng-dev \
  libz-dev \
  libpoppler-glib-dev \
  libpoppler-glib-dev \
  libpoppler-private-dev \
  automake \
  fasd \
  isync \
  notmuch \
  # ibus \
  # ibus-clutter \
  # ibus-gtk \
  # ibus-gtk3 \
  # ibus-qt4 \
  # ibus-pinyin \
  # ibus-rime \
  python-gi \
  python3-gi \
  python-xlib \
  net-tools \
  netcat \
  telnet \
# su-exec
    && git clone https://github.com/ncopa/su-exec.git /tmp/su-exec \
    && cd /tmp/su-exec \
    && make \
    && chmod 770 su-exec \
    && mv ./su-exec /usr/local/sbin/ \
# Cleanup
#    && apt-get purge build-essential \
#    && apt-get autoremove \
  && rm -rf /tmp/* /var/lib/apt/lists/* /root/.cache/*

# Manually install libopencc
RUN git clone https://github.com/BYVoid/OpenCC.git
WORKDIR OpenCC/
RUN make
RUN make install

# Fix libgtest problem during compiling
WORKDIR /usr/src/gtest
RUN cmake CMakeLists.txt
RUN make
#copy or symlink libgtest.a and libgtest_main.a to your /usr/lib folder
RUN cp *.a /usr/lib

# Build librime
WORKDIR /
RUN git clone https://github.com/rime/librime.git
WORKDIR librime/
RUN make
RUN make install

RUN curl -fsSL https://git.io/rime-install | bash


COPY asEnvUser /usr/local/sbin/

# Only for sudoers
RUN chown root /usr/local/sbin/asEnvUser \
    && chmod 700  /usr/local/sbin/asEnvUser

# ^^^^^^^ Those layers are shared ^^^^^^^

RUN apt-get update \
    && apt-get install  software-properties-common \
    && apt-get install apt-utils \
    && apt-add-repository ppa:kelleyk/emacs \
    && apt-get update \
    && apt-get install emacs26 emacs26-el \
    && apt-get purge software-properties-common \
  && rm -rf /tmp/* /var/lib/apt/lists/* /root/.cache/*

RUN git clone  https://gitlab.com/liberime/liberime.git
WORKDIR liberime/
RUN make



ENV UNAME="cloudqq" \
    GNAME="cloudqq" \
    UHOME="/home/cloudqq" \
    UID="1000" \
    GID="1000" \
    WORKSPACE="/mnt/workspace" \
    SHELL="/bin/bash"

ENV FONT_HOME="${UHOME}/.local/share/fonts"

RUN mkdir -p "{$FONT_HOME}/adobe-fonts/source-code-pro"

RUN (git clone \
 	--branch release \
	--depth 1 \
	'https://github.com/adobe-fonts/source-code-pro.git' \
	"$FONT_HOME/adobe-fonts/source-code-pro" && \
  fc-cache -f -v "$FONT_HOME/adobe-fonts/source-code-pro")

ENV http_proxy 10.1.0.9:1088
ENV https_proxy 10.1.0.9:1088

RUN wget https://dl.google.com/go/go1.13.linux-amd64.tar.gz \
  && sudo tar xvf go1.13.linux-amd64.tar.gz \
  && sudo mv go /usr/local \
  &&  export GOROOT=/usr/local/go \
  && export GOPATH=/mnt/workspace/go \
  && export PATH=$GOPATH/bin:$GOROOT/bin:$PATH \
  && go env \
  && git clone --depth 1 https://github.com/junegunn/fzf.git /usr/local/fzf \
  && cd /usr/local/fzf \
  && make install \
  && ./install --all

ENV GOROOT=/usr/local/go
ENV GOPATH=/mnt/workspace/go
ENV PATH="${GOROOT}/bin:${GOROOT}/bin:/usr/local/fzf/bin:${PATH}"

RUN docker_url=https://download.docker.com/linux/static/stable/x86_64 \
  &&  docker_version=18.09.7 \
  &&  curl -fsSL $docker_url/docker-$docker_version.tgz | \
  tar zxvf - --strip 1 -C /usr/bin docker/docker \
  && curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
  && chmod +x /usr/local/bin/docker-compose

#RUN cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
#  echo 'Asia/Shanghai' > /etc/timezone && date
#RUN sed -e 's;UTC=yes;UTC=no;' -i /etc/default/rcS
RUN echo 'LC_ALL=zh_CN.UTF-8' > /etc/default/locale && \
  echo 'LANG=zh_CN.UTF-8' >> /etc/default/locale && \
  locale-gen zh_CN.UTF-8

ENV LC_CTYPE zh_CN.UTF-8

WORKDIR "${WORKSPACE}"

ENTRYPOINT ["asEnvUser"]
CMD ["bash", "-c", "emacs; /bin/bash"]

