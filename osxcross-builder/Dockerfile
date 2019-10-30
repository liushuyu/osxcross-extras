# base image, not the final image
FROM ubuntu:18.04
RUN apt-get update
RUN apt-get full-upgrade -y
RUN apt-get install -y build-essential clang wget python2.7 python3 \
 python3-pip python3-distutils cmake git p7zip-full bsdtar curl \
 cpio xz-utils patch pixz llvm sudo libxml2-dev libssl-dev \
 zlib1g-dev liblzma-dev libbz2-dev
COPY * /tmp/
ARG XCODE_USERNAME
ARG XCODE_PASSWORD
ENV XCODE_PASSWORD=$XCODE_PASSWORD
ENV XCODE_USERNAME=$XCODE_USERNAME
RUN /tmp/ci.sh

# second stage
FROM ubuntu:18.04
RUN apt-get update
RUN apt-get full-upgrade -y
RUN apt-get install -y build-essential clang cmake wget git p7zip-full ccache ninja-build
COPY --from=0 /opt/osxcross /opt/osxcross
ENV PATH="${PATH}:/opt/osxcross/bin/"
