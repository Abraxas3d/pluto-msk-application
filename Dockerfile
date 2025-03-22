FROM ubuntu:24.10
WORKDIR /app
RUN apt update -y
RUN apt upgrade -y
RUN apt install -y wget xz-utils
RUN wget http://releases.linaro.org/components/toolchain/binaries/7.5-2019.12/arm-linux-gnueabihf/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz
RUN tar xvf gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz
RUN rm gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz
ENV PATH=/app/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf/bin/:$PATH

WORKDIR /root
RUN wget https://github.com/analogdevicesinc/plutosdr-fw/releases/download/v0.38/sysroot-v0.38.tar.gz
RUN tar xvfz sysroot-v0.38.tar.gz 
RUN mv staging pluto-0.38.sysroot
RUN rm sysroot-v0.38.tar.gz

WORKDIR /repo
