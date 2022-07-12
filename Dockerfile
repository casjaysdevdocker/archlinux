FROM --platform=linux/amd64 archlinux/archlinux:latest as build

ARG LICENSE=WTFPL \
  IMAGE_NAME=archlinux \
  TIMEZONE=America/New_York \
  PORT=

ENV SHELL=/bin/bash \
  TERM=xterm-256color \
  HOSTNAME=${HOSTNAME:-casjaysdev-$IMAGE_NAME} \
  TZ=$TIMEZONE

RUN mkdir -p /bin/ /config/ /data/ && \
  rm -Rf /bin/.gitkeep /config/.gitkeep /data/.gitkeep && \
  pacman --noconfirm -Syyu --noconfirm && \
  pacman --noconfirm -Syy --noconfirm \
  base-devel \
  bash \
  git && \
  useradd -m -r -s /bin/bash aur && \
  passwd -d aur && \
  echo 'aur ALL=(ALL) ALL' > /etc/sudoers.d/aur && \
  mkdir -p /home/aur/.gnupg && \
  echo 'standard-resolver' > /home/aur/.gnupg/dirmngr.conf && \
  chown -R aur:aur /home/aur && \
  mkdir /build && \
  chown -R aur:aur /build && \
  cd /build && \
  sudo -u aur git clone --depth 1 https://aur.archlinux.org/yay.git && \
  cd yay && \
  sudo -u aur makepkg --noconfirm -si && \
  sudo -u aur yay --afterclean --removemake --save && \
  pacman -Qtdq | xargs -r pacman --noconfirm -Rcns && \
  rm -rf /home/aur/.cache && \
  rm -rf /build && \
  mkdir -p /config && \
  ln -sf /bin/bash /bin/sh

COPY ./bin/. /usr/local/bin/
COPY ./config/. /config/
COPY ./data/. /data/

FROM scratch
ARG BUILD_DATE="$(date +'%Y-%m-%d %H:%M')"

LABEL org.label-schema.name="archlinux" \
  org.label-schema.description="Containerized version of archlinux" \
  org.label-schema.url="https://hub.docker.com/r/casjaysdevdocker/archlinux" \
  org.label-schema.vcs-url="https://github.com/casjaysdevdocker/archlinux" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.version=$BUILD_DATE \
  org.label-schema.vcs-ref=$BUILD_DATE \
  org.label-schema.license="$LICENSE" \
  org.label-schema.vcs-type="Git" \
  org.label-schema.schema-version="latest" \
  org.label-schema.vendor="CasjaysDev" \
  maintainer="CasjaysDev <docker-admin@casjaysdev.com>"

ENV SHELL="/bin/bash" \
  TERM="xterm-256color" \
  HOSTNAME="casjaysdev-archlinux" \
  TZ="${TZ:-America/New_York}"

WORKDIR /root

VOLUME ["/root","/config","/data"]

EXPOSE $PORT

COPY --from=build /. /

HEALTHCHECK CMD ["/usr/local/bin/entrypoint-archlinux.sh", "healthcheck"]

ENTRYPOINT ["/usr/local/bin/entrypoint-archlinux.sh"]
