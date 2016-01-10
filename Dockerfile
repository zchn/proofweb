FROM avsm/docker-opam-build:ubuntu-14.04-ocaml-4.02.1
MAINTAINER zchn

RUN apt-get update && apt-get install -y \
    build-essential \
    make \
    gcc \
    ocaml
RUN wget https://github.com/zchn/proofweb/archive/master.zip
RUN unzip master.zip
ENV CHROOT /
RUN make -C proofweb-master
