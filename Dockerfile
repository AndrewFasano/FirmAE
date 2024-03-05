FROM ubuntu:18.04
MAINTAINER Mingeun Kim <pr0v3rbs@kaist.ac.kr>, Minkyo Seo <0xsaika@gmail.com>

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -q -yy  \
        apt-utils \
        wget tar bc psmisc ruby telnet \
        socat net-tools iputils-ping iptables iproute2 curl \
        busybox-static bash-static fakeroot git kpartx netcat-openbsd nmap python3-psycopg2 snmp uml-utilities util-linux vlan  \
        libpq-dev \
        mtd-utils gzip bzip2 tar arj lhasa p7zip p7zip-full cabextract fusecram cramfsswap squashfs-tools sleuthkit default-jdk cpio lzop lzma srecord zlib1g-dev liblzma-dev liblzo2-dev \
        python3-magic unrar \
        postgresql sudo \
        openjdk-8-jdk \
        qemu-system-arm qemu-system-mips qemu-system-x86 qemu-utils \
        gnupg gnupg2 \
        ntfs-3g \
        python python3 python3-pip

# google chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list
RUN apt-get update && \
    apt-get install -y \
        google-chrome-stable

RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install \
            psycopg2 psycopg2-binary python-lzo cstruct ubi_reader \
            selenium bs4 requests future paramiko pysnmp==4.4.6 pycryptodome

# for binwalk
RUN wget https://github.com/ReFirmLabs/binwalk/archive/refs/tags/v2.3.4.tar.gz && \
    tar -xf v2.3.4.tar.gz && \
    cd binwalk-2.3.4 && \
    sed -i 's/^install_ubireader//g' deps.sh && \
    echo y | ./deps.sh && \
    python3 setup.py install


RUN ln -s /bin/ntfs-3g /bin/mount.ntfs-3g

# Install static bins
COPY download.sh /tmp/
RUN mkdir -p /work/FirmAE && \
    cd /work/FirmAE/ && \
    bash /tmp/download.sh

# Setup database
COPY database/schema /tmp
RUN service postgresql start && sudo -u postgres psql -c "CREATE USER firmadyne WITH PASSWORD 'firmadyne';" \
  && sudo -u postgres createdb -O firmadyne firmware \
  && sudo -u postgres psql -d firmware < /tmp/schema \
  && service postgresql stop

RUN apt-get update && \
    apt-get install -q -yy  \
        libarchive13

RUN wget 'https://github.com/panda-re/genext2fs/releases/download/release_9bc57e232e8bb7a0e5c8ccf503b57b3b702b973a/genext2fs.deb' && \
    dpkg -i genext2fs.deb

COPY . /work/FirmAE/

RUN mkdir -p /work/firmwares && \
    cp /work/FirmAE/unstuff /usr/local/bin
ENV USER=root