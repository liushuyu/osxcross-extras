FROM liushuyu/osxcross:latest
RUN apt-get update
RUN apt-get install -y qt5-default qttools5-dev-tools
COPY osxcross-setup.sh /tmp/
RUN bash -e /tmp/osxcross-setup.sh
ENV PATH="${PATH}:/opt/osxcross/bin/"
COPY toolchain.cmake /opt/osxcross/
