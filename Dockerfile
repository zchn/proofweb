FROM ocaml/opam:ubuntu
MAINTAINER zchn

USER root
RUN apt-get update && apt-get install -y \
    build-essential \
    make \
    gcc \
    wget
RUN opam install ocamlnet ocamlscript
RUN wget https://github.com/zchn/proofweb/archive/master.zip
RUN unzip master.zip
ENV CHROOT /
RUN make -C proofweb-master
