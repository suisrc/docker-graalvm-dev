# debian镜像体积更小，更适合构建镜像， 所以推荐使用debian构建
FROM centos:7
LABEL maintainer="Y13 <suisrc@outlook.com>"

ARG LINUX_MIRRORS=http://mirrors.aliyun.com

RUN echo "**** update linux ****" && \
    set -eux &&\
    if [ ! -z ${LINUX_MIRRORS+x} ]; then \
        mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak &&\
        curl -fsSL ${LINUX_MIRRORS}/repo/Centos-7.repo -o /etc/yum.repos.d/CentOS-Base.repo &&\
        sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' /etc/yum.repos.d/CentOS-Base.repo &&\
        sed -i 's/gpgcheck=1/gpgcheck=0/g' /etc/yum.repos.d/CentOS-Base.repo &&\
        curl -fsSL ${LINUX_MIRRORS}/repo/epel-7.repo -o /etc/yum.repos.d/epel.repo; \
    fi &&\
    yum clean all && yum makecache && yum update -y &&\
    yum install -y curl gcc libz-dev && \
    rm -rf /tmp/* /var/tmp/* /var/cache/yum

# install oracle graalvm-ce 
RUN echo "**** install graalvm-ce ****" &&\
    set -eux &&\
    if [ -z ${GRAALVM_RELEASE+x} ]; then \
        if [ -z ${GRAALVM_RELEASE+x} ]; then \
            GRAALVM_RELEASE=$(curl -sX GET "https://api.github.com/repos/graalvm/graalvm-ce-builds/releases/latest" \
            | awk '/tag_name/{print $4;exit}' FS='[""]'); \
        fi && \
        GRAALVM_URL=$(curl -sX GET "https://api.github.com/repos/graalvm/graalvm-ce-builds/releases/tags/${GRAALVM_RELEASE}" \
            | jq -r '.assets[] | select(.browser_download_url | contains("graalvm-ce-${GRAALVM_JDK}-linux")) | .browser_download_url'); \
    fi &&\
    mkdir -p /graalvm &&\
    #curl `#--fail --silent --location --retry 3` -fSL ${GRAALVM_URL} | tar -zxC /graalvm --strip-components 1 &&\
    curl -fsSLO --compressed ${GRAALVM_URL} -o /tmp/graalvm-ce.tar.gz &&\
    tar -xzf /tmp/graalvm-ce.tar.gz -C /graalvm --strip-components 1 &&\
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* &&\
    # smoke tests
    java -version

ENV PATH=/graalvm/bin:$PATH
RUN gu install native-image

# mvn
RUN echo "**** install maven ****" &&\
    if [ -z ${MAVEN_URL+x} ]; then \
        MAVEN_URL="https://downloads.apache.org/maven/maven-3/${MAVEN_RELEASE}/binaries/apache-maven-${MAVEN_RELEASE}-bin.tar.gz"; \
    fi &&\
    mkdir -p /usr/share/maven &&\
    curl -L ${MAVEN_URL} -o /tmp/apache-maven.tar.gz &&\
    tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 &&\
    ln -s /usr/share/maven/bin/mvn /usr/bin/mvn &&\
    rm -rf /tmp/* &&\
    # smoke tests
    mvn -version

ENV MAVEN_HOME /usr/share/maven

CMD ["java", "-version"]
