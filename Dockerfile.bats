FROM balenalib/raspberry-pi2
#FROM arm32v7/debian:stretch-slim
 
RUN apt-get update && apt-get install -y git locales systemd
RUN git clone https://github.com/bats-core/bats-core.git && \
    cd bats-core && \
    ./install.sh /usr/local
RUN adduser openhabian --gecos "Openhabian,,," --disabled-password
RUN echo "openhabian:openhabian" | chpasswd   
RUN /bin/echo -n "Running on " && /usr/bin/arch

COPY . /opt/openhabian/
COPY openhabian.conf.dist /etc/openhabian.conf

WORKDIR /opt/openhabian/
