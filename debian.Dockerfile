# https://github.com/suisrc/docker-code-server/blob/master/debian.Dockerfile
# https://github.com/suisrc/docker-code-server/releases
# https://github.com/graalvm/graalvm-ce-builds/releases
# https://hub.docker.com/r/suisrc/vscode
FROM suisrc/vscode:1.43.2-3.1.1-debian9

# args
ARG GRAALVM_RELEASE
ARG GRAALVM_URL

ARG MAVEN_RELEASE=3.6.3
ARG MAVEN_URL

ENV GRAALVM_JDK java8

RUN apt-get update && apt-get install -y gcc libz-dev && \
    apt-get autoremove -y && apt-get clean && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

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
# http://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/${MAVEN_RELEASE}/binaries/apache-maven-${MAVEN_RELEASE}-bin.tar.gz"
# https://downloads.apache.org/maven/maven-3/${MAVEN_RELEASE}/binaries/apache-maven-${MAVEN_RELEASE}-bin.tar.gz
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

# extension
RUN echo "**** install code-server extension ****" && \
    #code-server --install-extension mhutchie.git-graph &&\
    #code-server --install-extension intellsmi.comment-translate &&\
    code-server --install-extension redhat.vscode-yaml &&\
    code-server --install-extension redhat.vscode-xml &&\
    code-server --install-extension vscjava.vscode-java-pack
