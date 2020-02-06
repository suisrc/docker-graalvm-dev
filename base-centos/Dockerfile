FROM centos:7
LABEL maintainer="Y13 <suisrc@outlook.com>"

ARG GRAAL_VERSION="19.3.1"
ARG JDK_VERSION="java8"
ARG GRAALVM_PKG="https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-${GRAAL_VERSION}/graalvm-ce-${JDK_VERSION}-linux-amd64-${GRAAL_VERSION}.tar.gz"
ARG LINUX_MIRRORS

# install oracle graalvm-ce 
RUN set -eux && export container=docker &&\
    mkdir -p /graalvm &&\
    curl `#--fail --silent --location --retry 3` -fSL ${GRAALVM_PKG} | tar -zxC /graalvm --strip-components 1 &&\
    rm -rf /tmp/* /var/tmp/* /var/cache/yum &&\
    echo 'PATH="/graalvm/bin:$PATH"' | install --mode 0644 /dev/stdin /etc/profile.d/graal-on-path.sh

ENV PATH=/graalvm/bin:$PATH

CMD ["java", "-version"]