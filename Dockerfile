# syntax=docker/dockerfile:1
FROM ubuntu:22.04

# build参数
ARG user=gzl
ENV DEBIAN_FRONTEND noninteractive

MAINTAINER author "gongzhanli855@163.com"

RUN apt-get update && apt-get install -y apt-utils && apt-get install --reinstall ca-certificates -y
RUN apt-get update && apt-get install -y dialog 
RUN apt-get install whiptail -y
# change source to china source
RUN mv /etc/apt/sources.list /etc/apt/sources.list.back
ADD sources.list /etc/apt/
# install some basic app
RUN apt-get update && apt-get install -y \
    automake \
    build-essential \
    curl \
    git-lfs \
    sudo \
    vim \
    python3 \
    cmake \
    default-jdk \
    shellcheck \
    golang \
 && rm -rf /var/lib/apt/lists/*

# Install bazelisk for target architecture
RUN curl -L https://github.com/bazelbuild/bazelisk/releases/download/v1.10.1/bazelisk-linux-$TARGETARCH -O && \
    mv bazelisk-linux-$TARGETARCH /usr/local/bin/bazel && \
    chmod +x /usr/local/bin/bazel

RUN go install github.com/bazelbuild/buildtools/buildifier@latest && \
    cp ~/go/bin/buildifier /usr/local/bin/

# Get clang-format-15
RUN curl https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && echo "deb http://apt.llvm.org/focal/ llvm-toolchain-focal-15 main" >> /etc/apt/sources.list
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  clang-format-15 \
  && rm -rf /var/lib/apt/lists/*

# add softlink for umicom compile
RUN ln -s /usr/bin/python3 /usr/bin/python

# Default clang-format to clang-format-15
RUN ln -s /usr/bin/clang-format-15 /usr/bin/clang-format

# add group
RUN groupadd -g 1001 gzl

# 添加用户：赋予sudo权限，指定密码
RUN useradd --create-home --no-log-init --shell /bin/bash -u 1001 -g gzl ${user} \
    && adduser ${user} sudo \
    && echo "${user}:gzl123" | chpasswd

# 改变用户的UID和GID
#RUN usermod -u 1001 ${user} && usermod -G 1001 ${user}
# sudoer 添加
RUN mv /etc/sudoers /etc/sudoers.back
ADD sudoers /etc/sudoers
# 指定容器起来的工作目录
WORKDIR /home/${user}

# cmd to build
#docker build --build-arg user=gzl -t gzl_ubuntu_2204:latest .
#docker run -it --shm-size=2048m --rm --network=host -u $(id -u):$(id -g) -v ~/work/:$HOME/work/ -v /tmp/:/tmp/ -v $HOME/.ssh:/home/gzl/.ssh -v $HOME/.bashrc:/home/gzl/.bashrc -v $HOME/.gitconfig:/home/gzl/.gitconfig  -v $HOME/go/bin:/home/gzl/go/bin gzl_ubuntu_2204