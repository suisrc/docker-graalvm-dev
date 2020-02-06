FROM centos:7
LABEL maintainer="Y13 <suisrc@outlook.com>"

ARG GRAAL_VERSION="19.3.1"
ARG JDK_VERSION="java8"
ARG GRAALVM_PKG="https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-${GRAAL_VERSION}/graalvm-ce-${JDK_VERSION}-linux-amd64-${GRAAL_VERSION}.tar.gz"
ARG LINUX_MIRRORS

#ENV container docker
# install oracle graalvm-ce 
RUN set -eux && export DEBIAN_FRONTEND=noninteractive &&\
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
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl &&\
    mkdir -p /graalvm &&\
    curl `#--fail --silent --location --retry 3` -fSL ${GRAALVM_PKG} | tar -zxC /graalvm --strip-components 1 &&\
    apt-get autoremove -y && apt-get clean &&\
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* &&\
    echo 'PATH="/graalvm/bin:$PATH"' | install --mode 0644 /dev/stdin /etc/profile.d/graal-on-path.sh

ENV PATH=/graalvm/bin:$PATH

CMD ["java", "-version"]