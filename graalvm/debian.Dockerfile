FROM debian:stretch-slim

# args
ARG GRAALVM_RELEASE
ARG GRAALVM_URL

ARG MAVEN_RELEASE=3.6.3
ARG MAVEN_URL

ARG LINUX_MIRRORS=http://mirrors.aliyun.com

LABEL maintainer="Y13 <suisrc@outlook.com>"

# install oracle graalvm-ce 
RUN echo "**** update linux ****" && \
    set -eux && export DEBIAN_FRONTEND=noninteractive &&\
    if [ ! -z ${LINUX_MIRRORS+x} ]; then \
        mv /etc/apt/sources.list /etc/apt/sources.list.bak && \
        echo "deb ${LINUX_MIRRORS}/debian/ stretch main non-free contrib" >>/etc/apt/sources.list &&\
        echo "deb-src ${LINUX_MIRRORS}/debian/ stretch main non-free contrib" >>/etc/apt/sources.list &&\
        echo "deb ${LINUX_MIRRORS}/debian-security stretch/updates main" >>/etc/apt/sources.list &&\
        echo "deb-src ${LINUX_MIRRORS}/debian-security stretch/updates main" >>/etc/apt/sources.list &&\
        echo "deb ${LINUX_MIRRORS}/debian/ stretch-updates main non-free contrib" >>/etc/apt/sources.list &&\
        echo "deb-src ${LINUX_MIRRORS}/debian/ stretch-updates main non-free contrib" >>/etc/apt/sources.list &&\
        echo "deb ${LINUX_MIRRORS}/debian/ stretch-backports main non-free contrib" >>/etc/apt/sources.list &&\
        echo "deb-src ${LINUX_MIRRORS}/debian/ stretch-backports main non-free contrib" >>/etc/apt/sources.list; \
    fi &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends ca-certificates curl jq gcc libz-dev &&\
    apt-get clean &&\
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

# install oracle graalvm-ce 
RUN echo "**** install graalvm-ce ****" &&\
    set -eux &&\
    if [ -z ${GRAALVM_RELEASE+x} ]; then \
        if [ -z ${GRAALVM_RELEASE+x} ]; then \
            GRAALVM_RELEASE=$(curl -sX GET "https://api.github.com/repos/graalvm/graalvm-ce-builds/releases/latest" \
            | awk '/tag_name/{print $4;exit}' FS='[""]'); \
        fi && \
        GRAALVM_URL=$(curl -sX GET "https://api.github.com/repos/graalvm/graalvm-ce-builds/releases/tags/${GRAALVM_RELEASE}" \
            | jq -r '.assets[] | select(.browser_download_url | contains("graalvm-ce-java8-linux")) | .browser_download_url'); \
    fi &&\
    mkdir -p /graalvm &&\
    #curl `#--fail --silent --location --retry 3` -fSL ${GRAALVM_URL} | tar -zxC /graalvm --strip-components=1 &&\
    curl -fsSL --compressed ${GRAALVM_URL} -o graalvm-ce.tar.gz &&\
    tar -xzf graalvm-ce.tar.gz -C /graalvm --strip-components=1 &&\
    rm -f graalvm-ce.tar.gz

ENV PATH=/graalvm/bin:$PATH
RUN gu install native-image

ENV JDK_HOME=/graalvm
ENV JAVA_HOME=/graalvm

# mvn
RUN echo "**** install maven ****" &&\
    if [ -z ${MAVEN_URL+x} ]; then \
        MAVEN_URL="https://downloads.apache.org/maven/maven-3/${MAVEN_RELEASE}/binaries/apache-maven-${MAVEN_RELEASE}-bin.tar.gz"; \
    fi &&\
    mkdir -p /usr/share/maven &&\
    curl -fsSL ${MAVEN_URL} -o apache-maven.tar.gz &&\
    tar -xzf apache-maven.tar.gz -C /usr/share/maven --strip-components=1 &&\
    rm -f apache-maven.tar.gz &&\
    ln -s /usr/share/maven/bin/mvn /usr/bin/mvn &&\
    # smoke tests
    mvn -version

ENV MAVEN_HOME /usr/share/maven

CMD ["java", "-version"]
