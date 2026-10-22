# A clean Ubuntu with cron, git and Python, and the user tester, for tests/run.sh.
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive TZ=America/Mexico_City LANG=C.UTF-8
RUN apt-get update -qq && apt-get install -y -qq bash cron git python3 procps sudo tzdata ca-certificates >/dev/null \
 && ln -snf /usr/share/zoneinfo/America/Mexico_City /etc/localtime \
 && useradd -m -s /bin/bash tester && echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester
